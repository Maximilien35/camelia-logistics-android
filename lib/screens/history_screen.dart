import 'package:camelia/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/services/order_service.dart';
import 'package:camelia/l10n/app_localizations.dart';

// Définition de l'écran d'historique
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final OrderService _orderService = OrderService();

  late final Stream<List<Order>> _ordersStream;

  @override
  void initState() {
    super.initState();
    _ordersStream = _orderService.streamUserOrders(userId, limit: 50);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/home_custom');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.history,
            style: GoogleFonts.pacifico(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              context.push('/home_custom');
            },
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.history_toggle_off_rounded),
            ),
          ],
        ),

        body: SingleChildScrollView(
          child: Column(
            children: [
              StreamBuilder<List<Order>>(
                stream: _ordersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 50.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 50.0),
                        child: Text(
                          l10n.historyError(snapshot.error.toString()),
                        ),
                      ),
                    );
                  }

                  final orders = snapshot.data ?? [];
                  final completedOrders = orders
                      .where((order) => order.status == 'COMPLETED')
                      .toList();
                  final totalSpent = completedOrders.fold<double>(
                    0.0,
                    (sum, order) => sum + (order.priceQuote ?? 0.0),
                  );
                  final deliveredCount = completedOrders.length;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _CardHistory(
                                icon: Icons.inventory_2,
                                value: deliveredCount.toString(),
                                label: l10n.packagesDelivered,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _CardHistory(
                                icon: Icons.monetization_on,
                                value: totalSpent.toStringAsFixed(0),
                                label: l10n.totalSpent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (orders.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 50.0),
                            child: Text(l10n.noOrdersFound),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];

                            return _CardInventory(
                              type: order.packageNature != 'Non spécifié'
                                  ? order.packageNature
                                  : order.serviceType,
                              depart: order.pickupAddress,
                              destination: order.dropoffAddress,
                              date: order.timestamp.toString().substring(0, 10),
                              prix: order.priceQuote != 0.0
                                  ? '${order.priceQuote} FCFA'
                                  : 'Devis en cours ...',
                              status: order.status,
                              onTap: () {
                                if ((order.status == "PENDING" ||
                                        order.status == "ASSIGNED") &&
                                    order.isQuote == true) {
                                  context.push('/waiting/${order.id!}');
                                }
                              },
                              l10n: l10n,
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardHistory extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _CardHistory({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.ubuntu(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardInventory extends StatelessWidget {
  final String type;
  final String depart;
  final String destination;
  final String date;
  final String prix;
  final String status;
  final VoidCallback onTap; // Ajouté pour gérer le clic
  final AppLocalizations l10n;

  const _CardInventory({
    required this.type,
    required this.depart,
    required this.destination,
    required this.date,
    required this.prix,
    required this.onTap,
    required this.status, // Requis
    required this.l10n,
  });
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.green.shade700;
      case 'ACCEPTED': 
        return const Color.fromARGB(255, 129, 7, 229);
      case 'ASSIGNED':
        return Colors.blue.shade700;
      case 'COMPLETED': 
        return Colors.indigo.shade700;
      case 'CANCELLED':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getDisplayStatus(String status) {
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
    final statusColor = _getStatusColor(status);
    final displayStatus = _getDisplayStatus(status);
    return GestureDetector(
      onTap: onTap, // Lier le onTap
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  type,
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
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
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.my_location, color: Colors.blue, size: 10),
                const SizedBox(width: 10),

                AutoSizeText(
                  depart.substring(
                    0,
                    depart.length > 30 ? depart.length ~/ 2 : depart.length,
                  ),
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  minFontSize: 10,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green, size: 10),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    destination,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: GoogleFonts.playfair(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  prix,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
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
