// Importations nécessaires
import 'package:camelia_logistics/models/services/order_service.dart';
import 'package:camelia_logistics/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../screens/waiting_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/order_model.dart';

class OrderSummaryScreen extends StatefulWidget {
  final String orderId;
  const OrderSummaryScreen({super.key, required this.orderId});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  final OrderService _orderService = OrderService();

  void finalizeOrder(String orderId, String statut) async {
    final OrderService order = OrderService();
    await order.updateOrderStatus(orderId: orderId, newStatus: statut);
  }

  bool _hasShownFlashCard = false;

  void showManageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.manageOrder),
          content: Text(
            l10n.cancelOrderConfirmation,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    finalizeOrder(widget.orderId, 'CANCELLED'); // Statut payé/terminé
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                  ),
                  child: Text(
                    l10n.confirm,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade600,
                  ),
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void showSuccessFlashCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_hasShownFlashCard) return;
    setState(() {
      _hasShownFlashCard = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.orderValidated,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.orderValidationSuccessMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Material(
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => context.go('/home_custom'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          l10n.backToHome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (kDebugMode) {
      print('Tentative de chargement de la commande avec ID: ${widget.orderId}');
    }

    if (widget.orderId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errorMissingOrderId)),
      );
    }
    return StreamBuilder<Order?>(
      stream: _orderService.streamOrder(widget.orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            body: Center(child: Text(l10n.orderNotFound)),
          );
        }

        final currentOrder = snapshot.data!;
        return _buildInterface(context, currentOrder, widget.orderId);
      },
    );
  }

  Widget _buildInterface(BuildContext context, Order order, String id) {
    final l10n = AppLocalizations.of(context)!;
    if (order.priceQuote == 0.0) {
      return WaitingScreen(orderId: widget.orderId);
    } else {
      return Scaffold(
          appBar: AppBar(title: Text(l10n.confirmYourOrder)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5, //
                  child: Stack(
                    children: [
                      SizedBox.expand(
                        child: Lottie.asset(
                          'assets/Success.json',
                          fit: BoxFit.fill,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.quoteDetails,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                Card(
                  color: Colors.lightGreen.shade50,
                  child: ListTile(
                    title: Text(l10n.finalPriceWithoutTax),
                    trailing: Text(
                      "${order.priceQuote!.toStringAsFixed(0)} FCFA",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      finalizeOrder(widget.orderId, 'CONFIRMED');
                      showSuccessFlashCard(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      l10n.confirmAndReceiveCall,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      showManageDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE10C0C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      l10n.refuse,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
      );
    }
  }
}
