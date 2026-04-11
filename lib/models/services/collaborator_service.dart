import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../user_profile.dart';

class CollaboratorService {
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  Stream<List<UserProfile>> getCollaboratorsStream({int limit = 50}) {
    return _usersCollection
        .where('isCollaborator', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .limit(limit) // OPTIMISATION: Limiter les résultats
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    UserProfile.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  Future<UserProfile?> getCollaborator(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isCollaborator'] == true) {
          return UserProfile.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération du collaborateur: $e');
      }
      return null;
    }
  }

  Future<String> createCollaborator({
    required String name,
    required String phoneNumber,
    required String email,
    String? password,
    String? serviceZone,
    String? vehicle,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final existing = await _usersCollection
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw Exception('Un utilisateur existe déjà avec cet email.');
      }

      // Générer un UID unique au lieu de créer un compte Firebase Auth
      final uid = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';

      final docRef = _usersCollection.doc(uid);

      final collaborator = UserProfile(
        uid: uid,
        name: name,
        phoneNumber: phoneNumber,
        email: email.trim(),
        role: 'collaborator',
        isCollaborator: true,
        serviceZone: serviceZone,
        vehicle: vehicle,
        isActive: true,
        latitude: latitude,
        longitude: longitude,
      );

      await docRef.set(collaborator.toJson());

      if (kDebugMode) {
        print('Collaborateur créé avec succès: $uid');
      }

      return uid;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la création du collaborateur: $e');
      }
      throw Exception('Une erreur inattendue s\'est produite lors de la création du collaborateur. Veuillez réessayer.');
    }
  }

  Future<void> updateCollaborator(UserProfile collaborator) async {
    try {
      if (!collaborator.isCollaborator) {
        throw Exception('Cet utilisateur n\'est pas un collaborateur');
      }

      await _usersCollection
          .doc(collaborator.uid)
          .update(collaborator.toJson());

      if (kDebugMode) {
        print('Collaborateur mis à jour: ${collaborator.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour du collaborateur: $e');
      }
      throw Exception('Une erreur inattendue s\'est produite lors de la mise à jour du collaborateur. Veuillez réessayer.');
    }
  }

  /// Supprime un collaborateur
  Future<void> deleteCollaborator(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();

      if (kDebugMode) {
        print('Collaborateur supprimé: $uid');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression du collaborateur: $e');
      }
      throw Exception('Impossible de supprimer le collaborateur: $e');
    }
  }

  /// Active/Désactive un collaborateur
  Future<void> toggleCollaboratorStatus(String uid, bool isActive) async {
    try {
      await _usersCollection.doc(uid).update({'isActive': isActive});

      if (kDebugMode) {
        print(
          'Statut du collaborateur $uid: ${isActive ? 'Actif' : 'Inactif'}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la modification du statut: $e');
      }
      throw Exception('Une erreur inattendue s\'est produite lors de la modification du statut. Veuillez réessayer.');
    }
  }

  /// Recherche des collaborateurs par zone de service
  Stream<List<UserProfile>> searchCollaboratorsByZone(
    String zone, {
    int limit = 20,
  }) {
    return _usersCollection
        .where('isCollaborator', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .where('serviceZone', isEqualTo: zone)
        .limit(limit) // OPTIMISATION: Limiter les résultats
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    UserProfile.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  /// Recherche collaborateurs par nom (pour la UI)
  Future<List<UserProfile>> searchCollaboratorsByName(String query) async {
    try {
      final normalizedQuery = query.toLowerCase();
      final snapshot = await _usersCollection
          .where('isCollaborator', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      final results = snapshot.docs
          .map(
            (doc) => UserProfile.fromJson(doc.data() as Map<String, dynamic>),
          )
          .where(
            (collab) =>
                collab.name.toLowerCase().contains(normalizedQuery) ||
                collab.email.toLowerCase().contains(normalizedQuery) ||
                collab.phoneNumber.contains(query),
          )
          .toList();

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la recherche: $e');
      }
      return [];
    }
  }
}
