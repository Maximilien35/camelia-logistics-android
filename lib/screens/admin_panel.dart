import 'package:camelia_logistics/models/services/user_profile_service.dart';
import 'package:camelia_logistics/models/user_profile.dart';
import 'package:camelia_logistics/screens/admin_dashboard.dart';
import 'package:camelia_logistics/screens/admin_deliverers.dart';
import 'package:camelia_logistics/screens/admin_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:camelia_logistics/models/services/order_service.dart';
import 'package:camelia_logistics/models/order_model.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
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
      return const AssetImage('assets/logo.webp');
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
            color: Colors.grey.withValues(alpha:0.08),
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
                  color: _selectedIndex == 0 ? Colors.white : Colors.grey.shade500,
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
                  color: _selectedIndex == 1 ? Colors.white : Colors.grey.shade500,
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
                  color: _selectedIndex == 2 ? Colors.white : Colors.grey.shade500,
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
                  Icons.settings_rounded,
                  color: _selectedIndex == 3 ? Colors.white : Colors.grey.shade500,
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
            padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
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
                            color: Colors.grey.withValues(alpha:0.1),
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
                        color: Colors.grey.withValues(alpha:0.05),
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

          // Liste des commandes
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
                      color:  Color(0xFF6C63FF),
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
                  final pickupMatch =
                      order.pickupAddress.toLowerCase().contains(query);
                  final dropoffMatch =
                      order.dropoffAddress.toLowerCase().contains(query);

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
      case 'PENDING': return const Color(0xFFFF9800);
      case 'ACCEPTED': return const Color(0xFF4CAF50);
      case 'ASSIGNED': return const Color(0xFF2196F3);
      case 'COMPLETED': return const Color(0xFF6C63FF);
      case 'CANCELLED': return const Color(0xFFF44336);
      default: return Colors.grey;
    }
  }

  static String _getDisplayStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return 'En attente';
      case 'ACCEPTED': return 'Validée';
      case 'ASSIGNED': return 'Assignée';
      case 'COMPLETED': return 'Livrée';
      case 'CANCELLED': return 'Annulée';
      default: return status;
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
                                statusColor.withValues(alpha:0.2),
                                statusColor.withValues(alpha:0.05),
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
                        color: statusColor.withValues(alpha:0.1),
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
                          context.go('/orderDetailsAdmin/${order.id}');
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
                          onTap: () {
                            if (order.status.toUpperCase() == 'PENDING') {
                              _showAssignDialog(context);
                            } else if (order.status.toUpperCase() == 'ACCEPTED') {
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
                                  statusColor.withValues(alpha:0.8),
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
      case 'PENDING': return 'Accepter';
      case 'ACCEPTED':
      case 'ASSIGNED': return 'Gérer';
      default: return 'Terminé';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Icons.access_time_rounded;
      case 'ACCEPTED': return Icons.check_circle_outline_rounded;
      case 'ASSIGNED': return Icons.local_shipping_rounded;
      case 'COMPLETED': return Icons.done_all_rounded;
      case 'CANCELLED': return Icons.cancel_outlined;
      default: return Icons.info_outline_rounded;
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

  void _showAssignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        String? selectedDelivererId;
        final formKey = GlobalKey<FormState>();
        final textFieldController = TextEditingController();

        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Assigner un livreur',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: textFieldController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Prix final (FCFA)',
                              labelStyle: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                              prefixIcon: Icon(
                                Icons.attach_money_rounded,
                                color: Colors.grey.shade500,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6C63FF),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  double.tryParse(value) == null) {
                                return 'Prix invalide';
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
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  child:const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF6C63FF),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }

                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Aucun livreur disponible',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                );
                              }

                              List<UserProfile> deliverers = snapshot.data!;
                              return DropdownButtonFormField<String>(
                                initialValue: selectedDelivererId,
                                decoration: InputDecoration(
                                  labelText: 'Livreur',
                                  labelStyle: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_search_rounded,
                                    color: Colors.grey.shade500,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF6C63FF),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                items: deliverers.map((deliverer) {
                                  return DropdownMenuItem<String>(
                                    value: deliverer.uid,
                                    child: Text(deliverer.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedDelivererId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez sélectionner un livreur';
                                  }
                                  return null;
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(builderContext).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 12),
                        Material(
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () {
                              if (formKey.currentState!.validate()) {
                                _submitForm(builderContext, selectedDelivererId, textFieldController);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Assigner',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
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
            );
          },
        );
      },
    );
  }

  void _submitForm(BuildContext context, String? selectedDelivererId, TextEditingController textFieldController) {
    if (selectedDelivererId == null) return;

    final priceQuote = textFieldController.text;
    _service.updateFinalPrice(order.id!, double.parse(priceQuote));
    _service.assignDeliverer(
      orderId: order.id!,
      delivererUid: selectedDelivererId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Commande assignée pour $priceQuote FCFA'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: const Color(0xFF6C63FF),
      ),
    );
    textFieldController.clear();
    Navigator.of(context).pop();
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
                    color: const Color(0xFF6C63FF).withValues(alpha:0.1),
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
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
  State<OrderDetailsAdminScreen> createState() => _OrderDetailsAdminScreenState();
}

