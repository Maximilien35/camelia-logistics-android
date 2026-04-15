import 'package:camelia/models/services/user_profile_service.dart';
import 'package:camelia/models/user_profile.dart';
import 'package:camelia/screens/admin_assign_staff.dart';
import 'package:camelia/screens/admin_dashboard.dart';
import 'package:camelia/screens/admin_deliverers.dart';
import 'package:camelia/screens/admin_settings.dart';
import 'package:camelia/screens/admin_collaborators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:camelia/models/services/order_service.dart';
import 'package:camelia/models/order_model.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ImageCacheService {
  ImageCacheService._private();
  static final ImageCacheService instance = ImageCacheService._private();

  final Map<String, ImageProvider> _cache = {};
  final Map<String, DateTime> _expiry = {};
  Duration ttl = const Duration(minutes: 30);
  final int _maxEntries = 200;

  Future<ImageProvider> getImageProvider(
    String url,
    BuildContext context,
  ) async {
    final now = DateTime.now();
    final cached = _cache[url];
    final expiry = _expiry[url];
    if (cached != null && expiry != null && expiry.isAfter(now)) {
      return cached;
    }

    try {
      final provider = NetworkImage(url);
      await precacheImage(provider, context);
      _addToCache(url, provider);
      return provider;
    } catch (e) {
      return const AssetImage('assets/logo2.webp');
    }
  }

  void _addToCache(String url, ImageProvider provider) {
    if (_cache.length >= _maxEntries) {
      String? oldestKey;
      DateTime oldest = DateTime.now().add(const Duration(days: 365));
      _expiry.forEach((k, v) {
        if (v.isBefore(oldest)) {
          oldest = v;
          oldestKey = k;
        }
      });
      if (oldestKey != null) {
        _cache.remove(oldestKey);
        _expiry.remove(oldestKey);
      }
    }
    _cache[url] = provider;
    _expiry[url] = DateTime.now().add(ttl);
  }

  void invalidate(String url) {
    _cache.remove(url);
    _expiry.remove(url);
  }

  void clear() {
    _cache.clear();
    _expiry.clear();
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    initializeFCMToken();
  }

  void initializeFCMToken() async {
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await FirebaseMessaging.instance.getToken();

      final currentUser = FirebaseAuth.instance.currentUser;

      if (token != null && currentUser != null) {
        if (kDebugMode) {
          print("FCM Token Admin récupéré : $token");
        }
        // Sauvegarde via le service existant
        UserProfileService().saveFCMToken(currentUser.uid, token);
      }
    } else {
      if (kDebugMode) {
        print("Permissions de notification refusées par l'admin.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          AdminDashboard(),
          AdminOrdersScreen(),
          AdminDeliverersScreen(),
          AdminCollaboratorsScreen(),
          AdminSettings(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF6C63FF),
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: _selectedIndex == 0
                      ? const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                        )
                      : null,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.dashboard_rounded,
                  color: _selectedIndex == 0
                      ? Colors.white
                      : Colors.grey.shade500,
                  size: 20,
                ),
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: _selectedIndex == 1
                      ? const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                        )
                      : null,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.list_alt_rounded,
                  color: _selectedIndex == 1
                      ? Colors.white
                      : Colors.grey.shade500,
                  size: 20,
                ),
              ),
              label: 'Commandes',
            ),
            BottomNavigationBarItem(
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: _selectedIndex == 2
                      ? const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                        )
                      : null,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: _selectedIndex == 2
                      ? Colors.white
                      : Colors.grey.shade500,
                  size: 20,
                ),
              ),
              label: 'Chauffeurs',
            ),
            BottomNavigationBarItem(
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: _selectedIndex == 3
                      ? const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                        )
                      : null,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.groups_rounded,
                  color: _selectedIndex == 3
                      ? Colors.white
                      : Colors.grey.shade500,
                  size: 20,
                ),
              ),
              label: 'Collaborateurs',
            ),
            BottomNavigationBarItem(
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: _selectedIndex == 4
                      ? const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                        )
                      : null,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.settings_rounded,
                  color: _selectedIndex == 4
                      ? Colors.white
                      : Colors.grey.shade500,
                  size: 20,
                ),
              ),
              label: 'Paramètres',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
          },
        ),
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
  String _selectedStatusFilter = 'Toutes';
  bool _sortAscending = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = value.toLowerCase());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Header épuré
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 30,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey.shade50],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Commandes',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF6C63FF),
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.05),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Rechercher une commande...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey.shade400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filtres
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Toutes', display: 'Toutes'),
                  const SizedBox(width: 8),
                  _buildFilterChip('PENDING', display: 'En attente'),
                  const SizedBox(width: 8),
                  _buildFilterChip('ACCEPTED', display: 'Validées'),
                  const SizedBox(width: 8),
                  _buildFilterChip('ASSIGNED', display: 'Assignées'),
                  const SizedBox(width: 8),
                  _buildFilterChip('COMPLETED', display: 'Terminées'),
                  const SizedBox(width: 8),
                  _buildFilterChip('CANCELLED', display: 'Annulées'),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() => _sortAscending = !_sortAscending);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _sortAscending
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 18,
                            color: const Color(0xFF6C63FF),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _sortAscending ? 'Anciennes' : 'Récentes',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6C63FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Liste des commandes (lecture à la demande, pas de realtime)
          Expanded(
            child: StreamBuilder<List<Order>>(
              stream: _orderService.streamAllOrders(
                limit: 100,
                statusFilter: _selectedStatusFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6C63FF),
                      strokeWidth: 2,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erreur de chargement',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune commande',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  );
                }

                List<Order> allOrders = snapshot.data!;
                List<Order> filteredOrders = allOrders.where((order) {
                  final query = _searchQuery.trim();
                  if (query.isEmpty) return true;

                  final idMatch =
                      order.id?.toLowerCase().contains(query) ?? false;
                  final pickupMatch = order.pickupAddress
                      .toLowerCase()
                      .contains(query);
                  final dropoffMatch = order.dropoffAddress
                      .toLowerCase()
                      .contains(query);

                  return idMatch || pickupMatch || dropoffMatch;
                }).toList();

                filteredOrders.sort((a, b) {
                  if (_sortAscending) {
                    return a.timestamp.compareTo(b.timestamp);
                  } else {
                    return b.timestamp.compareTo(a.timestamp);
                  }
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
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
    );
  }

  Widget _buildFilterChip(String statusKey, {required String display}) {
    final bool isSelected = _selectedStatusFilter == statusKey;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedStatusFilter = statusKey);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                )
              : null,
          color: isSelected ? null : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Text(
          display,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class OrderAdminCard extends StatelessWidget {
  final Order order;
  final OrderService _service = OrderService();
  final UserProfileService _userProfileService = UserProfileService();

  OrderAdminCard({super.key, required this.order});

  static Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFFF9800);
      case 'ACCEPTED':
        return const Color(0xFF4CAF50);
      case 'ASSIGNED':
        return const Color(0xFF2196F3);
      case 'COMPLETED':
        return const Color(0xFF6C63FF);
      case 'CANCELLED':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  static String _getDisplayStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'En attente';
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

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final displayStatus = _getDisplayStatus(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                statusColor.withValues(alpha: 0.2),
                                statusColor.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getStatusIcon(order.status),
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${(order.id?.substring(0, 6) ?? '000000').toUpperCase()}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(order.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        displayStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Client',
                      value: _getClientName(context),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Départ',
                      value: order.pickupAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.flag_outlined,
                      label: 'Destination',
                      value: order.dropoffAddress,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderDetailsAdminScreen(orderId: order.id!),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6C63FF),
                          side: const BorderSide(color: Color(0xFF6C63FF)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Détails'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Material(
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () async {
                            final status = order.status.toUpperCase();
                            if (status == 'PENDING') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminAssignStaffScreen(
                                    orderId: order.id!,
                                  ),
                                ),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Commande acceptée.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }

                            if (status == 'PENDING' ||
                                status == 'ACCEPTED' ||
                                status == 'ASSIGNED') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminAssignStaffScreen(
                                    orderId: order.id!,
                                  ),
                                ),
                              );
                            } else if (status == 'COMPLETED' ||
                                status == 'CANCELLED') {
                              _showManageDialog(context);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  statusColor,
                                  statusColor.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                _getActionButtonText(order.status),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required dynamic value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              if (value is Widget)
                value
              else
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _getActionButtonText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Accepter';
      case 'ACCEPTED':
      case 'ASSIGNED':
        return 'Gérer';
      default:
        return 'Terminé';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.access_time_rounded;
      case 'ACCEPTED':
        return Icons.check_circle_outline_rounded;
      case 'ASSIGNED':
        return Icons.local_shipping_rounded;
      case 'COMPLETED':
        return Icons.done_all_rounded;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _getClientName(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: _userProfileService.getProfile(order.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            'Chargement...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Text(
            'Client inconnu',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          );
        }

        return Text(
          snapshot.data!.name,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }

  void _showManageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Color(0xFF6C63FF),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Gérer la commande',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '#${(order.id?.substring(0, 6) ?? '').toUpperCase()}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _service.updateOrderStatus(
                            orderId: order.id!,
                            newStatus: 'CANCELLED',
                          );
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Material(
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            _service.updateOrderStatus(
                              orderId: order.id!,
                              newStatus: 'COMPLETED',
                            );
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Terminer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class OrderDetailsAdminScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsAdminScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsAdminScreen> createState() =>
      _OrderDetailsAdminScreenState();
}

