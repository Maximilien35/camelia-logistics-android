import 'package:camelia_logistics/models/services/chart.dart';
import 'package:camelia_logistics/models/services/graph_service.dart';
import 'package:camelia_logistics/models/services/order_service.dart';
import 'package:camelia_logistics/models/services/userProfileService.dart';
import 'package:camelia_logistics/models/userProfile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDeliverersState();
}

class _AdminDeliverersState extends State<AdminDashboard> {
  final MetricsService metricsService = MetricsService();
  final String? idUser = FirebaseAuth.instance.currentUser?.uid;
  final UserProfileService _delivererService = UserProfileService();
  final OrderService _orderService = OrderService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
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
              child: StreamBuilder<UserProfile?>(
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

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin panel',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 24,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Tableau de bord , ${prof.name}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 40,
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 15),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,

                  children: [
                    StreamBuilder<List<UserProfile>>(
                      stream: _delivererService.getUserStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Erreur : ${snapshot.error}'),
                          );
                        }

                        final allUsers = snapshot.data ?? [];
                        return Expanded(
                          child: _buildStatCard(
                            icon: Icons.people,
                            iconColor: Colors.blue,
                            value: allUsers.length.toString(),
                            label: 'utilisateurs',
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 20),
                    StreamBuilder<List<UserProfile>>(
                      stream: _delivererService.getDeliverersStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Erreur : ${snapshot.error}'),
                          );
                        }

                        final allDeliverers = snapshot.data ?? [];
                        return Expanded(
                          child: _buildStatCard(
                            icon: Icons.delivery_dining,
                            iconColor: Colors.green,
                            value: allDeliverers.length.toString(),
                            label: 'chauffeurs actifs',
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    FutureBuilder(
                      future: _orderService.getOrderForToday(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        // État d'erreur ou profil non trouvé
                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data == null) {
                          return Scaffold(
                            appBar: AppBar(title: const Text('Profil')),
                            body: Center(
                              child: Text(
                                'Erreur de chargement: ${snapshot.error ?? "Données introuvables"}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        final count = snapshot.data;
                        return Expanded(
                          child: _buildStatCard(
                            icon: Icons.card_giftcard,
                            iconColor: Colors.purpleAccent,
                            value: count.toString(),
                            label: 'Livraisons ajourd\'hui',
                          ),
                        );
                      },
                    ),

                    SizedBox(width: 20),
                    FutureBuilder(
                      future: _orderService.chiffreAffaire(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        // État d'erreur ou profil non trouvé
                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data == null) {
                          return Scaffold(
                            appBar: AppBar(title: const Text('Profil')),
                            body: Center(
                              child: Text(
                                'Erreur de chargement: ${snapshot.error ?? "Données introuvables"}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        final count = snapshot.data;
                        return Expanded(
                          child: _buildStatCard(
                            icon: Icons.monetization_on,
                            iconColor: Colors.orangeAccent,
                            value: count.toString(),
                            label: 'chiffres d\'affaires',
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Distribution des Commandes par Statut',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<Map<String, int>>(
                          future: metricsService.calculateOrdersByStatus(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Erreur: ${snapshot.error}'),
                              );
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(
                                child: Text(
                                  'Aucune donnée de statut disponible.',
                                ),
                              );
                            }

                            return OrderDistributionChart(
                              statusData: snapshot.data!,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chiffre d\'Affaires Mensuel (Dernière Année)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<Map<int, double>>(
                          future: metricsService.calculateMonthlyRevenue(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Erreur: ${snapshot.error}'),
                              );
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(
                                child: Text('Aucune donnée de CA disponible.'),
                              );
                            }

                            return MonthlyRevenueChart(
                              monthlyData: snapshot.data!,
                            );
                          },
                        ),
                      ],
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
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
