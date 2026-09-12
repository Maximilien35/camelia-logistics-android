/**
 * API REST B2B pour les entreprises partenaires (Cloud Function V2 onRequest + Express).
 *
 * Authentification : header `Authorization: Bearer <clé API>` (clé générée via
 * la fonction onCall `createPartner`, réservée aux admins).
 *
 * Voir docs/partner-api.md pour la référence complète destinée aux partenaires.
 */
const { onRequest } = require('firebase-functions/v2/https');
const express = require('express');
const cors = require('cors');
const { z } = require('zod');
const admin = require('firebase-admin');
const { FieldValue, Timestamp } = require('firebase-admin/firestore');
const { hashApiKey } = require('./lib/partnerCrypto');

const RATE_LIMIT_PER_MINUTE = 60;
const IMPORTANT_ORDER_FIELDS = [
  'id',
  'status',
  'serviceType',
  'pickupAddress',
  'dropoffAddress',
  'packageNature',
  'vehicleType',
  'priceQuote',
  'isQuote',
  'estimatedDistanceKm',
  'contactName',
  'contactPhone',
  'partnerOrderRef',
  'source',
  'partnerId',
  'delivererId',
  'createdAt',
];

const coordsSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
});

const orderSchema = z.object({
  partnerOrderRef: z.string().min(1).max(100),
  serviceType: z.string().min(1).max(60),
  pickupAddress: z.string().min(1).max(300),
  dropoffAddress: z.string().min(1).max(300),
  packageNature: z.string().min(1).max(300),
  vehicleType: z.string().min(1).max(60),
  description: z.string().max(1000).optional(),
  contactName: z.string().min(1).max(120),
  contactPhone: z.string().min(3).max(30),
  photoUrls: z.array(z.string().url()).max(10).optional(),
  additionalDetails: z.record(z.any()).optional(),
  // Optionnels : si fournis pour serviceType 'LIVRAISON', un prix ferme est
  // renvoyé immédiatement dans la réponse (voir computeLivraisonPrice
  // ci-dessous). Sans ces coordonnées, la commande part en devis (isQuote:true)
  // comme avant, en attente d'un prix posé manuellement côté admin.
  pickupCoords: coordsSchema.optional(),
  dropoffCoords: coordsSchema.optional(),
});

/**
 * Distance à vol d'oiseau (km) entre deux points GPS — formule de Haversine.
 * Approximation volontairement simple : suffisante pour une tarification
 * indicative immédiate, pas pour un calcul d'itinéraire routier précis.
 */
