/**
 * Cloud Functions V2 (Node.js 22) pour Camelia Logistics
 * - setAdminRole & setDelivererRole (Permissions & UI)
 * - notifyAdminOnNewOrder & notifyClientOnOrderUpdate (Notifications FCM)
 */

// --- IMPORTS V2 ET ADMIN SDK ---
const { onCall } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
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
 * 1. Notification à l'Administrateur (Création & Mise à jour de Commande)
 * Se déclenche lorsqu'une NOUVELLE commande est créée ou lorsqu'un client ACCEPTE un devis.
 */
exports.notifyAdminOnNewOrder = firestoreFunc.onDocumentWritten( // Remplacé par onDocumentWritten pour gérer créations et mises à jour
  'orders/{orderId}',
  async (event) => {
    const orderId = event.params.orderId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    let notificationDetails = null;

    // Cas 1: NOUVELLE commande (document créé)
    if (!before && after) {
      notificationDetails = {
        title: '🔔 Nouvelle Commande Reçue!',
        body: `La commande #${orderId.substring(0, 6)} attend votre validation.`,
        status: after.status,
      };
    }
    // Cas 2: Le client ACCEPTE le devis (mise à jour du statut)
    else if (before && after && before.status !== after.status && after.status === 'ACCEPTED') {
      let clientName = 'Un client';
      if (after.userId) {
        try {
          const userDoc = await db.collection('users').doc(after.userId).get();
          if (userDoc.exists) {
            clientName = userDoc.data().name || clientName;
          }
        } catch (e) {
          console.error("Erreur en récupérant le nom du client:", e);
        }
      }

      notificationDetails = {
        title: '✅ Devis Accepté !',
        body: `${clientName} a validé le prix pour la commande #${orderId.substring(0, 6)}.`,
        status: after.status,
      };
    }

    // Si aucun des cas ne correspond, on arrête la fonction.
    if (!notificationDetails) {
      return;
    }

    // --- Logique commune pour l'envoi de notification aux admins ---
    const adminsSnapshot = await db
      .collection('users')
      .where('role', '==', 'admin')
      .get();

    if (adminsSnapshot.empty) {
      console.log("Aucun administrateur trouvé pour la notification.");
      return;
    }

    const tokens = [];
    const adminIds = [];
    adminsSnapshot.forEach(doc => {
      const adminData = doc.data();
      if (adminData?.fcmToken) {
        tokens.push(adminData.fcmToken);
        adminIds.push(doc.id);
      }
    });

    if (tokens.length === 0) {
      console.log("Aucun token FCM trouvé pour les administrateurs pour l'événement pertinent.");
      return;
    }

    const message = {
      notification: {
        title: notificationDetails.title,
        body: notificationDetails.body,
      },
      data: {
        screen: 'admin_orders_details',
        orderId: String(orderId),
        status: String(notificationDetails.status),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      tokens: tokens,
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`Notification admin envoyée: ${response.successCount} succès, ${response.failureCount} échecs.`);

      // Nettoyage des tokens invalides
      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const error = resp.error;
            console.error(`Échec pour le token ${tokens[idx]}:`, error.code);
            
            if (error.code === 'messaging/invalid-registration-token' ||
              error.code === 'messaging/registration-token-not-registered') {
              db.collection('users').doc(adminIds[idx]).update({ fcmToken: admin.firestore.FieldValue.delete() });
            }
          }
        });
      }
    } catch (error) {
      console.error('Erreur fatale lors de l\'envoi FCM aux admins:', error);
    }
  }
);

/**
 * 2. Notification au Client (Validation de Commande)
 * Se déclenche pour les changements de statut importants (ASSIGNED, COMPLETED, CANCELLED).
 */
