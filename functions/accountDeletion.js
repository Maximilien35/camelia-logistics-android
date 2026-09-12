/**
 * Cloud Function (onCall) — suppression réelle de compte, conforme Apple 5.1.1(v).
 *
 * Appelée par l'utilisateur lui-même depuis l'app (Profil > Supprimer mon compte).
 * Utilise l'Admin SDK, donc pas besoin de ré-authentification récente côté client
 * (contrainte habituelle de `user.delete()` côté Firebase Auth client SDK).
 *
 * Portée (voir https://camelialogistics.com/account-deletion/) :
 *  - Le compte Firebase Auth est définitivement supprimé.
 *  - Le document profil (users/{uid}) — nom, téléphone, email — est définitivement supprimé.
 *  - Les photos de colis de l'utilisateur (Storage, préfixe orders/{uid}/) sont supprimées.
 *  - L'historique de commandes (orders) est CONSERVÉ pour la comptabilité/le support
 *    collaborateur, mais anonymisé : plus aucune donnée identifiable n'y reste rattachée.
 */
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { FieldValue } = require('firebase-admin/firestore');

const ORDERS_BATCH_SIZE = 400; // marge sous la limite Firestore de 500 écritures/batch

exports.deleteMyAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'Vous devez être connecté pour supprimer votre compte.'
    );
  }

  const uid = request.auth.uid;
  const db = admin.firestore();

  // 1. Anonymiser les commandes liées à ce compte (on garde l'enregistrement
  //    opérationnel/comptable, on retire tout ce qui identifie l'utilisateur).
  try {
    const ordersSnap = await db
      .collection('orders')
      .where('userId', '==', uid)
      .get();

    for (let i = 0; i < ordersSnap.docs.length; i += ORDERS_BATCH_SIZE) {
      const batch = db.batch();
      ordersSnap.docs.slice(i, i + ORDERS_BATCH_SIZE).forEach((doc) => {
        batch.update(doc.ref, {
          userId: 'deleted_user',
          contactName: FieldValue.delete(),
          contactPhone: FieldValue.delete(),
          photoUrls: [],
          userDeletedAt: FieldValue.serverTimestamp(),
        });
      });
      await batch.commit();
    }
  } catch (err) {
    console.error(`deleteMyAccount: échec anonymisation des commandes pour ${uid}:`, err);
    throw new HttpsError('internal', "Erreur lors de la suppression de l'historique de commandes.");
  }

  // 2. Supprimer les photos de colis de l'utilisateur dans Storage.
  //    Non bloquant : on continue la suppression du compte même en cas d'échec partiel.
  try {
    const bucket = admin.storage().bucket();
    await bucket.deleteFiles({ prefix: `orders/${uid}/` });
  } catch (err) {
    console.error(`deleteMyAccount: échec suppression Storage pour ${uid}:`, err);
  }

  // 3. Supprimer le document profil Firestore (nom, téléphone, email, etc.).
  try {
    await db.collection('users').doc(uid).delete();
  } catch (err) {
    console.error(`deleteMyAccount: échec suppression du profil Firestore pour ${uid}:`, err);
    throw new HttpsError('internal', 'Erreur lors de la suppression du profil.');
  }

  // 4. Supprimer le compte Firebase Auth.
  try {
    await admin.auth().deleteUser(uid);
  } catch (err) {
    console.error(`deleteMyAccount: échec suppression Auth pour ${uid}:`, err);
    throw new HttpsError('internal', 'Erreur lors de la suppression du compte.');
  }

  return { success: true };
});