function haversineDistanceKm(a, b) {
  const toRad = (deg) => (deg * Math.PI) / 180;
  const R = 6371; // rayon moyen de la Terre en km
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

const LIVRAISON_RATE_PER_KM_BEYOND_8 = 150;
function computeLivraisonPrice(distanceKm) {
  if (distanceKm <= 3) return 1000;
  if (distanceKm <= 8) return 1500;

  return Math.round(2000 + (distanceKm - 8) * LIVRAISON_RATE_PER_KM_BEYOND_8);
}

function db() {
  return admin.firestore();
}


function asyncHandler(fn) {
  return (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
}

async function authenticatePartner(req, res, next) {
  const header = req.get('authorization') || '';
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    return res.status(401).json({ error: 'unauthorized', message: 'En-tête Authorization: Bearer <clé> requis.' });
  }

  const apiKeyHash = hashApiKey(match[1].trim());
  const snap = await db()
    .collection('partners')
    .where('apiKeyHash', '==', apiKeyHash)
    .limit(1)
    .get();

  if (snap.empty) {
    return res.status(401).json({ error: 'unauthorized', message: 'Clé API invalide.' });
  }

  const partnerDoc = snap.docs[0];
  const partner = partnerDoc.data();
  if (partner.status !== 'active') {
    return res.status(403).json({ error: 'forbidden', message: 'Ce compte partenaire est suspendu.' });
  }

  req.partner = { id: partnerDoc.id, ...partner };
  return next();
}

/** Garde-fou anti-abus léger : ≤60 requêtes/minute/partenaire. */
async function rateLimit(req, res, next) {
  const minuteBucket = Math.floor(Date.now() / 60000);
  const bucketRef = db()
    .collection('partners')
    .doc(req.partner.id)
    .collection('rateLimits')
    .doc(String(minuteBucket));

  const bucketSnap = await bucketRef.get();
  const currentCount = bucketSnap.exists ? bucketSnap.data().count || 0 : 0;

  if (currentCount >= RATE_LIMIT_PER_MINUTE) {
    return res.status(429).json({ error: 'rate_limited', message: 'Trop de requêtes, réessayez dans une minute.' });
  }

  await bucketRef.set(
    {
      count: FieldValue.increment(1),
      expiresAt: Timestamp.fromMillis((minuteBucket + 2) * 60000),
    },
    { merge: true }
  );
  return next();
}

function serializeOrder(id, data) {
  const out = { id };
  for (const field of IMPORTANT_ORDER_FIELDS) {
    if (field === 'id') continue;
    if (field === 'createdAt') {
      out.createdAt = data.timestamp ? data.timestamp.toDate().toISOString() : null;
      continue;
    }
    out[field] = data[field] !== undefined ? data[field] : null;
  }
  return out;
}

const app = express();
app.use(cors({ origin: true }));
app.use(express.json({ limit: '1mb' }));
app.use(asyncHandler(authenticatePartner));
app.use(asyncHandler(rateLimit));

// POST /v1/orders — création idempotente d'une commande.
app.post('/v1/orders', asyncHandler(async (req, res) => {
  const parsed = orderSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'invalid_request', details: parsed.error.flatten() });
  }
  const payload = parsed.data;
  const ordersRef = db().collection('orders');

  // Idempotence : un même (partnerId, partnerOrderRef) ne crée jamais deux commandes.
  const existing = await ordersRef
    .where('partnerId', '==', req.partner.id)
    .where('partnerOrderRef', '==', payload.partnerOrderRef)
    .limit(1)
    .get();

  if (!existing.empty) {
    const doc = existing.docs[0];
    return res.status(200).json({ order: serializeOrder(doc.id, doc.data()) });
  }

  // Prix ferme immédiat pour LIVRAISON quand les coordonnées GPS sont fournies
  // (mêmes paliers que l'app, voir computeLivraisonPrice ci-dessus) : le
  // partenaire n'a pas à attendre qu'un admin pose un devis à la main.
  // Sans coordonnées, ou pour tout autre service, comportement inchangé (devis).
  let isQuote = true;
  let priceQuote = null;
  let estimatedDistanceKm = null;
  if (
    payload.serviceType === 'LIVRAISON' &&
    payload.pickupCoords &&
    payload.dropoffCoords
  ) {
    const rawDistanceKm = haversineDistanceKm(payload.pickupCoords, payload.dropoffCoords);
    priceQuote = computeLivraisonPrice(rawDistanceKm);
    // Le prix (déjà arrondi) est calculé sur la distance brute ; on n'arrondit
    // qu'ensuite la valeur exposée dans la réponse (purement informative).
    estimatedDistanceKm = Math.round(rawDistanceKm * 10) / 10;
    isQuote = false;
  }

  const now = Timestamp.now();
  const orderData = {
    userId: req.partner.id,
    source: 'partner_api',
    partnerId: req.partner.id,
    partnerOrderRef: payload.partnerOrderRef,
    serviceType: payload.serviceType,
    pickupAddress: payload.pickupAddress,
    dropoffAddress: payload.dropoffAddress,
    packageNature: payload.packageNature,
    vehicleType: payload.vehicleType,
    description: payload.description || null,
    contactName: payload.contactName,
    contactPhone: payload.contactPhone,
    photoUrls: payload.photoUrls || [],
    additionalDetails: payload.additionalDetails || {},
    status: 'PENDING',
    isQuote,
    priceQuote,
    estimatedDistanceKm,
    delivererId: null,
    timestamp: now,
  };

  const docRef = await ordersRef.add(orderData);
  await db()
    .collection('partners')
    .doc(req.partner.id)
    .update({ monthlyOrderCount: FieldValue.increment(1) });

  return res.status(201).json({ order: serializeOrder(docRef.id, orderData) });
}));

// GET /v1/orders/:id — statut d'une commande appartenant au partenaire authentifié.
app.get('/v1/orders/:id', asyncHandler(async (req, res) => {
  const doc = await db().collection('orders').doc(req.params.id).get();
  if (!doc.exists || doc.data().partnerId !== req.partner.id) {
    return res.status(404).json({ error: 'not_found', message: 'Commande introuvable.' });
  }
  return res.status(200).json({ order: serializeOrder(doc.id, doc.data()) });
}));

// GET /v1/orders — liste paginée des commandes du partenaire authentifié.
app.get('/v1/orders', asyncHandler(async (req, res) => {
  const limit = Math.min(Number(req.query.limit) || 20, 100);
  let query = db()
    .collection('orders')
    .where('partnerId', '==', req.partner.id)
    .orderBy('timestamp', 'desc')
    .limit(limit);

  if (req.query.status) {
    query = query.where('status', '==', String(req.query.status));
  }

  const snap = await query.get();
  return res.status(200).json({
    orders: snap.docs.map((doc) => serializeOrder(doc.id, doc.data())),
  });
}));

app.use((req, res) => {
  res.status(404).json({ error: 'not_found', message: 'Route inconnue.' });
});

// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error('Erreur API partenaire:', err);
  res.status(500).json({ error: 'internal_error', message: 'Erreur interne.' });
});

// invoker: 'public' est indispensable en v2 : sans cela, Cloud Functions bloque
// tout appel non authentifié Google IAM avant même d'atteindre Express.
exports.partnerApi = onRequest({ region: 'us-central1', invoker: 'public' }, app);
