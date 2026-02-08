import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/foundation.dart';
import '../../models/order_model.dart';

class OrderService {
  final CollectionReference _ordersRef = FirebaseFirestore.instance.collection('orders');

  Future<String> addOrder(Order order) async {
    try {
      DocumentReference orderRef = await _ordersRef.add(order.toJson());
      return orderRef.id;
    } on FirebaseException catch (e) {
      throw Exception(
        "Erreur Firestore lors de l'ajout de la commande : ${e.message}",
      );
    }
  }

  Future<List<Order>> getOrdersByUserId(String userId) async {
    try {
      final snapshotCache = await _ordersRef
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get(const GetOptions(source: Source.cache));
      
      if (snapshotCache.docs.isNotEmpty) {
        return snapshotCache.docs.map((doc) => Order.fromJson(doc.data() as Map<String, dynamic>, id: doc.id)).toList();
      }
    } catch (_) {}

    try {
      final snapshotServer = await _ordersRef
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get(const GetOptions(source: Source.server));

      return snapshotServer.docs.map((doc) => Order.fromJson(doc.data() as Map<String, dynamic>, id: doc.id)).toList();
    } on FirebaseException catch (e) {
      throw Exception(
        'Erreur Firestore lors de la récupération : ${e.message}',
      );
    }
  }

  Stream<List<Order>> streamUserOrders(String userId, {int? limit}) {
    Query query = _ordersRef
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Order.fromJson(data, id: doc.id);
          }).toList();
        });
  }

  Stream<Order?> streamOrder(String orderId) {
    return _ordersRef.doc(orderId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return Order.fromJson(doc.data() as Map<String, dynamic>, id: doc.id);
      }
      return null;
    });
  }

  Future<Order?> getOrder(String uid) async {
    try {
      final doc = await _ordersRef.doc(uid).get(const GetOptions(source: Source.cache));
      if (doc.exists && doc.data() != null) {
        return Order.fromJson(doc.data() as Map<String, dynamic>, id: doc.id);
      }
    } catch (_) {}

    final docServer = await _ordersRef.doc(uid).get(const GetOptions(source: Source.server));
    if (docServer.exists && docServer.data() != null) {
      return Order.fromJson(docServer.data() as Map<String, dynamic>, id: docServer.id);
    }
    return null;
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
  }) async {
    try {
      DocumentReference docRef = _ordersRef.doc(orderId);
      await docRef.update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('Statut de la commande $orderId mis à jour à : $newStatus');
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la mise à jour du statut de la commande : $e");
      }
      rethrow;
    }
  }

  Future<void> updateFinalPrice(String orderId, double finalPrice) async {
    try {
      await _ordersRef.doc(orderId).update({
        'priceQuote': finalPrice,
        'status':
            'PRICE_QUOTED', 
      });
    } on FirebaseException catch (e) {
      throw Exception(
        "Erreur Firestore lors de la mise à jour du prix : ${e.message}",
      );
    }
  }

  Stream<List<Order>> streamAllOrders({int limit = 50, String? statusFilter}) {
    Query query = _ordersRef
        .orderBy('timestamp', descending: true)
        .limit(limit);

    // OPTIMISATION: Appliquer le filtre de statut directement sur la requête Firestore
    if (statusFilter != null && statusFilter != 'Toutes') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // CORRECTION: Passer l'ID via le paramètre nommé id
            return Order.fromJson(data, id: doc.id);
          }).toList(),
        );
  }

  Future<void> assignDeliverer({
    required String orderId,
    required String delivererUid,
    
  }) async {
    try {
      await _ordersRef.doc(orderId).update({
        'delivererId': delivererUid,
        'status': 'ASSIGNED', 
        'assignedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        print('Commande $orderId assignée ');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur d\'assignation: $e');
      }
      rethrow;
    }
  }

  Future<double> calculateTotalSpent(String userId) async {
    try {
      final aggregateQuery = await _ordersRef
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'COMPLETED')
          .aggregate(sum('priceQuote'))
          .get();

      return aggregateQuery.getSum('priceQuote')?.toDouble() ?? 0.0;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors du calcul du total dépensé pour $userId: $e");
      }
      return 0.0;
    }
  }

  Future<int?> getOrderForToday() async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      Timestamp startTimestamp = Timestamp.fromDate(startOfDay);
      Timestamp endTimestamp = Timestamp.fromDate(endOfDay);

      final querySnapshot = await _ordersRef
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .where('timestamp', isLessThanOrEqualTo: endTimestamp)
          .count() 
          .get();

      return querySnapshot.count;
    } catch (e) {
      if (kDebugMode) {
        print(
          "Erreur lors de la récupération du nombre de commandes du jour: $e",
        );
      }
      return 0;
    }
  }

  Future<double> chiffreAffaire() async {
    try {
      final aggregateQuery = await _ordersRef
          .where('status', isEqualTo: 'COMPLETED')
          .aggregate(sum('priceQuote'))
          .get();

      return aggregateQuery.getSum('priceQuote')?.toDouble() ?? 0.0;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors du calcul du chiffre d'affaires: $e");
      }
      return 0.0; 
    }
  }

  Future<Order?> getOrdersById(String orderId) async {
    try {
      DocumentSnapshot docSnapshot;
      try {
        docSnapshot = await _ordersRef.doc(orderId).get(const GetOptions(source: Source.cache));
        if (!docSnapshot.exists) throw Exception("Cache miss");
      } catch (_) {
        docSnapshot = await _ordersRef.doc(orderId).get(const GetOptions(source: Source.server));
      }

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        if (kDebugMode) {
          print('Commande non trouvée pour l\'ID: $orderId');
        }
        return null;
      }
      final data = docSnapshot.data() as Map<String, dynamic>;

      return Order.fromJson(data, id: docSnapshot.id);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération de la commande $orderId: $e');
      }
      return null;
    }
  }
}
