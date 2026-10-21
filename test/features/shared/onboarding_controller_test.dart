import 'package:camelia/core/storage/key_value_store.dart';
import 'package:camelia/features/shared/state/onboarding_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stockage dont toutes les opérations échouent, comme un stockage de
/// plate-forme indisponible.
class _BrokenStore implements KeyValueStore {
  @override
  Future<String?> read(String key) => Future.error(StateError('ko'));

  @override
  Future<void> write(String key, String value) =>
      Future.error(StateError('ko'));

  @override
  Future<void> remove(String key) => Future.error(StateError('ko'));
}

void main() {
  test('inconnu tant que le repère n\'est pas lu', () {
    final controller = OnboardingController(store: MemoryKeyValueStore());
    expect(controller.seen, isNull);
  });

  test('premier lancement : présentation à montrer', () async {
    final controller = OnboardingController(store: MemoryKeyValueStore());
    await controller.load();
    expect(controller.seen, isFalse);
  });

  test('complete() la marque vue, et le reste au lancement suivant', () async {
    final store = MemoryKeyValueStore();
    await OnboardingController(store: store).complete();

    final next = OnboardingController(store: store);
    await next.load();
    expect(next.seen, isTrue);
  });

  test('stockage illisible : présentation sautée, sans erreur', () async {
    final controller = OnboardingController(store: _BrokenStore());
    await controller.load();
    expect(controller.seen, isTrue);
    await controller.complete();
    expect(controller.seen, isTrue);
  });
}
