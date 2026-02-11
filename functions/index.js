/**
 * Cloud Functions V2 (Node.js 22) pour Camelia Logistics
 * - setAdminRole & setDelivererRole (Permissions & UI)
 * - notifyAdminOnNewOrder & notifyClientOnOrderUpdate (Notifications FCM)
 */

// --- IMPORTS V2 ET ADMIN SDK ---
const { onCall } = require('firebase-functions/v2/https');
// On importe le module firestore V2 complet sous l'alias 'firestoreFunc'
const firestoreFunc = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

// Initialisation de l'Admin SDK
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging(); // Import du service de messagerie (FCM)

// --- 1. FONCTIONS DE GESTION DES RÔLES (HTTPS V2) ---

/**
 * Définit le rôle 'admin' pour un utilisateur spécifié.
 * Type de déclencheur: Appelable HTTPS.
 */
exports.setAdminRol = onCall(async (request) => {
    const targetUid = request.data.uid;

    // Sécurité: Assurez-vous que l'appelant est authentifié
    if (!request.auth) {
        // Dans une application réelle, vous vérifieriez si l'appelant est déjà admin
        throw new Error('L\'appelant doit être authentifié.');
    }

    if (!targetUid) {
        throw new Error('L\'UID de l\'utilisateur cible est manquant.');
    }

    try {
        // 1. Définition du Custom Claim (Sécurité)
        await admin.auth().setCustomUserClaims(targetUid, { role: 'admin' });

        // 2. MISE À JOUR DANS FIRESTORE (Interface Utilisateur)
        await db.collection('users').doc(targetUid).update({ role: 'admin' });

        return {
            message: `Succès : Rôle 'admin' attribué à l'UID: ${targetUid}.`,
            success: true
        };

    } catch (error) {
        console.error("Erreur lors de l'attribution du rôle admin:", error);
        throw new Error('Échec de l\'attribution du rôle admin.');
    }
});


/**
 * Définit le rôle 'deliverer' pour un utilisateur spécifié.
 * Type de déclencheur: Appelable HTTPS.
 */
exports.setDelivererRol = onCall(async (request) => {
    const targetUid = request.data.uid;

    if (!request.auth) {
        // Dans une application réelle, vous vérifieriez si l'appelant est déjà admin
        throw new Error('L\'appelant doit être authentifié.');
    }

    if (!targetUid) {
        throw new Error('L\'UID est manquant.');
    }

    try {
        // 1. Définition du Custom Claim
        await admin.auth().setCustomUserClaims(targetUid, { role: 'deliverer' });

        // 2. MISE À JOUR DANS FIRESTORE (Interface Utilisateur)
        await db.collection('users').doc(targetUid).update({ role: 'deliverer' });

        return { message: 'Rôle Livreur attribué.', success: true };
    } catch (error) {
        console.error("Erreur lors de l'attribution du rôle livreur:", error);
        throw new Error('Échec de l\'attribution du rôle livreur.');
    }
});


// --- 2. FONCTIONS DE NOTIFICATION (FIRESTORE V2) ---

/**
 * 1. Notification à l'Administrateur (Création de Commande)
 * Se déclenche lorsqu'une NOUVELLE commande est ajoutée (status: PENDING).
 */
exports.notifyAdminOnNewOrder = firestoreFunc.onDocumentCreated(
  'orders/{orderId}', 
  async (event) => {
    const newOrder = event.data?.data();
    if (!newOrder) return;

    const orderId = event.params.orderId;

    // Récupérer les administrateurs
    const adminsSnapshot = await db
      .collection('users')
      .where('role', '==', 'admin')
      .get();

    if (adminsSnapshot.empty) {
      console.log("Aucun administrateur trouvé.");
      return;
    }

    const tokens = [];
    const adminIds = []; // CORRECTION : Initialisation du tableau des IDs
    adminsSnapshot.forEach(doc => {
      const adminData = doc.data();
      if (adminData && adminData.fcmToken) {
        tokens.push(adminData.fcmToken);
        adminIds.push(doc.id); // CORRECTION : On sauvegarde l'ID correspondant au token
      }
    });

    if (tokens.length === 0) {
      console.log("Aucun token FCM trouvé pour les administrateurs.");
      return;
    }

    // --- NOUVELLE STRUCTURE DE MESSAGE (FCM v1) ---
    const message = {
      notification: {
        title: '🔔 Nouvelle Commande Reçue!',
        body: `Commande #${orderId.substring(0, 6)} est en attente de validation.`,
      },
      data: {
        screen: 'admin_orders_details',
        orderId: String(orderId),
        status: String(newOrder.status),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      tokens: tokens, 
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      
      console.log(`Notification envoyée : ${response.successCount} succès, ${response.failureCount} échecs.`);
      
      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const error = resp.error;
            console.error(`Échec pour le token ${tokens[idx]}:`, error.code);
            
            if (error.code === 'messaging/invalid-registration-token' ||
                error.code === 'messaging/registration-token-not-registered') {
                // CORRECTION : adminIds est maintenant défini et accessible
                db.collection('users').doc(adminIds[idx]).update({ fcmToken: admin.firestore.FieldValue.delete() });
            }
          }
        });
      }
    } catch (error) {
      console.error('Erreur fatale lors de l\'envoi FCM:', error);
    }
  }
);

/**
 * 2. Notification au Client (Validation de Commande)
 * Se déclenche lorsqu'une commande passe de PENDING à ACCEPTED.
 */
exports.notifyClientOnOrderUpdate = firestoreFunc.onDocumentUpdated( 
  'orders/{orderId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) {
      return;
    }

    // Déclencher lorsque la commande passe à 'ASSIGNED' (Assignée/Validée par admin)
    if (after.status === 'ASSIGNED' && before.status !== 'ASSIGNED') {
      const userId = after.userId;
      const orderId = event.params.orderId;

      const userDoc = await db.collection('users').doc(userId).get();
      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        console.log(`Jeton FCM du client ${userId} manquant.`);
        return;
      }

      // On s'assure d'avoir un prix par défaut si null
      const price = after.priceQuote || 0;

      const payload = {
        token: fcmToken,
        notification: {
          title: '✅ Commande validée !',
          body: `Votre commande a été assignée. Prix final : ${price} FCFA.`,
        },
        data: {
          screen: 'client_order_waiting', // Redirige vers l'écran de résumé/attente
          orderId: orderId,
          status: after.status,
        },
      };

      try {
        await messaging.send(payload);
        console.log('Notification V2 envoyée au client pour le devis:', orderId);
      } catch (error) {
        console.error('Erreur lors de l\'envoi au client (V2):', error);
      }
    }
  });