import 'package:camelia_logistics/models/services/user_profile_service.dart';
import 'package:camelia_logistics/models/user_profile.dart';
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

  Future<void> saveDeliver() async {
    await _delivererService.saveDeliverer(
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
          title:const Row(
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
                const SizedBox(height: 14),
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
                const SizedBox(height: 13),
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
                const SizedBox(height: 13),
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

  String _getSimulatedStatus() {
    return 'DISPONIBLE';
  }

  @override
  Widget build(BuildContext context) {
    final status = _getSimulatedStatus();
    final bool isAvailable = status == 'DISPONIBLE';

    final statusColor = isAvailable ? Colors.green : Colors.orange;
    final initials = deliverer.name.isNotEmpty
        ? deliverer.name
            .split(' ')
            .where((s) => s.isNotEmpty)
            .map((s) => s[0])
            .join()
            .toUpperCase()
        : '?';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isAvailable
                          ? [Colors.blue.shade100, Colors.blue.shade300]
                          : [Colors.grey.shade300, Colors.grey.shade400],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100.withValues(alpha:0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: isAvailable ? Colors.blue.shade900 : Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deliverer.name.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.grey.shade900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Livreur • ${deliverer.vehicle}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          
                          // Badge de status moderne
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha:0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withValues(alpha:0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Informations de contact
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.phone_iphone_rounded,
                        color: Colors.blue.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          deliverer.phoneNumber,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.blue.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          deliverer.location!,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Barre d'actions moderne
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildModernActionButton(
                    icon: Icons.phone_rounded,
                    label: 'Appeler',
                    onPressed: () {},
                  ),
                  _buildDivider(),
                  _buildModernActionButton(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Message',
                    onPressed: () {},
                  ),
                  _buildDivider(),
                  _buildModernActionButton(
                    icon: Icons.location_on_rounded,
                    label: 'Localiser',
                    onPressed: () {},
                  ),
                  _buildDivider(),
                  _buildModernActionButton(
                    icon: Icons.info_outline_rounded,
                    label: 'Détails',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 20,
      color: Colors.grey.shade300,
    );
  }
}