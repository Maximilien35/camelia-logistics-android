import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MetricsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String ordersCollection = 'orders';

  Map<int, double> monthlySales = {};

  Map<String, int> ordersByStatus = {};

  Future<Map<int, double>> calculateMonthlyRevenue() async {
    final currentYear = DateTime.now().year;
    monthlySales = {
      for (var month in List.generate(12, (i) => i + 1)) month: 0.0,
    };

    try {
      List<Future<void>> tasks = [];

      for (int month = 1; month <= 12; month++) {
        final startOfMonth = DateTime(currentYear, month, 1);
        final endOfMonth = (month == 12) 
            ? DateTime(currentYear + 1, 1, 1).subtract(const Duration(milliseconds: 1))
            : DateTime(currentYear, month + 1, 1).subtract(const Duration(milliseconds: 1));

        tasks.add(_firestore
            .collection(ordersCollection)
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
            .where('status', isEqualTo: 'COMPLETED') // On ne compte que les commandes payées
            .aggregate(sum('priceQuote'))
            .get()
            .then((snapshot) {
              monthlySales[month] = snapshot.getSum('priceQuote')?.toDouble() ?? 0.0;
            }));
      }
      
      await Future.wait(tasks);
      return monthlySales;
    } catch (e) {
      if (kDebugMode) print('Erreur lors du calcul du CA mensuel : $e');
      return {};
    }
  }

  Future<Map<String, int>> calculateOrdersByStatus() async {
    ordersByStatus = {};
    final statuses = ['PENDING', 'ACCEPTED', 'ASSIGNED', 'COMPLETED', 'CANCELLED'];
    
    try {
      List<Future<void>> tasks = [];

      for (var status in statuses) {
        tasks.add(_firestore
            .collection(ordersCollection)
            .where('status', isEqualTo: status)
            .count()
            .get()
            .then((snapshot) {
              ordersByStatus[status] = snapshot.count ?? 0;
            }));
      }
      
      await Future.wait(tasks);
      return ordersByStatus;
    } catch (e) {
      if (kDebugMode) print("Erreur lors du calcul des commandes par statut : $e");
      return {};
    }
  }
}
