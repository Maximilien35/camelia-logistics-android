// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:camelia/screens/admin_panel.dart';
import 'package:camelia/screens/home_custumer_screen.dart';
import 'package:camelia/screens/order_summary_screen.dart';
import 'package:camelia/screens/admin_dashboard.dart';
import 'package:camelia/screens/admin_deliverers.dart';
import 'package:camelia/screens/admin_assign_staff.dart';
import 'package:camelia/screens/auth_wrapper.dart';
import 'package:camelia/screens/change_informations.dart';
import 'package:camelia/screens/reset_password.dart';
import 'package:camelia/screens/collaborator/collaborator_auth_screen.dart';
import 'package:camelia/screens/collaborator/collaborator_home_screen.dart';
import 'package:camelia/screens/collaborator/collaborator_orders_screen.dart';
import 'package:camelia/screens/collaborator/collaborator_order_detail_screen.dart';
import 'package:camelia/models/collaborator_state_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camelia/models/services/user_profile_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'models/services/local_notification_service.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/order_state_model.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/order_screen.dart';
import 'screens/profil.dart';
import 'screens/history_screen.dart';
import 'package:provider/provider.dart';
import 'package:camelia/l10n/app_localizations.dart';
import 'providers/language_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void handleNotificationRedirect(RemoteMessage message, BuildContext context) {
  final data = message.data;
  final String? screenKey = data['screen'];
  final String? orderId = data['orderId'];

  if (orderId == null) {
    context.go('/home_custom');
    return;
  }

  switch (screenKey) {
    case 'client_order_waiting':
      context.go('/waiting/$orderId');
      break;

    case 'admin_orders_details':
      context.go('/orderDetailsAdmin/$orderId');
      break;

    default:
      context.go('/admin'); // Page admin par défaut
      break;
  }
}

Future<void> setupInteractions(BuildContext context) async {
  await LocalNotificationService.init();
  NotificationSettings settings = await FirebaseMessaging.instance
      .requestPermission(alert: true, badge: true, sound: true);

  // Permet d'afficher les notifications (Alert, Badge, Son) même si l'app est au premier plan
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    String? token = await FirebaseMessaging.instance.getToken();
    final user = FirebaseAuth.instance.currentUser;
    if (token != null && user != null) {
      await UserProfileService().saveFCMToken(user.uid, token);
    }

    await FirebaseMessaging.instance.subscribeToTopic('global_marketing');

    // 3. Écouter les changements de token
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (user != null) {
        UserProfileService().saveFCMToken(user.uid, newToken);
      }
    });
  }

  void redirectWrapper(RemoteMessage message) {
    handleNotificationRedirect(message, context);
  }

  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      redirectWrapper(message);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen(redirectWrapper);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final l10n = AppLocalizations.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.notification?.title ?? l10n?.newEvent ?? 'New Event',
        ),
        action: SnackBarAction(
          label: l10n?.view ?? 'VIEW',
          onPressed: () {
            // L'utilisateur clique sur l'action du SnackBar
            // redirectWrapper(message);
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  });
}

// Handler pour les notifications en arrière-plan (Doit être en top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseAppCheck.instance.activate(
    androidProvider: kReleaseMode
        ? AndroidProvider.playIntegrity
        : AndroidProvider.debug,
    appleProvider: AppleProvider.appAttest,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Configuration du Router (inchangée)
    final GoRouter router = GoRouter(
      initialLocation: '/start',
      navigatorKey: navigatorKey,
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/order',
          builder: (context, state) => const OrderScreen(),
        ),

        GoRoute(
          path: '/waiting/:orderId',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId']!;
            return OrderSummaryScreen(orderId: orderId);
          },
        ),

        GoRoute(
          path: '/profil',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/start',
          builder: (context, state) => const NotificationInitializer(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const AuthWrapper(),
        ),
        GoRoute(
          path: '/home_custom',
          builder: (context, state) => const HomeCustumerScreen(),
        ),
        GoRoute(path: '/admin', builder: (context, state) => const AdminPage()),
        GoRoute(
          path: '/adminDashboard',
          builder: (context, state) => const AdminDashboard(),
        ),
        GoRoute(
          path: '/adminDeliverers',
          builder: (context, state) => const AdminDeliverersScreen(),
        ),
        GoRoute(
          path: '/reset',
          builder: (context, state) => const ResetPassword(),
        ),
        GoRoute(
          path: '/change',
          builder: (context, state) => const ChangeInformations(),
        ),
        // Route Admin (Détails Commande)
        GoRoute(
          path: '/orderDetailsAdmin/:orderId',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId']!;
            return OrderDetailsAdminScreen(orderId: orderId);
          },
        ),
        GoRoute(
          path: '/admin/assign/:orderId',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId']!;
            return AdminAssignStaffScreen(orderId: orderId);
          },
        ),

        // Routes Collaborateur
        GoRoute(
          path: '/collaborator/login',
          builder: (context, state) => const CollaboratorAuthScreen(),
        ),
        GoRoute(
          path: '/collaborator/home',
          builder: (context, state) => const CollaboratorHomeScreen(),
        ),
        GoRoute(
          path: '/collaborator/orders',
          builder: (context, state) => const CollaboratorOrdersScreen(),
        ),
        GoRoute(
          path: '/collaborator/order-detail',
          builder: (context, state) => const CollaboratorOrderDetailScreen(),
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => OrderStateModel()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => CollaboratorStateModel()),
        // ... autres providers
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp.router(
            title: 'Camelia Logistics',
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            locale: languageProvider.currentLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
              textTheme: TextTheme(bodyLarge: GoogleFonts.montserrat()),
            ),
          );
        },
      ),
    );
  }
}

class NotificationInitializer extends StatelessWidget {
  const NotificationInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    // Utiliser addPostFrameCallback pour s'assurer que le widget est rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // On s'assure que le BuildContext du Navigator est prêt
      final context = navigatorKey.currentState?.context;
      if (context != null) {
        setupInteractions(context);
      }
    });
    return AuthWrapper();
  }
}
