import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String phoneNumber;
  final String email;
  final String? fcmToken;
  final String role; // 'client', 'deliverer', ou 'collaborator'
  final String? vehicle;
  final String? location;
  final String? serviceType;
  final double? pricePerKm;
  final bool isCollaborator; 

  final String? serviceZone; 
  final bool isActive;
  final double? latitude; // Nouveau : position fixe du collaborateur
  final double? longitude; // Nouveau : position fixe du collaborateur

  UserProfile({
    required this.uid,
    required this.name,
    required this.phoneNumber,
    required this.email,
    this.fcmToken,
    required this.role,
    this.vehicle,
    this.location,
    this.serviceType,
    this.pricePerKm,
    this.isCollaborator = false,
    this.serviceZone,
    this.isActive = true,
    this.latitude,
    this.longitude,
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
      'serviceType': serviceType,
      'pricePerKm': pricePerKm,
      'isCollaborator': isCollaborator,
      'serviceZone': serviceZone,
      'isActive': isActive,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static UserProfile fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String,
      fcmToken: json['fcmToken'] as String? ?? '',
      role: json['role'] as String? ?? 'client',
      vehicle: json['vehicle'] as String?,
      location: json['location'] as String?,
      serviceType: json['serviceType'] as String?,
      pricePerKm: (json['pricePerKm'] as num?)?.toDouble(),
      isCollaborator: json['isCollaborator'] as bool? ?? false,
      serviceZone: json['serviceZone'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}