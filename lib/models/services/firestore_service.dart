import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // L'instance unique de la base de données

  //final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionName = 'users';
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');
  // Crée un nouveau document dans la collection 'users'
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String fullName,
    required String phoneNumber,
    final String? fcmToken,
    String role = 'client', // Rôle par défaut de l'application mobile
  }) async {
    return _usersCollection
        .doc(uid) // Utilise l'UID de Firebase Auth comme ID du document
        .set({
          'uid': uid,
          'email': email,
          'full_name': fullName,
          'phone_number': phoneNumber,
          'role': role,
          'is_active': true,
          'fcmToken': fcmToken, // Ajouté pour les notifications push'
          'created_at': FieldValue.serverTimestamp(),
        });
  }
}

// NOTE: On ajoutera ici d'autres méthodes pour lire/mettre à jour les données
