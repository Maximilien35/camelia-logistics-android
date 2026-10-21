import 'dart:async';

import 'package:camelia/core/api/api_exception.dart';
import 'package:camelia/features/client/models/geocode_result.dart';
import 'package:camelia/features/client/services/address_service.dart';
import 'package:camelia/features/client/services/geocode_service.dart';
import 'package:camelia/features/client/state/address_picker_controller.dart';
import 'package:camelia/features/shared/models/geo_point.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/mock_session.dart';

const _bonanjo = GeoPoint(latitude: 4.0430, longitude: 9.6921);
const _akwa = GeoPoint(latitude: 4.0503, longitude: 9.7005);

/// Géocodage piloté par le test : réponses retenues, appels comptés.
class _FakeGeocode extends GeocodeService {
  _FakeGeocode(MockSession session) : super(client: session.client);

  final Map<GeoPoint, String?> labels = {
    _bonanjo: 'Rue Njo-Njo, Bonanjo',
    _akwa: 'Boulevard de la Liberté, Akwa',
  };

  /// Permet de retenir une réponse pour simuler un serveur lent.
  Completer<String?>? pendingLabel;
  int reverseCalls = 0;
  int searchCalls = 0;
  Object? searchError;
  Object? reverseError;

  @override
  Future<String?> reverse(GeoPoint point) {
    reverseCalls++;
    if (reverseError != null) return Future.error(reverseError!);
    if (pendingLabel != null) return pendingLabel!.future;
    return Future.value(labels[point]);
  }

  @override
  Future<List<GeocodeResult>> search(String query) async {
    searchCalls++;
    if (searchError != null) throw searchError!;
    return [
      if (query.toLowerCase().contains('akwa'))
        const GeocodeResult(label: 'Akwa, Douala', point: _akwa),
    ];
  }
}

