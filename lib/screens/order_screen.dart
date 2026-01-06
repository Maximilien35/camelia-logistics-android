import 'dart:io';
import 'package:camelia_logistics/models/services/userProfileService.dart';
import 'package:camelia_logistics/models/userProfile.dart';
import 'package:camelia_logistics/screens/history_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/order_model.dart';
import '../models/services/order_service.dart';
import '../models/order_state_model.dart';
import '../models/services/storage_service.dart';
import 'package:geolocator/geolocator.dart'; // Nouvelle dépendance
import 'package:geocoding/geocoding.dart'; // Nouvelle dépendance
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Nouvelle dépendance
import 'dart:async'; // Nécessaire pour les Completer

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  // Dans votre classe _PackagePhotoScreenState

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Choisir un vehicule',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            context.go('/home_custom');
          },
          icon: Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => HistoryScreen()));
            },
            icon: Icon(Icons.history),
          ),
          IconButton(
            onPressed: () {
              context.go('/profil');
            },
            icon: Icon(Icons.person),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Text(
              'Sélectionnez votre mode de transport',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: 10),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(15),
            ),

            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue.shade800),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Service Bientot disponible à Yaoundé, Bafoussam, Garoua et Kribi',
                    style: TextStyle(color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              children: [
                SelectCar(
                  icon: Icons.bike_scooter,
                  iconColor: Colors.lightBlueAccent,
                  typeCar: 'Camion Bennes',
                  description: 'rapide et economique',
                  onTap: () {
                    // 1. Accès au modèle SANS ÉCOUTER (listen: false)
                    final orderState = Provider.of<OrderStateModel>(
                      context,
                      listen: false,
                    );

                    // 2. Mise à jour de l'état (appelle setVehicleType)
                    orderState.setVehicleType(
                      'Camion Bennes',
                    ); // ou 'Tricycle', etc.

                    // 3. Navigation vers l'étape suivante (ex: Saisie des Adresses)
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PackagePhotoScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(height: 30),
                SelectCar(
                  icon: Icons.fire_truck_outlined,
                  iconColor: Colors.greenAccent,
                  typeCar: 'camionnette',
                  description: 'transport securise',
                  onTap: () {
                    final orderState = Provider.of<OrderStateModel>(
                      context,
                      listen: false,
                    );
                    orderState.setVehicleType(
                      'Camionnette',
                    ); // ou 'Tricycle', etc.

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PackagePhotoScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(height: 30),
                SelectCar(
                  icon: Icons.train_outlined,
                  iconColor: Colors.purpleAccent,
                  typeCar: 'Tricycle',
                  description: 'rapide et economique',
                  onTap: () {
                    final orderState = Provider.of<OrderStateModel>(
                      context,
                      listen: false,
                    );

                    orderState.setVehicleType(
                      'Tricycle',
                    ); // ou 'Tricycle', etc.
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PackagePhotoScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(height: 30),
                SelectCar(
                  icon: Icons.local_shipping_outlined,
                  iconColor: Colors.indigo,
                  typeCar: 'Fourgonnette',
                  description: 'rapide et economique',
                  onTap: () {
                    final orderState = Provider.of<OrderStateModel>(
                      context,
                      listen: false,
                    );

                    orderState.setVehicleType('Fourgonnette');
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PackagePhotoScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.location_on, color: Colors.blue.shade800),
                    label: Text('Suivi colis'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      foregroundColor: Colors.blue.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      side: BorderSide(color: Colors.blue.shade800),
                    ),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(
                      Icons.chat_bubble,
                      color: Colors.purple.shade600,
                    ),
                    label: Text('Support'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      foregroundColor: Colors.purple.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      side: BorderSide(color: Colors.purple.shade600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget SelectCar({
  required IconData icon,
  required Color iconColor,
  required String typeCar,
  required String description,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 45, color: iconColor),
          SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeCar,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class PackagePhotoScreen extends StatefulWidget {
  const PackagePhotoScreen({super.key});

  @override
  _PackagePhotoScreenState createState() => _PackagePhotoScreenState();
}

class _PackagePhotoScreenState extends State<PackagePhotoScreen> {
  void _pickAndAddPhoto() async {
    final ImagePicker picker = ImagePicker();
    // 1. Déclencher le sélecteur d'image (depuis la galerie)
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    // 2. Gérer le résultat
    if (pickedFile != null) {
      // Le XFile de image_picker est un objet intermédiaire.
      // Nous avons besoin de le convertir en l'objet File de Dart pour le stocker.
      final File imageFile = File(pickedFile.path);

      // 3. Envoyer au Provider
      final orderState = Provider.of<OrderStateModel>(context, listen: false);

      // 4. Utiliser la méthode que nous venons de créer
      orderState.addPhoto(imageFile);
    }
  }

  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // On écoute les changements dans le champ pour mettre à jour le Provider
    _descriptionController.addListener(_updateDescription);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // Nouvelle méthode utilitaire
  void _updateDescription() {
    final orderState = Provider.of<OrderStateModel>(context, listen: false);
    orderState.setDescription(_descriptionController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nouvelle commande',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Aligner le texte à gauche
          children: [
            // Indicateur d'étape
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10,
              ),
              child: Text(
                'Étape 2 sur 4',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            // Titre de la section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Photo du colis',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 5,
              ),
              child: Text(
                'Prenez une photo pour faciliter la livraison',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),

            // Dans la méthode build()
            Consumer<OrderStateModel>(
              builder: (context, orderState, child) {
                // 1. Détermine si on affiche le grand conteneur vide ou les miniatures.
                final bool hasPhotos = orderState.selectedFiles.isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      if (hasPhotos)
                        // Affiche la grille si des photos existent
                        _buildPhotoGrid(orderState.selectedFiles)
                      else
                        // Sinon, affiche le grand conteneur pour ajouter une photo
                        GestureDetector(
                          onTap: _pickAndAddPhoto,
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.camera_alt,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Touchez pour ajouter/prendre une photo',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      SizedBox(
                        height: hasPhotos ? 10 : 20,
                      ), // Ajuster l'espacement
                      // Boutons "Prendre une photo" et "Choisir depuis la galerie"
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _pickAndAddPhoto, // NOTE : Utilisez la même fonction pour simplifier
                          icon: const Icon(Icons.camera_alt),
                          label: const Text(
                            'Prendre une photo / Choisir une photo',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 30),
            // Type de colis
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Type de colis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Consumer<OrderStateModel>(
                builder: (context, orderState, child) {
                  final currentSelection =
                      orderState.packageNature; // Lit la sélection actuelle
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      // On passe currentSelection à la fonction utilitaire
                      buildTypeColisChip(
                        'Marchandises',
                        Icons.local_shipping,
                        currentSelection,
                      ),
                      buildTypeColisChip(
                        'Électronique',
                        Icons.laptop_mac,
                        currentSelection,
                      ),
                      buildTypeColisChip(
                        'Meubles',
                        Icons.chair,
                        currentSelection,
                      ),
                      buildTypeColisChip(
                        'Nourriture',
                        Icons.fastfood,
                        currentSelection,
                      ),
                      buildTypeColisChip(
                        'Fragile',
                        Icons.warning,
                        currentSelection,
                      ),
                      buildTypeColisChip(
                        'Autre',
                        Icons.more_horiz,
                        currentSelection,
                      ),
                    ],
                  );
                },
              ),
            ),
            // ...
            SizedBox(height: 30),

            // Description (optionnel)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Description (optionnel)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextFormField(
                controller: _descriptionController,
                onChanged: (value) {
                  // Pas besoin de l'onChanged ici car l'écouteur du contrôleur fait le travail
                },
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Décrivez votre colis...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            // Bouton "Continuer"
            Consumer<OrderStateModel>(
              builder: (context, orderState, child) {
                // 1. Détermine si on affiche le grand conteneur vide ou les miniatures.
                final bool hasPhotos = orderState.selectedFiles.isNotEmpty;
                final bool? hasShip = orderState.packageNature?.isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (hasPhotos && hasShip != null && hasShip) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DeliveryPointsScreen(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez terminer la selection.'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Color(
                          0xFF4CAF50,
                        ), // Une couleur verte par exemple
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text('Continuer', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(List<File> files) {
    return Wrap(
      spacing: 10.0, // Espacement horizontal entre les images
      runSpacing: 10.0, // Espacement vertical entre les lignes
      children: files.map((file) {
        // Pour chaque fichier dans la liste, nous construisons un widget :
        return Stack(
          children: [
            // 1. La Miniature elle-même
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.file(
                file, // Affichage du fichier local !
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),

            // 2. Le Bouton de Suppression (pour l'appel à removePhoto)
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: () {
                  // Pour la suppression, nous avons besoin d'accéder au Provider
                  final orderState = Provider.of<OrderStateModel>(
                    context,
                    listen: false,
                  );
                  orderState.removePhoto(file);
                },
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      }).toList(), // Convertion en liste widget
    );
  }

  // Fonction utilitaire pour créer une "puce" de type de colis
  // La méthode doit prendre en entrée la valeur actuelle de la sélection du Provider
  Widget buildTypeColisChip(
    String label,
    IconData icon,
    String? currentSelection,
  ) {
    // Détermine si cette puce est la puce sélectionnée
    final bool isSelected = currentSelection == label;
    final Color baseColor = isSelected
        ? Color(0xFF4CAF50)
        : Colors.grey.shade100;
    final Color contentColor = isSelected ? Colors.white : Colors.grey.shade700;

    return GestureDetector(
      onTap: () {
        final orderState = Provider.of<OrderStateModel>(context, listen: false);
        final String? newValue = isSelected ? null : label;

        orderState.setPackageNature(newValue);
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Color(0xFF4CAF50) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: contentColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.ubuntu(fontSize: 12, color: contentColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:geolocator/geolocator.dart'; // Nouvelle dépendance
// import 'package:geocoding/geocoding.dart'; // Nouvelle dépendance
// import 'package:google_maps_flutter/google_maps_flutter.dart'; // Nouvelle dépendance
// import 'dart:async'; // Nécessaire pour les Completer
//
// // --- MOCKUP / PLACEHOLDERS ---
// // Remplacez par vos imports réels
// import 'package:your_project_name/models/order_state_model.dart';
// import 'package:your_project_name/screens/finalisation_order.dart';
//
// // Importez votre écran de sélection de carte (voir le widget défini plus bas)
// import 'package:your_project_name/widgets/map_selector_screen.dart';
// --- MOCKUP / PLACEHOLDERS ---

class DeliveryPointsScreen extends StatefulWidget {
  const DeliveryPointsScreen({super.key});
  @override
  DeliveryPointsScreenState createState() => DeliveryPointsScreenState();
}

class DeliveryPointsScreenState extends State<DeliveryPointsScreen> {
  final TextEditingController _depart = TextEditingController();
  final TextEditingController _arrive = TextEditingController();

  // Variables d'état pour les coordonnées et la distance
  LatLng? _pickupCoords;
  LatLng? _dropoffCoords;
  double? _estimatedDistance; // En kilomètres

  @override
  void initState() {
    super.initState();
    _arrive.addListener(_updatePointDelivery);
    _depart.addListener(_updatePointDelivery);
  }

  @override
  void dispose() {
    _depart.dispose();
    _arrive.dispose();
    super.dispose();
  }

  void _updatePointDelivery() {
    final orderState = Provider.of<OrderStateModel>(context, listen: false);
    // Met à jour le provider avec les adresses textuelles
    orderState.setPointDelivery(_depart.text, _arrive.text);

    // Recalcule la distance à chaque changement d'adresse textuelle
    _calculateDistance();
  }

  // Fonction de géolocalisation pour le point de départ
  Future<void> _useMyLocation() async {
    // 1. Demander la permission et obtenir la position
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        // Gérer le cas où la permission est refusée de manière permanente
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La localisation est refusée de manière permanente.',
              ),
            ),
          );
        }
        return;
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final LatLng coords = LatLng(position.latitude, position.longitude);

      // 2. Convertir les coordonnées en adresse lisible (Reverse Geocoding)
      final placemarks = await placemarkFromCoordinates(
        coords.latitude,
        coords.longitude,
      );

      if (placemarks.isNotEmpty) {
        final address = placemarks.first;
        final fullAddress =
            "${address.street}, ${address.locality}, ${address.country}";

        setState(() {
          _depart.text = fullAddress; // Mettre à jour le TextField
          _pickupCoords = coords; // Mettre à jour les coordonnées
          _calculateDistance(); // Recalculer la distance
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'obtenir la position: $e')),
        );
      }
    }
  }

  // Ouvre l'écran de carte pour sélectionner la destination
  Future<void> _selectDestinationOnMap() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapSelectorScreen(
          // Passe une position initiale par défaut (ex: Douala) si aucune n'est définie
          initialPosition: _dropoffCoords ?? const LatLng(4.0450, 9.7041),
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final LatLng coords = result['coords'];
      final String address = result['address'];

      setState(() {
        _arrive.text = address; // Mettre à jour le TextField
        _dropoffCoords = coords; // Mettre à jour les coordonnées
        _calculateDistance(); // Recalculer la distance
      });
    }
  }

  // Calcule la distance entre les deux points (Utilise la distance orthodromique simple pour la démo)
  void _calculateDistance() {
    if (_pickupCoords != null && _dropoffCoords != null) {
      final distanceInMeters = Geolocator.distanceBetween(
        _pickupCoords!.latitude,
        _pickupCoords!.longitude,
        _dropoffCoords!.latitude,
        _dropoffCoords!.longitude,
      );

      setState(() {
        _estimatedDistance = distanceInMeters / 1000; // Convertir en km
      });
      // Dans une appli réelle, vous utiliseriez ici une API de Google Maps Directions
      // (Geocoding API ou Distance Matrix API) pour obtenir la distance routière exacte.
    } else {
      setState(() {
        _estimatedDistance = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Le code de build est le même, seuls les onPressed changent) ...
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nouvelle commande',
          style: GoogleFonts.pacifico(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Étape 2 sur 4',
                style: GoogleFonts.montserrat(color: Colors.grey[600]),
              ),
              const SizedBox(height: 5),
              const Text(
                'Points de livraison',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                'Définissez le départ et la destination',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),

              _buildDepartureSection(),
              const SizedBox(height: 20),

              _buildDestinationSection(),
              const SizedBox(height: 30),

              _buildMapSection(), // Utilise _estimatedDistance
              const SizedBox(height: 30),

              _buildContinueButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepartureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Point de départ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        TextFormField(
          // readOnly: true, // Si vous voulez forcer le choix via la carte/position
          controller: _depart,
          decoration: InputDecoration(
            hintText: 'Akwa, Douala',
            prefixIcon: Icon(Icons.location_on, color: Colors.blue.shade500),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        TextButton.icon(
          onPressed:
              _useMyLocation, // ⭐ Appel de la fonction de géolocalisation
          icon: Icon(Icons.my_location, color: Colors.blue.shade800),
          label: Text(
            'Utiliser ma position',
            style: TextStyle(color: Colors.blue.shade800),
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Destination',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _arrive,
          decoration: InputDecoration(
            hintText: 'Adresse de livraison',
            prefixIcon: Icon(
              Icons.add_location_alt_sharp,
              color: Colors.green.shade500,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _selectDestinationOnMap, // ⭐ Appel du sélecteur de carte
          icon: Icon(Icons.map_outlined, color: Colors.blue.shade800),
          label: Text(
            'Choisir sur la carte',
            style: TextStyle(color: Colors.blue.shade800),
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    final distanceText = _estimatedDistance != null
        ? '${_estimatedDistance!.toStringAsFixed(2)} km' // Afficher la distance
        : 'Distance estimée...';

    final Map<MarkerId, Marker> markers = {};
    if (_pickupCoords != null) {
      markers[const MarkerId('start')] = Marker(
        markerId: const MarkerId('start'),
        position: _pickupCoords!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    }
    if (_dropoffCoords != null) {
      markers[const MarkerId('end')] = Marker(
        markerId: const MarkerId('end'),
        position: _dropoffCoords!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: markers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 60, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text(
                    'Carte interactive',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    distanceText,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _pickupCoords ?? const LatLng(4.0450, 9.7041),
                  zoom: 12,
                ),
                markers: markers.values.toSet(),
                // Vous pouvez ajouter des polylines ici pour l'itinéraire
                // Polylines: _createPolylines().toSet(),
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (controller) {
                  // Ajuster la caméra pour montrer les deux marqueurs
                  if (_pickupCoords != null && _dropoffCoords != null) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngBounds(
                        LatLngBounds(
                          southwest: LatLng(
                            _pickupCoords!.latitude < _dropoffCoords!.latitude
                                ? _pickupCoords!.latitude
                                : _dropoffCoords!.latitude,
                            _pickupCoords!.longitude < _dropoffCoords!.longitude
                                ? _pickupCoords!.longitude
                                : _dropoffCoords!.longitude,
                          ),
                          northeast: LatLng(
                            _pickupCoords!.latitude > _dropoffCoords!.latitude
                                ? _pickupCoords!.latitude
                                : _dropoffCoords!.latitude,
                            _pickupCoords!.longitude > _dropoffCoords!.longitude
                                ? _pickupCoords!.longitude
                                : _dropoffCoords!.longitude,
                          ),
                        ),
                        50, // padding
                      ),
                    );
                  }
                },
              ),
            ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        // Le bouton est activé seulement si les deux coordonnées sont définies
        onPressed: (_pickupCoords != null && _dropoffCoords != null)
            ? () {
                // Mise à jour finale de l'état de la commande avant la navigation
                final orderState = Provider.of<OrderStateModel>(
                  context,
                  listen: false,
                );
                orderState.setCoordinates(
                  _pickupCoords!,
                  _dropoffCoords!,
                  _estimatedDistance ?? 0.0,
                );

                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => finalisation_Order()),
                );
              }
            : null, // Le bouton est désactivé si les points ne sont pas sélectionnés
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text('Continuer', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

class finalisation_Order extends StatefulWidget {
  const finalisation_Order({super.key});

  @override
  _finalisation_OrderState createState() => _finalisation_OrderState();
}

class _finalisation_OrderState extends State<finalisation_Order> {
  final UserProfileService _userServices = UserProfileService();
  Future<String?> get_Phone() async {
    final UserProfileService service = UserProfileService();
    final userProfile = await service.getProfile(id!);
    String? phone = userProfile?.phoneNumber;
    return phone;
  }

  final id = FirebaseAuth.instance.currentUser?.uid;

  bool _isLoading = false;

  void createOrder() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final OrderStateModel orderState = Provider.of<OrderStateModel>(
      context,
      listen: false,
    );
    final DateTime now = DateTime.now();

    if (orderState.pickupAddress == null || orderState.vehicleType == null) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      List<Future<String>> uploadTasks = orderState.selectedFiles.map((file) {
        String fileName = file.path.split('/').last;
        String path =
            'orders/${currentUser.uid}/${now.millisecondsSinceEpoch}/$fileName';
        return StorageService().uploadImage(file, path);
      }).toList();

      // Attendre que TOUS les uploads se terminent et collecter les URLs
      List<String> photoUrls = await Future.wait(uploadTasks);
      //List<String> photoUrls = [];

      // 3. CONSTRUIRE L'OBJET ORDER FINAL
      final newOrder = Order(
        userId: currentUser.uid, // Récupéré de Firebase Auth
        pickupAddress: orderState.pickupAddress!,
        dropoffAddress: orderState.dropoffAddress!,
        packageNature:
            orderState.packageNature ??
            'Non spécifié', // Utilisation de ?? pour gérer le null
        photoUrls: photoUrls, // La liste d'URLs obtenue du Storage
        vehicleType: orderState.vehicleType!,
        status: 'PENDING', // Statut initial
        timestamp: now,
        priceQuote: orderState.priceQuote,
        description: orderState.description,
      );

      // 4. ENVOYER À FIRESTORE

      final String newOrderId = await OrderService().addOrder(newOrder);
      //renitialisation
      // Nécessite une nouvelle méthode dans OrderStateModel (voir ci-dessous)

      context.go('/waiting/$newOrderId');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'envoi de la commande.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Nouvelle Commande',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'etape 4 sur 4',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: FutureBuilder<UserProfile?>(
        future: _userServices.getProfile(id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final profile = snapshot.data!;
          return Center(
            child: Padding(
              padding: EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Résumé de votre commande',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        buildSummaryRow(
                          'Transport:',
                          Provider.of<OrderStateModel>(
                            context,
                          ).vehicleType.toString(),
                        ),
                        SizedBox(height: 10),
                        buildSummaryRow('Telephone:', profile.phoneNumber),
                        SizedBox(height: 10),
                        buildSummaryRow(
                          'Depart:',
                          Provider.of<OrderStateModel>(
                            context,
                          ).pickupAddress.toString(),
                        ),
                        SizedBox(height: 10),
                        buildSummaryRow(
                          'Colis:',
                          Provider.of<OrderStateModel>(
                            context,
                          ).packageNature.toString(),
                        ),
                        SizedBox(height: 10),
                        Divider(),
                        SizedBox(height: 10),
                        buildSummaryRow(
                          'Destinaion',
                          Provider.of<OrderStateModel>(
                            context,
                          ).dropoffAddress.toString(),
                          isBold: true,
                          isPrice: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),

                  // Bouton "Confirmer la commande"
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : createOrder,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              'Confirmer la commande',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget buildSummaryRow(
  String label,
  String value, {
  bool isBold = false,
  bool isPrice = false,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 16,
          color: Colors.black,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 16,
          color: isPrice ? Colors.green.shade800 : Colors.black,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ],
  );
}

class MapSelectorScreen extends StatefulWidget {
  final LatLng initialPosition;

  const MapSelectorScreen({super.key, required this.initialPosition});

  @override
  State<MapSelectorScreen> createState() => _MapSelectorScreenState();
}

class _MapSelectorScreenState extends State<MapSelectorScreen> {
  LatLng? _selectedPosition;
  String _selectedAddress = "Déplacez la carte pour choisir l'adresse";
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _updateMarker(_selectedPosition!);
  }

  // Met à jour la position et lance la conversion en adresse
  void _updateMarker(LatLng position) async {
    setState(() {
      _isLoading = true;
      _selectedPosition = position;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    });

    // Conversion LatLng -> Adresse
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final address = placemarks.first;
        final fullAddress =
            "${address.street}, ${address.locality}, ${address.country}";
        setState(() {
          _selectedAddress = fullAddress;
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = "Adresse non trouvée.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choisir la destination')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onLongPress:
                _updateMarker, // L'utilisateur peut maintenir appuyé pour choisir
            markers: _markers,
          ),

          // Barre de confirmation et d'adresse
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Adresse de destination:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    _isLoading
                        ? const LinearProgressIndicator()
                        : Text(
                            _selectedAddress,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedPosition == null || _isLoading
                            ? null
                            : () {
                                // Retourne les coordonnées et l'adresse à l'écran précédent
                                Navigator.pop(context, {
                                  'coords': _selectedPosition,
                                  'address': _selectedAddress,
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('Confirmer cette adresse'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Confirm_Course extends StatelessWidget {
  const Confirm_Course({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Offre recue',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
    );
  }
}
