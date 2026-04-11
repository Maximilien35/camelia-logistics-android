import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String? id;
  final String userId;
  final String serviceType; 
  final String pickupAddress;
  final String dropoffAddress;
  final String packageNature;
  final List<String> photoUrls;
  final String vehicleType;
  final String status;
  final DateTime timestamp;
  final double? priceQuote;
  final bool isQuote;
  final Map<String, dynamic> additionalDetails;
  final String? description;
  final String? delivererId;

  Order({
    this.id,
    required this.userId,
    required this.serviceType,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.packageNature,
    required this.photoUrls,
    required this.vehicleType,
    required this.status,
    required this.timestamp,
    required this.priceQuote,
    required this.isQuote,
    required this.additionalDetails,
    required this.description,
    this.delivererId,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'serviceType': serviceType,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'packageNature': packageNature,
      'photoUrls': photoUrls,
      'vehicleType': vehicleType,
      'status': status,
      'priceQuote': priceQuote,
      'isQuote': isQuote,
      'additionalDetails': additionalDetails,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'delivererId': delivererId,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json, {String? id}) {
    final priceQuoteValue = json['priceQuote'];

    return Order(
      id: id,
      userId: json['userId'] as String,
      serviceType: json['serviceType'] as String? ?? 'Transport',
      pickupAddress: json['pickupAddress'] as String,
      dropoffAddress: json['dropoffAddress'] as String,
      packageNature: json['packageNature'] as String,
      description: json['description'] as String?,
      photoUrls: List<String>.from(json['photoUrls']),
      vehicleType: json['vehicleType'] as String,
      status: json['status'] as String,
      delivererId: json['delivererId'] as String?,
      priceQuote: priceQuoteValue != null
          ? (priceQuoteValue as num).toDouble()
          : 0.0,
      isQuote: json['isQuote'] as bool? ?? false,
      additionalDetails: Map<String, dynamic>.from(json['additionalDetails'] ?? {}),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }
}