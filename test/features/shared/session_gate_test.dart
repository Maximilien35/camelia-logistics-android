import 'dart:convert';

import 'package:camelia/core/api/api_client.dart';
import 'package:camelia/core/theme/app_icons.dart';
import 'package:camelia/core/auth/token_store.dart';
import 'package:camelia/core/storage/key_value_store.dart';
import 'package:camelia/features/client/services/address_service.dart';
import 'package:camelia/features/client/services/order_service.dart';
import 'package:camelia/features/driver/services/position_reporter.dart';
import 'package:camelia/features/driver/state/current_course_store.dart';
import 'package:camelia/features/client/screens/client_shell.dart';
import 'package:camelia/features/driver/screens/driver_profile_tab.dart';
import 'package:camelia/features/driver/screens/driver_shell.dart';
import 'package:camelia/features/shared/routing/session_gate.dart';
import 'package:camelia/features/shared/screens/auth/login_screen.dart';
import 'package:camelia/features/shared/screens/onboarding/onboarding_screen.dart';
import 'package:camelia/features/shared/screens/auth/unsupported_role_screen.dart';
import 'package:camelia/features/driver/services/driver_service.dart';
import 'package:camelia/features/shared/services/auth_service.dart';
import 'package:camelia/features/shared/services/wallet_service.dart';
import 'package:camelia/core/platform/push_registrar.dart';
import 'package:camelia/features/shared/services/device_service.dart';
import 'package:camelia/features/shared/services/emergency_service.dart';
import 'package:camelia/features/shared/state/auth_controller.dart';
import 'package:camelia/features/shared/state/onboarding_controller.dart';
import 'package:camelia/features/shared/state/push_controller.dart';
import 'package:camelia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

class _FakeTokenStore extends TokenStore {
  _FakeTokenStore({this.access});

  String? access;

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => access == null ? null : 'r';

  @override
  Future<void> saveTokens(AuthTokens tokens) async => access = tokens.access;

  @override
  Future<void> clear() async => access = null;
}

Map<String, dynamic> _me(String role) => {
  'id': 'u-1',
  'email': 'aicha@example.cm',
  'phone': '+237690000000',
  'first_name': 'Aïcha',
  'last_name': 'Ngono',
  'role': role,
  'language': 'fr',
  'email_verified': true,
  'created_at': '2026-09-12T10:04:00+01:00',
};

const _emptyPage = {
  'count': 0,
  'next': null,
  'previous': null,
  'results': <Map<String, dynamic>>[],
};

const _driverStatus = {
  'status': 'approved',
  'is_online': false,
  'vehicle_type': 'fourgonnette',
  'vehicle_plate': 'LT 4821 AB',
  'rating_average': '4.90',
  'rating_count': 12,
  'last_position_at': null,
  'documents': <Map<String, dynamic>>[],
};

const _ambassadorDashboard = {
  'balance': '0.00',
  'usage_count': 0,
  'conversion_count': 0,
  'total_earned': '0.00',
  'recent_conversions': <Map<String, dynamic>>[],
};

