import 'package:camelia/core/api/api_client.dart';
import 'package:camelia/core/api/mock/mock_backend.dart';
import 'package:camelia/core/auth/token_store.dart';
import 'package:camelia/features/shared/models/app_user.dart';
import 'package:camelia/features/shared/services/auth_service.dart';

/// Coffre en mémoire : `flutter_secure_storage` n'a pas de canal sous
/// `flutter test`.
class MemoryTokenStore extends TokenStore {
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

/// Vrais services branchés sur le faux serveur, sans latence.
///
/// Un seul serveur pour toute la session : se reconnecter avec un autre compte
/// conserve les commandes et les offres, comme deux téléphones parlant au même
/// backend.
class MockSession {
  MockSession()
    : backend = MockBackend(latency: Duration.zero),
      tokens = MemoryTokenStore() {
    client = ApiClient(tokenStore: tokens, httpClient: backend);
    auth = AuthService(client: client, tokenStore: tokens);
  }

  final MockBackend backend;
  final MemoryTokenStore tokens;
  late final ApiClient client;
  late final AuthService auth;

  Future<AppUser> signIn(String email) async {
    await auth.loginWithPassword(email: email, password: 'motdepasse8');
    return auth.fetchMe();
  }
}
