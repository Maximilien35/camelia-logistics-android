import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import '../../models/order_model.dart';

class OrderService {
  final CollectionReference _ordersRef = FirebaseFirestore.instance.collection(
    'orders',
  );

  /// Helper method to safely get documents with retry and cache fallback
  Future<QuerySnapshot> _safeGet(Query query, {int maxRetries = 2}) async {
    int attempt = 0;
    while (attempt <= maxRetries) {
      try {
        // Try server first
        return await query.get();
      } on FirebaseException catch (e) {
        if (e.code == 'unavailable' && attempt < maxRetries) {
          // Wait with exponential backoff
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          attempt++;
          continue;
        }
        // If server fails and we're out of retries, try cache
        if (e.code == 'unavailable') {
          try {
            return await query.get(const GetOptions(source: Source.cache));
          } catch (_) {
            // If cache also fails, rethrow original error
            rethrow;
          }
        }
        rethrow;
      }
    }
    // This should never be reached, but just in case
    return await query.get();
  }

  /// Calcule la distance en km entre deux points GPS en utilisant la formule de Haversine
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Rayon de la Terre en km
    double dLat = (lat2 - lat1) * pi / 180;
    double dLon = (lon2 - lon1) * pi / 180;
    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  Future<String> addOrder(Order order) async {
    try {
      DocumentReference orderRef = await _ordersRef.add(order.toJson());
      return orderRef.id;
    } on FirebaseException catch (_) {
      throw Exception(
        "Impossible de créer la commande. Vérifiez votre connexion internet.",
      );
    }
  }

  /// Crée une commande avec assignation automatique du collaborateur le plus proche si c'est une LIVRAISON
  Future<String> addOrderWithAutoAssignment(
    Order order, {
    double? clientLat,
    double? clientLon,
  }) async {
    try {
      String orderId = await addOrder(order);

      // Pour LIVRAISON, assigner automatiquement le collaborateur le plus proche
      if (order.serviceType == 'LIVRAISON' &&
          clientLat != null &&
          clientLon != null) {
        String? nearestCollaboratorId = await findNearestCollaborator(
          clientLat,
          clientLon,
        );
        if (nearestCollaboratorId != null) {
          await assignDeliverer(
            orderId: orderId,
            delivererUid: nearestCollaboratorId,
          );
        }
      }

      return orderId;
    } on FirebaseException catch (_) {
      throw Exception(
        "Impossible de créer la commande. Vérifiez votre connexion internet.",
      );
    }
  }

