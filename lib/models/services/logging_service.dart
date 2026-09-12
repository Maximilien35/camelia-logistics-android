import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Service centralisé pour logger tous les erreurs techniques
/// Accessible uniquement aux administrateurs pour diagnostic et audit
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Buffer pour éviter les appels excessifs à Firestore
  final List<Map<String, dynamic>> _logBuffer = [];
  Timer? _flushTimer;

  factory LoggingService() {
    return _instance;
  }

  LoggingService._internal();

  /// Log une erreur technique avec contexte complet
  /// Destiné aux administrateurs pour diagnostic
  Future<void> logError({
    required String title,
    required String technicalMessage,
    String? category,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      final timestamp = DateTime.now();

      final logEntry = {
        'timestamp': timestamp,
        'title': title,
        'technicalMessage': technicalMessage,
        'category': category ?? 'unknown',
        'userId': currentUser?.uid,
        'userEmail': currentUser?.email,
        'stackTrace': stackTrace?.toString() ?? 'N/A',
        'context': additionalContext ?? {},
        'severity': 'error',
      };

      _logBuffer.add(logEntry);

      // Si en production, envoyer à Firestore
      if (!kDebugMode) {
        _scheduleBatchFlush();
      }

      // En développement, afficher dans console
      if (kDebugMode) {
        print('⚠️ [ERROR LOG] $title: $technicalMessage');
        if (stackTrace != null) {
          print('Stack Trace:\n$stackTrace');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du logging: $e');
      }
    }
  }

  /// Log un avertissement (erreur non-bloquante)
  Future<void> logWarning({
    required String title,
    required String message,
    Map<String, dynamic>? context,
  }) async {
    try {
      final logEntry = {
        'timestamp': DateTime.now(),
        'title': title,
        'message': message,
        'userId': _auth.currentUser?.uid,
        'context': context ?? {},
        'severity': 'warning',
      };

      _logBuffer.add(logEntry);

      if (!kDebugMode) {
        _scheduleBatchFlush();
      }

      if (kDebugMode) {
        print('⚠️ [WARNING] $title: $message');
      }
    } catch (e) {
      if (kDebugMode) print('Erreur lors du logging: $e');
    }
  }

  /// Log une action utilisateur pour audit
  Future<void> logUserAction({
    required String action,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      final logEntry = {
        'timestamp': DateTime.now(),
        'action': action,
        'description': description,
        'userId': currentUser?.uid,
        'metadata': metadata ?? {},
        'severity': 'info',
      };

      _logBuffer.add(logEntry);

      if (!kDebugMode) {
        _scheduleBatchFlush();
      }
    } catch (e) {
      if (kDebugMode) print('Erreur lors du logging d\'action: $e');
    }
  }

  /// Programme un envoi en batch des logs
  void _scheduleBatchFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(const Duration(seconds: 5), _flushLogs);
  }

  /// Envoie tous les logs en attente à Firestore
  Future<void> _flushLogs() async {
    if (_logBuffer.isEmpty) return;

    try {
      final batch = _firestore.batch();
      final logsRef = _firestore.collection('app_logs');

      for (var log in _logBuffer) {
        final docRef = logsRef.doc();
        batch.set(docRef, log);
      }

      await batch.commit();
      _logBuffer.clear();

      if (kDebugMode) {
        print('✅ Logs envoyés à Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de l\'envoi des logs: $e');
      }
      // Garder les logs en buffer pour retry
    }
  }

  /// Force l'envoi immédiat des logs
  Future<void> flush() async {
    _flushTimer?.cancel();
    await _flushLogs();
  }

  /// Récupère les logs pour l'interface admin
  /// Seulement accessible aux administrateurs
  Stream<QuerySnapshot> getLogsForAdmin({
    int limitDays = 7,
  }) {
    final startDate = DateTime.now().subtract(Duration(days: limitDays));

    return _firestore
        .collection('app_logs')
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .orderBy('timestamp', descending: true)
        .limit(500)
        .snapshots();
  }

  /// Récupère les erreurs d'un utilisateur spécifique
  Stream<QuerySnapshot> getUserErrors(String userId) {
    return _firestore
        .collection('app_logs')
        .where('userId', isEqualTo: userId)
        .where('severity', isEqualTo: 'error')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  /// Statistiques des erreurs par catégorie
  Future<Map<String, int>> getErrorStats(int limitDays) async {
    final startDate = DateTime.now().subtract(Duration(days: limitDays));

    try {
      final querySnapshot = await _firestore
          .collection('app_logs')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('severity', isEqualTo: 'error')
          .get();

      final stats = <String, int>{};
      for (var doc in querySnapshot.docs) {
        final category = doc['category'] ?? 'unknown';
        stats[category] = (stats[category] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la récupération des stats: $e');
      return {};
    }
  }

  /// Nettoie les logs anciens (> 30 jours)
  Future<void> cleanOldLogs({int retentionDays = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

      final querySnapshot = await _firestore
          .collection('app_logs')
          .where('timestamp', isLessThan: cutoffDate)
          .limit(500)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (kDebugMode) {
        print('✅ ${querySnapshot.docs.length} anciens logs supprimés');
      }
    } catch (e) {
      if (kDebugMode) print('Erreur lors du nettoyage des logs: $e');
    }
  }
}