import 'package:camelia_logistics/models/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:camelia_logistics/models/order_model.dart';
import 'package:go_router/go_router.dart';

class WaitingScreen extends StatefulWidget {
  final String orderId;
  const WaitingScreen({super.key, required this.orderId});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final OrderService _orderService = OrderService();
  late final AnimationController _animationController;
  final List<String> messages = [
    'Recherche d\'un chauffeur en cours...',
    'Cela ne devrait pas prendre plus de quelques minutes',
    'Vous recevrez une notification dès qu\'un chauffeur acceptera votre commande',
    'Un chauffeur va vous contacter très bientôt !',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _animationController.repeat();
      }
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
      return context.go('/home_custom');
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: StreamBuilder<Order?>(
          stream: _orderService.streamOrder(widget.orderId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6C63FF),
                  strokeWidth: 2,
                ),
              );
            }

            final order = snapshot.data;


            return CustomScrollView(
              slivers: [
                // Header avec animation
                SliverAppBar(
                  expandedHeight: 320,
                  floating: false,
                  pinned: false,
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 200,
                            child: Lottie.asset(
                              'assets/car.json',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 80,
                            child: PageView.builder(
                              controller: _pageController,
                              scrollDirection: Axis.vertical,
                              itemCount: messages.length * 1000,
                              itemBuilder: (context, index) {
                                final messageIndex = index % messages.length;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _getMessageIcon(messageIndex),
                                        size: 24,
                                        color: Colors.white.withValues(alpha:0.9),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        messages[messageIndex],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(alpha:0.95),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Section de résumé
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: order != null
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey.shade100,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6C63FF)
                                            .withValues(alpha:0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.info_outline_rounded,
                                        color: Color(0xFF6C63FF),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'Résumé de votre commande',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildInfoRow(
                                  icon: Icons.location_on_rounded,
                                  label: 'Départ',
                                  value: order.pickupAddress,
                                  color: const Color(0xFF6C63FF),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  icon: Icons.flag_rounded,
                                  label: 'Destination',
                                  value: order.dropoffAddress,
                                  color: const Color(0xFF4CAF50),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  icon: Icons.local_shipping_rounded,
                                  label: 'Véhicule',
                                  value: order.vehicleType,
                                  color: const Color(0xFFFF9800),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  icon: Icons.inventory_2_rounded,
                                  label: 'Type de colis',
                                  value: order.packageNature,
                                  color: const Color(0xFF9C27B0),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey.shade100,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Commande non trouvée',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),

                // Section statut chauffeurs
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey.shade100,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.people_alt_rounded,
                              color: Color(0xFF2196F3),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Chauffeurs actifs',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Plus de 100 chauffeurs disponibles dans votre zone',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF4CAF50),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Boutons d'action
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                },
                                icon: const Icon(
                                  Icons.phone_rounded,
                                  color: Color(0xFF2196F3),
                                  size: 20,
                                ),
                                label: const Text(
                                  'Urgence',
                                  style: TextStyle(
                                    color: Color(0xFF2196F3),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFF2196F3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                },
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Color(0xFF9C27B0),
                                  size: 20,
                                ),
                                label: const Text(
                                  'Support',
                                  style: TextStyle(
                                    color: Color(0xFF9C27B0),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFF9C27B0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/home_custom'),
                            icon: const Icon(
                              Icons.home_rounded,
                              color: Color(0xFF6C63FF),
                              size: 20,
                            ),
                            label: const Text(
                              'Retour à l\'accueil',
                              style: TextStyle(
                                color: Color(0xFF6C63FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Color(0xFF6C63FF)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Indicateur de chargement
                if (snapshot.connectionState == ConnectionState.active &&
                    order?.status == 'PENDING')
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF6C63FF),
                            strokeWidth: 2,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'En attente d\'un chauffeur...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Espace en bas
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _getMessageIcon(int index) {
    switch (index) {
      case 0:
        return Icons.search_rounded;
      case 1:
        return Icons.access_time_rounded;
      case 2:
        return Icons.phone_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
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
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}