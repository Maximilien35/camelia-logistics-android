import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String phoneNumber;
  final String email;
  final String? fcmToken;
  final String role;
  final String? vehicle;
  final String? location;

  UserProfile({
    required this.uid,
    required this.name,
    required this.phoneNumber,
    required this.email,
    this.fcmToken,
    required this.role,
    this.vehicle,
    this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'fcmToken': fcmToken,
      'role': role,
      'created_at': FieldValue.serverTimestamp(),
      'vehicle': vehicle,
      'location': location,
    };
  }

  // Méthode statique pour convertir un Document Firestore en objet Dart
  static UserProfile fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String ?? '',
      fcmToken: json['fcmToken'] as String? ?? '',
      role: json['role'] as String? ?? 'client',
      vehicle: json['vehicle'] as String? ?? 'Non spécifié',
      location: json['location'] as String? ?? '',
    );
  }
}