  Future<List<Order>> getOrdersByUserId(String userId, {int limit = 20}) async {
    try {
      final query = _ordersRef
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit); // OPTIMISATION: Limiter à 20 commandes récentes

      final snapshotServer = await _safeGet(query);

      return snapshotServer.docs
          .map(
            (doc) =>
                Order.fromJson(doc.data() as Map<String, dynamic>, id: doc.id),
          )
          .toList();
    } on FirebaseException catch (_) {
      throw Exception("Impossible de récupérer l'historique des commandes.");
    }
  }

  Stream<List<Order>> streamUserOrders(String userId, {int? limit}) {
    Query query = _ordersRef
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
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
      final docServer = await _ordersRef.doc(uid).get();
      if (docServer.exists && docServer.data() != null) {
        return Order.fromJson(
          docServer.data() as Map<String, dynamic>,
          id: docServer.id,
        );
      }
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        try {
          final cacheDoc = await _ordersRef
              .doc(uid)
              .get(const GetOptions(source: Source.cache));
          if (cacheDoc.exists && cacheDoc.data() != null) {
            return Order.fromJson(
              cacheDoc.data() as Map<String, dynamic>,
              id: cacheDoc.id,
            );
          }
        } catch (_) {
          // Ignore cache fallback failure and continue to null return.
        }
      }
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
      throw Exception(
        "Impossible de mettre à jour le statut. Vérifiez votre connexion.",
      );
    }
  }

  Future<void> updateFinalPrice(String orderId, double finalPrice) async {
    try {
      await _ordersRef.doc(orderId).update({
        'priceQuote': finalPrice,
        'status': 'PRICE_QUOTED',
      });
    } on FirebaseException catch (_) {
      throw Exception("Échec de l'envoi du devis. Veuillez réessayer.");
    }
  }

  Future<List<Order>> getAllOrders({
    int limit = 50,
    String? statusFilter,
  }) async {
    Query query = _ordersRef
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (statusFilter != null && statusFilter != 'Toutes') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    final snapshot = await _safeGet(query);

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Order.fromJson(data, id: doc.id);
    }).toList();
  }

  Stream<List<Order>> streamAllOrders({int limit = 50, String? statusFilter}) {
    Query query = _ordersRef
        .orderBy('timestamp', descending: true)
        .limit(limit);

    // OPTIMISATION: Appliquer le filtre de statut directement sur la requête Firestore
    if (statusFilter != null && statusFilter != 'Toutes') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // CORRECTION: Passer l'ID via le paramètre nommé id
        return Order.fromJson(data, id: doc.id);
      }).toList(),
    );
  }

  // OPTIMISATION: Récupère uniquement les commandes actives pour vérifier la disponibilité des chauffeurs
  // Cela évite de faire une requête par chauffeur.
  Stream<List<Order>> streamActiveOrdersForDrivers({int limit = 20}) {
    return _ordersRef
        .where('status', isEqualTo: 'ASSIGNED')
        .limit(limit) // OPTIMISATION: Limiter pour éviter surcharge
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Order.fromJson(data, id: doc.id);
          }).toList(),
        );
  }

  Future<void> assignDeliverer({
    required String orderId,
    required String delivererUid,
  }) async {
    try {
      final orderSnapshot = await _ordersRef.doc(orderId).get();
      if (!orderSnapshot.exists || orderSnapshot.data() == null) {
        throw Exception('Commande introuvable.');
      }
      final data = orderSnapshot.data() as Map<String, dynamic>;
      final priceQuote = (data['priceQuote'] as num?)?.toDouble() ?? 0.0;
      if (priceQuote <= 0) {
        throw Exception(
          'Impossible d\'assigner une commande sans prix valide.',
        );
      }

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
      throw Exception("Impossible d'assigner le chauffeur. ${e.toString()}");
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
        docSnapshot = await _ordersRef.doc(orderId).get();
      } on FirebaseException catch (e) {
        if (e.code == 'unavailable') {
          docSnapshot = await _ordersRef
              .doc(orderId)
              .get(const GetOptions(source: Source.cache));
        } else {
          rethrow;
        }
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

  /// Trouve le collaborateur le plus proche pour une livraison
  Future<String?> findNearestCollaborator(
    double clientLat,
    double clientLon, {
    int limit = 50,
  }) async {
    try {
      final collaboratorsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isCollaborator', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .limit(limit) // OPTIMISATION: Limiter les collaborateurs récupérés
          .get();

      if (collaboratorsSnapshot.docs.isEmpty) {
        return null;
      }

      String? nearestId;
      double minDistance = double.infinity;

      for (final doc in collaboratorsSnapshot.docs) {
        final data = doc.data();
        final lat = data['latitude'] as double?;
        final lon = data['longitude'] as double?;

        if (lat != null && lon != null) {
          final distance = calculateDistance(clientLat, clientLon, lat, lon);
          if (distance < minDistance) {
            minDistance = distance;
            nearestId = doc.id;
          }
        }
      }

      return nearestId;
    } catch (e) {
      if (kDebugMode) {
        print(
          'Erreur lors de la recherche du collaborateur le plus proche: $e',
        );
      }
      return null;
    }
  }

  Future<void> openWhatsAppService(
    String phoneNumber, {
    String message = "Bonjour Camelia Logistics, j'aimerais...",
  }) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    final String url =
        "https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}";
    final Uri whatsappUri = Uri.parse(url);

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint(
          'Impossible d\'ouvrir WhatsApp. Vérifiez s\'il est installé.',
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture de WhatsApp: $e');
    }
  }
}
