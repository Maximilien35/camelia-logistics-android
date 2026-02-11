import 'package:camelia_logistics/models/services/chart.dart';
import 'package:camelia_logistics/models/services/graph_service.dart';
import 'package:camelia_logistics/models/services/order_service.dart';
import 'package:camelia_logistics/models/services/user_profile_service.dart';
import 'package:camelia_logistics/models/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final MetricsService metricsService = MetricsService();
  final String? idUser = FirebaseAuth.instance.currentUser?.uid;
  final UserProfileService _delivererService = UserProfileService();
  final OrderService _orderService = OrderService();

  late Stream<List<UserProfile>>? _usersStream;
  late Stream<List<UserProfile>>? _deliverersStream;
  late Future<int?> _ordersTodayFuture;
  late Future<double> _revenueFuture;
  late Future<Map<String, int>> _ordersByStatusFuture;
  late Future<Map<int, double>> _monthlyRevenueFuture;
  late Stream<UserProfile?> _adminProfileStream;

  @override
  void initState() {
    super.initState();
    _usersStream = _delivererService.getUserStream();
    _deliverersStream = _delivererService.getDeliverersStream();
    _ordersTodayFuture = _orderService.getOrderForToday();
    _revenueFuture = _orderService.chiffreAffaire();
    _ordersByStatusFuture = metricsService.calculateOrdersByStatus();
    _monthlyRevenueFuture = metricsService.calculateMonthlyRevenue();
    _adminProfileStream = _delivererService.streamProfile(idUser!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6C63FF).withValues(alpha:0.9),
                      const Color(0xFF8B84FF).withValues(alpha:0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    top: 60,
                  ),
                  child: StreamBuilder<UserProfile?>(
                    stream: _adminProfileStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        );
                      }
                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data == null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tableau de bord',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha:0.85),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      }

                      final prof = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bonjour, ${prof.name}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha:0.85),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha:0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.admin_panel_settings_rounded,
                                    color: Color(0xFF6C63FF),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Administrateur',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Gérez votre plateforme',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha:0.85),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Statistiques
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Titre section
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.analytics_outlined,
                          color: Color(0xFF6C63FF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Statistiques',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Grille de stats - Utilisation de LayoutBuilder pour gérer l'espace
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      final cardWidth = (availableWidth - 16) / 2;
                      final cardHeight = cardWidth * 1.1; // Ratio 1.1:1

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: [
                          // Utilisateurs
                          SizedBox(
                            height: cardHeight,
                            child: _buildStatCard(
                              context: context,
                              icon: Icons.people_alt_rounded,
                              title: 'Utilisateurs',
                              color: const Color(0xFF6C63FF),
                              stream: _usersStream,
                              builder: (data) => data.length.toString(),
                              loadingWidget: '...',
                            ),
                          ),

                          // Chauffeurs
                          SizedBox(
                            height: cardHeight,
                            child: _buildStatCard(
                              context: context,
                              icon: Icons.local_shipping_rounded,
                              title: 'Chauffeurs',
                              color: const Color(0xFF4CAF50),
                              stream: _deliverersStream,
                              builder: (data) => data.length.toString(),
                              loadingWidget: '...',
                            ),
                          ),

                          // Livraisons aujourd'hui
                          SizedBox(
                            height: cardHeight,
                            child: _buildStatCardFuture(
                              context: context,
                              icon: Icons.delivery_dining_rounded,
                              title: 'Livraisons',
                              subtitle: 'Aujourd\'hui',
                              color: const Color(0xFFFF9800),
                              future: _ordersTodayFuture,
                              formatter: (value) => value?.toString() ?? '0',
                            ),
                          ),

                          // Chiffre d'affaires
                          SizedBox(
                            height: cardHeight,
                            child: _buildStatCardFuture(
                              context: context,
                              icon: Icons.attach_money_rounded,
                              title: 'Chiffre d\'affaires',
                              color: const Color(0xFF9C27B0),
                              future: _revenueFuture,
                              formatter: (value) => '${value?.toStringAsFixed(0) ?? '0'} FCFA',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Graphiques
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre section
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          color: Color(0xFF6C63FF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Analyses',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Distribution des commandes
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100, width: 1),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.pie_chart_rounded,
                            color: Color(0xFF6C63FF),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Distribution des commandes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    SizedBox(
                      
                      child: FutureBuilder<Map<String, int>>(
                        future: _ordersByStatusFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const  Center(
                              child: CircularProgressIndicator(
                                color:  Color(0xFF6C63FF),
                                strokeWidth: 2,
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.grey.shade400,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Erreur de chargement',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox_rounded,
                                      color: Colors.grey.shade400,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Aucune donnée disponible',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return OrderDistributionChart(
                            statusData: snapshot.data!,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Chiffre d'affaires mensuel
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100, width: 1),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.trending_up_rounded,
                            color: Color(0xFF6C63FF),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Chiffre d\'affaires mensuel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: FutureBuilder<Map<int, double>>(
                        future: _monthlyRevenueFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color:  Color(0xFF6C63FF),
                                strokeWidth: 2,
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.grey.shade400,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Erreur de chargement',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.trending_flat_rounded,
                                      color: Colors.grey.shade400,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Aucune donnée de CA',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return MonthlyRevenueChart(
                            monthlyData: snapshot.data!,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Espace en bas
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required Stream<List<UserProfile>>? stream,
    required String Function(List<UserProfile> data) builder,
    required String loadingWidget,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: StreamBuilder<List<UserProfile>>(
          stream: stream,
          builder: (context, snapshot) {
            return Padding(
              padding: const EdgeInsets.all(16), // Réduit de 20 à 16
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, // Réduit de 48 à 40
                    height: 40, // Réduit de 48 à 40
                    decoration: BoxDecoration(
                      color: color.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 22, // Réduit de 24 à 22
                    ),
                  ),
                  const SizedBox(height: 10), // Réduit de 12 à 10
                  if (snapshot.connectionState == ConnectionState.waiting)
                    FittedBox(
                      child: Text(
                        loadingWidget,
                        style: const TextStyle(
                          fontSize: 22, // Réduit de 24 à 22
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    )
                  else if (snapshot.hasError)
                    FittedBox(
                      child: Text(
                        'Erreur',
                        style: TextStyle(
                          fontSize: 22, // Réduit de 24 à 22
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  else
                    FittedBox(
                      child: Text(
                        builder(snapshot.data ?? []),
                        style: const TextStyle(
                          fontSize: 22, // Réduit de 24 à 22
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6), // Réduit de 8 à 6
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 11, // Réduit de 12 à 11
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCardFuture({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required Future<dynamic> future,
    required String Function(dynamic value) formatter,
    String? subtitle,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: FutureBuilder<dynamic>(
          future: future,
          builder: (context, snapshot) {
            return Padding(
              padding: const EdgeInsets.all(16), // Réduit de 20 à 16
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, // Réduit de 48 à 40
                    height: 40, // Réduit de 48 à 40
                    decoration: BoxDecoration(
                      color: color.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 22, // Réduit de 24 à 22
                    ),
                  ),
                  const SizedBox(height: 10), // Réduit de 12 à 10
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const FittedBox(
                      child: Text(
                        '...',
                        style:  TextStyle(
                          fontSize: 22, // Réduit de 24 à 22
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    )
                  else if (snapshot.hasError)
                    FittedBox(
                      child: Text(
                        'Erreur',
                        style: TextStyle(
                          fontSize: 22, // Réduit de 24 à 22
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  else
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatter(snapshot.data),
                        style: const TextStyle(
                          fontSize: 22, // Réduit de 24 à 22
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  const SizedBox(height: 6), // Réduit de 8 à 6
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 11, // Réduit de 12 à 11
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 9, // Réduit de 10 à 9
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ],
              ),
              ),
            );
          },
        ),
      ),
    );
  }
}