class _OrderDetailsAdminScreenState extends State<OrderDetailsAdminScreen> {
  late Future<Order?> _orderFuture;
  final OrderService orderService = OrderService();
  final UserProfileService _userProfileService = UserProfileService();
  List<LatLng> _routePoints = [];
  LatLng? _pickupCoords;
  LatLng? _dropoffCoords;
  bool _isLoadingMap = true;
  String? _delivererName;

  late TextEditingController _priceController;
  bool _isSavingPrice = false;

  void _initPriceController(double? price) {
    _priceController = TextEditingController(
      text: price != null && price > 0 ? price.toStringAsFixed(0) : '',
    );
  }

  @override
  void initState() {
    super.initState();
    _orderFuture = orderService.getOrdersById(widget.orderId).then((order) {
      if (order != null) {
        _loadMapData(order);
        _loadDelivererName(order.delivererId);
        _initPriceController(order.priceQuote);
      }
      return order;
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadDelivererName(String? delivererId) async {
    if (delivererId == null) return;
    final profile = await _userProfileService.getProfile(delivererId);
    if (mounted) {
      setState(() {
        _delivererName = '${profile?.name}-${profile?.phoneNumber ?? ''}';
      });
    }
  }

  Future<void> _setOrderPrice(String orderId) async {
    final quoteValue = double.tryParse(_priceController.text);
    if (quoteValue == null || quoteValue <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un prix de devis valide.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSavingPrice = true);
    try {
      await orderService.updateFinalPrice(orderId, quoteValue);
      await orderService.updateOrderStatus(
        orderId: orderId,
        newStatus: 'ACCEPTED',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prix de devis mis à jour avec succès.'),
          backgroundColor: Colors.green,
        ),
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur mise à jour devis: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingPrice = false);
    }
  }

  Future<void> _loadMapData(Order order) async {
    try {
      List<Location> pickupLocations = await locationFromAddress(
        order.pickupAddress,
      );
      List<Location> dropoffLocations = await locationFromAddress(
        order.dropoffAddress,
      );

      if (pickupLocations.isNotEmpty && dropoffLocations.isNotEmpty) {
        _pickupCoords = LatLng(
          pickupLocations.first.latitude,
          pickupLocations.first.longitude,
        );
        _dropoffCoords = LatLng(
          dropoffLocations.first.latitude,
          dropoffLocations.first.longitude,
        );

        final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/${_pickupCoords!.longitude},${_pickupCoords!.latitude};${_dropoffCoords!.longitude},${_dropoffCoords!.latitude}?overview=full&geometries=geojson',
        );
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final geometry = data['routes'][0]['geometry']['coordinates'] as List;
          if (mounted) {
            setState(
              () => _routePoints = geometry
                  .map((p) => LatLng(p[1].toDouble(), p[0].toDouble()))
                  .toList(),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Erreur chargement carte: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMap = false);
    }
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 300,
                      height: 300,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: FutureBuilder<Order?>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6C63FF),
                strokeWidth: 2,
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: GoogleFonts.poppins(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            );
          }

          final order = snapshot.data!;
          final List<String> photoUrls = order.photoUrls;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 350,
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                leading: IconButton(
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.black87,
                      size: 20,
                    ),
                  ),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildMapSection(),
                  title: Text(
                    '#${(order.id?.substring(0, 6) ?? '').toUpperCase()}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  centerTitle: true,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(order.status),
                      const SizedBox(height: 24),
                      _buildSection(
                        title: 'Informations de livraison',
                        children: [
                          _buildDetailRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Client',
                            value: _buildClientNameWidget(order.userId),
                          ),

                          _buildDetailRow(
                            icon: Icons.local_shipping_rounded,
                            label: 'Livreur assigné',
                            value:
                                _delivererName ??
                                order.delivererId ??
                                'Non assigné',
                          ),
                          if (order.status.toUpperCase() != 'CANCELLED')
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 8),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AdminAssignStaffScreen(
                                            orderId: order.id!,
                                          ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.sync_alt_rounded),
                                label: const Text('Changer de prestataire'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          _buildDetailRow(
                            icon: Icons.attach_money_rounded,
                            label: 'Prix',
                            value:
                                '${order.priceQuote?.toStringAsFixed(2) ?? '0.00'} FCFA',
                          ),
                          if (order.isQuote)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                Text(
                                  'Devis',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _priceController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          hintText: 'Saisir le prix final',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: _isSavingPrice
                                          ? null
                                          : () => _setOrderPrice(order.id!),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF6C63FF,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: _isSavingPrice
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Valider'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          _buildDetailRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Date de création',
                            value: _formatDate(order.timestamp),
                          ),
                          _buildDetailRow(icon: Icons.abc, label: "type", value: order.serviceType),
                          if (order.description != null &&
                              order.description!.isNotEmpty)
                            _buildDetailRow(
                              icon: Icons.description_outlined,
                              label: 'Description',
                              value: order.description!,
                              isMultiLine: true,
                            ),
                          if (order.serviceType != 'LIVRAISON' &&
                              order.additionalDetails.isNotEmpty)
                            _buildDetailRow(
                              icon: Icons.info_outline_rounded,
                              label: 'Détails supplémentaires',
                              value: order.additionalDetails.entries
                                  .map((e) => '${e.key}: ${e.value}')
                                  .join('\n'),
                              isMultiLine: true,                 
                              ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildAddressSection(order),
                      const SizedBox(height: 24),
                      if (photoUrls.isNotEmpty) ...[
                        _buildSection(
                          title: 'Photos',
                          children: [
                            SizedBox(
                              height: 200,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: photoUrls.length,
                                itemBuilder: (context, index) {
                                  final url = photoUrls[index];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: index < photoUrls.length - 1
                                          ? 16
                                          : 0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () => _showFullScreenImage(url),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: FutureBuilder<ImageProvider>(
                                          future: ImageCacheService.instance
                                              .getImageProvider(url, context),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Container(
                                                width: 150,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Color(
                                                          0xFF6C63FF,
                                                        ),
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              );
                                            }
                                            if (snapshot.hasError ||
                                                snapshot.data == null) {
                                              return Container(
                                                width: 150,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .broken_image_rounded,
                                                      color: Colors.grey,
                                                      size: 40,
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      'Image non disponible',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                            return Image(
                                              image: snapshot.data!,
                                              width: 150,
                                              height: 200,
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'Appuyez sur une photo pour l\'agrandir',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    final statusColor = OrderAdminCard._getStatusColor(status);
    final displayStatus = OrderAdminCard._getDisplayStatus(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statut actuel',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayStatus,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    if (_isLoadingMap) {
      return Container(
        color: Colors.grey.shade50,
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6C63FF),
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (_pickupCoords == null || _dropoffCoords == null) {
      return Container(
        color: Colors.grey.shade50,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'Impossible de localiser les adresses',
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: _pickupCoords!,
            initialZoom: 13,
            initialCameraFit: CameraFit.bounds(
              bounds: LatLngBounds(_pickupCoords!, _dropoffCoords!),
              padding: const EdgeInsets.all(60),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.camelia.logistics',
            ),
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 4.0,
                    color: const Color(0xFF6C63FF),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _pickupCoords!,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF6C63FF),
                      size: 28,
                    ),
                  ),
                ),
                Marker(
                  point: _dropoffCoords!,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: Color(0xFF4CAF50),
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF6C63FF),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text('Départ', style: GoogleFonts.poppins(fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(
                  Icons.flag_rounded,
                  color: Color(0xFF4CAF50),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text('Arrivée', style: GoogleFonts.poppins(fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adresses',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade100, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.05),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildAddressTile(
                icon: Icons.location_on_rounded,
                title: 'Point de départ',
                address: order.pickupAddress,
                color: const Color(0xFF6C63FF),
              ),
              Divider(height: 1, color: Colors.grey.shade100),
              _buildAddressTile(
                icon: Icons.flag_rounded,
                title: 'Point de destination',
                address: order.dropoffAddress,
                color: const Color(0xFF4CAF50),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressTile({
    required IconData icon,
    required String title,
    required String address,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  address,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.grey.shade900,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade100, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.05),
                blurRadius: 20,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  // Modifié pour accepter soit un Widget soit une String
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required dynamic value,
    bool isMultiLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: isMultiLine
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                // Si value est un Widget, on l'affiche directement, sinon Text
                value is Widget
                    ? value
                    : Text(
                        value.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Retourne un Widget (FutureBuilder) pour le nom du client
  Widget _buildClientNameWidget(String userId) {
    return FutureBuilder<UserProfile?>(
      future: _userProfileService.getProfile(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF6C63FF),
            ),
          );
        }
        final name = snapshot.data?.name ?? userId;
        final phone = snapshot.data?.phoneNumber ?? 'N/A';
        return Text(
          '$name\n$phone',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade900,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.access_time_rounded;
      case 'ACCEPTED':
        return Icons.check_circle_outline_rounded;
      case 'ASSIGNED':
        return Icons.local_shipping_rounded;
      case 'COMPLETED':
        return Icons.done_all_rounded;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
