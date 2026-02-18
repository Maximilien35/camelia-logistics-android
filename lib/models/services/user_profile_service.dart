import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../user_profile.dart';

class UserProfileService {
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

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
      throw Exception("Impossible d'enregistrer le chauffeur. Vérifiez les droits d'accès ou la connexion.");
    } catch (e) {
      if (kDebugMode) {
        print('Erreur inconnue lors de l\'enregistrement du chauffeur : $e');
      }
      throw Exception("Une erreur inattendue est survenue lors de l'enregistrement.");
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _usersCollection
        .doc(profile.uid)
        .set(profile.toJson(), SetOptions(merge: true));
  }


  Future<UserProfile?> getProfile(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get(const GetOptions(source: Source.cache));
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data() as Map<String, dynamic>);
      }
    } catch (_) {
    }
    
    try {
      final docServer = await _usersCollection.doc(uid).get(const GetOptions(source: Source.server));
      if (docServer.exists && docServer.data() != null) {
        return UserProfile.fromJson(docServer.data() as Map<String, dynamic>);
      }
    } catch (_) {
      // En cas d'erreur serveur (ex: hors ligne), on retourne null proprement
    }
    return null;
  }

  Future<void> saveFCMToken(String userId, String token) async {
    try {
      await _usersCollection.doc(userId).set({
        'fcmToken': token,
        'lastActive':
            FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la sauvegarde du token FCM : $e");
      }
    }
  }

  Stream<UserProfile?> streamProfile(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      final data = snapshot.data();

      if (data is Map<String, dynamic>) {
        return UserProfile.fromJson(data);
      }

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
      DocumentReference docRef = _usersCollection.doc(uid);

      await docRef.update({
        'name': name,
        'phoneNumber': phone,
        'email': email,
      });
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la mise à jour du statut de la commande : $e");
      }
      rethrow;
    }
  }

  Future<int?> calculateAndSetClientRank({
    required String uid,
    required String stat,
  }) async {
    try {
      final aggregateQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: stat)
          .count()
          .get();

      return aggregateQuery.count;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors du calcul du rang client: $e");
      }
    }
    return null;
  }

  Stream<List<UserProfile>>? getDeliverersStream() {
    return _usersCollection
        .where('role', isEqualTo: 'deliverer')
        .snapshots()
        .map((QuerySnapshot snapshot) {
          if (snapshot.docs.isEmpty) {
            return []; 
          }
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return UserProfile.fromJson(
              data,
            ); 
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

 Future<void> deleteUserAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final String uid = user.uid;

      // 1. Récupérer et supprimer les commandes associées (Nettoyage client)
      final ordersRef = FirebaseFirestore.instance.collection('orders');
      final ordersSnapshot =
          await ordersRef.where('userId', isEqualTo: uid).get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      int count = 0;

      for (var doc in ordersSnapshot.docs) {
        batch.delete(doc.reference);
        count++;
        if (count >= 450) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          count = 0;
        }
      }

      // 2. Supprimer le document utilisateur dans le batch final
      batch.delete(_usersCollection.doc(uid));
      await batch.commit();

      // 3. Supprimer le compte d'authentification
      await user.delete();
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la suppression du compte : $e");
      }
      rethrow;
    }
  }
}
