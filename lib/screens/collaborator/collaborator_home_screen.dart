import 'package:camelia/models/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/collaborator_state_model.dart';
import 'collaborator_orders_screen.dart';
import 'collaborator_order_detail_screen.dart';
import 'widgets/order_card.dart';

class CollaboratorHomeScreen extends StatefulWidget {
  const CollaboratorHomeScreen({super.key});

  @override
  State<CollaboratorHomeScreen> createState() => _CollaboratorHomeScreenState();
}

class _CollaboratorHomeScreenState extends State<CollaboratorHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollaboratorStateModel>().initializeSession();
    });
  }

  final AuthService _authService = AuthService();

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirmation',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: GoogleFonts.poppins(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(color: const Color(0xFF6C63FF)),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                context.go('/login');
              }
            },
            child: Text(
              'Déconnecter',
              style: GoogleFonts.poppins(color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<CollaboratorStateModel>().logout();
      if (mounted) {
        // Redirection vers la page de connexion collaborateur
        context.go('/collaborator/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF6C63FF);
    return Consumer<CollaboratorStateModel>(
      builder: (context, collaboratorState, child) {
        return PopScope(
          canPop: false, // Empêche le retour en arrière
          child: Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              title: Text(
                'Tableau de bord',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              backgroundColor: primaryColor,
              elevation: 0,
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: collaboratorState.isLoading
                      ? null
                      : () => collaboratorState.refreshOrders(),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: _handleLogout,
                ),
              ],
            ),
            body: collaboratorState.isLoading && collaboratorState.isOnline
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6C63FF),
                      strokeWidth: 2,
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Indicateur hors ligne
                        if (!collaboratorState.isOnline)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            color: Colors.orange.shade100,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cloud_off_rounded,
                                  color: Colors.orange.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Mode hors ligne - Données en cache',
                                  style: GoogleFonts.poppins(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Message de bienvenue
                              Text(
                                'Bienvenue, ${collaboratorState.collaboratorProfile?.name ?? "Collaborateur"}',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Grille des statistiques
                              GridView.count(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  _buildStatCard(
                                    title: 'Commandes',
                                    value: collaboratorState.totalOrders
                                        .toString(),
                                    icon: Icons.shopping_cart_rounded,
                                    color: primaryColor,
                                  ),
                                  _buildStatCard(
                                    title: "Aujourd'hui",
                                    value: collaboratorState.completedToday
                                        .toString(),
                                    icon: Icons.check_circle_rounded,
                                    color: Colors.green.shade600,
                                  ),
                                  _buildStatCard(
                                    title: 'Revenus totaux',
                                    value:
                                        '${(collaboratorState.totalEarnings / 1000).toStringAsFixed(1)}k',
                                    icon: Icons.attach_money_rounded,
                                    color: Colors.amber.shade700,
                                  ),
                                  _buildStatCard(
                                    title: "Aujourd'hui",
                                    value: CollaboratorStateModel.formatPrice(
                                      collaboratorState.todayEarnings,
                                    ),
                                    icon: Icons.trending_up_rounded,
                                    color: Colors.purple.shade600,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // Section commandes récentes
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Vos commandes',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade900,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CollaboratorOrdersScreen(),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: primaryColor,
                                    ),
                                    child: Text(
                                      'Voir tout',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Liste des commandes récentes
                              if (collaboratorState.assignedOrders.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 48,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.inbox_rounded,
                                          size: 64,
                                          color: Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Aucune commande assignée',
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey.shade600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Les commandes disponibles s\'afficheront ici',
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey.shade500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: collaboratorState.assignedOrders
                                      .take(3)
                                      .length,
                                  itemBuilder: (context, index) {
                                    final order =
                                        collaboratorState.assignedOrders[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: OrderCard(
                                        order: order,
                                        onTap: () {
                                          collaboratorState.selectOrder(order);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const CollaboratorOrderDetailScreen(),
                                            ),
                                          );
                                        },
                                        onAccept: () =>
                                            _handleAcceptOrder(context, order),
                                        onRefuse: () =>
                                            _handleRefuseOrder(context, order),
                                        showActions:
                                            order['status'] == 'PENDING' ||
                                            order['status'] == 'ASSIGNED',
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAcceptOrder(
    BuildContext context,
    Map<String, dynamic> order,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Accepter la commande',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir accepter cette commande ?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Accepter',
              style: GoogleFonts.poppins(color: Colors.green.shade600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<CollaboratorStateModel>().acceptOrder(
        order['id'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  success
                      ? 'Commande acceptée!'
                      : 'Erreur lors de l\'acceptation',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            backgroundColor: success
                ? Colors.green.shade600
                : Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleRefuseOrder(
    BuildContext context,
    Map<String, dynamic> order,
  ) async {
    String? reason;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Refuser la commande',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Êtes-vous sûr de vouloir refuser cette commande ?',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Raison du refus (optionnel)',
                hintText: 'Précisez votre raison...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: 3,
              onChanged: (value) => reason = value,
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Refuser',
              style: GoogleFonts.poppins(color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<CollaboratorStateModel>().refuseOrder(
        order['id'],
        reason: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success
                      ? Icons.info_outline_rounded
                      : Icons.error_outline_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  success ? 'Commande refusée' : 'Erreur lors du refus',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            backgroundColor: success
                ? Colors.orange.shade600
                : Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