/// Monte `SessionGate` comme l'app réelle, mais avec un transport simulé.
///
/// [onboarding] : stockage du repère « présentation vue » — déjà vue par
/// défaut, pour que les tests d'aiguillage arrivent droit à la connexion.
///
/// [reduceMotion] : « Réduire les animations » du système. Activé par défaut :
/// l'onboarding anime en boucle tant qu'il est à l'écran, ce qui empêcherait
/// `pumpAndSettle` de jamais rendre la main. Désactivé, la fonction ne fait
/// qu'avancer l'horloge de quelques secondes.
Future<void> _pumpGate(
  WidgetTester tester, {
  String? storedToken,
  String role = 'client',
  MemoryKeyValueStore? onboarding,
  bool reduceMotion = true,
}) async {
  final onboardingStore =
      onboarding ??
      (MemoryKeyValueStore()..values[OnboardingController.storageKey] = '1');
  final onboardingController = OnboardingController(store: onboardingStore);
  await onboardingController.load();

  final store = _FakeTokenStore(access: storedToken);
  final client = ApiClient(
    tokenStore: store,
    // Réponses **par route**, comme le vrai serveur : renvoyer le même corps
    // partout faisait planter l'onglet Courses sur un statut illisible.
    httpClient: MockClient((request) async {
      final path = request.url.path;
      final body = switch (path) {
        '/v1/me/' => _me(role),
        '/v1/driver/status/' => _driverStatus,
        '/v1/driver/offers/' => _emptyPage,
        '/v1/driver/orders/current/' => _emptyPage,
        '/v1/orders/' => _emptyPage,
        '/v1/me/addresses/' => _emptyPage,
        '/v1/driver/earnings/summary/' => {
          'period': 'week',
          'period_start': '2026-09-21T00:00:00+01:00',
          'period_end': '2026-09-28T00:00:00+01:00',
          'total_earned': '0.00',
          'trip_count': 0,
          'currency': 'XAF',
        },
        '/v1/driver/wallet/' => {..._emptyPage, 'balance': '0.00'},
        '/v1/me/ambassador-code/' => _ambassadorDashboard,
        _ => {'detail': 'ok'},
      };
      return http.Response.bytes(
        utf8.encode(jsonEncode(body)),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
  final controller = AuthController(
    service: AuthService(client: client, tokenStore: store),
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: controller),
        // Les coquilles construisent leurs propres contrôleurs depuis ces
        // services, exactement comme dans l'app réelle.
        Provider<DriverService>.value(value: DriverService(client: client)),
        Provider<WalletService>.value(value: WalletService(client: client)),
        Provider<OrderService>.value(value: OrderService(client: client)),
        Provider<AddressService>.value(value: AddressService(client: client)),
        Provider<EmergencyContactService>.value(
          value: EmergencyContactService(client: client),
        ),
        // Aucun jeton push en test : comme un appareil qui a refusé les
        // notifications, cas réel que l'app doit savoir traiter.
        ChangeNotifierProvider<PushController>.value(
          value: PushController(
            registrar: const NoPushRegistrar(),
            service: DeviceService(client: client),
          ),
        ),
        Provider<CurrentCourseStore>.value(
          value: CurrentCourseStore(store: MemoryKeyValueStore()),
        ),
        Provider<PositionReporter>.value(value: const NoopPositionReporter()),
        ChangeNotifierProvider<OnboardingController>.value(
          value: onboardingController,
        ),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('en')],
        locale: const Locale('fr'),
        home: const SessionGate(),
      ),
    ),
  );
  // Laisse passer le `addPostFrameCallback` du bootstrap puis sa réponse.
  if (reduceMotion) {
    await tester.pumpAndSettle();
  } else {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

void main() {
  testWidgets('sans session stockée, ouvre l\'écran de connexion', (
    tester,
  ) async {
    await _pumpGate(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(ClientShell), findsNothing);
    expect(find.byType(DriverShell), findsNothing);
  });

  testWidgets('role "client" ouvre l\'expérience client', (tester) async {
    await _pumpGate(tester, storedToken: 'bon', role: 'client');

    expect(find.byType(ClientShell), findsOneWidget);
    expect(find.byType(DriverShell), findsNothing);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('role "driver" ouvre l\'expérience chauffeur', (tester) async {
    await _pumpGate(tester, storedToken: 'bon', role: 'driver');

    expect(find.byType(DriverShell), findsOneWidget);
    expect(find.byType(ClientShell), findsNothing);
  });

  testWidgets('role "admin" n\'ouvre aucune des deux expériences', (
    tester,
  ) async {
    await _pumpGate(tester, storedToken: 'bon', role: 'admin');

    expect(find.byType(UnsupportedRoleScreen), findsOneWidget);
    expect(find.byType(ClientShell), findsNothing);
    expect(find.byType(DriverShell), findsNothing);
  });

  testWidgets('la déconnexion depuis le dernier onglet ramène à la connexion', (
    tester,
  ) async {
    await _pumpGate(tester, storedToken: 'bon', role: 'driver');
    expect(find.byType(DriverShell), findsOneWidget);

    // La déconnexion vit dans l'onglet « Profil » : on y va par la barre basse,
    // ce qui éprouve au passage la navigation entre onglets.
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    // La déconnexion est en bas du profil : on fait défiler comme un
    // utilisateur, la liste ne construit pas ce qui est hors écran.
    await tester.scrollUntilVisible(
      find.byIcon(AppIcons.logout),
      300,
      scrollable: find.descendant(
        of: find.byType(DriverProfileTab),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byIcon(AppIcons.logout));
    await tester.pumpAndSettle();

    // C'est le garde-fou du bug corrigé : si `user` n'était pas vidé,
    // `destination` renverrait encore « driver » et l'écran resterait ouvert.
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(DriverShell), findsNothing);
  });

  group('présentation (onboarding)', () {
    testWidgets('premier lancement sans session : présentation, puis '
        'connexion une fois « Passer » touché', (tester) async {
      final store = MemoryKeyValueStore();
      await _pumpGate(tester, onboarding: store);

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      // Retenue pour les lancements suivants.
      expect(store.values[OnboardingController.storageKey], '1');
    });

    testWidgets('les quatre pages se parcourent jusqu\'à « Commencer »', (
      tester,
    ) async {
      await _pumpGate(tester, onboarding: MemoryKeyValueStore());

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Suivant'), findsNothing);
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('une session valide ne repasse jamais par la présentation', (
      tester,
    ) async {
      await _pumpGate(
        tester,
        storedToken: 'bon',
        onboarding: MemoryKeyValueStore(),
      );

      expect(find.byType(ClientShell), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    });

    testWidgets('les animations tournent sans erreur, page après page', (
      tester,
    ) async {
      await _pumpGate(
        tester,
        onboarding: MemoryKeyValueStore(),
        reduceMotion: false,
      );
      expect(find.byType(OnboardingScreen), findsOneWidget);

      for (var page = 0; page < 4; page++) {
        // Un cycle complet de l'illustration la plus longue.
        for (var i = 0; i < 60; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (page < 3) {
          await tester.fling(
            find.byType(PageView),
            const Offset(-400, 0),
            1200,
          );
          for (var i = 0; i < 10; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }
      }
      expect(tester.takeException(), isNull);
      expect(find.text('Commencer'), findsOneWidget);
    });
  });

  testWidgets('l\'œil du mot de passe affiche puis masque la saisie', (
    tester,
  ) async {
    await _pumpGate(tester);

    TextField password() => tester.widget<TextField>(
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            (w.autofillHints?.contains(AutofillHints.password) ?? false),
      ),
    );

    expect(password().obscureText, isTrue);
    await tester.tap(find.byTooltip('Afficher le mot de passe'));
    await tester.pumpAndSettle();
    expect(password().obscureText, isFalse);
    await tester.tap(find.byTooltip('Masquer le mot de passe'));
    await tester.pumpAndSettle();
    expect(password().obscureText, isTrue);
  });
}
