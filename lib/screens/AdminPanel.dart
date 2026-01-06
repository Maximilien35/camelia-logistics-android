import 'package:camelia_logistics/models/services/userProfileService.dart';
import 'package:camelia_logistics/models/userProfile.dart';
import 'package:camelia_logistics/screens/adminDashboard.dart';
import 'package:camelia_logistics/screens/adminDeliverers.dart';
import 'package:camelia_logistics/screens/adminSettings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:camelia_logistics/models/services/order_service.dart';
import 'package:camelia_logistics/models/order_model.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 1;
  static final List<Widget> _widgetOptions = <Widget>[
    AdminDashboard(),
    AdminOrdersScreen(),
    AdminDeliverersScreen(),
    AdminSettings(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(
        _selectedIndex,
      ), // Affiche l'écran sélectionné
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag), // Ou Icons.list_alt
            label: 'Commandes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Chauffeurs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
        currentIndex: _selectedIndex, // Spécifie l'icône active
        onTap: _onItemTapped, // Utilise la fonction de mise à jour de l'état
      ),
    );
  }
}

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final OrderService _orderService = OrderService();
  String _selectedStatusFilter = 'Toutes'; // Filtre par défaut
  bool _sortAscending = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _getStatusPriority(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 0; // Priorité la plus haute
      case 'ACCEPTED':
        return 1; // Priorité moyenne
      case 'ASSIGNED':
        return 2;
      default:
        return 3; // Priorité la plus basse
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4C4CE7), Color(0xFF6B4EE7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
                Text(
                  'Commandes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          // --- Barre de Recherche et Filtres ---
          _buildFilterBar(context),

          // --- Liste des Commandes (Dynamique) ---
          Expanded(
            child: StreamBuilder<List<Order>>(
              stream: _orderService
                  .streamAllOrders(), // Récupère TOUTES les commandes
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erreur: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Aucune commande trouvée.'));
                }

                List<Order> allOrders = snapshot.data!;

                List<Order> filteredOrders = allOrders.where((order) {
                  final statusMatch =
                      _selectedStatusFilter == 'Toutes' ||
                      order.status.toUpperCase() ==
                          _selectedStatusFilter.toUpperCase();

                  // 2. Filtrer par recherche (ID, pickup, dropoff)
                  final query = _searchQuery.trim();
                  if (query.isEmpty) {
                    return statusMatch;
                  }

                  final idMatch =
                      order.id?.toLowerCase().contains(query) ?? false;
                  final pickupMatch = order.pickupAddress
                      .toLowerCase()
                      .contains(query);
                  final dropoffMatch = order.dropoffAddress
                      .toLowerCase()
                      .contains(query);

                  return statusMatch &&
                      (idMatch || pickupMatch || dropoffMatch);
                }).toList();
                filteredOrders.sort((a, b) {
                  final priorityA = _getStatusPriority(a.status);
                  final priorityB = _getStatusPriority(b.status);

                  // 1. Tri par Priorité (PENDING vs ACCEPTED vs Autres)
                  if (priorityA != priorityB) {
                    // Si les priorités sont différentes, trie par priorité (0 avant 1, 1 avant 2...)
                    return priorityA.compareTo(priorityB);
                  }

                  // 2. Tri Secondaire par Date (si les priorités sont les mêmes)
                  // Utilise _sortAscending (false par défaut = Récent d'abord)
                  if (_sortAscending) {
                    // Tri Ascendant (Ancien -> Récent)
                    return a.timestamp.compareTo(b.timestamp);
                  } else {
                    // Tri Descendant (Récent -> Ancien) : le plus courant pour l'admin
                    return b.timestamp.compareTo(a.timestamp);
                  }
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return OrderAdminCard(order: order);
                  },
                );
              },
            ),
          ),
        ],
      ),
      // bottomNavigationBar: _buildBottomNavigationBar(), // Votre BottomNavBar
    );
  }

  // --- Widgets de la Page ---

  Widget _buildFilterBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Barre de recherche (simple pour le moment)
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Rechercher une commande...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
          const SizedBox(height: 10),
          // Boutons de filtre de statut
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusFilterButton('Toutes', display: 'Toutes'),
                const SizedBox(width: 8),
                // Utilisez les noms EN MAJUSCULES de la BD (PENDING, ACCEPTED...)
                _buildStatusFilterButton('PENDING', display: 'En Attente'),
                const SizedBox(width: 8),
                _buildStatusFilterButton('ACCEPTED', display: 'Validée'),
                const SizedBox(width: 8),
                _buildStatusFilterButton('ASSIGNED', display: 'Assignée'),
                const SizedBox(width: 8),
                _buildStatusFilterButton('COMPLETED', display: 'Terminée'),
                const SizedBox(width: 8),
                _buildStatusFilterButton('CANCELLED', display: 'Annulée'),
                const SizedBox(width: 8),
                _buildDateFilterButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterButton(String statusKey, {required String display}) {
    final bool isSelected = _selectedStatusFilter == statusKey;
    return ChoiceChip(
      label: Text(display), // Afficher le texte lisible
      selected: isSelected,
      selectedColor: const Color(0xFF8B85F1),
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : Colors.black87, // Couleurs ajustées pour plus de contraste
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey.shade200,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedStatusFilter = statusKey; // Changer l'état avec la clé BD
          });
        }
      },
    );
  }

  Widget _buildDateFilterButton() {
    return ActionChip(
      label: Text(
        _sortAscending ? 'Anciennes en premier' : 'Récentes en premier',
      ),
      avatar: Icon(
        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
        size: 18,
      ),
      onPressed: () {
        setState(() {
          _sortAscending = !_sortAscending; // Inverse l'ordre de tri
        });
      },
      backgroundColor: _sortAscending
          ? Colors.blue.shade100
          : Colors.grey.shade200,
    );
  }

  Widget _buildBottomNavigationBar() {
    // Une simple barre de navigation pour l'exemple
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, // Les labels restent visibles
      selectedItemColor: const Color(0xFF4C4CE7), // Votre couleur primaire
      unselectedItemColor: Colors.grey,
      currentIndex: 1, // 'Commandes' est le deuxième onglet (index 1)
      onTap: (index) {
        // Logique de navigation ici (utilisez GoRouter)
        switch (index) {
          case 0:
            context.go(
              '/adminDashboard',
            ); // Vers l'écran de tableau de bord Admin
            break;
          case 1:
            // Déjà sur l'écran des commandes, ne rien faire
            break;
          case 2:
            context.go('/adminDeliverers'); // Vers la liste des chauffeurs
            break;
          case 3:
            //context.go('/adminSettings'); // Vers les paramètres Admin
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Tableau de bord',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag), // Ou Icons.list_alt
          label: 'Commandes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping),
          label: 'Chauffeurs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Paramètres',
        ),
      ],
    );
  }
}

