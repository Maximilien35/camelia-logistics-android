// Importations nécessaires
import 'package:camelia_logistics/models/services/AdminService.dart';
import 'package:camelia_logistics/models/services/order_service.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/order_state_model.dart';
import '../screens/waiting_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/order_model.dart';

class OrderSummaryScreen extends StatelessWidget {
  final String orderId;
  OrderSummaryScreen({super.key, required this.orderId});
  void finalize_order(String orderId, String Statut) async {
    final OrderService order = OrderService();
    order.updateOrderStatus(orderId: orderId, newStatus: Statut);
  }

  void showManageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Gérer la commande'),
          content: Text(
            'etes vous sure de vouloir annuler la commande ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    finalize_order(orderId, 'CANCELLED'); // Statut payé/terminé
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .snapshots(),
      builder: (context, snapshot) {
        // Gérer les états de connexion (chargement, erreur)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("Commande introuvable.")),
          );
        }

        // Convertir les données Firestore en modèle Order (méthode fromJson dans votre modèle)
        final orderData = snapshot.data!.data() as Map<String, dynamic>;
        final currentOrder = Order.fromJson(orderData);

        // 2. Afficher la bonne interface utilisateur
        return _buildInterface(context, currentOrder, orderId);
      },
    );
  }

  // Fonction pour construire l'interface basée sur le statut
  Widget _buildInterface(BuildContext context, Order order, String id) {
    if (order.priceQuote == 0.0) {
      return WaitingScreen(orderId: orderId);
    }
    // Statut 2 : Le prix final est fixé et prêt pour la confirmation
    else {
      final OrderStateModel orderState = Provider.of<OrderStateModel>(
        context,
        listen: false,
      );
      return PopScope(
        // 1. Bloquer l'action par défaut du retour (GoRouter)
        canPop: false,

        // 2. Intercepter l'action bloquée et effectuer la logique
        onPopInvoked: (didPop) {
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
                      // The Lottie animation is the background
                      SizedBox.expand(
                        child: Lottie.asset(
                          'assets/Success.json',
                          fit: BoxFit.fill,
                        ),
                      ),
                    ],
                  ),
                ),
                // Détails de la commande (adresses, colis, etc.)
                const Text(
                  "Détails du Devis",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                // Affichage du prix FINAL
                Card(
                  color: Colors.lightGreen.shade50,
                  child: ListTile(
                    title: const Text("Prix Final (Hors Taxes) :"),
                    trailing: Text(
                      "${order.priceQuote!.toStringAsFixed(0)} FCFA", // Utilisez ! car on sait qu'il n'est pas null ici
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Bouton de CONFIRMATION
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      finalize_order(orderId, 'CONFIRMED');
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
                // Option d'annulation, etc.
              ],
            ),
          ),
        ),
      );
    }
  }
}
