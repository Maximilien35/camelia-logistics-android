// Contrat proposé C5 (`docs/backend-a-implementer.md`) : le service parle au
// faux serveur exactement comme il parlera au Django, routes et champs compris.

import 'package:camelia/core/api/api_exception.dart';
import 'package:camelia/features/client/services/geocode_service.dart';
import 'package:camelia/features/shared/models/geo_point.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/mock_session.dart';

void main() {
  late MockSession session;
  late GeocodeService geocode;

  setUp(() async {
    session = MockSession();
    geocode = GeocodeService(client: session.client);
    await session.signIn('aicha@camelia.test');
  });

  test('recherche : lieux avec libellé et coordonnées', () async {
    final results = await geocode.search('akwa');

    expect(results, hasLength(1));
    expect(results.single.label, 'Boulevard de la Liberté, Akwa, Douala');
    expect(
      results.single.point,
      const GeoPoint(latitude: 4.0503, longitude: 9.7005),
    );
  });

  test('recherche sans résultat : liste vide, pas une erreur', () async {
    expect(await geocode.search('Tombouctou'), isEmpty);
  });

  test('géocodeur indisponible : code exploitable geocoding_unavailable', () {
    expect(
      geocode.search('PANNE'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ApiErrorCode.geocodingUnavailable,
        ),
      ),
    );
  });

  test('libellé d\'un point proche d\'un lieu connu', () async {
    final label = await geocode.reverse(
      const GeoPoint(latitude: 4.0432, longitude: 9.6925),
    );
    expect(label, 'Rue Njo-Njo, Bonanjo, Douala');
  });

  test('point isolé : aucun libellé', () async {
    final label = await geocode.reverse(
      const GeoPoint(latitude: 6.5, longitude: 13.2),
    );
    expect(label, isNull);
  });

  test('les routes exigent une session, comme le reste de l\'API', () async {
    await session.tokens.clear();
    expect(geocode.search('akwa'), throwsA(isA<ApiException>()));
  });
}
