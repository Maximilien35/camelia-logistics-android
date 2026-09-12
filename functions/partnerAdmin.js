/**
 * Cloud Functions V2 (onCall) réservées aux admins pour gérer les entreprises
 * partenaires B2B (création, rotation de clé API, suspension).
 *
 * La clé API en clair n'est JAMAIS stockée : seul son hash SHA-256 est persisté
 * dans Firestore. Elle n'est renvoyée à l'appelant qu'au moment de sa génération
 * (création ou rotation) — comme chez Stripe/EasyPost.
 */
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { FieldValue } = require('firebase-admin/firestore');
const {
  generateApiKey,
  hashApiKey,
  apiKeyPrefixFor,
  generateWebhookSecret,
} = require('./lib/partnerCrypto');

function requireAdmin(request) {
  if (!request.auth || request.auth.token.role !== 'admin') {
    throw new HttpsError('permission-denied', 'Réservé aux administrateurs.');
  }
}

exports.createPartner = onCall(async (request) => {
  requireAdmin(request);

  const { name, contactEmail, webhookUrl } = request.data || {};
  if (!name || typeof name !== 'string' || !name.trim()) {
    throw new HttpsError('invalid-argument', 'Le nom du partenaire est requis.');
  }

  const db = admin.firestore();
  const plainKey = generateApiKey();
  const webhookSecret = generateWebhookSecret();

  const partnerRef = db.collection('partners').doc();
  await partnerRef.set({
    name: name.trim(),
    contactEmail: contactEmail || null,
    status: 'active',
    apiKeyHash: hashApiKey(plainKey),
    apiKeyPrefix: apiKeyPrefixFor(plainKey),
    webhookUrl: webhookUrl || null,
    webhookSecret,
    monthlyOrderCount: 0,
    createdAt: FieldValue.serverTimestamp(),
    createdBy: request.auth.uid,
  });

  return {
    success: true,
    partnerId: partnerRef.id,
    // Clé en clair : n'est JAMAIS renvoyée ni consultable après cet appel.
    apiKey: plainKey,
  };
});

exports.rotatePartnerApiKey = onCall(async (request) => {
  requireAdmin(request);

  const { partnerId } = request.data || {};
  if (!partnerId) {
    throw new HttpsError('invalid-argument', 'partnerId est requis.');
  }

  const db = admin.firestore();
  const partnerRef = db.collection('partners').doc(partnerId);
  const snap = await partnerRef.get();
  if (!snap.exists) {
    throw new HttpsError('not-found', 'Partenaire introuvable.');
  }

  const plainKey = generateApiKey();
  await partnerRef.update({
    apiKeyHash: hashApiKey(plainKey),
    apiKeyPrefix: apiKeyPrefixFor(plainKey),
    keyRotatedAt: FieldValue.serverTimestamp(),
    keyRotatedBy: request.auth.uid,
  });

  return { success: true, apiKey: plainKey };
});

async function setPartnerStatus(request, status) {
  requireAdmin(request);
  const { partnerId } = request.data || {};
  if (!partnerId) {
    throw new HttpsError('invalid-argument', 'partnerId est requis.');
  }

  const db = admin.firestore();
  const partnerRef = db.collection('partners').doc(partnerId);
  const snap = await partnerRef.get();
  if (!snap.exists) {
    throw new HttpsError('not-found', 'Partenaire introuvable.');
  }

  await partnerRef.update({
    status,
    statusChangedAt: FieldValue.serverTimestamp(),
    statusChangedBy: request.auth.uid,
  });

  return { success: true, status };
}

exports.suspendPartner = onCall((request) => setPartnerStatus(request, 'suspended'));
exports.reactivatePartner = onCall((request) => setPartnerStatus(request, 'active'));

exports.listPartners = onCall(async (request) => {
  requireAdmin(request);

  const db = admin.firestore();
  const snap = await db.collection('partners').orderBy('createdAt', 'desc').get();

  return {
    partners: snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        name: data.name,
        contactEmail: data.contactEmail || null,
        status: data.status,
        apiKeyPrefix: data.apiKeyPrefix,
        webhookUrl: data.webhookUrl || null,
        monthlyOrderCount: data.monthlyOrderCount || 0,
        createdAt: data.createdAt ? data.createdAt.toMillis() : null,
        // apiKeyHash / webhookSecret volontairement exclus de la réponse.
      };
    }),
  };
});
