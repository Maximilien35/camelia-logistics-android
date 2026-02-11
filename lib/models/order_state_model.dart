import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class OrderStateModel extends ChangeNotifier {
  String? vehicleType;
  String? description;
  String? pickupAddress;
  String? dropoffAddress;
  String? packageNature;
  double? priceQuote;
  List<File> selectedFiles = [];
  LatLng? pickupCoords;
  LatLng? dropoffCoords;
  double? estimatedDistance;

  void setVehicleType(String type) {
    vehicleType = type;
    notifyListeners();
  }

  void setDescription(String? desc) {
    description = desc;
    notifyListeners();
  }

  void addPhoto(File file) {
    if (selectedFiles.length >= 3) {
      ScaffoldMessenger(
        child: Text("Limite de 3 photos atteinte. Impossible d'ajouter."),
      );
      return;
    }
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
    notifyListeners();
  }

  void resetOrderState() {
    vehicleType = null;
    pickupAddress = null;
    dropoffAddress = null;
    packageNature = null;
    description = null;
    priceQuote = null;
    selectedFiles = [];
    notifyListeners();
  }
}
