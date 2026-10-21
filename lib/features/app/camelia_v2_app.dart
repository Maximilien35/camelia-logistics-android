/// Racine de l'application V2 : câble les dépendances, le thème et la langue.
///
/// Ordre de construction imposé par les dépendances :
/// `TokenStore` → `ApiClient` → `AuthService` → `AuthController`.
///
/// `ApiClient.onSessionExpired` pointe vers le contrôleur construit juste
/// après : la fermeture ne capture `_controller` qu'à l'appel, bien plus tard,
/// quand un rafraîchissement de jeton a échoué.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../../config/env.dart';
import '../../core/api/api_client.dart';
import '../../core/api/mock/mock_backend.dart';
import '../../core/api/mock/mock_social_sign_in.dart';
import '../../core/auth/token_store.dart';
import '../../core/platform/firebase_push_registrar.dart';
import '../../core/platform/push_registrar.dart';
import '../../core/platform/social_sign_in.dart';
import '../../core/storage/key_value_store.dart';
import '../client/services/address_service.dart';
import '../client/services/catalogue_service.dart';
import '../client/services/geocode_service.dart';
import '../client/services/order_service.dart';
import '../shared/services/device_service.dart';
import '../shared/services/emergency_service.dart';
import '../shared/services/profile_service.dart';
import '../driver/services/position_reporter.dart';
import '../driver/state/current_course_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../shared/routing/session_gate.dart';
import '../driver/services/driver_service.dart';
import '../shared/services/auth_service.dart';
import '../shared/services/wallet_service.dart';
import '../shared/state/auth_controller.dart';
import '../shared/state/onboarding_controller.dart';
import '../shared/state/push_controller.dart';

class CameliaV2App extends StatefulWidget {
  const CameliaV2App({super.key});

  @override
  State<CameliaV2App> createState() => _CameliaV2AppState();
}

class _CameliaV2AppState extends State<CameliaV2App> {
  late final TokenStore _tokenStore;
  late final ApiClient _client;
  late final AuthService _authService;
  late final AuthController _authController;
  late final DriverService _driverService;
  late final WalletService _walletService;
  late final OrderService _orderService;
  late final CurrentCourseStore _currentCourseStore;
  late final PositionReporter _positionReporter;
  late final ProfileService _profileService;
  late final AddressService _addressService;
  late final GeocodeService _geocodeService;
  late final CatalogueService _catalogueService;
  late final DeviceService _deviceService;
  late final EmergencyContactService _emergencyService;
  late final PushController _pushController;
  late final OnboardingController _onboarding;

  @override
  void initState() {
    super.initState();
    _tokenStore = TokenStore();
    _client = ApiClient(
      tokenStore: _tokenStore,
      onSessionExpired: () async => _authController.handleSessionExpired(),
      // Seul point de bascule entre données simulées et vrai backend : tout le
      // reste de l'app est identique dans les deux modes. `Env.useMockApi` est
      // verrouillé à `false` en build release.
      httpClient: Env.useMockApi ? MockBackend() : null,
    );
    _authService = AuthService(client: _client, tokenStore: _tokenStore);
    _authController = AuthController(
      service: _authService,
      // Le désenregistrement de l'appareil a besoin d'un jeton encore valide :
      // il part avant la révocation de la session (§ 7.7).
      beforeLogout: () => _pushController.detach(),
      // Google / Apple (`06c`, lot 8). Les boutons n'apparaissent que si le
      // build les configure (`GOOGLE_SERVER_CLIENT_ID`, `APPLE_SIGN_IN`).
      social: Env.useMockApi ? MockSocialSignIn() : PlatformSocialSignIn(),
    );
    _driverService = DriverService(client: _client);
    _walletService = WalletService(client: _client);
    _orderService = OrderService(client: _client);
    final keyValues = SharedPreferencesStore();
    _currentCourseStore = CurrentCourseStore(store: keyValues);
    // Lu pendant que la session se valide : l'écran d'attente couvre les deux.
    _onboarding = OnboardingController(store: keyValues)..load();
    _positionReporter = GeolocatorPositionReporter(service: _driverService);
    _profileService = ProfileService(client: _client);
    _addressService = AddressService(client: _client);
    _geocodeService = GeocodeService(client: _client);
    _catalogueService = CatalogueService(client: _client);
    _deviceService = DeviceService(client: _client);
    _emergencyService = EmergencyContactService(client: _client);
    _pushController = PushController(
      // En mode simulé, aucun jeton : l'app se comporte exactement comme sur
      // un appareil dont l'utilisateur a refusé les notifications — un cas
      // réel qu'il faut de toute façon savoir traiter.
      registrar: Env.useMockApi
          ? const NoPushRegistrar()
          : FirebasePushRegistrar(),
      service: _deviceService,
    );
  }

  @override
  void dispose() {
    _pushController.dispose();
    _onboarding.dispose();
    _authController.dispose();
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: _client),
        Provider<AuthService>.value(value: _authService),
        ChangeNotifierProvider<AuthController>.value(value: _authController),
        Provider<DriverService>.value(value: _driverService),
        Provider<WalletService>.value(value: _walletService),
        // Au-dessus de `MaterialApp` : les écrans du parcours de commande et de
        // la course sont poussés sur le navigateur racine, hors des coquilles.
        Provider<OrderService>.value(value: _orderService),
        Provider<CurrentCourseStore>.value(value: _currentCourseStore),
        Provider<PositionReporter>.value(value: _positionReporter),
        Provider<ProfileService>.value(value: _profileService),
        Provider<AddressService>.value(value: _addressService),
        // Géocodage serveur (§ 7.8) : utilisé par le seul écran de sélection
        // d'adresses (A4), jamais pour une distance ou un prix.
        Provider<GeocodeService>.value(value: _geocodeService),
        // Catalogue de configuration (§ 7.3.2) : véhicules, types de logement
        // et de manutention, tous traduits par le serveur — l'app n'en écrit
        // aucun en dur.
        Provider<CatalogueService>.value(value: _catalogueService),
        // Enregistrement de l'appareil pour les notifications (§ 7.7) : c'est
        // ce qui rend tenable l'absence de connexion persistante (règle n°5).
        Provider<DeviceService>.value(value: _deviceService),
        Provider<EmergencyContactService>.value(value: _emergencyService),
        ChangeNotifierProvider<PushController>.value(value: _pushController),
        ChangeNotifierProvider<OnboardingController>.value(value: _onboarding),
      ],
      // La langue suit la préférence du **serveur** (`User.language`), pas un
      // réglage purement local : elle suit donc l'utilisateur d'un appareil à
      // l'autre. Hors session, l'app suit la locale du système.
      child: Consumer<AuthController>(
        builder: (context, auth, _) {
          final language = auth.user?.language;
          return MaterialApp(
            title: 'Camelia Logistics',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            locale: language == null ? null : Locale(language.wire),
            supportedLocales: const [Locale('fr'), Locale('en')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SessionGate(),
            // Bandeau permanent en mode simulé : personne ne doit confondre une
            // fausse commande avec une vraie.
            builder: (context, child) => Env.useMockApi
                ? Banner(
                    message: 'DONNÉES SIMULÉES',
                    location: BannerLocation.topEnd,
                    color: AppColors.warning,
                    child: child ?? const SizedBox.shrink(),
                  )
                : (child ?? const SizedBox.shrink()),
          );
        },
      ),
    );
  }
}
