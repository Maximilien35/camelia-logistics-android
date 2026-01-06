import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Nouvelle dépendance

class OrderStateModel extends ChangeNotifier {
  // Propriétés temporaires
  String? vehicleType;
  String? description;
  String? pickupAddress;
  String? dropoffAddress;
  String? packageNature;
  double? priceQuote;
  List<File> selectedFiles = [];
  LatLng? _pickupCoords;
  LatLng? _dropoffCoords;
  double? _estimatedDistance;

  // Méthode pour l'Étape 1 : Choisir le Véhicule
  void setVehicleType(String type) {
    vehicleType = type;
    notifyListeners();
  }

  void setDescription(String? desc) {
    description = desc;
    notifyListeners();
  }

  void addPhoto(File file) {
    // Vérification de la limite (max 3)
    if (selectedFiles.length >= 3) {
      // Dans l'UI, cela déclencherait un message d'erreur/snackbar
      ScaffoldMessenger(
        child: Text("Limite de 3 photos atteinte. Impossible d'ajouter."),
      );
      return;
    }

    // 1. Ajouter le nouveau fichier à la liste
    selectedFiles.add(file);

    // 2. Notifier tous les widgets (y compris le PackagePhotoScreen) pour qu'ils se mettent à jour.
    notifyListeners();
  }

  // Pour retirer une photo
  void removePhoto(File file) {
    selectedFiles.remove(file);
    notifyListeners();
  }

  void setPackageNature(String? type) {
    packageNature = type;
    notifyListeners();
  }

  //ajouter les points de livraison et de depart
  void setPointDelivery(String depart, String destination) {
    pickupAddress = depart;
    dropoffAddress = destination;
    notifyListeners();
  }

  // Dans order_state_model.dart
  void setCoordinates(
    LatLng _pickupCoord,
    LatLng _dropoffCoord,
    double _estimatedDistances,
  ) {
    _pickupCoords = _pickupCoord;
    _dropoffCoords = _dropoffCoord;
    _estimatedDistance = _estimatedDistances;
    notifyListeners();
  }
  // ... vos autres méthodes setXXX()

  // Méthode de réinitialisation complète
  void resetOrderState() {
    vehicleType = null;
    pickupAddress = null;
    dropoffAddress = null;
    packageNature = null;
    description = null;
    priceQuote = null;
    selectedFiles = []; // Vider la liste

    // On notifie tout le monde que le panier est vide
    notifyListeners();
  }
}
