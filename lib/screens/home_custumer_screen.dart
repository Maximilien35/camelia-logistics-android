// ignore_for_file: file_names
import 'package:camelia/models/order_model.dart';
import 'package:camelia/models/services/admin_service.dart';
import 'package:camelia/models/services/order_service.dart';
import 'package:camelia/models/user_profile.dart';
import 'package:camelia/screens/history_screen.dart';
import 'package:camelia/screens/order_screen.dart';
import 'package:camelia/screens/profil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camelia/models/services/user_profile_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camelia/l10n/app_localizations.dart';
import 'package:camelia/models/order_state_model.dart';
import 'package:provider/provider.dart';

class HomeCustumerScreen extends StatefulWidget {
  const HomeCustumerScreen({super.key});

  @override
  State<HomeCustumerScreen> createState() => HomeCustumerSate();
}

class HomeCustumerSate extends State<HomeCustumerScreen> {
  int _selectedIndex = 0;
  final AdminService admin = AdminService();

  Future<void> handlePopInvoked(bool didPop, BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    if (didPop) {
      return;
    }
    // ignore: unused_local_variable
    bool? exitConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            l10n.confirmLogout,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          content: Text(
            l10n.confirmLogoutMessage,
            style: GoogleFonts.poppins(color: Colors.grey.shade600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                l10n.cancel.toUpperCase(),
                style: GoogleFonts.poppins(
                  color: const Color(0xFF6C63FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                SystemNavigator.pop();
              },
              child: Text(
                l10n.quit.toUpperCase(),
                style: GoogleFonts.poppins(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
    const _HomeContent(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void initializeFCMToken() async {
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
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
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        } else {
          handlePopInvoked(didPop, context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF6C63FF),
          unselectedItemColor: Colors.grey.shade400,
          backgroundColor: Colors.white,
          elevation: 8,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: l10n.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history_rounded),
              label: l10n.history,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: l10n.profile,
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final OrderService _orderService = OrderService();
  final UserProfileService _userProfileService = UserProfileService();
  late Stream<UserProfile?> _profileStream;
  final String? idUser = FirebaseAuth.instance.currentUser?.uid;
  int _currentServiceIndex = 0;
  final PageController _pageController = PageController();

  late Future<int?> _completedOrdersFuture;
  late Future<int?> _assignedOrdersFuture;
  late Stream<List<Order>> _recentOrdersStream;

  final List<Map<String, dynamic>> services = [
    {
      'name': 'Colis',
      'image': "assets/livraison-carousel.webp",
      'color': Colors.blue,
    },
    {
      'name': 'Déménagement',
      'image': "assets/demenagement-carousel.webp",
      'color': Colors.orange,
    },
    {
      'name': 'Stockage',
      'image': 'assets/stockage-carousel.webp',
      'color': Colors.brown,
    },
    {
      'name': 'A l\'internationale',
      'image': 'assets/internationale.webp',
      'color': Colors.green,
    },
    {
      'name': 'Expédition',
      'image': 'assets/expedition-carousel.webp',
      'color': Colors.red,
    },
  ];

  @override
  void initState() {
    super.initState();
    _profileStream = idUser != null
        ? _userProfileService.streamProfile(idUser!)
        : Stream.value(null);
    if (idUser != null) {
      _completedOrdersFuture = _userProfileService.calculateAndSetClientRank(
        uid: idUser!,
        stat: 'COMPLETED',
      );
      _assignedOrdersFuture = _userProfileService.calculateAndSetClientRank(
        uid: idUser!,
        stat: 'ASSIGNED',
      );
      _recentOrdersStream = _orderService.streamUserOrders(idUser!, limit: 3);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.green.shade700;
      case 'ASSIGNED':
        return Colors.blue.shade700;
      case 'ACCEPTED':
        return const Color(0xFF6C63FF);
      case 'COMPLETED':
        return Colors.indigo.shade700;
      case 'CANCELLED':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getDisplayStatus(String status, AppLocalizations l10n) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return l10n.statusPending;
      case 'ACCEPTED':
        return l10n.statusAccepted;
      case 'ASSIGNED':
        return l10n.statusAssigned;
      case 'COMPLETED':
        return l10n.statusCompleted;
      case 'CANCELLED':
        return l10n.statusCancelled;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (idUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.offlineMode,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.checkConnection,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<UserProfile?>(
            stream: _profileStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerHeader();
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null) {
                return _buildHeader(
                  name: l10n.client,
                  subtitle: l10n.offlineMode,
                  isOffline: true,
                );
              }
              final prof = snapshot.data!;
              return _buildHeader(
                name: l10n.hello(prof.name.split(' ')[0].toUpperCase()),
                subtitle: l10n.whatToDoToday,
                isOffline: false,
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.needed,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                // Carrousel des services
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: services.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentServiceIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return GestureDetector(
                        onTap: () {
                          Provider.of<OrderStateModel>(
                            context,
                            listen: false,
                          ).reset();
                          Provider.of<OrderStateModel>(
                            context,
                            listen: false,
                          ).setServiceType(service['name']);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OrderScreen(),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  service['image'],
                                  fit: BoxFit.cover,
                                  // loadingBuilder:
                                  //     (context, child, loadingProgress) {
                                  //       if (loadingProgress == null) {
                                  //         return child;
                                  //       }
                                  //       return Container(
                                  //         color: Colors.grey.shade200,
                                  //         child: const Center(
                                  //           child: CircularProgressIndicator(),
                                  //         ),
                                  //       );
                                  //     },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: (service['color'] as Color)
                                          .withValues(alpha: 0.1),
                                      child: Icon(
                                        Icons.broken_image,
                                        color: service['color'],
                                        size: 50,
                                      ),
                                    );
                                  },
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withValues(alpha: 0.6),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 20,
                                  left: 20,
                                  right: 20,
                                  child: Text(
                                    service['name'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Indicateurs du carrousel
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    services.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentServiceIndex == index ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentServiceIndex == index
                            ? const Color(0xFF6C63FF)
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Material(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white,
                  elevation: 0,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const OrderScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.grey.shade100,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.05),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF6C63FF,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Color(0xFF6C63FF),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.newTransport,
                                  style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Planifiez une nouvelle livraison',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey.shade400,
                            size: 26,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Cartes statistiques
                FutureBuilder(
                  future: _completedOrdersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      return Center(
                        child: Text(
                          l10n.checkConnection,
                          style: GoogleFonts.poppins(
                            color: Colors.red.shade600,
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    }
                    final orderCount = snapshot.data!;
                    return Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.unarchive_rounded,
                            iconColor: const Color(0xFF6C63FF),
                            value: orderCount.toString(),
                            label: l10n.sentPackages,
                          ),
                        ),
                        const SizedBox(width: 12),
                        FutureBuilder(
                          future: _assignedOrdersFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Expanded(
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return Expanded(
                              child: _buildStatCard(
                                icon: Icons.local_shipping_rounded,
                                iconColor: Colors.green.shade600,
                                value: snapshot.data?.toString() ?? '0',
                                label: l10n.inProgress,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.access_time_rounded,
                            iconColor: Colors.orange.shade800,
                            value: orderCount.toString(),
                            label: l10n.thisMonth,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Titre "Livraisons récentes"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.recentDeliveries,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const HistoryScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6C63FF),
                      ),
                      child: Text(
                        l10n.seeAll,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Liste des commandes récentes
                StreamBuilder<List<Order>>(
                  stream: _recentOrdersStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                            l10n.checkConnection,
                            style: GoogleFonts.poppins(
                              color: Colors.red.shade600,
                            ),
                          ),
                        ),
                      );
                    }
                    final orders = snapshot.data;
                    if (orders == null || orders.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                            l10n.noOrdersFound,
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: orders.map((order) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildRecentDeliveryCard(
                            destination: order.dropoffAddress.toUpperCase(),
                            time: order.timestamp.toString().substring(0, 16),
                            status: order.status,
                            l10n: l10n,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 150,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required String name,
    required String subtitle,
    required bool isOffline,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isOffline
                  ? Icons.cloud_off_rounded
                  : Icons.local_shipping_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDeliveryCard({
    required String destination,
    required String time,
    required String status,
    required AppLocalizations l10n,
  }) {
    final statusColor = _getStatusColor(status);
    final displayStatus = _getDisplayStatus(status, l10n);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              displayStatus,
              style: GoogleFonts.poppins(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
