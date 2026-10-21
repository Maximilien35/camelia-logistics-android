/// Rythme des relevés de position du chauffeur (§ 6.9.1 côté backend).
///
/// Sans ces relevés, le chauffeur est **invisible** : le backend ne lui offre
/// une course que si sa dernière position date de moins de 12 minutes et se
/// trouve à moins de 10 km du point de collecte (§ 6.4.1). Chaque relevé
/// déclenche aussi, côté serveur, le rattrapage des commandes déjà en
/// recherche autour de lui.
///
/// | État | Rythme |
/// |---|---|
/// | hors ligne, sans course | aucun relevé |
/// | en ligne, sans course | un relevé tout de suite, puis toutes les 10 min |
/// | course en cours | un relevé tout de suite, puis toutes les 3 min |
///
/// Plus un relevé immédiat au retour au premier plan, pour ne pas attendre
/// la fin d'un intervalle commencé avant la mise en veille.
///
/// Ce sont des appels REST ponctuels, pas une connexion ouverte : la règle
/// n°5 interdit le WebSocket et le streaming, pas un `POST` toutes les dix
/// minutes, que le backend attend explicitement.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../services/position_reporter.dart';

enum HeartbeatMode { off, idle, course }

/// Fabrique de minuterie, remplaçable dans les tests.
typedef PeriodicTimerFactory =
    Timer Function(Duration interval, void Function(Timer) onTick);

class PositionHeartbeat extends ChangeNotifier with WidgetsBindingObserver {
  PositionHeartbeat({
    required PositionReporter reporter,
    this.idleInterval = const Duration(minutes: 10),
    this.courseInterval = const Duration(minutes: 3),
    PeriodicTimerFactory? timerFactory,
    bool observeLifecycle = true,
  }) : _reporter = reporter,
       _timerFactory = timerFactory ?? Timer.periodic,
       _observeLifecycle = observeLifecycle {
    if (_observeLifecycle) WidgetsBinding.instance.addObserver(this);
  }

  final PositionReporter _reporter;
  final PeriodicTimerFactory _timerFactory;
  final bool _observeLifecycle;

  /// En ligne sans course — § 6.9.1.
  final Duration idleInterval;

  /// Course en cours — § 6.9.1.
  final Duration courseInterval;

  HeartbeatMode _mode = HeartbeatMode.off;
  Timer? _timer;
  bool _inFlight = false;
  bool _promptPending = false;
  bool _disposed = false;
  PositionReportOutcome? _lastOutcome;

  HeartbeatMode get mode => _mode;

  /// Issue du dernier relevé, `null` avant le premier.
  PositionReportOutcome? get lastOutcome => _lastOutcome;

  /// Le dernier relevé n'a pas pu partir faute de permission ou de GPS :
  /// le chauffeur ne recevra aucune course tant que ce n'est pas réglé.
  bool get locationUnavailable =>
      _mode != HeartbeatMode.off &&
      (_lastOutcome == PositionReportOutcome.permissionDenied ||
          _lastOutcome == PositionReportOutcome.serviceDisabled);

  /// Recalcule le rythme à partir de l'état **renvoyé par le serveur**.
  ///
  /// [userGesture] : le changement vient d'un geste du chauffeur (bascule en
  /// ligne) — seul cas où la permission de localisation peut être demandée.
  void update({
    required bool online,
    required bool inCourse,
    bool userGesture = false,
  }) {
    final next = inCourse
        ? HeartbeatMode.course
        : online
        ? HeartbeatMode.idle
        : HeartbeatMode.off;
    if (next == _mode) return;
    _mode = next;
    _restart(mayPrompt: userGesture);
    notifyListeners();
  }

  /// Relevé immédiat à la demande (ex. le chauffeur vient d'accorder la
  /// permission depuis les réglages).
  Future<void> pingNow({bool mayPrompt = false}) async {
    if (_mode == HeartbeatMode.off) return;
    await _ping(mayPrompt: mayPrompt);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _mode != HeartbeatMode.off) {
      _restart(mayPrompt: false);
    }
  }

  void _restart({required bool mayPrompt}) {
    _timer?.cancel();
    _timer = null;
    if (_mode == HeartbeatMode.off) return;
    unawaited(_ping(mayPrompt: mayPrompt));
    final interval = _mode == HeartbeatMode.course
        ? courseInterval
        : idleInterval;
    _timer = _timerFactory(interval, (_) => unawaited(_ping(mayPrompt: false)));
  }

  Future<void> _ping({required bool mayPrompt}) async {
    // Un relevé lent (fix GPS jusqu'à 8 s) ne doit pas en empiler un second.
    // Sauf une demande de permission née d'un geste : elle est retenue et
    // rejouée si le relevé en cours échoue précisément faute de permission.
    if (_inFlight) {
      _promptPending = _promptPending || mayPrompt;
      return;
    }
    _inFlight = true;
    PositionReportOutcome? outcome;
    try {
      outcome = await _reporter.reportOnce(mayPrompt: mayPrompt);
      if (_disposed) return;
      if (outcome != _lastOutcome) {
        _lastOutcome = outcome;
        notifyListeners();
      }
    } finally {
      _inFlight = false;
    }
    final retryWithPrompt =
        _promptPending &&
        outcome == PositionReportOutcome.permissionDenied &&
        _mode != HeartbeatMode.off;
    _promptPending = false;
    if (retryWithPrompt) await _ping(mayPrompt: true);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    if (_observeLifecycle) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