void main() {
  late MockSession session;
  late _FakeGeocode geocode;

  setUp(() {
    session = MockSession();
    geocode = _FakeGeocode(session);
  });

  AddressPickerController controller({PickerMode mode = PickerMode.route}) =>
      AddressPickerController(
        geocode: geocode,
        addresses: AddressService(client: session.client),
        mode: mode,
      );

  /// Place un point puis le valide, comme le fait l'écran A4.
  Future<void> place(AddressPickerController c, GeoPoint point) async {
    c.onCameraIdle(point);
    await c.resolveActiveLabel();
  }

  // --- T2.9 : le géocodage inverse part à la validation, pas à l'arrêt de la
  // carte (arbitrage du 7 octobre 2026). Ces deux tests sont la garde.

  test('déplacer la carte retient le point sans appeler le serveur', () {
    final c = controller();

    c.onCameraIdle(_bonanjo);

    expect(geocode.reverseCalls, 0, reason: 'aucun appel à l\'arrêt de carte');
    expect(c.pickup?.point, _bonanjo);
    expect(c.pickup?.label, isEmpty);
    expect(c.canResolveLabel, isTrue, reason: 'le point attend son libellé');
    expect(c.canConfirm, isFalse, reason: 'pas de libellé, pas de validation');
  });

  test('« Ma position » retient le point, sans libellé ni appel', () async {
    final c = controller();

    final target = c.placeDevicePosition(_bonanjo);

    expect(target, _bonanjo, reason: 'la carte doit s\'y rendre');
    expect(c.pickup?.point, _bonanjo);
    expect(c.pickup?.label, isEmpty);
    expect(geocode.reverseCalls, 0, reason: 'le libellé vient à la validation');
    expect(c.canResolveLabel, isTrue);

    await c.resolveActiveLabel();
    expect(c.pickup?.label, 'Rue Njo-Njo, Bonanjo');
  });

  test('l\'arrêt de la carte en fin d\'animation n\'écrase pas le point', () {
    final c = controller();

    c.placeDevicePosition(_bonanjo);
    // Le SDK rend une cible à peine différente à la fin de l'animation.
    c.onCameraIdle(
      const GeoPoint(latitude: 4.0430000001, longitude: 9.6920999999),
    );

    expect(c.pickup?.point, _bonanjo);
  });

  test('glisser plusieurs fois ne coûte qu\'un seul appel, à la fin', () async {
    final c = controller();

    c.onCameraIdle(_akwa);
    c.onCameraIdle(_bonanjo);
    c.onCameraIdle(_akwa);
    expect(geocode.reverseCalls, 0);

    await c.resolveActiveLabel();

    expect(geocode.reverseCalls, 1);
    expect(c.pickup?.label, 'Boulevard de la Liberté, Akwa');
  });

  test('valider le point en demande le libellé', () async {
    final c = controller();

    await place(c, _bonanjo);

    expect(geocode.reverseCalls, 1);
    expect(c.pickup?.point, _bonanjo);
    expect(c.pickup?.label, 'Rue Njo-Njo, Bonanjo');
    expect(c.text, 'Rue Njo-Njo, Bonanjo');
    expect(c.resolvingLabel, isFalse);
    expect(c.canResolveLabel, isFalse, reason: 'le libellé est là');
    expect(c.canConfirm, isFalse, reason: 'arrivée pas encore placée');
  });

  test('valider deux fois le même point ne rappelle pas le serveur', () async {
    final c = controller();

    await place(c, _bonanjo);
    await c.resolveActiveLabel();

    expect(geocode.reverseCalls, 1);
  });

  test('sans libellé trouvé, l\'utilisateur doit en saisir un', () async {
    final c = controller();
    geocode.labels[_bonanjo] = null;

    await place(c, _bonanjo);

    expect(c.labelNotFound, isTrue);
    expect(c.labelFailure, isNull, reason: 'un 200 n\'est pas une erreur');
    expect(c.pickup?.label, isEmpty);
    expect(
      c.canResolveLabel,
      isFalse,
      reason: 'rappeler la route rendrait la même réponse',
    );

    c.updateText('Immeuble Sawa');
    expect(c.pickup?.label, 'Immeuble Sawa');
    expect(c.pickup?.point, _bonanjo, reason: 'le point ne bouge pas');
    expect(c.canConfirm, isFalse, reason: 'arrivée pas encore placée');
  });

  test('géocodeur saturé : échec distinct, et réessayable', () async {
    final c = controller();
    geocode.reverseError = const ApiException(
      statusCode: 503,
      code: ApiErrorCode.geocodeBusy,
      message: 'trop de recherches',
    );

    await place(c, _bonanjo);

    expect((c.labelFailure as ApiException?)?.code, ApiErrorCode.geocodeBusy);
    expect(
      c.labelNotFound,
      isFalse,
      reason: 'une panne n\'est pas « aucune adresse ici »',
    );
    expect(c.pickup?.point, _bonanjo, reason: 'le point reste retenu');
    expect(c.canResolveLabel, isTrue, reason: 'réessayable');

    geocode.reverseError = null;
    await c.resolveActiveLabel();

    expect(c.labelFailure, isNull);
    expect(c.pickup?.label, 'Rue Njo-Njo, Bonanjo');
  });

  test('une réponse de libellé périmée est ignorée', () async {
    final c = controller();
    geocode.pendingLabel = Completer();
    final slow = geocode.pendingLabel!;

    c.onCameraIdle(_bonanjo);
    final first = c.resolveActiveLabel();
    geocode.pendingLabel = null;
    c.onCameraIdle(_akwa);
    await c.resolveActiveLabel();
    // La première recherche répond après la seconde position : ignorée.
    slow.complete('Obsolète');
    await first;

    expect(c.pickup?.point, _akwa);
    expect(c.pickup?.label, 'Boulevard de la Liberté, Akwa');
  });

  test('un zoom sans déplacement ne change pas le point', () async {
    final c = controller();
    await place(c, _bonanjo);
    final calls = geocode.reverseCalls;

    c.onCameraIdle(_bonanjo);

    expect(geocode.reverseCalls, calls);
    expect(c.pickup?.label, 'Rue Njo-Njo, Bonanjo', reason: 'libellé conservé');
  });

  test('trajet complet : départ puis arrivée, validation possible', () async {
    final c = controller();

    await place(c, _bonanjo);
    c.activate(AddressSlot.dropoff);
    await place(c, _akwa);

    expect(c.dropoff?.point, _akwa);
    expect(c.canConfirm, isTrue);
    expect(geocode.reverseCalls, 2, reason: 'un appel par point validé');
  });

  test(
    'taper ne lance aucune recherche : seul l\'appui la déclenche',
    () async {
      final c = controller();

      c.updateText('Ak');
      expect(c.canSearch, isFalse, reason: 'moins de 3 caractères');
      c.updateText('Akwa');
      await Future<void>.delayed(Duration.zero);
      expect(geocode.searchCalls, 0);
      expect(c.canSearch, isTrue);

      await c.search();
      expect(geocode.searchCalls, 1);
      expect(c.results.single.label, 'Akwa, Douala');
    },
  );

  test('choisir un résultat le place sans aucun géocodage inverse', () async {
    final c = controller();
    c.updateText('Akwa');
    await c.search();

    final target = c.pickResult(c.results.first);
    expect(target, _akwa);
    expect(c.results, isEmpty);
    // L'adresse reste active : l'utilisateur peut ajuster le repère.
    expect(c.active, AddressSlot.pickup);
    expect(c.pickup?.label, 'Akwa, Douala');
    // Le libellé vient déjà du serveur : le redemander serait un appel pour
    // rien sur un fournisseur limité à une requête par seconde.
    expect(c.canResolveLabel, isFalse);

    c.onCameraIdle(_akwa);
    expect(geocode.reverseCalls, 0);
    expect(c.pickup?.label, 'Akwa, Douala');
  });

  test('recherche sans résultat, puis recherche en échec', () async {
    final c = controller();

    c.updateText('Tombouctou');
    await c.search();
    expect(c.searchedWithoutResult, isTrue);

    geocode.searchError = const ApiException(
      statusCode: 503,
      code: ApiErrorCode.geocodingUnavailable,
      message: 'indisponible',
    );
    await c.search();
    expect(c.searchedWithoutResult, isFalse);
    expect(
      (c.searchFailure as ApiException?)?.code,
      ApiErrorCode.geocodingUnavailable,
    );
  });

  test('mode point unique : l\'arrivée n\'existe pas', () async {
    final c = controller(mode: PickerMode.singlePoint);

    expect(c.activate(AddressSlot.dropoff), isNull);
    await place(c, _bonanjo);

    expect(c.active, AddressSlot.pickup);
    expect(c.canConfirm, isTrue);
  });

  test('les favoris viennent du serveur et s\'enregistrent', () async {
    await session.signIn('aicha@camelia.test');
    final c = controller(mode: PickerMode.singlePoint);

    await c.loadFavorites();
    expect(c.favoritesAvailable, isTrue);
    expect(c.favorites, isEmpty);

    await place(c, _bonanjo);
    expect(await c.saveActiveAsFavorite('Maison'), isTrue);
    expect(c.favorites.single.label, 'Maison');

    final placed = c.pickFavorite(c.favorites.single);
    expect(placed, _bonanjo);
    expect(
      c.canResolveLabel,
      isFalse,
      reason: 'un favori porte déjà son libellé',
    );
  });

  test('une réponse après fermeture de l\'écran ne lève rien', () async {
    final c = controller();
    geocode.pendingLabel = Completer();
    c.onCameraIdle(_bonanjo);
    final pending = c.resolveActiveLabel();

    c.dispose();
    geocode.pendingLabel!.complete('Tard');
    await pending;
  });
}
