import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../userProfile.dart';

class UserProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Nom de la collection où nous stockons les profils (et les tokens)
  final String _collectionName = 'users';
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  // --- 1. SAUVEGARDER/CRÉER UN PROFIL (Utilisé à l'inscription) ---
  Future<void> saveDeliverer(
    String name,
    String phoneNumber,
    String vehicle,
    String location,
  ) async {
    try {
      final docRef = _usersCollection.doc();
      final id = docRef.id;
      final newDeliverer = UserProfile(
        uid: id,
        name: name,
        phoneNumber: phoneNumber,
        vehicle: vehicle,
        email: '',
        location: location,
        role: 'deliverer',
      );
      await docRef.set(newDeliverer.toJson());
      if (kDebugMode) {
        print("chauffeur enregistrer avec succes");
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print(
          'Erreur Firebase lors de l\'enregistrement du chauffeur : ${e.code} - ${e.message}',
        );
      }
      // Relancez l'exception pour la gérer dans l'interface utilisateur de l'administrateur
      throw Exception("Échec de l'enregistrement du chauffeur : ${e.message}");
    } catch (e) {
      if (kDebugMode) {
        print('Erreur inconnue lors de l\'enregistrement du chauffeur : $e');
      }
      throw Exception("Échec de l'enregistrement du chauffeur : $e");
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _usersCollection
        .doc(profile.uid)
        .set(profile.toJson(), SetOptions(merge: true));
  }

  // --- 2. RÉCUPÉRER LE PROFIL (Utilisé sur l'écran d'accueil) ---

  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  /// Sauvegarde ou met à jour le jeton FCM pour un utilisateur donné.
  Future<void> saveFCMToken(String userId, String token) async {
    try {
      await _db.collection(_collectionName).doc(userId).set({
        'fcmToken': token,
        'lastActive':
            FieldValue.serverTimestamp(), // Utile pour savoir si le token est encore actif
      }, SetOptions(merge: true));
      // Utilisation de merge: true pour ne pas écraser d'autres champs du profil
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la sauvegarde du token FCM : $e");
      }
    }
  }

  // --- 4. ÉCOUTER LE PROFIL EN TEMPS RÉEL (Optionnel pour l'UI) ---
  Stream<UserProfile?> streamProfile(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      // 1. Vérification standard de l'existence
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      // 2. Récupération sécurisée des données
      final data = snapshot.data();

      // 3. Vérification du type (pour être sûr que c'est bien une Map<String, dynamic>)
      if (data is Map<String, dynamic>) {
        // 4. Conversion si le type est correct
        return UserProfile.fromJson(data);
      }

      // Si ce n'est pas une map, on pourrait logguer une erreur ou retourner null
      if (kDebugMode) {
        print(
          "Erreur de format de document pour l'utilisateur $uid: données non-Map.",
        );
      }
      return null;
    });
  }

  Future<void> updateProfile({
    required String email,
    required String phone,
    required String name,
    required String uid,
  }) async {
    try {
      // 1. Obtenir la référence du document
      DocumentReference docRef = _usersCollection.doc(uid);

      // 2. Mettre à jour le champ 'status'
      await docRef.update({
        'name': name,
        'phoneNumber': phone,
        // Optionnel : ajouter un champ de date de mise à jour
        'email': email,
      });

      SnackBar(content: Text('le profil $uid a ete  mis à jour à'));
    } catch (e) {
      print("Erreur lors de la mise à jour du statut de la commande : $e");
      rethrow;
    }
  }

  Future<int?> calculateAndSetClientRank({
    required String uid,
    required String stat,
  }) async {
    try {
      final querySnapshot = await _db
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .where(
            'status',
            isEqualTo: stat,
          ) // Compter uniquement les commandes terminées
          .get();

      final int orderCount = querySnapshot.docs.length;
      return orderCount;
      // 2. Déterminer le rang (Vous pouvez ajuster les seuils ci-dessous)
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors du calcul du rang client: $e");
      }
      // Gérer l'erreur (par exemple, logguer ou afficher un message à l'administrateur)
    }
    return null;
  }

  Stream<List<UserProfile>>? getDeliverersStream() {
    // 1. Configure la requête : filtre par rôle et trie (timestamp doit exister en BD)
    return _usersCollection
        .where('role', isEqualTo: 'deliverer')
        .snapshots()
        .map((QuerySnapshot snapshot) {
          if (snapshot.docs.isEmpty) {
            return []; // Retourne une liste vide au lieu de null
          }
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return UserProfile.fromJson(
              data,
            ); // Utilise la méthode statique fromMap
          }).toList();
        });
  }

  Stream<List<UserProfile>>? getUserStream() {
    // 1. Configure la requête : filtre par rôle et trie (timestamp doit exister en BD)
    return _usersCollection.where('role', isEqualTo: 'client').snapshots().map((
      QuerySnapshot snapshot,
    ) {
      if (snapshot.docs.isEmpty) {
        return []; // Retourne une liste vide au lieu de null
      }
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserProfile.fromJson(
          data,
        ); // Utilise la méthode statique fromMap
      }).toList();
    });
  }

  // ... (Vos méthodes existantes : getProfile, etc.)
}
