import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/collaborator_state_model.dart';
import 'widgets/order_card.dart';

class CollaboratorOrdersScreen extends StatefulWidget {
  const CollaboratorOrdersScreen({super.key});

  @override
  State<CollaboratorOrdersScreen> createState() =>
      _CollaboratorOrdersScreenState();
}

class _CollaboratorOrdersScreenState extends State<CollaboratorOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF6C63FF);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Commandes',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Consumer<CollaboratorStateModel>(
        builder: (context, collaboratorState, child) {
          return Column(
            children: [
              // Filtres
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'Tous',
                        isSelected: collaboratorState.filter == 'ALL',
                        onTap: () => collaboratorState.applyFilter('ALL'),
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'En attente',
                        isSelected: collaboratorState.filter == 'PENDING',
                        onTap: () => collaboratorState.applyFilter('PENDING'),
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'En cours',
                        isSelected: collaboratorState.filter == 'IN_PROGRESS',
                        onTap: () => collaboratorState.applyFilter('IN_PROGRESS'),
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Terminées',
                        isSelected: collaboratorState.filter == 'COMPLETED',
                        onTap: () => collaboratorState.applyFilter('COMPLETED'),
                        primaryColor: primaryColor,
                      ),
                    ],
                  ),
                ),
              ),

              // Liste des commandes
              Expanded(
                child: collaboratorState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF),
                          strokeWidth: 2,
                        ),
                      )
                    : collaboratorState.assignedOrders.isEmpty
                        ? Center(
                            child: Column(
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
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Il n\'y a aucune commande pour ce filtre',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => collaboratorState.refreshOrders(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: collaboratorState.assignedOrders.length,
                              itemBuilder: (context, index) {
                                final order = collaboratorState.assignedOrders[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: OrderCard(
                                    order: order,
                                    onTap: () {
                                      collaboratorState.selectOrder(order);
                                      context.go('/collaborator/order-detail');
                                    },
                                    onAccept: order['status'] == 'PENDING' ||
                                            order['status'] == 'ASSIGNED'
                                        ? () => _handleAcceptOrder(context, order)
                                        : null,
                                    onRefuse: order['status'] == 'PENDING' ||
                                            order['status'] == 'ASSIGNED'
                                        ? () => _handleRefuseOrder(context, order)
                                        : null,
                                    showActions:
                                        order['status'] == 'PENDING' ||
                                        order['status'] == 'ASSIGNED',
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha:0.05),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  void _handleAcceptOrder(BuildContext context, Map<String, dynamic> order) async {
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
            child: Text('Annuler', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Accepter', style: GoogleFonts.poppins(color: Colors.green.shade600)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context
          .read<CollaboratorStateModel>()
          .acceptOrder(order['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  success ? 'Commande acceptée!' : 'Erreur lors de l\'acceptation',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleRefuseOrder(BuildContext context, Map<String, dynamic> order) async {
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Text('Annuler', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Refuser', style: GoogleFonts.poppins(color: Colors.red.shade600)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context
          .read<CollaboratorStateModel>()
          .refuseOrder(order['id'], reason: reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(success ? Icons.info_outline_rounded : Icons.error_outline_rounded,
                    color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  success ? 'Commande refusée' : 'Erreur lors du refus',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            backgroundColor: success ? Colors.orange.shade600 : Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}