exports.notifyClientOnOrderUpdate = firestoreFunc.onDocumentUpdated( 
  'orders/{orderId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) {
      return;
    }

    // Liste des statuts nécessitant une notification
    const statusChanged = after.status !== before.status;
    const importantStatuses = ['ASSIGNED', 'COMPLETED', 'CANCELLED'];

    if (statusChanged && importantStatuses.includes(after.status)) {
      const userId = after.userId;
      const orderId = event.params.orderId;

      const userDoc = await db.collection('users').doc(userId).get();
      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        console.log(`Notification annulée : Jeton FCM introuvable pour le client ${userId} (Compte peut-être supprimé).`);
        return;
      }

      let title = 'Mise à jour de votre commande';
      let body = `Le statut de votre commande est maintenant : ${after.status}`;

      switch (after.status) {
          case 'ASSIGNED':
              title = '✅ Commande Validée !';
              body = `Votre commande a été assignée. Prix final : ${after.priceQuote || 0} FCFA. Un chauffeur arrive.`;
              break;
          case 'COMPLETED':
              title = '📦 Colis Livré';
              body = 'Votre colis est arrivé à destination. Merci de votre confiance !';
              break;
          case 'CANCELLED':
              title = '❌ Commande Annulée';
              body = 'Votre commande a été annulée. Contactez le support pour plus d\'infos.';
              break;
      }

      const payload = {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          screen: 'client_order_waiting', // Redirige vers l'écran de résumé/attente
          orderId: orderId,
          status: after.status,
        },
      };

      try {
        await messaging.send(payload); 
        console.log(`Notification envoyée au client ${userId} pour le statut ${after.status}`);
      } catch (error) {
        console.error('Erreur lors de l\'envoi au client (V2):', error);
      }
    }
  });

// --- 3. FONCTIONS MARKETING & RAPPELS (AUTOMATISATION) ---

/**
 * 3. Campagne Marketing (Admin)
 * Permet à un administrateur d'envoyer une notification à TOUS les utilisateurs.
 * Utile pour : Promotions, Annonces, Vœux.
 */
exports.sendMarketingCampaign = onCall(async (request) => {
    // 1. Vérification Sécurité (Admin seulement)
    if (!request.auth || request.auth.token.role !== 'admin') {
        throw new Error('Permission refusée. Seuls les administrateurs peuvent envoyer des campagnes.');
    }

    const { title, body, imageUrl } = request.data;

    if (!title || !body) {
        throw new Error('Titre et message requis.');
    }

    try {
        // 2. Récupération de tous les tokens utilisateurs
        // Note: Pour une très grande base de données, il faudrait utiliser les "Topics" FCM ou diviser en lots via TaskQueue.
        const usersSnapshot = await db.collection('users').where('fcmToken', '!=', null).get();
        
        if (usersSnapshot.empty) {
            return { success: true, message: "Aucun utilisateur avec token trouvé." };
        }

        const tokens = [];
        usersSnapshot.forEach(doc => {
            const data = doc.data();
            if (data.fcmToken) tokens.push(data.fcmToken);
        });

        // 3. Préparation du message
        const message = {
            notification: {
                title: title,
                body: body,
                ...(imageUrl && { imageUrl: imageUrl }) // Ajoute l'image si présente
            },
            data: {
                screen: 'home_custom', // Redirige vers l'accueil client
                type: 'MARKETING'
            },
            tokens: tokens
        };

        // 4. Envoi en masse (Multicast gère jusqu'à 500 tokens par appel, ici on simplifie pour l'exemple)
        // Pour la prod : découper le tableau `tokens` en chunks de 500.
        const response = await messaging.sendEachForMulticast(message);

        console.log(`Campagne marketing envoyée : ${response.successCount} succès.`);

        return { 
            success: true, 
            sentCount: response.successCount, 
            failureCount: response.failureCount 
        };

    } catch (error) {
        console.error("Erreur campagne marketing:", error);
        throw new Error("Erreur lors de l'envoi de la campagne.");
    }
});

/**
 * 4. Réengagement Automatique (Cron Job)
 * S'exécute tous les dimanches à 10h00.
 * Vérifie les utilisateurs inactifs depuis > 30 jours et envoie un rappel.
 */
exports.reengageInactiveUsers = onSchedule("every sunday 10:00", async (event) => {
    const thirtyDaysAgo = admin.firestore.Timestamp.fromMillis(Date.now() - (30 * 24 * 60 * 60 * 1000));

    try {
        // Trouver les utilisateurs inactifs
        const inactiveUsersSnapshot = await db.collection('users')
            .where('lastActive', '<', thirtyDaysAgo)
            .where('fcmToken', '!=', null)
            .limit(100) // Limite pour éviter de spammer ou dépasser les quotas en une fois
            .get();

        if (inactiveUsersSnapshot.empty) return;

        const tokens = [];
        inactiveUsersSnapshot.docs.forEach(doc => tokens.push(doc.data().fcmToken));

        if (tokens.length > 0) {
            const message = {
                notification: {
                    title: "Vous nous manquez ! 🚚",
                    body: "Besoin d'une livraison rapide ? Revenez profiter de nos services express.",
                },
                tokens: tokens
            };
            await messaging.sendEachForMulticast(message);
            console.log(`Rappel inactivité envoyé à ${tokens.length} utilisateurs.`);
        }
    } catch (error) {
        console.error("Erreur réengagement:", error);
    }
});