class _OrderDetailsAdminScreenState extends State<OrderDetailsAdminScreen> {
  late Future<Order?> _orderFuture;
  final OrderService orderService = OrderService();
  List<LatLng> _routePoints = [];
  LatLng? _pickupCoords;
  LatLng? _dropoffCoords;
  bool _isLoadingMap = true;

  @override
  void initState() {
    super.initState();
    _orderFuture = orderService.getOrdersById(widget.orderId).then((order) {
      if (order != null) _loadMapData(order);
      return order;
    });
  }

  Future<void> _loadMapData(Order order) async {
    try {
      List<Location> pickupLocations = await locationFromAddress(order.pickupAddress);
      List<Location> dropoffLocations = await locationFromAddress(order.dropoffAddress);

      if (pickupLocations.isNotEmpty && dropoffLocations.isNotEmpty) {
        _pickupCoords = LatLng(pickupLocations.first.latitude, pickupLocations.first.longitude);
        _dropoffCoords = LatLng(dropoffLocations.first.latitude, dropoffLocations.first.longitude);

        final url = Uri.parse('http://router.project-osrm.org/route/v1/driving/${_pickupCoords!.longitude},${_pickupCoords!.latitude};${_dropoffCoords!.longitude},${_dropoffCoords!.latitude}?overview=full&geometries=geojson');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final geometry = data['routes'][0]['geometry']['coordinates'] as List;
          if (mounted) setState(() => _routePoints = geometry.map((p) => LatLng(p[1].toDouble(), p[0].toDouble())).toList());
        }
      }
    } catch (e) {
      debugPrint("Erreur chargement carte: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMap = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              child: Text(
                'Erreur de chargement',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            );
          }

          final order = snapshot.data!;
          final List<String> photoUrl = order.photoUrls;
          final List<String> photos = photoUrl;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                leading: IconButton(
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha:0.1),
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
                  onPressed: () => context.go('/admin'),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildMapSection(),
                  title: Text(
                    '#${(order.id?.substring(0, 6) ?? '').toUpperCase()}',
                    style: const TextStyle(
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
                      // Status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: OrderAdminCard._getStatusColor(order.status)
                              .withValues(alpha:0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: OrderAdminCard._getStatusColor(order.status)
                                .withValues(alpha:0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: OrderAdminCard._getStatusColor(order.status)
                                    .withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getStatusIcon(order.status),
                                color: OrderAdminCard._getStatusColor(order.status),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Statut',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    OrderAdminCard._getDisplayStatus(order.status),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: OrderAdminCard._getStatusColor(order.status),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Informations
                      _buildSection(
                        title: 'Informations',
                        children: [
                          _buildDetailRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Client ID',
                            value: order.userId,
                          ),
                          _buildDetailRow(
                            icon: Icons.attach_money_rounded,
                            label: 'Prix final',
                            value: '${order.priceQuote?.toStringAsFixed(2) ?? '0.00'} FCFA',
                          ),
                          _buildDetailRow(
                            icon: Icons.description_outlined,
                            label: 'Description',
                            value: order.description ?? 'Non spécifiée',
                          ),
                          _buildDetailRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Date',
                            value: _formatDate(order.timestamp),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Adresses
                      _buildSection(
                        title: 'Adresses',
                        children: [
                          _buildDetailRow(
                            icon: Icons.location_on_outlined,
                            label: 'Départ',
                            value: order.pickupAddress,
                            isMultiLine: true,
                          ),
                          _buildDetailRow(
                            icon: Icons.flag_outlined,
                            label: 'Destination',
                            value: order.dropoffAddress,
                            isMultiLine: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Images
                      if (photos.isNotEmpty) ...[
                        _buildSection(
                          title: 'Photos',
                          children: [
                            SizedBox(
                              height: 200,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: photos.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: index < photos.length - 1 ? 16 : 0,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: FutureBuilder<ImageProvider>(
                                        future: ImageCacheService.instance
                                            .getImageProvider(photos[index], context),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Container(
                                              width: 150,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  color: Color(0xFF6C63FF),
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            );
                                          }
                                          return Image(
                                            image: snapshot.data ??
                                                const AssetImage('assets/logo.webp'),
                                            width: 150,
                                            height: 200,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
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
        child: const Center(
          child: Icon(
            Icons.location_off_rounded,
            size: 48,
            color: Colors.grey,
          ),
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: _pickupCoords!,
        initialZoom: 13,
        initialCameraFit: CameraFit.bounds(
          bounds: LatLngBounds(_pickupCoords!, _dropoffCoords!),
          padding: const EdgeInsets.all(40),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha:0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF6C63FF),
                  size: 24,
                ),
              ),
            ),
            Marker(
              point: _dropoffCoords!,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha:0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMultiLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment:
            isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (isMultiLine)
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
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

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Icons.access_time_rounded;
      case 'ACCEPTED': return Icons.check_circle_outline_rounded;
      case 'ASSIGNED': return Icons.local_shipping_rounded;
      case 'COMPLETED': return Icons.done_all_rounded;
      case 'CANCELLED': return Icons.cancel_outlined;
      default: return Icons.info_outline_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}