import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../user_profile.dart';

class UserProfileService {
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  // Cache locale agressive pour la durée de la session
  static final Map<String, UserProfile> _inMemoryUserCache = {};

  Future<void> clearMemoryCache() async {
    _inMemoryUserCache.clear();
  }

  Future<String> createDeliverer({
    required String name,
    required String phoneNumber,
    required String email,
    String? vehicle,
    String? location,
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

      final newDeliverer = UserProfile(
        uid: uid,
        name: name,
        phoneNumber: phoneNumber,
        email: email.trim(),
        role: 'deliverer',
        isCollaborator: false,
        isActive: true,
        vehicle: vehicle,
        location: location,
      );

      await _usersCollection.doc(uid).set(newDeliverer.toJson());

      if (kDebugMode) {
        print('Chauffeur créé avec succès: $uid');
      }

      return uid;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuth error: ${e.code} - ${e.message}');
      }
      throw Exception('Erreur d\'authentification : ${e.message}');
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firebase error: ${e.code} - ${e.message}');
      }
      throw Exception('Erreur Firebase : ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la création du chauffeur : $e');
      }
      throw Exception('Erreur lors de la création du chauffeur : $e');
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _usersCollection
        .doc(profile.uid)
        .set(profile.toJson(), SetOptions(merge: true));
  }

  Future<UserProfile?> getProfile(String uid) async {
    // 1. Cache mémoire session (instantané)
    if (_inMemoryUserCache.containsKey(uid)) {
      return _inMemoryUserCache[uid];
    }

    // 2. Cache Firestore local
    try {
      final doc = await _usersCollection
          .doc(uid)
          .get(const GetOptions(source: Source.cache));
      if (doc.exists && doc.data() != null) {
        final profile = UserProfile.fromJson(
          doc.data() as Map<String, dynamic>,
        );
        _inMemoryUserCache[uid] = profile;
        return profile;
      }
    } catch (_) {}

    // 3. Serveur (chapel main) pour données fraîches si manquant
    try {
      final docServer = await _usersCollection.doc(uid).get();
      if (docServer.exists && docServer.data() != null) {
        final profile = UserProfile.fromJson(
          docServer.data() as Map<String, dynamic>,
        );
        _inMemoryUserCache[uid] = profile;
        return profile;
      }
    } catch (_) {
      // En cas d'erreur serveur (ex: hors ligne), on retourne null proprement
    }
    return null;
  }

  Future<UserProfile?> getProfileFresh(String uid) async {
    // Force fetch from server, ignore cache
    try {
      final docServer = await _usersCollection.doc(uid).get();
      if (docServer.exists && docServer.data() != null) {
        final profile = UserProfile.fromJson(
          docServer.data() as Map<String, dynamic>,
        );
        _inMemoryUserCache[uid] = profile; // Update cache
        return profile;
      }
    } catch (_) {
      // En cas d'erreur serveur, on retourne null
    }
    return null;
  }

  Future<void> saveFCMToken(String userId, String token) async {
    try {
      await _usersCollection.doc(userId).set({
        'fcmToken': token,
        'lastActive': FieldValue.serverTimestamp(),
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

      await docRef.update({'name': name, 'phoneNumber': phone, 'email': email});
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

  Stream<List<UserProfile>>? getDeliverersStream({int limit = 50}) {
    return _usersCollection
        .where('role', isEqualTo: 'deliverer')
        .limit(
          limit,
        ) // OPTIMISATION: Limiter les résultats pour éviter surcharge
        .snapshots()
        .map((QuerySnapshot snapshot) {
          if (snapshot.docs.isEmpty) {
            return [];
          }
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return UserProfile.fromJson(data);
          }).toList();
        });
  }

  Future<List<UserProfile>> getStaff({
    String group = 'all',
    String? zone,
    int limit = 50,
  }) async {
    Query query = _usersCollection.where('isActive', isEqualTo: true);

    if (group == 'deliverer') {
      query = query.where('role', isEqualTo: 'deliverer');
    } else if (group == 'collaborator') {
      query = query.where('role', isEqualTo: 'collaborator');
    } else {
      query = query.where('role', whereIn: ['deliverer', 'collaborator']);
    }

    if (zone != null && zone.isNotEmpty) {
      query = query.where('serviceZone', isEqualTo: zone);
    }

    final snapshot = await query
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return UserProfile.fromJson(data);
    }).toList();
  }

  List<String>? _serviceZoneCache;

  Future<List<String>> getServiceZones({
    bool forceRefresh = false,
    int limit = 100,
  }) async {
    if (_serviceZoneCache != null && !forceRefresh) {
      return _serviceZoneCache!;
    }

    try {
      final QuerySnapshot snapshot = await _usersCollection
          .where('role', isEqualTo: 'collaborator')
          .limit(limit) // OPTIMISATION: Limiter pour éviter surcharge
          .get(const GetOptions(source: Source.cache));

      List<String> zones = snapshot.docs
          .map(
            (doc) =>
                (doc.data() as Map<String, dynamic>)['serviceZone'] as String?,
          )
          .whereType<String>()
          .where((zone) => zone.trim().isNotEmpty)
          .toSet()
          .toList();

      if (zones.isEmpty) {
        final serverSnapshot = await _usersCollection
            .where('role', isEqualTo: 'collaborator')
            .limit(limit) // OPTIMISATION: Limiter
            .get();

        zones = serverSnapshot.docs
            .map(
              (doc) =>
                  (doc.data() as Map<String, dynamic>)['serviceZone']
                      as String?,
            )
            .whereType<String>()
            .where((zone) => zone.trim().isNotEmpty)
            .toSet()
            .toList();
      }

      _serviceZoneCache = zones;
      return zones;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur getServiceZones: $e');
      }
      return _serviceZoneCache ?? [];
    }
  }

  Stream<List<UserProfile>>? getUserStream() {
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

  Future<UserProfile?> getProfileByEmail(String email) async {
    final querySnapshot = await _usersCollection
        .where('email', isEqualTo: email)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  Future<UserProfile?> getProfileByPhone(String phoneNumber) async {
    final querySnapshot = await _usersCollection
        .where('phoneNumber', isEqualTo: phoneNumber)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  Future<bool> isPhoneNumberTaken(String phoneNumber) async {
    final result = await getProfileByPhone(phoneNumber);
    return result != null;
  }

  Future<void> deleteUserAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final String uid = user.uid;

      await _usersCollection.doc(uid).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseAuth.instance.signOut();

      if (kDebugMode) {
        print("Compte désactivé avec succès (soft delete)");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la désactivation du compte : $e");
      }
      rethrow;
    }
  }
}
