import 'package:camelia_logistics/screens/AdminPanel.dart';
import 'package:camelia_logistics/screens/HomeCustumer_Screen.dart';
import 'package:camelia_logistics/screens/OrderSummaryScreen.dart';
import 'package:camelia_logistics/screens/adminDashboard.dart';
import 'package:camelia_logistics/screens/adminDeliverers.dart';
import 'package:camelia_logistics/screens/auth_wrapper.dart';
import 'package:camelia_logistics/screens/change_informations.dart';
import 'package:camelia_logistics/screens/reset_password.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/order_state_model.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/order_screen.dart';
import 'screens/profil.dart';
import 'screens/history_screen.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// =======================================================
// 1. LOGIQUE DE REDIRECTION (LE PONT ENTRE LE PAYLOAD ET LA ROUTE)
// =======================================================

/// Interprète la clé 'screen' et navigue vers la route GoRouter correspondante.
void handleNotificationRedirect(RemoteMessage message, BuildContext context) {
  final data = message.data;
  final String? screenKey = data['screen'];
  final String? orderId = data['orderId'];

  // On s'assure d'avoir l'ID pour la navigation
  if (orderId == null) {
    print(
      'Notification reçue sans ID de commande. Redirection vers /home_custom.',
    );
    context.go('/home_custom'); // Rediriger vers la page d'accueil par défaut
    return;
  }

  switch (screenKey) {
    case 'client_order_waiting':
      // Route Client : Commande Validée
      context.go('/waiting/$orderId');
      break;

    case 'admin_orders_details':
      // Route Admin : Nouvelle Commande
      context.go('/orderDetailsAdmin/$orderId');
      break;

    default:
      // Fallback si la clé n'est pas reconnue
      context.go('/admin'); // Page admin par défaut
      break;
  }
}

// =======================================================
// 2. GESTION DES INTERACTIONS (SETUP)
// =======================================================

/// Configure les écouteurs de Firebase Messaging pour les 3 états de l'application.
void setupInteractions(BuildContext context) {
  // Wrapper pour lier le message au BuildContext nécessaire à GoRouter.
  void redirectWrapper(RemoteMessage message) {
    handleNotificationRedirect(message, context);
  }

  // --- ÉTAT 1 : TERMINATED (Application complètement fermée) ---
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      redirectWrapper(message);
    }
  });

  // --- ÉTAT 2 : BACKGROUND (Application en arrière-plan) ---
  FirebaseMessaging.onMessageOpenedApp.listen(redirectWrapper);

  // --- ÉTAT 3 : FOREGROUND (Application ouverte et active) ---
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Notification reçue en premier plan: ${message.notification?.title}');

    // Afficher un SnackBar pour alerter et proposer la navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.notification?.title ?? 'Nouvel événement'),
        action: SnackBarAction(
          label: 'VOIR',
          onPressed: () {
            // L'utilisateur clique sur l'action du SnackBar
            redirectWrapper(message);
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  });
}

// =======================================================
// 3. MAIN ET INITIALISATION (CORRIGÉS)
// =======================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // NOTE: On NE PEUT PAS appeler setupInteractions ici, car le BuildContext n'existe pas.

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ⭐️ SOLUTION: On utilise le NavigatorKey pour créer le GoRouter
    final GoRouter router = GoRouter(
      initialLocation: '/start',
      navigatorKey: navigatorKey, // Utilisation du GlobalKey ici
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/order',
          builder: (context, state) => const OrderScreen(),
        ),

        // Route Client (Devis/Attente)
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
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => OrderStateModel()),
        // ... autres providers
      ],
      child: MaterialApp.router(
        title: 'Camelia Logistics',
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: TextTheme(bodyLarge: GoogleFonts.montserrat()),
          primarySwatch: Colors.blue,
        ),
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
        print("Interactions de notification initialisées.");
      }
    });
    // Retourne un widget vide ou le widget de votre écran de démarrage
    return AuthWrapper();
  }
}
