import 'package:cloud_firestore/cloud_firestore.dart';
import 'cache_manager.dart';
import 'package:flutter/foundation.dart';

class CollaboratorOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheManager _cacheManager = CacheManager();

  /// Get assigned orders for a collaborator (with caching)
  /// Priority: Cache first → Background refresh if online
  Future<List<Map<String, dynamic>>> getAssignedOrders(
    String collaboratorId,
  ) async {
    final cachedOrders = _cacheManager.getCachedCollaboratorOrders(
      collaboratorId,
    );
    if (cachedOrders != null) {
      if (_cacheManager.isOnline) {
        _refreshOrdersInBackground(collaboratorId);
      }
      return cachedOrders;
    }
    return _fetchAssignedOrdersFromFirestore(collaboratorId);
  }

  Future<List<Map<String, dynamic>>> _fetchAssignedOrdersFromFirestore(
    String collaboratorId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('delivererId', isEqualTo: collaboratorId)
          .get();

      final orders = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      _cacheManager.cacheCollaboratorOrders(collaboratorId, orders);

      return orders;
    } catch (e) {
      // Try cache as fallback
      final cachedOrders = _cacheManager.getCachedCollaboratorOrders(
        collaboratorId,
      );
      return cachedOrders ?? [];
    }
  }

  /// Refresh orders in background (non-blocking)
  void _refreshOrdersInBackground(String collaboratorId) {
    _fetchAssignedOrdersFromFirestore(collaboratorId)
        .then((_) {
          // Background refresh complete
        })
        .catchError((e) {
          if (kDebugMode) {
            print('Background refresh error: $e');
          }
        });
  }

  /// Get single order details with caching
  /// Status que l'ordre peut appartient à orderList cache avant d'aller à Firestore
  Future<Map<String, dynamic>?> getOrderDetail(String orderId) async {
    try {
      final doc = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          return {'id': doc.id, ...data};
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching order detail: $e');
      }
      return null;
    }
  }

  /// Accept an order (update status to ACCEPTED)
  Future<bool> acceptOrder(String orderId, String collaboratorId) async {
    try {
      final orderSnapshot = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();
      if (!orderSnapshot.exists || orderSnapshot.data() == null) {
        if (kDebugMode) {
          print('Order not found for acceptance: $orderId');
        }
        return false;
      }

      final priceQuote =
          (orderSnapshot.data()?['priceQuote'] as num?)?.toDouble() ?? 0.0;
      if (priceQuote <= 0) {
        if (kDebugMode) {
          print('Cannot accept order with zero or invalid price: $orderId');
        }
        return false;
      }

      await _firestore.collection('orders').doc(orderId).update({
        'status': 'ACCEPTED',
        'delivererId': collaboratorId,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate cache to force refresh
      _cacheManager.clearCollaboratorOrdersCache(collaboratorId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error accepting order: $e');
      }
      return false;
    }
  }

  /// Refuse an order (set status back to PENDING)
  Future<bool> refuseOrder(
    String orderId,
    String collaboratorId, {
    String? reason,
  }) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'PENDING',
        'delivererId': FieldValue.delete(),
        'refusedBy': collaboratorId,
        'refusedAt': FieldValue.serverTimestamp(),
        'refusalReason': reason ?? 'Collaborator refused',
      });

      // Invalidate cache
      _cacheManager.clearCollaboratorOrdersCache(collaboratorId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error refusing order: $e');
      }
      return false;
    }
  }

  /// Update order status (collaborator perspective)
  /// ACCEPTED → IN_PROGRESS → COMPLETED
  Future<bool> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? notes,
  }) async {
    try {
      final updateData = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null) {
        updateData['collaboratorNotes'] = notes;
      }

      if (newStatus == 'IN_PROGRESS') {
        updateData['startedAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'COMPLETED') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating order status: $e');
      }
      return false;
    }
  }

  /// Get orders stream for real-time updates (if sync enabled)
  /// Use sparingly to avoid hitting Firestore read limits
  Stream<List<Map<String, dynamic>>> getAssignedOrdersStream(
    String collaboratorId, {
    int limit = 20,
  }) {
    return _firestore
        .collection('orders')
        .where('delivererId', isEqualTo: collaboratorId)
        .limit(limit) // OPTIMISATION: Limiter les résultats
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  /// Get orders snapshot (non-realtime, preferred for cost control)
  Future<List<Map<String, dynamic>>> getAssignedOrdersOnce(
    String collaboratorId, {
    int limit = 20,
  }) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('delivererId', isEqualTo: collaboratorId)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Get filtered orders by status
  Future<List<Map<String, dynamic>>> getOrdersByStatus(
    String collaboratorId,
    String status,
  ) async {
    final allOrders = await getAssignedOrders(collaboratorId);
    return allOrders.where((order) => order['status'] == status).toList();
  }

  /// Get total earnings for collaborator
  /// Filters orders by COMPLETED status and sums priceQuote
  Future<double> getTotalEarnings(String collaboratorId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('delivererId', isEqualTo: collaboratorId)
          .where('status', isEqualTo: 'COMPLETED')
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final priceQuote = doc.data()['priceQuote'] as num?;
        if (priceQuote != null) {
          total += priceQuote.toDouble();
        }
      }

      return total;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating earnings: $e');
      }
      return 0;
    }
  }

  /// Get today's earnings
  Future<double> getTodayEarnings(String collaboratorId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfDayTimestamp = Timestamp.fromDate(startOfDay);

      final snapshot = await _firestore
          .collection('orders')
          .where('delivererId', isEqualTo: collaboratorId)
          .where('status', isEqualTo: 'COMPLETED')
          .where('completedAt', isGreaterThanOrEqualTo: startOfDayTimestamp)
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final priceQuote = doc.data()['priceQuote'] as num?;
        if (priceQuote != null) {
          total += priceQuote.toDouble();
        }
      }

      return total;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating today earnings: $e');
      }
      return 0;
    }
  }

  /// Get pending orders count (excluding self)
  /// Returns how many orders are still PENDING (not assigned to this collaborator)
  /// Useful for showing availability
  Future<int> getPendingOrdersCount() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'PENDING')
          .get();

      return snapshot.size;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting pending orders count: $e');
      }
      return 0;
    }
  }

  /// Upload photo for order completion proof
  /// Returns the photo URL


  /// Clear all cached data (on logout)
  void clearAllCache() {
    _cacheManager.clearAllCache();
  }
}
