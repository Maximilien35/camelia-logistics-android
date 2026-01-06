import 'package:camelia_logistics/models/order_model.dart';
import 'package:camelia_logistics/models/services/AdminService.dart';
import 'package:camelia_logistics/models/services/order_service.dart';
import 'package:camelia_logistics/models/userProfile.dart';
import 'package:camelia_logistics/screens/history_screen.dart';
import 'package:camelia_logistics/screens/order_screen.dart';
import 'package:camelia_logistics/screens/profil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:camelia_logistics/models/services/userProfileService.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeCustumerScreen extends StatefulWidget {
  const HomeCustumerScreen({super.key});

  @override
  _HomeCustumer_Sate createState() => _HomeCustumer_Sate();
}

class _HomeCustumer_Sate extends State<HomeCustumerScreen> {
  int _selectedIndex = 0;
  final AdminService admin = AdminService();
  Future<bool> _handlePop(BuildContext context) async {
    // Si l'utilisateur est sur l'onglet "Accueil" (selectedIndex == 0)
    if (_selectedIndex == 0) {
      // 1. Ouvrir une boîte de dialogue de confirmation
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmer la sortie'),
          content: const Text('Voulez-vous vraiment quitter l\'application ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false), // Rester dans l'appli
              child: const Text('NON'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Quitter
              child: const Text('OUI'),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    // Si l'utilisateur est sur un autre onglet (Historique ou Profil)
    else {
      // 2. Simplement revenir à l'onglet "Accueil" sans quitter l'appli
      setState(() {
        _selectedIndex = 0;
      });
      return false; // ⭐ Retourne false pour BLOQUER la pop (donc rester dans l'appli)
    }
  }

  Future<void> handlePopInvoked(bool didPop, BuildContext context) async {
    if (didPop) {
      return;
    }
    bool? exitConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmer la Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir  quitter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ANNULER'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                SystemNavigator.pop();
              },
              child: const Text('QUITTER'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    initializeFCMToken();
  }

  static final List<Widget> _widgetOptions = <Widget>[
    _HomeContent(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void initializeFCMToken() async {
    // 1. Demander les permissions de notification (obligatoire sur iOS/Android 13+)
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Récupérer le jeton unique de l'appareil
      String? token = await FirebaseMessaging.instance.getToken();

      final currentUser = FirebaseAuth.instance.currentUser;

      if (token != null && currentUser != null) {
        if (kDebugMode) {
          print("FCM Token récupéré : $token");
        }
        UserProfileService().saveFCMToken(currentUser.uid, token);
      }
    } else {
      if (kDebugMode) {
        print("Permissions de notification refusées par l'utilisateur.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 1. Bloquer l'action par défaut du retour (GoRouter)
      canPop: false,

      // 2. Intercepter l'action bloquée et effectuer la logique
      onPopInvoked: (didPop) {
        handlePopInvoked(didPop, context);
      },
      child: Scaffold(
        body: _widgetOptions.elementAt(
          _selectedIndex,
        ), // Affiche l'écran sélectionné
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue.shade800,
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Historique',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
          currentIndex: _selectedIndex, // Spécifie l'icône active
          onTap: _onItemTapped, // Utilise la fonction de mise à jour de l'état
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final OrderService _orderService = OrderService();
  final UserProfileService _userProfileService = UserProfileService();
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
        return 'En cours';
      case 'COMPLETED':
        return 'Livrée';
      case 'CANCELLED':
        return 'Annulée';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final idUser = FirebaseAuth.instance.currentUser?.uid;
    // if (id_user == null) {
    //   return const Center(child: CircularProgressIndicator());
    // }
    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. Le Container pour la zone de bienvenue
          // --- Carte d'Accueil/Profil ---
          StreamBuilder<UserProfile?>(
            stream: UserProfileService().streamProfile(idUser!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null) {
                return Text(
                  'Erreur de chargement du profil.,${snapshot.error}',
                );
              }

              final prof = snapshot.data!;

              return Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Bonjour, ${prof.name.split(' ')[0].toUpperCase()}',
                            style: GoogleFonts.pacifico(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Que souhaitez-vous aujourd\'hui?',
                            style: GoogleFonts.montserrat(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.local_shipping,
                      color: Colors.white,
                      size: 40,
                    ),
                  ],
                ),
              );
            },
          ),

          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => OrderScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade800,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Nouveau transport',
                          style: GoogleFonts.ubuntu(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 35),

              FutureBuilder(
                future: _userProfileService.calculateAndSetClientRank(
                  uid: idUser,
                  stat: 'COMPLETED',
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data == null) {
                    return Text(
                      'Erreur de chargement du profil.,${snapshot.error}',
                    );
                  }
                  final orderCount = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.unarchive,
                            iconColor: Colors.blue.shade800,
                            value: orderCount.toString(),
                            label: 'Colis envoyés',
                          ),
                        ),
                        const SizedBox(width: 10),
                        FutureBuilder(
                          future: _userProfileService.calculateAndSetClientRank(
                            uid: idUser,
                            stat: 'ASSIGNED',
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.data == null) {
                              Text('0');
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return Expanded(
                              child: _buildStatCard(
                                icon: Icons.local_shipping,
                                iconColor: Colors.green.shade600,
                                value: snapshot.data.toString(),
                                label: 'en cours ',
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.access_time,
                            iconColor: Colors.orange.shade800,
                            value: orderCount.toString(),
                            label: 'Ce mois',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          // 2. Le bouton "Nouveau transport"
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Livraisons récentes',
                  style: GoogleFonts.ubuntu(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => HistoryScreen()),
                    );
                  },
                  child: Text(
                    'Voir tout',
                    style: GoogleFonts.montserrat(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<Order>>(
            stream:
                _orderService.streamUserOrders(idUser) as Stream<List<Order>>?,

            builder: (context, snapshot) {
              // 1. État de Chargement
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // 2. État d'Erreur
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50.0),
                    child: Text('Erreur : ${snapshot.error}'),
                  ),
                );
              }

              // 3. État sans Données
              final orders = snapshot.data;
              if (orders == null || orders.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50.0),
                    child: Text('Aucune commande trouvée.'),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orders.length > 3 ? 3 : orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Column(
                    children: [
                      _buildRecentDeliveryCard(
                        destination: order.dropoffAddress.toUpperCase(),
                        time: order.timestamp.toString().substring(0, 16),

                        status: order.status,
                        iconColor: Colors.green.shade600,
                      ),
                      SizedBox(height: 15),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDeliveryCard({
    required String destination,
    required String time,
    required String status,
    // required double rating,
    required Color iconColor,
  }) {
    final statusColor = _getStatusColor(status);
    final displayStatus = _getDisplayStatus(status);
    // ... (le code de la carte reste le même)
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.symmetric(horizontal: 20), // Ajout d'une marge
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(
                0.2,
              ), // Colors.blueAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.location_on, color: statusColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.playfair(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  // TextStyle(
                  //   fontSize: 14,
                  //   fontFamily: 'Roboto',
                  //   color: Colors.grey[600],
                  // ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  displayStatus,
                  style: GoogleFonts.ubuntu(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              //if (status == 'Livré')
              // Row(
              //   children: List.generate(5, (index) {
              //     return Icon(
              //       index < rating ? Icons.star : Icons.star_border,
              //       color: Colors.amber,
              //       size: 15,
              //     );
              //   }),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 35, color: iconColor),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.playfair(fontSize: 14, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
