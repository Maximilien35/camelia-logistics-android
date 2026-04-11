import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class OrderStateModel extends ChangeNotifier {
  String? serviceType; // Nouveau : Transport, Déménagement, etc.
  String? vehicleType;
  String? description;
  String? pickupAddress;
  String? dropoffAddress;
  String? packageNature;
  double? priceQuote;
  bool isQuote = false; // Nouveau : true si devis demandé
  Map<String, dynamic> additionalDetails =
      {}; // Nouveau : détails selon serviceType
  List<File> selectedFiles = [];
  LatLng? pickupCoords;
  LatLng? dropoffCoords;
  double? estimatedDistance;

  static const Map<String, String> _vehicleNameMapping = {
    'Camion Bennes': 'Dump Truck',
    'Camionnette': 'Camionnette',
    'Tricycle': 'Tricycle',
    'Fourgonnette': 'Camionnette',
    'train': 'train',
    'Moto': 'Moto',
  };

  OrderStateModel() {
    isQuote;
    additionalDetails;
  }

  void setServiceType(String type) {
    serviceType = type;
    notifyListeners();
  }

  void setVehicleType(String type) {
    vehicleType = _vehicleNameMapping[type] ?? type;
    if (serviceType == 'LIVRAISON') {
      calculatePrice();
    }
    notifyListeners();
  }

  void setDescription(String? desc) {
    description = desc;
    notifyListeners();
  }

  void addPhoto(File file) {
    if (selectedFiles.length >= 3) return;
    selectedFiles.add(file);
    notifyListeners();
  }

  void removePhoto(File file) {
    selectedFiles.remove(file);
    notifyListeners();
  }

  void setPackageNature(String? type) {
    packageNature = type;
    notifyListeners();
  }

  void setPointDelivery(String depart, String destination) {
    pickupAddress = depart;
    dropoffAddress = destination;
    notifyListeners();
  }

  void setCoordinates(
    LatLng pickupCoordValue,
    LatLng dropoffCoordValue,
    double estimatedDistanceValue,
  ) {
    pickupCoords = pickupCoordValue;
    dropoffCoords = dropoffCoordValue;
    estimatedDistance = estimatedDistanceValue;
    if (serviceType == 'LIVRAISON') {
      calculatePrice();
    }
    notifyListeners();
  }

  /// Calcule le prix estimé basé sur le serviceType et la distance
  void calculatePrice() {
    if (serviceType == 'LIVRAISON' && estimatedDistance != null) {
      if (estimatedDistance! <= 3) {
        priceQuote = 1000.0;
      } else if (estimatedDistance! <= 8) {
        priceQuote = 1500.0;
      } else {
        priceQuote = 2000.0;
      }
      isQuote = false; // Prix ferme
    } else if (serviceType == 'DÉMÉNAGEMENT ET TRANSPORT' ||
        serviceType == 'EXPÉDITION' ||
        serviceType == 'STOCKAGE') {
      priceQuote = 0.0;
      isQuote = true;
    } else {
      priceQuote = null;
    }
  }

  void setIsQuote(bool quote) {
    isQuote = quote;
    notifyListeners();
  }

  void setAdditionalDetails(Map<String, dynamic> details) {
    additionalDetails = details;
    notifyListeners();
  }

  void addAdditionalDetail(String key, dynamic value) {
    additionalDetails[key] = value;
    notifyListeners();
  }

  void reset() {
    serviceType = null;
    vehicleType = null;
    description = null;
    pickupAddress = null;
    dropoffAddress = null;
    packageNature = null;
    priceQuote = null;
    isQuote = false;
    additionalDetails = {};
    selectedFiles = [];
    estimatedDistance = null;
    notifyListeners();
  }
}
