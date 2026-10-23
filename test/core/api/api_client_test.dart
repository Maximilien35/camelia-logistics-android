import 'dart:convert';

import 'package:camelia/config/env.dart';
import 'package:camelia/core/api/api_client.dart';
import 'package:camelia/core/api/api_exception.dart';
import 'package:camelia/core/auth/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Coffre en mémoire : évite le canal de plateforme de
/// `flutter_secure_storage`, indisponible sous `flutter test`.
class _FakeTokenStore extends TokenStore {
  _FakeTokenStore({String? access, String? refresh})
    : _access = access,
      _refresh = refresh;

  String? _access;
  String? _refresh;
  int clearCount = 0;

  @override
  Future<String?> readAccess() async => _access;

  @override
  Future<String?> readRefresh() async => _refresh;

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    _access = tokens.access;
    _refresh = tokens.refresh;
  }

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
    clearCount++;
  }
}

Map<String, String> _jsonHeaders() => {'content-type': 'application/json'};

void main() {
  group('URL et en-têtes', () {
    test('appelle la route sous /v1/ avec la barre oblique finale', () async {
      late Uri seen;
      final client = ApiClient(
        tokenStore: _FakeTokenStore(access: 'jeton-acces'),
        httpClient: MockClient((request) async {
          seen = request.url;
          return http.Response('{}', 200, headers: _jsonHeaders());
        }),
      );

      await client.get('me');

      expect(seen.path, '/v1/me/');
      expect(seen.toString(), '${Env.apiRoot}/me/');
    });

    test('pose Authorization: Bearer sur une requête authentifiée', () async {
      late Map<String, String> headers;
      final client = ApiClient(
        tokenStore: _FakeTokenStore(access: 'jeton-acces'),
        httpClient: MockClient((request) async {
          headers = request.headers;
          return http.Response('{}', 200, headers: _jsonHeaders());
        }),
      );

      await client.get('me');

      expect(headers['Authorization'], 'Bearer jeton-acces');
    });

    test('n\'envoie aucun jeton sur une route publique', () async {
      late Map<String, String> headers;
      final client = ApiClient(
        tokenStore: _FakeTokenStore(access: 'jeton-acces'),
        httpClient: MockClient((request) async {
          headers = request.headers;
          return http.Response('{}', 200, headers: _jsonHeaders());
        }),
      );

      // `GET /v1/track/{token}/` est en AllowAny côté backend.
      await client.get('track/abc123', authenticated: false);

      expect(headers.containsKey('Authorization'), isFalse);
    });
  });

  group('Erreurs', () {
    test('lève une ApiException portant le code du backend', () async {
      final client = ApiClient(
        tokenStore: _FakeTokenStore(access: 'a'),
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'code': 'invalid_order_transition',
              'message': 'Cette commande n\'est pas en attente de paiement.',
              'details': <String, dynamic>{},
            }),
            409,
            headers: _jsonHeaders(),
          );
        }),
      );

      await expectLater(
        client.post('orders/1/confirm-delivery'),
        throwsA(
          isA<ApiException>()
              .having(
                (e) => e.code,
                'code',
                ApiErrorCode.invalidOrderTransition,
              )
              .having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
    });

    test('décode l\'UTF-8 des messages accentués', () async {
      final client = ApiClient(
        tokenStore: _FakeTokenStore(access: 'a'),
        httpClient: MockClient((request) async {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'code': 'invalid_otp',
                'message': 'Code périmé ou déjà utilisé.',
                'details': <String, dynamic>{},
              }),
            ),
            400,
            headers: _jsonHeaders(),
          );
        }),
      );

      try {
        await client.post('auth/verify-otp', body: const {'email': 'a@b.c'});
        fail('aurait dû lever');
      } on ApiException catch (e) {
        expect(e.message, 'Code périmé ou déjà utilisé.');
      }
    });
  });

  group('Rafraîchissement du jeton', () {
    test('rejoue la requête après un 401 et garde la nouvelle paire', () async {
      final store = _FakeTokenStore(access: 'perime', refresh: 'refresh-1');
      final calls = <String>[];

      final client = ApiClient(
        tokenStore: store,
        httpClient: MockClient((request) async {
          final path = request.url.path;
          calls.add(path);
          if (path == '/v1/auth/refresh/') {
            return http.Response(
              jsonEncode({'access': 'neuf', 'refresh': 'refresh-2'}),
              200,
              headers: _jsonHeaders(),
            );
          }
          // Le premier passage voit encore l'ancien jeton.
          if (request.headers['Authorization'] == 'Bearer perime') {
            return http.Response(
              jsonEncode({
                'code': 'invalid_token',
                'message': '',
                'details': <String, dynamic>{},
              }),
              401,
              headers: _jsonHeaders(),
            );
          }
          return http.Response(
            jsonEncode({'id': 'u1', 'role': 'client'}),
            200,
            headers: _jsonHeaders(),
          );
        }),
      );

      final body = await client.get('me');

      expect(body['role'], 'client');
      expect(calls, ['/v1/me/', '/v1/auth/refresh/', '/v1/me/']);
      // Rotation serveur : l'ancien `refresh` est blacklisté, on garde le neuf.
      expect(await store.readAccess(), 'neuf');
      expect(await store.readRefresh(), 'refresh-2');
    });

    test(
      'ne déclenche qu\'un seul refresh pour plusieurs 401 simultanés',
      () async {
        final store = _FakeTokenStore(access: 'perime', refresh: 'refresh-1');
        var refreshCalls = 0;

        final client = ApiClient(
          tokenStore: store,
          httpClient: MockClient((request) async {
            if (request.url.path == '/v1/auth/refresh/') {
              refreshCalls++;
              return http.Response(
                jsonEncode({'access': 'neuf', 'refresh': 'refresh-2'}),
                200,
                headers: _jsonHeaders(),
              );
            }
            if (request.headers['Authorization'] == 'Bearer perime') {
              return http.Response(
                jsonEncode({
                  'code': 'invalid_token',
                  'message': '',
                  'details': <String, dynamic>{},
                }),
                401,
                headers: _jsonHeaders(),
              );
            }
            return http.Response('{}', 200, headers: _jsonHeaders());
          }),
        );

        await Future.wait([
          client.get('me'),
          client.get('driver/status'),
          client.get('driver/wallet'),
        ]);

        // Deux refresh en parallèle s'annuleraient : le second présenterait un
        // `refresh` déjà mis en liste noire par la rotation.
        expect(refreshCalls, 1);
      },
    );

    test('efface la session quand le refresh est refusé', () async {
      final store = _FakeTokenStore(access: 'perime', refresh: 'mort');
      var expired = 0;

      final client = ApiClient(
        tokenStore: store,
        onSessionExpired: () async => expired++,
        httpClient: MockClient((request) async {
          if (request.url.path == '/v1/auth/refresh/') {
            return http.Response(
              jsonEncode({
                'code': 'invalid_token',
                'message': '',
                'details': <String, dynamic>{},
              }),
              401,
              headers: _jsonHeaders(),
            );
          }
          return http.Response(
            jsonEncode({
              'code': 'invalid_token',
              'message': '',
              'details': <String, dynamic>{},
            }),
            401,
            headers: _jsonHeaders(),
          );
        }),
      );

      await expectLater(client.get('me'), throwsA(isA<ApiException>()));

      expect(store.clearCount, 1);
      expect(await store.readAccess(), isNull);
      expect(expired, 1);
    });

    test('ne rafraîchit pas une requête non authentifiée', () async {
      var refreshCalls = 0;
      final client = ApiClient(
        tokenStore: _FakeTokenStore(refresh: 'refresh-1'),
        httpClient: MockClient((request) async {
          if (request.url.path == '/v1/auth/refresh/') refreshCalls++;
          return http.Response(
            jsonEncode({
              'code': 'invalid_credentials',
              'message': '',
              'details': <String, dynamic>{},
            }),
            401,
            headers: _jsonHeaders(),
          );
        }),
      );

      await expectLater(
        client.post(
          'auth/login',
          body: const {'email': 'a@b.c', 'password': 'x'},
          authenticated: false,
        ),
        throwsA(isA<ApiException>()),
      );

      // Un mot de passe refusé n'est pas une session expirée.
      expect(refreshCalls, 0);
    });
  });

  group('Pagination', () {
    test('lit results, count, et les champs hors pagination', () async {
      final client = ApiClient(
        tokenStore: _FakeTokenStore(access: 'a'),
        httpClient: MockClient((request) async {
          expect(request.url.queryParameters['page_size'], '50');
          return http.Response(
            jsonEncode({
              'count': 2,
              'next': null,
              'previous': null,
              'results': [
                {'id': '1', 'entry_type': 'driver_credit', 'amount': '1500.00'},
                {'id': '2', 'entry_type': 'withdrawal', 'amount': '-2000.00'},
              ],
              // `GET /v1/driver/wallet/` ajoute `balance` à l'enveloppe.
              'balance': '12500.00',
            }),
            200,
            headers: _jsonHeaders(),
          );
        }),
      );

      final page = await client.getPage(
        'driver/wallet',
        (json) => json['id'] as String,
        pageSize: 50,
      );

      expect(page.count, 2);
      expect(page.results, ['1', '2']);
      expect(page.hasNext, isFalse);
      // Le solde vit au niveau racine, pas dans `results`.
      expect(page.envelope['balance'], '12500.00');
    });
  });

  group('Multipart', () {
    test('envoie les champs et la photo avec son type MIME', () async {
      late String body;
      late String contentType;
      final client = ApiClient(
        tokenStore: _FakeTokenStore(access: 'a'),
        httpClient: MockClient((request) async {
          contentType = request.headers['content-type'] ?? '';
          // MockClient remet une `http.Request` dont le corps multipart est
          // déjà finalisé : les octets sont lisibles directement.
          body = utf8.decode(request.bodyBytes, allowMalformed: true);
          return http.Response('{}', 201, headers: _jsonHeaders());
        }),
      );

      await client.multipart(
        'orders',
        fields: const {'service_type': 'delivery', 'package_weight_kg': '4.5'},
        files: [
          ApiFileField(
            field: 'package_photo',
            filename: 'colis.webp',
            bytes: const [1, 2, 3],
            contentType: 'image/webp',
          ),
        ],
      );

      expect(contentType, startsWith('multipart/form-data'));
      expect(body, contains('service_type'));
      expect(body, contains('package_photo'));
      expect(body, contains('image/webp'));
    });
  });
}
