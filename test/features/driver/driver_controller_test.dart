import 'package:camelia/core/api/api_client.dart';
import 'package:camelia/core/api/mock/mock_backend.dart';
import 'package:camelia/core/auth/token_store.dart';
import 'package:camelia/features/driver/models/driver_status.dart';
import 'package:camelia/features/driver/services/driver_service.dart';
import 'package:camelia/features/driver/state/driver_controller.dart';
import 'package:camelia/features/shared/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTokenStore extends TokenStore {
  String? access;
  String? refresh;

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    access = tokens.access;
    refresh = tokens.refresh;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

void main() {
  late DriverController controller;

  setUp(() async {
    final store = _FakeTokenStore();
    final client = ApiClient(
      tokenStore: store,
      httpClient: MockBackend(latency: Duration.zero),
    );
    await AuthService(client: client, tokenStore: store).loginWithPassword(
      email: 'jeanpaul@camelia.test',
      password: 'motdepasse8',
    );
    controller = DriverController(service: DriverService(client: client));
  });

  test('dépose une pièce puis relit le statut du serveur', () async {
    await controller.refresh();
    expect(controller.status, isNotNull);

    final ok = await controller.uploadDocument(
      DriverDocumentType.idCard,
      const ApiFileField(
        field: 'photo',
        filename: 'cni.jpg',
        bytes: [1, 2, 3],
        contentType: 'image/jpeg',
      ),
    );

    expect(ok, isTrue);
    expect(controller.failure, isNull);
    expect(controller.uploadingDocument, isNull);
    expect(
      controller.status!.documents.map((d) => d.type),
      contains(DriverDocumentType.idCard),
    );
  });
}
