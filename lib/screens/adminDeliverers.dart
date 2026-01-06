import 'package:camelia_logistics/models/services/userProfileService.dart';
import 'package:camelia_logistics/models/userProfile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminDeliverersScreen extends StatefulWidget {
  const AdminDeliverersScreen({super.key});

  @override
  State<AdminDeliverersScreen> createState() => _DeliverersScreenState();
}

class _DeliverersScreenState extends State<AdminDeliverersScreen> {
  final UserProfileService _delivererService = UserProfileService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _vehicle = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final UserProfileService _service = UserProfileService();
  Future<void> saveDeliver() async {
    await _service.saveDeliverer(
      _nameController.text,
      _phone.text,
      _vehicle.text,
      _locationController.text,
    );
  }

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void addDeliverDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add, color: Colors.blueAccent),
              Text(
                'Ajouter un chauffeur',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Arial',
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  validator: (value) {
                    if (value!.isEmpty) return 'Le nom est obligatoire.';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'nom',
                    hintText: 'Entrer le nom du chauffeur',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                SizedBox(height: 14),
                TextFormField(
                  controller: _vehicle,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'le type du vehicule est obligatoire.';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'type de vehicule',
                    hintText: 'Entrer le type du vehicule',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                SizedBox(height: 13),
                TextFormField(
                  controller: _phone,
                  validator: (value) {
                    if (value!.isEmpty) return 'le numero est obligatoire.';
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'tel',
                    hintText: 'Entrer le numero de telephone',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                SizedBox(height: 13),
                TextFormField(
                  controller: _locationController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'la localisation du chauffeur est obligatoire.';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'localisation',
                    hintText: 'Entrer la localisation ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Retour'),
            ),
            ElevatedButton(
              onPressed: () {
                saveDeliver();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text(
                'Confirmer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chauffeurs'),
        automaticallyImplyLeading:
            false, // Supprime la flèche de retour si c'est la TabBar
      ),
      body: Column(
        children: [
          // Champ de recherche
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher par nom ou téléphone...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<UserProfile>>(
              stream: _delivererService.getDeliverersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ${snapshot.error}'));
                }

                final allDeliverers = snapshot.data ?? [];

                // Filtrage
                final filteredDeliverers = allDeliverers.where((d) {
                  final name = d.name.toLowerCase();
                  final phone = d.phoneNumber.toLowerCase();
                  final location = d.location?.toLowerCase() ?? '';
                  return name.contains(_searchQuery) ||
                      phone.contains(_searchQuery) ||
                      location.contains(_searchQuery);
                }).toList();

                if (filteredDeliverers.isEmpty) {
                  return const Center(child: Text('Aucun chauffeur trouvé.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  itemCount: filteredDeliverers.length,
                  itemBuilder: (context, index) {
                    return DelivererCard(deliverer: filteredDeliverers[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addDeliverDialog(context);
        },
        heroTag: FloatingActionButtonLocation.endFloat,
        tooltip: 'Ajouter',
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class DelivererCard extends StatelessWidget {
  final UserProfile deliverer;

  const DelivererCard({super.key, required this.deliverer});

  // Fonction de simulation pour obtenir le statut (à remplacer par le statut réel de Firestore)
  String _getSimulatedStatus() {
    return 'DISPONIBLE';
  }

  @override
  Widget build(BuildContext context) {
    final status = _getSimulatedStatus();
    final bool isAvailable = status == 'DISPONIBLE';

    // Style du badge de statut
    final statusColor = isAvailable ? Colors.green : Colors.orange;
    final initials = deliverer.name.isNotEmpty
        ? deliverer.name
              .split(' ')
              .where(
                (s) => s.isNotEmpty,
              ) // S'assurer que la chaîne n'est pas vide
              .map((s) => s[0])
              .join()
              .toUpperCase()
        : '?';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar avec les initiales
            CircleAvatar(
              radius: 28,
              backgroundColor: isAvailable
                  ? Colors.blue.shade100
                  : Colors.grey.shade300,
              child: Text(
                initials,
                style: TextStyle(
                  color: isAvailable ? Colors.blue.shade900 : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Informations du chauffeur
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        deliverer.name.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      // ⭐ Badge de Statut
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Détail du véhicule (simulé ici, à lire depuis le modèle si possible)
                  Column(
                    children: [
                      Text(
                        'Véhicule: ${deliverer.vehicle} | Tél: ${deliverer.phoneNumber}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.blue, size: 13),
                          Text(
                            deliverer.location!,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Actions rapides
                  Row(
                    children: [
                      // Bouton d'appel (ajoutez l'URL Launcher pour le rendre fonctionnel)
                      _buildActionButton(
                        icon: Icons.phone,
                        onPressed: () {
                          // launchUrl('tel:${deliverer.phoneNumber}')
                        },
                      ),
                      const SizedBox(width: 10),
                      // Bouton de message
                      _buildActionButton(
                        icon: Icons.chat_bubble_outline,
                        onPressed: () {
                          /* Rediriger vers l'écran de chat */
                        },
                      ),
                      const SizedBox(width: 10),
                      // Bouton de localisation (si implémenté)
                      _buildActionButton(
                        icon: Icons.location_on_outlined,
                        onPressed: () {
                          /* Afficher la carte ou les logs de localisation */
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper pour les boutons d'action
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: Colors.blue),
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
