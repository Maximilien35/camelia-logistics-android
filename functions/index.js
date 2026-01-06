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
exports.notifyAdminOnNewOrder = firestoreFunc.onDocumentCreated( // ⭐ CORRECTION ICI ⭐
  'orders/{orderId}', // Nom de la collection et du paramètre
  async (event) => {
    const newOrder = event.data?.data();
    if (!newOrder) {
      return;
    }

    const orderId = event.params.orderId;

    // Récupérer le jeton FCM de l'administrateur (on utilise db = admin.firestore())
    const adminSnapshot = await db
      .collection('users')
      .where('role', '==', 'admin')
      .limit(1)
      .get();

    if (adminSnapshot.empty) {
      console.log('Aucun administrateur trouvé.');
      return;
    }

    const adminData = adminSnapshot.docs[0].data();
    const fcmToken = adminData.fcmToken;

    if (!fcmToken) {
      console.log('Jeton FCM de l\'administrateur manquant.');
      return;
    }

    const payload = {
      token: fcmToken,
      notification: {
        title: '🔔 Nouvelle Commande Reçue!',
        body: `Commande #${orderId.substring(0, 6)} est en attente de validation.`,
      },
      data: {
        screen: 'admin_orders_details',
        orderId: orderId,
        status: newOrder.status,
      },
    };

    try {
      // Utilisation de 'messaging' pour l'envoi
      await messaging.send(payload);
      console.log('Notification V2 envoyée à l\'admin pour la commande:', orderId);
    } catch (error) {
      console.error('Erreur lors de l\'envoi à l\'admin (V2):', error);
    }
  }
);

/**
 * 2. Notification au Client (Validation de Commande)
 * Se déclenche lorsqu'une commande passe de PENDING à ACCEPTED.
 */
exports.notifyClientOnOrderUpdate = firestoreFunc.onDocumentUpdated( // ⭐ CORRECTION ICI ⭐
  'orders/{orderId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) {
      return;
    }

    // Vérifier si le statut a changé de PENDING à ACCEPTED
    if (before.status === 'PENDING' && after.status === 'ACCEPTED') {
      const userId = after.userId;
      const orderId = event.params.orderId;

      // Récupérer le jeton FCM du client (on utilise db = admin.firestore())
      const userDoc = await db.collection('users').doc(userId).get();
      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        console.log(`Jeton FCM du client ${userId} manquant.`);
        return;
      }

      const price = after.priceQuote;

      const payload = {
        token: fcmToken,
        notification: {
          title: '✅ Commande Validée !',
          body: `Votre devis est prêt. Prix: ${price} FCFA. Cliquez pour voir les détails.`,
        },
        data: {
          screen: 'client_order_waiting',
          orderId: orderId,
          status: after.status,
        },
      };

      try {
        // Utilisation de 'messaging' pour l'envoi
        await messaging.send(payload);
        console.log('Notification V2 envoyée au client pour la validation:', orderId);
      } catch (error) {
        console.error('Erreur lors de l\'envoi au client (V2):', error);
      }
    }
  }
);