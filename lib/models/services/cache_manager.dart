import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:async';

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  late SharedPreferences _prefs;
  final bool _isOnline = true;
  bool _isInitialized = false;

  // Cache keys
  static const String _collaboratorOrdersCacheKey = 'collab_orders_cache';
  static const String _collaboratorOrdersTimestampKey = 'collab_orders_timestamp';
  static const String _collaboratorSessionKey = 'collab_session';

  // Cache TTL in seconds (5 minutes for order list, 30 minutes for session)
  static const int ordersCacheTTL = 300; // 5 min
  static const int sessionCacheTTL = 1800; // 30 min

  factory CacheManager() {
    return _instance;
  }

  CacheManager._internal();

  /// Initialize the cache manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    // Connectivity check can be done on-demand without continuous listener
    // to reduce costs
  }

  /// Check if device is online
  bool get isOnline => _isOnline;

  /// Clean Firestore objects by converting Timestamps to ISO strings
  Map<String, dynamic> _cleanFirestoreObject(Map<String, dynamic> obj) {
    final cleaned = Map<String, dynamic>.from(obj);
    cleaned.removeWhere((key, value) {
      // Remove timestamps and complex objects that can't be serialized
      return value is Timestamp || value is DateTime;
    });
    // Keep only serializable fields
    return cleaned;
  }

  /// Save collaborator orders to cache
  void cacheCollaboratorOrders(String collaboratorId, List<Map<String, dynamic>> orders) {
    try {
      if (!_isInitialized) return; // Skip if not initialized
      // Clean orders before encoding - remove Timestamps and complex objects
      final cleanedOrders = orders.map(_cleanFirestoreObject).toList();
      final ordersJson = jsonEncode(cleanedOrders);
      _prefs.setString('${_collaboratorOrdersCacheKey}_$collaboratorId', ordersJson);
      _prefs.setInt('${_collaboratorOrdersTimestampKey}_$collaboratorId', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) {
        print('Error caching orders: $e');
      }
      // Don't throw - silently fail to prevent infinite loops
    }
  }

  /// Get cached collaborator orders
  List<Map<String, dynamic>>? getCachedCollaboratorOrders(String collaboratorId) {
    try {
      if (!_isInitialized) return null; // Return null if not initialized
      final cached = _prefs.getString('${_collaboratorOrdersCacheKey}_$collaboratorId');
      if (cached == null) return null;

      // Check if cache is expired
      final timestamp = _prefs.getInt('${_collaboratorOrdersTimestampKey}_$collaboratorId') ?? 0;
      if (timestamp == 0) return null;
      
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;

      if (cacheAge > (ordersCacheTTL * 1000)) {
        clearCollaboratorOrdersCache(collaboratorId);
        return null;
      }

      final decoded = jsonDecode(cached) as List;
      return List<Map<String, dynamic>>.from(
        decoded.map((item) => Map<String, dynamic>.from(item as Map))
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving cached orders: $e');
      }
      // Clear corrupted cache
      try {
        clearCollaboratorOrdersCache(collaboratorId);
      } catch (_) {}
      return null;
    }
  }

  void clearCollaboratorOrdersCache(String collaboratorId) {
    _prefs.remove('${_collaboratorOrdersCacheKey}_$collaboratorId');
    _prefs.remove('${_collaboratorOrdersTimestampKey}_$collaboratorId');
  }

  void cacheCollaboratorSession(Map<String, dynamic> sessionData) {
    try {
      final sessionJson = jsonEncode(sessionData);
      _prefs.setString(_collaboratorSessionKey, sessionJson);
      _prefs.setInt('${_collaboratorSessionKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) {
        print('Error caching session: $e');
      }
    }
  }

  /// Get cached collaborator session
  Map<String, dynamic>? getCachedCollaboratorSession() {
    try {
      final cached = _prefs.getString(_collaboratorSessionKey);
      if (cached == null) return null;

      // Check if session is expired (30 minutes)
      final timestamp = _prefs.getInt('${_collaboratorSessionKey}_timestamp') ?? 0;
      final sessionAge = DateTime.now().millisecondsSinceEpoch - timestamp;

      if (sessionAge > (sessionCacheTTL * 1000)) {
        clearCollaboratorSession();
        return null;
      }

      return Map<String, dynamic>.from(jsonDecode(cached) as Map);
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving cached session: $e');
      }
      return null;
    }
  }

  /// Clear collaborator session
  void clearCollaboratorSession() {
    _prefs.remove(_collaboratorSessionKey);
    _prefs.remove('${_collaboratorSessionKey}_timestamp');
  }

  /// Check if cache exists and is valid
  bool isCacheValid(String collaboratorId) {
    final timestamp = _prefs.getInt('${_collaboratorOrdersTimestampKey}_$collaboratorId') ?? 0;
    if (timestamp == 0) return false;

    final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
    return cacheAge < (ordersCacheTTL * 1000);
  }

  /// Get cache age in seconds
  int? getCacheAgeSeconds(String collaboratorId) {
    final timestamp = _prefs.getInt('${_collaboratorOrdersTimestampKey}_$collaboratorId');
    if (timestamp == null) return null;

    final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
    return (cacheAge / 1000).toInt();
  }

  /// Clear all caches
  void clearAllCache() {
    try {
      _prefs.clear();
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing all cache: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    // No connectivity listener to dispose
  }
}
