/// Coquille de l'expérience **chauffeur** : trois onglets et la barre basse.
///
/// On n'arrive ici que parce que `GET /v1/me/` a renvoyé `role: "driver"` —
/// jamais par un réglage local, jamais par une bascule dans l'app.
///
/// Les trois onglets de la maquette sont tous alimentés par des endpoints
/// existants :
/// - **Courses** : `GET /v1/driver/status/`, `POST /v1/driver/online/`,
///   `GET /v1/driver/offers/` (+ accept / decline), puis la course en cours
///   (`pickup-proof/`, `delivery-proof/`, `POST /v1/driver/position/`) ;
/// - **Gains** : `GET /v1/driver/wallet/`, `POST /v1/driver/wallet/withdraw/` ;
/// - **Profil** : `GET`/`PATCH /v1/me/`, `POST /v1/auth/logout/`.
///
/// Les contrôleurs sont créés **ici** et non au niveau de l'app : leur état
/// n'a de sens que dans l'expérience chauffeur, et il disparaît avec elle à la
/// déconnexion.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/services/wallet_service.dart';
import '../../shared/state/wallet_controller.dart';
import 'driver_profile_tab.dart';
import '../../shared/widgets/camelia_bottom_bar.dart';
import '../../shared/state/auth_controller.dart';
import '../../shared/widgets/wallet_view.dart';
import '../services/driver_service.dart';
import '../services/position_reporter.dart';
import '../state/course_controller.dart';
import '../state/current_course_store.dart';
import '../state/driver_controller.dart';
import '../state/position_heartbeat.dart';
import 'driver_earnings_summary_card.dart';
import 'driver_jobs_tab.dart';
import 'driver_order_history_screen.dart';
import '../../../core/theme/app_icons.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _index = 0;
  late final DriverController _driver;
  late final WalletController _wallet;
  late final CourseController _course;
  late final PositionHeartbeat _heartbeat;

  @override
  void initState() {
    super.initState();
    _heartbeat = PositionHeartbeat(reporter: context.read<PositionReporter>());
    _driver = DriverController(service: context.read<DriverService>())
      ..addListener(_syncHeartbeat);
    _wallet = WalletController(
      service: context.read<WalletService>(),
      kind: WalletKind.driver,
    );
    _course = CourseController(
      service: context.read<DriverService>(),
      store: context.read<CurrentCourseStore>(),
      positions: context.read<PositionReporter>(),
      userId: context.read<AuthController>().user?.id ?? '',
    )..addListener(_syncHeartbeat);
    _course.load();
  }

  /// Rythme des relevés de position calé sur l'état **renvoyé par le
  /// serveur** : en ligne d'après `GET /driver/status/`, course en cours
  /// d'après `GET /driver/orders/current/` (§ 6.9.1).
  void _syncHeartbeat() {
    _heartbeat.update(
      online: _driver.status?.isOnline ?? false,
      inCourse: _course.hasCourse,
    );
  }

  @override
  void dispose() {
    _driver.removeListener(_syncHeartbeat);
    _course.removeListener(_syncHeartbeat);
    _heartbeat.dispose();
    _driver.dispose();
    _wallet.dispose();
    _course.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DriverController>.value(value: _driver),
        ChangeNotifierProvider<WalletController>.value(value: _wallet),
        ChangeNotifierProvider<CourseController>.value(value: _course),
        ChangeNotifierProvider<PositionHeartbeat>.value(value: _heartbeat),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: [
              const DriverJobsTab(),
              WalletView(
                title: l10n.navEarnings,
                // Récapitulatif de période (§ 7.4.4) au-dessus du solde : deux
                // lectures différentes du même livre comptable, pas deux
                // représentations d'une même ressource.
                // Puis l'entrée vers l'historique des courses (§ 7.4.6) : le
                // portefeuille liste des écritures, pas des courses.
                header: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DriverEarningsSummaryCard(
                      service: context.read<DriverService>(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DriverHistoryEntryCard(
                      service: context.read<DriverService>(),
                    ),
                  ],
                ),
              ),
              const DriverProfileTab(),
            ],
          ),
        ),
        bottomNavigationBar: CameliaBottomBar(
          currentIndex: _index,
          onChanged: (i) => setState(() => _index = i),
          items: [
            BottomBarItem(
              label: l10n.navJobs,
              icon: AppIcons.jobs,
              activeIcon: AppIcons.jobsActive,
            ),
            BottomBarItem(
              label: l10n.navEarnings,
              icon: AppIcons.earnings,
              activeIcon: AppIcons.earningsActive,
            ),
            BottomBarItem(
              label: l10n.navProfile,
              icon: AppIcons.account,
              activeIcon: AppIcons.accountActive,
            ),
          ],
        ),
      ),
    );
  }
}
