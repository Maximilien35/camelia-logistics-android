import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String? id;
  final String userId;
  final String pickupAddress;
  final String dropoffAddress;
  final String packageNature;
  final List<String> photoUrls; // URLs de Firebase Storage
  final String vehicleType;
  final String status;
  final DateTime timestamp;
  final double? priceQuote;
  final String? description;
  final String? delivererId;

  Order({
    this.id,
    required this.userId,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.packageNature,
    required this.photoUrls,
    required this.vehicleType,
    required this.status,
    required this.timestamp,
    required this.priceQuote,
    required this.description,
    this.delivererId,
  });

  // Convertit l'objet Dart en Map<String, dynamic> pour l'écriture dans Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'packageNature': packageNature,
      'photoUrls': photoUrls,
      'vehicleType': vehicleType,
      'status': status,
      'priceQuote': priceQuote,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'delivererId': delivererId,
    };
  }

  // Crée un objet Dart à partir d'un Map de Firestore
  factory Order.fromJson(Map<String, dynamic> json, {String? id}) {
    final priceQuoteValue = json['priceQuote'];
    return Order(
      id: id,
      userId: json['userId'] as String,
      pickupAddress: json['pickupAddress'] as String,
      dropoffAddress: json['dropoffAddress'] as String,
      packageNature: json['packageNature'] as String,
      description: json['description'] as String,
      photoUrls: List<String>.from(json['photoUrls']),
      vehicleType: json['vehicleType'] as String,
      status: json['status'] as String,
      delivererId: json['delivererId'] as String?,
      priceQuote: priceQuoteValue != null
          ? (priceQuoteValue as num).toDouble()
          : 0.0,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }
}
