import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/foundation.dart';
import '../../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final CollectionReference _ordersRef = _db.collection('orders');
  final _ordersCollection = FirebaseFirestore.instance.collection('orders');

  // Méthode qui crée une commande et retourne son ID (String)

  // Sauvegarde une nouvelle commande
  Future<String> addOrder(Order order) async {
    try {
      DocumentReference orderRef = await _ordersRef.add(order);
      return orderRef.id;
    } on FirebaseException catch (e) {
      throw Exception(
        "Erreur Firestore lors de l'ajout de la commande : ${e.message}",
      );
    }
  }

  // Récupère les commandes d'un utilisateur
  Future<List<Order>> getOrdersByUserId(String userId) async {
    try {
      final snapshot = await _ordersRef
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      // La conversion est automatique grâce à withConverter
      return snapshot.docs.map((doc) => doc.data() as Order).toList();
    } on FirebaseException catch (e) {
      throw Exception(
        "Erreur Firestore lors de la récupération : ${e.message}",
      );
    }
  }

  Stream<List<Order>> streamUserOrders(String userId) {
    return _ordersRef
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots() // donne en temps reel
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            // 1. Convertir les données du document en Map
            final data = doc.data() as Map<String, dynamic>;
            return Order.fromJson(data, id: doc.id);
          }).toList();
        });
  }

  Future<Order?> getOrder(String uid) async {
    final doc = await _ordersRef.doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return Order.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
  }) async {
    try {
      // 1. Obtenir la référence du document
      DocumentReference docRef = _ordersCollection.doc(orderId);

      // 2. Mettre à jour le champ 'status'
      await docRef.update({
        'status': newStatus,
        // Optionnel : ajouter un champ de date de mise à jour
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

  //update price quote
  Future<void> updateFinalPrice(String orderId, double finalPrice) async {
    try {
      await _ordersRef.doc(orderId).update({
        'priceQuote': finalPrice,
        'status':
            'PRICE_QUOTED', // Nouveau statut pour indiquer que le prix est prêt
      });
    } on FirebaseException catch (e) {
      throw Exception(
        "Erreur Firestore lors de la mise à jour du prix : ${e.message}",
      );
    }
  }

  Stream<List<Order>> streamAllOrders() {
    return _ordersCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            // 1. Récupération sécurisée des données de la Map (les champs internes)
            final data = doc.data() as Map<String, dynamic>? ?? {};

            // 2. Créer une nouvelle Map en ajoutant l'ID du document
            final Map<String, dynamic> fullData = {...data, 'id': doc.id};

            // 3. Appeler fromJson avec l'ID inclus
            return Order.fromJson(fullData);
          }).toList(),
        );
  }

  Future<void> assignDeliverer({
    required String orderId,
    required String delivererUid,
    // Pour l'affichage
  }) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'delivererId': delivererUid,
        'status': 'ASSIGNED', // Change le statut de la commande
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
      // 1. Interroger la collection 'orders'
      final querySnapshot = await _db
          .collection('orders')
          // Filtrer par l'ID du client
          .where('userId', isEqualTo: userId)
          // Filtrer par le statut (seules les commandes complétées comptent)
          .where('status', isEqualTo: 'COMPLETED') // OU 'DELIVERED'
          .get();

      double totalSpent = 0.0;

      // 2. Parcourir les documents et additionner le prix final
      for (var doc in querySnapshot.docs) {
        // Le champ 'finalPrice' doit exister et être de type numérique (num ou double)
        final data = doc.data();
        final finalPrice = (data['finalPrice'] as num?)?.toDouble() ?? 0.0;

        totalSpent += finalPrice;
      }

      return totalSpent;
    } catch (e) {
      print("Erreur lors du calcul du total dépensé pour $userId: $e");
      // En cas d'erreur, retourner 0.0
      return 0.0;
    }
  }

  Future<int?> getOrderForToday() async {
    try {
      // Obtenir la date d'aujourd'hui
      DateTime now = DateTime.now();
      // Début de la journée (00:00:00)
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      // Fin de la journée (23:59:59)
      DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Convertir en Timestamps pour Firestore
      Timestamp startTimestamp = Timestamp.fromDate(startOfDay);
      Timestamp endTimestamp = Timestamp.fromDate(endOfDay);

      final querySnapshot = await _ordersCollection
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .where('timestamp', isLessThanOrEqualTo: endTimestamp)
          .count() // Utilise .count() pour une efficacité maximale
          .get();

      return querySnapshot.count;
    } catch (e) {
      if (kDebugMode) {
        print(
          "Erreur lors de la récupération du nombre de commandes du jour: $e",
        );
      }
      return 0; // Retourne 0 en cas d'erreur
    }
  }

  Future<double> chiffreAffaire() async {
    try {
      // Récupérer uniquement les commandes qui sont terminées
      final querySnapshot = await _ordersCollection
          .where('status', isEqualTo: 'COMPLETED')
          .get();

      double totalRevenue = 0.0;

      // Parcourir les documents et sommer les `finalPrice`
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        // Assurer que `finalPrice` est un nombre avant de l'ajouter
        final price = (data['finalPrice'] as num?)?.toDouble() ?? 0.0;
        totalRevenue += price;
      }

      return totalRevenue;
    } catch (e) {
      print("Erreur lors du calcul du chiffre d'affaires: $e");
      return 0.0; // Retourner 0 en cas d'erreur
    }
  }

  Future<Order?> getOrdersById(String orderId) async {
    try {
      // 1. Récupérer le document spécifique
      final docSnapshot = await _ordersCollection.doc(orderId).get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        print('Commande non trouvée pour l\'ID: $orderId');
        return null;
      }
      // 3. Convertir le Map en objet Order en utilisant votre factory
      final data = docSnapshot.data() as Map<String, dynamic>;
      // Ajoutez l'ID du document dans le Map avant de le passer à fromJson,
      // car votre fromJson attend l'ID pour le champ 'id'.
      data['id'] = docSnapshot.id;

      return Order.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération de la commande $orderId: $e');
      }
      // En mode production, vous pourriez vouloir loguer cette erreur
      return null;
    }
  }
}
