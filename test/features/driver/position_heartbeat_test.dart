import 'dart:async';

import 'package:camelia/features/driver/services/position_reporter.dart';
import 'package:camelia/features/driver/state/position_heartbeat.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeReporter implements PositionReporter {
  final List<bool> calls = [];
  PositionReportOutcome outcome = PositionReportOutcome.sent;
  Completer<void>? gate;

  @override
  Future<PositionReportOutcome> reportOnce({bool mayPrompt = true}) async {
    calls.add(mayPrompt);
    final g = gate;
    if (g != null) await g.future;
    return outcome;
  }
}

class _FakeTimer implements Timer {
  _FakeTimer(this.interval, this.onTick);

  final Duration interval;
  final void Function(Timer) onTick;
  bool cancelled = false;

  void fire() => onTick(this);

  @override
  void cancel() => cancelled = true;

  @override
  bool get isActive => !cancelled;

  @override
  int get tick => 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeReporter reporter;
  late List<_FakeTimer> timers;
  late PositionHeartbeat heartbeat;

  _FakeTimer activeTimer() => timers.lastWhere((t) => !t.cancelled);

  setUp(() {
    reporter = _FakeReporter();
    timers = [];
    heartbeat = PositionHeartbeat(
      reporter: reporter,
      observeLifecycle: false,
      timerFactory: (interval, onTick) {
        final t = _FakeTimer(interval, onTick);
        timers.add(t);
        return t;
      },
    );
  });

  tearDown(() => heartbeat.dispose());

  test('hors ligne sans course : aucun relevé', () {
    heartbeat.update(online: false, inCourse: false);

    expect(heartbeat.mode, HeartbeatMode.off);
    expect(reporter.calls, isEmpty);
    expect(timers, isEmpty);
  });

  test('en ligne : relevé immédiat, puis toutes les 10 minutes', () async {
    heartbeat.update(online: true, inCourse: false);
    await pumpEventQueue();

    expect(reporter.calls, hasLength(1));
    expect(activeTimer().interval, const Duration(minutes: 10));

    activeTimer().fire();
    await pumpEventQueue();
    expect(reporter.calls, hasLength(2));
  });

  test('course en cours : toutes les 3 minutes, même hors ligne', () async {
    heartbeat.update(online: false, inCourse: true);
    await pumpEventQueue();

    expect(heartbeat.mode, HeartbeatMode.course);
    expect(reporter.calls, hasLength(1));
    expect(activeTimer().interval, const Duration(minutes: 3));
  });

  test('repasser hors ligne arrête la minuterie', () async {
    heartbeat.update(online: true, inCourse: false);
    await pumpEventQueue();
    final timer = activeTimer();

    heartbeat.update(online: false, inCourse: false);

    expect(timer.cancelled, isTrue);
    expect(timers.where((t) => !t.cancelled), isEmpty);
  });

  test('un état inchangé ne relance pas de relevé', () async {
    heartbeat.update(online: true, inCourse: false);
    await pumpEventQueue();
    heartbeat.update(online: true, inCourse: false);
    await pumpEventQueue();

    expect(reporter.calls, hasLength(1));
    expect(timers, hasLength(1));
  });

  test('les relevés périodiques ne demandent jamais la permission', () async {
    heartbeat.update(online: true, inCourse: false);
    await pumpEventQueue();
    activeTimer().fire();
    await pumpEventQueue();

    expect(reporter.calls, everyElement(isFalse));
  });

  test('retour au premier plan : relevé immédiat', () async {
    heartbeat.update(online: true, inCourse: false);
    await pumpEventQueue();

    heartbeat.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();

    expect(reporter.calls, hasLength(2));
  });

  test('une demande de permission arrivée pendant un relevé est rejouée '
      'si celui-ci échoue faute de permission', () async {
    reporter
      ..outcome = PositionReportOutcome.permissionDenied
      ..gate = Completer<void>();
    heartbeat.update(online: true, inCourse: false);
    final gesture = heartbeat.pingNow(mayPrompt: true);

    reporter.gate!.complete();
    reporter.gate = null;
    await gesture;
    await pumpEventQueue();

    expect(reporter.calls, [false, true]);
  });

  test('signale une localisation indisponible tant que le chauffeur est en '
      'ligne', () async {
    reporter.outcome = PositionReportOutcome.serviceDisabled;
    heartbeat.update(online: true, inCourse: false);
    await pumpEventQueue();

    expect(heartbeat.locationUnavailable, isTrue);

    heartbeat.update(online: false, inCourse: false);
    expect(heartbeat.locationUnavailable, isFalse);
  });
}
