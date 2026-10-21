/// Racine de l'expérience V2 : décide quel arbre afficher selon la session.
///
/// C'est le « routeur racine qui aiguille après authentification » demandé par
/// CLAUDE.md § Architecture. La destination vient de [AuthController.destination],
/// lui-même dérivé du `role` renvoyé par `GET /v1/me/` — aucun autre chemin
/// n'existe pour atteindre l'expérience chauffeur.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../client/screens/client_shell.dart';
import '../../driver/screens/driver_shell.dart';
import '../routing/role_destination.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/unsupported_role_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../state/auth_controller.dart';
import '../state/onboarding_controller.dart';
import '../state/push_controller.dart';
import '../widgets/entrance.dart';
import '../widgets/transport_motion.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  SessionStatus? _lastStatus;

  /// Enregistre l'appareil pour les notifications dès qu'une session s'ouvre
  /// (§ 7.7). Le désenregistrement, lui, part **avant** la révocation de la
  /// session (`AuthController.beforeLogout`), faute de quoi il n'aurait plus
  /// de jeton d'accès valide.
  void _syncPush(SessionStatus status) {
    if (status == _lastStatus) return;
    _lastStatus = status;
    if (status == SessionStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<PushController>().attach();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Valide la session stockée contre le serveur avant de choisir l'écran.
    // `addPostFrameCallback` : `bootstrap` notifie ses écouteurs, ce qui est
    // interdit pendant la construction de l'arbre.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthController>().bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    _syncPush(auth.status);

    final onboarding = context.watch<OnboardingController>();

    final Widget screen = switch (auth.status) {
      SessionStatus.unknown => const _SessionLoading(),
      // La présentation précède la connexion, une seule fois par appareil.
      // Elle n'ouvre aucune expérience : seul le `role` du serveur le fait.
      SessionStatus.unauthenticated => switch (onboarding.seen) {
        null => const _SessionLoading(),
        false => OnboardingScreen(onDone: onboarding.complete),
        true => const LoginScreen(),
      },
      SessionStatus.authenticated => switch (auth.destination) {
        RoleDestination.client => const ClientShell(),
        RoleDestination.driver => const DriverShell(),
        // `unsupported` (compte admin) ou, théoriquement, destination absente :
        // dans les deux cas on n'ouvre aucune expérience par défaut.
        _ => const UnsupportedRoleScreen(),
      },
    };

    // Fondu entre deux états de session (démarrage → présentation →
    // connexion → app) plutôt qu'une coupure sèche.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(key: ValueKey(screen.runtimeType), child: screen),
    );
  }
}

/// Écran d'attente du démarrage, le temps de valider la session.
///
/// Fond blanc, comme l'écran natif qui le précède : pas de flash de couleur
/// au passage. La marque se pose, puis un camion « roule » sous elle tant que
/// le serveur n'a pas répondu.
class _SessionLoading extends StatelessWidget {
  const _SessionLoading();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Entrance(offset: 10, child: BrandMark(size: 88)),
            const SizedBox(height: AppSpacing.xl),
            Entrance(
              index: 1,
              child: Text.rich(
                TextSpan(
                  text: l10n.authBrandName,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w800,
                    fontSize: AppFontSize.display,
                    color: AppColors.ink,
                  ),
                  children: [
                    TextSpan(
                      text: ' ${l10n.authBrandTagline}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            const Entrance(index: 2, child: RoadLoader()),
            const SizedBox(height: AppSpacing.md),
            Entrance(
              index: 3,
              child: Text(
                l10n.authLoadingSession,
                style: const TextStyle(
                  fontSize: AppFontSize.label,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
