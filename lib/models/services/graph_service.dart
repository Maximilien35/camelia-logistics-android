import 'package:cloud_firestore/cloud_firestore.dart';

class MetricsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String ordersCollection = 'orders';

  // Structure simplifiée pour stocker les données du graphique
  // Utilisée pour le Chiffre d'Affaires Mensuel
  Map<int, double> monthlySales = {};

  // Structure pour stocker les totaux par statut
  // Utilisée pour la Distribution des Commandes
  Map<String, int> ordersByStatus = {};

  /// Calcule le chiffre d'affaires (CA) et le nombre de commandes par mois pour l'année en cours.
  Future<Map<int, double>> calculateMonthlyRevenue() async {
    // Récupérer toutes les commandes de l'année en cours
    final currentYear = DateTime.now().year;

    // Initialisation pour les 12 mois
    monthlySales = {
      for (var month in List.generate(12, (i) => i + 1)) month: 0.0,
    };

    try {
      final snapshot = await _firestore
          .collection(ordersCollection)
          // Si vous avez un champ 'createdAt' de type Timestamp, vous pouvez filtrer
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: DateTime(currentYear, 1, 1),
          )
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final price = (data['priceQuote'] as num?)?.toDouble() ?? 0.0;
        final timestamp = data['createdAt'] as Timestamp;
        final month = timestamp.toDate().month;

        // Ajouter le montant au mois correspondant
        monthlySales[month] = (monthlySales[month] ?? 0.0) + price;
      }

      return monthlySales;
    } catch (e) {
      print("Erreur lors du calcul du CA mensuel : $e");
      return {};
    }
  }

  /// Calcule le nombre de commandes pour chaque statut (ex: 'pending', 'delivered', 'cancelled').
  Future<Map<String, int>> calculateOrdersByStatus() async {
    ordersByStatus = {};
    try {
      final snapshot = await _firestore.collection(ordersCollection).get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'unknown';

        ordersByStatus[status] = (ordersByStatus[status] ?? 0) + 1;
      }

      return ordersByStatus;
    } catch (e) {
      print("Erreur lors du calcul des commandes par statut : $e");
      return {};
    }
  }
}