// --- Widget de Carte de Commande pour l'Admin ---

class OrderAdminCard extends StatelessWidget {
  final Order order;

  OrderAdminCard({super.key, required this.order});

  // Fonction pour obtenir la couleur du statut
  static Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange.shade700;
      case 'ACCEPTED': // Correspond à Validée
        return Colors.green.shade700;
      case 'ASSIGNED':
        return Colors.blue.shade700;
      case 'COMPLETED': // Correspond à Livrée
        return Colors.indigo.shade700;
      case 'CANCELLED':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  // Fonction pour obtenir le texte du statut
  static String _getDisplayStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'En Attente';
      case 'ACCEPTED':
        return 'Validée';
      case 'ASSIGNED':
        return 'Assignée';
      case 'COMPLETED':
        return 'Livrée';
      case 'CANCELLED':
        return 'Annulée';
      default:
        return status;
    }
  }

  final OrderService _service = OrderService();
  final UserProfileService _userProfileService = UserProfileService();
  String? _selectedDelivererId;

  final _formKey = GlobalKey<FormState>();
  final _textFieldController = TextEditingController();
  void _submitForm(BuildContext context) {
    if (_selectedDelivererId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un livreur.')),
      );
      return; // Stop submission if no deliverer is selected
    }

    final priceQuote = _textFieldController.text;
    _service.updateFinalPrice(order.id!, double.parse(priceQuote));

    // Assigner la commande
    _service.assignDeliverer(
      orderId: order.id!,
      delivererUid: _selectedDelivererId!,
    );

    // Afficher un message de confirmation rapide (optionnel)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Commande assignée avec le prix $priceQuote.')),
    );
    _textFieldController.clear();

    // Fermer la pop-up
    Navigator.of(context).pop();
  }

  void showSingleFieldFormDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              title: const Text('Accepter & Assigner'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _textFieldController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Prix final',
                          hintText: '12000',
                          icon: Icon(Icons.money),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              double.tryParse(value) == null) {
                            return 'Veuillez entrer un prix valide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      StreamBuilder<List<UserProfile>>(
                        stream: _userProfileService.getDeliverersStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text(
                              'Aucun livreur disponible.',
                              style: TextStyle(color: Colors.red),
                            );
                          }

                          List<UserProfile> deliverers = snapshot.data!;

                          return DropdownButtonFormField<String>(
                            initialValue: _selectedDelivererId,
                            hint: const Text('Choisir un livreur'),
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Livreur',
                              icon: Icon(Icons.local_shipping),
                            ),
                            items: deliverers.map((UserProfile deliverer) {
                              return DropdownMenuItem<String>(
                                value: deliverer.uid,
                                child: Text(deliverer.name.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                _selectedDelivererId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez assigner un livreur.';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('ANNULER'),
                  onPressed: () {
                    Navigator.of(builderContext).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('VALIDER'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _submitForm(builderContext);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showManageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Gérer la commande'),
          content: Text(
            'Que souhaitez-vous faire avec la commande #${order.id?.substring(0, 6).toUpperCase()} ?',
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
                _service.updateOrderStatus(
                  orderId: order.id!,
                  newStatus: 'COMPLETED',
                ); // Statut payé/terminé
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text(
                'Terminée (Payée)',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _service.updateOrderStatus(
                  orderId: order.id!,
                  newStatus: 'CANCELLED',
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Annuler',
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
    final statusColor = _getStatusColor(order.status);
    final displayStatus = _getDisplayStatus(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: #${order.id?.substring(0, 6).toUpperCase()}', // ID court
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    displayStatus,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            FutureBuilder<UserProfile?>(
              future: _userProfileService.getProfile(order.userId),
              builder: (context, snapshot) {
                // État de chargement
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Text('.....'));
                }

                // État d'erreur ou profil non trouvé
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data == null) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Profil')),
                    body: Center(
                      child: Text(
                        'Erreur de chargement du profil: ${snapshot.error ?? "Données introuvables"}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final UserProfile profile = snapshot.data!;
                return Text(
                  'Client: ${profile.name}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                );
              },
            ), // Vous voudrez le nom du client
            Text(
              'Depart: ${order.pickupAddress}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            Text(
              'Destination: ${order.dropoffAddress}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            Text(
              'Date: ${order.timestamp.toLocal().day}/${order.timestamp.toLocal().month}/${order.timestamp.toLocal().year} ${order.timestamp.toLocal().hour}:${order.timestamp.toLocal().minute}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Action pour voir les détails (naviguer vers un OrderDetailsScreen)
                      context.go('/orderDetailsAdmin/${order.id}');
                    },
                    icon: const Icon(Icons.remove_red_eye_outlined),
                    label: const Text('Voir détails'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4C4CE7),
                      side: const BorderSide(color: Color(0xFF4C4CE7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (order.status.toUpperCase() == 'PENDING') {
                        showSingleFieldFormDialog(context);
                      } else if (order.status.toUpperCase() == 'ACCEPTED' ||
                          order.status.toUpperCase() == 'ASSIGNED') {
                        showManageDialog(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          statusColor, // Couleur dynamique pour le bouton
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      order.status.toUpperCase() == 'PENDING'
                          ? 'Accepter'
                          : (order.status.toUpperCase() == 'ACCEPTED' ||
                                    order.status.toUpperCase() == 'ASSIGNED'
                                ? 'Gérer'
                                : 'Terminé'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OrderDetailsAdminScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailsAdminScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final OrderService orderService = OrderService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détails Commande #${orderId.substring(0, 6).toUpperCase()}',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/admin');
          },
        ),
        backgroundColor: const Color(0xFF4C4CE7),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Order?>(
        // Assurez-vous d'avoir une méthode fetchOrderById dans votre OrderService
        future: orderService.getOrdersById(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'Erreur de chargement des détails: ${snapshot.error}',
              ),
            );
          }

          final order = snapshot.data!;
          final List<String>? photoUrl = snapshot.data?.photoUrls;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusSection(order.status),
                const SizedBox(height: 20),
                _buildDetailCard(
                  title: 'Informations de Base',
                  children: [
                    _buildInfoRow('Client ID', order.userId),
                    _buildInfoRow(
                      'Prix Final',
                      '${order.priceQuote?.toStringAsFixed(2)} FCFA',
                    ),
                    _buildInfoRow('Description', '${order.description}'),
                    _buildInfoRow(
                      'Créée le',
                      '${order.timestamp.toLocal().day}/${order.timestamp.toLocal().month}/${order.timestamp.toLocal().year}',
                    ),
                    // Ajouter le nom du livreur si 'delivererId' est disponible
                    // _buildInfoRow('Livreur', order.delivererName ?? 'Non assigné'),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDetailCard(
                  title: 'Adresses',
                  children: [
                    _buildInfoRow(
                      'Départ',
                      order.pickupAddress,
                      icon: Icons.location_on,
                    ),
                    _buildInfoRow(
                      'Destination',
                      order.dropoffAddress,
                      icon: Icons.flag,
                    ),
                  ],
                ),
                SizedBox(height: 15),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: photoUrl?.length,
                  itemBuilder: (context, photo) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          photoUrl![photo], // L'URL de Firebase Storage
                          width: 100,
                          height: 500,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            // Afficher un indicateur pendant le chargement
                            if (loadingProgress == null) return child;
                            return const SizedBox(
                              height: 300,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            // Afficher un message si l'image ne charge pas
                            return const SizedBox(
                              height: 300,
                              child: Center(
                                child: Text(
                                  'Erreur de chargement de l\'image.',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),

                // Ajoutez d'autres sections pour le type de colis, notes, etc.
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusSection(String status) {
    final statusColor = OrderAdminCard._getStatusColor(status);
    final displayStatus = OrderAdminCard._getDisplayStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: statusColor),
          const SizedBox(width: 10),
          Text(
            'Statut Actuel: $displayStatus',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4C4CE7),
              ),
            ),
            const Divider(height: 15, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    IconData icon = Icons.info_outline,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
