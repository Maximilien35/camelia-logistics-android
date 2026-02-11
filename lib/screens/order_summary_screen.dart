// Importations nécessaires
import 'package:camelia_logistics/models/services/admin_service.dart';
import 'package:camelia_logistics/models/services/order_service.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../screens/waiting_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/order_model.dart';

class OrderSummaryScreen extends StatelessWidget {
  final String orderId;
  OrderSummaryScreen({super.key, required this.orderId});
  final OrderService _orderService = OrderService();

  void finalizeOrder(String orderId, String statut) async {
    final OrderService order = OrderService();
    await order.updateOrderStatus(orderId: orderId, newStatus: statut);
  }

  void showManageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Gérer la commande'),
          content:const Text(
            'etes vous sure de vouloir annuler la commande ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    finalizeOrder(orderId, 'CANCELLED'); // Statut payé/terminé
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                  ),
                  child: const Text(
                    'Confirmer',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade600,
                  ),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  final AdminService admin = AdminService();
  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('Tentative de chargement de la commande avec ID: $orderId');
    }

    if (orderId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Erreur: L'ID de la commande est manquant.")),
      );
    }
    return StreamBuilder<Order?>(
      stream: _orderService.streamOrder(orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text("Commande introuvable.")),
          );
        }

        final currentOrder = snapshot.data!;
        return _buildInterface(context, currentOrder, orderId);
      },
    );
  }

  Widget _buildInterface(BuildContext context, Order order, String id) {
    if (order.priceQuote == 0.0) {
      return WaitingScreen(orderId: orderId);
    }
    else {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          admin.handlePopInvoked(didPop, context);
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Confirmer votre commande')),
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
                const Text(
                  "Détails du Devis",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                Card(
                  color: Colors.lightGreen.shade50,
                  child: ListTile(
                    title: const Text("Prix Final (Hors Taxes) :"),
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
                      finalizeOrder(orderId, 'CONFIRMED');
                      context.go('/home_custom');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Confirmer et recevoir un appel',
                      style: TextStyle(fontSize: 18),
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
                    child: const Text(
                      'refuser',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                
              ],
            ),
          ),
        ),
      );
    }
  }
}
