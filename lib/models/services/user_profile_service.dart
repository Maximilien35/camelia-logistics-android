import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

      SnackBar(content: Text('le profil $uid a ete  mis à jour à'));
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

  // ... (Vos méthodes existantes : getProfile, etc.)
}
