/// Coquille de l'expérience **client** : trois onglets et la barre basse.
///
/// On n'arrive ici que parce que `GET /v1/me/` a renvoyé `role: "client"`.
///
/// Onglets (décision produit du 13 septembre 2026 : **pas d'onglet
/// Portefeuille**, les paiements se font directement après livraison) :
/// - **Accueil** ouvre le parcours de commande et affiche les commandes en
///   cours ;
/// - **Commandes** affiche l'historique réel du compte (`GET /v1/orders/`,
///   livré par T5.5) — l'appareil ne retient plus rien d'un historique, il le
///   demande, ce qu'un changement de téléphone ne perd plus ;
/// - **Compte** : informations personnelles, adresses favorites, parrainage,
///   langue, déconnexion.
///
/// [IndexedStack] plutôt qu'un remplacement de page : on conserve l'état de
/// chaque onglet (position de défilement, saisie en cours) en passant d'un
/// onglet à l'autre, comme on l'attend d'une barre de navigation.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/widgets/camelia_bottom_bar.dart';
import '../services/order_service.dart';
import '../state/active_orders_controller.dart';
import '../state/order_history_controller.dart';
import 'account/client_account_tab.dart';
import 'client_home_tab.dart';
import 'orders/order_history_tab.dart';
import '../../../core/theme/app_icons.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _index = 0;

  /// Commandes en cours de l'accueil. Vit avec la coquille : l'état disparaît
  /// à la déconnexion, et l'identifiant du compte cloisonne le stockage local.
  late final ActiveOrdersController _activeOrders;

  /// Historique de l'onglet « Commandes ». Vit avec la coquille pour conserver
  /// l'onglet de filtre et la position de défilement d'un aller-retour à
  /// l'autre.
  late final OrderHistoryController _history;

  @override
  void initState() {
    super.initState();
    final service = context.read<OrderService>();
    _activeOrders = ActiveOrdersController(service: service);
    _history = OrderHistoryController(service: service);
  }

  @override
  void dispose() {
    _activeOrders.dispose();
    _history.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ActiveOrdersController>.value(
          value: _activeOrders,
        ),
        ChangeNotifierProvider<OrderHistoryController>.value(value: _history),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        // L'accueil gère lui-même la zone sûre du haut : son en-tête en
        // dégradé passe sous la barre d'état. Les autres onglets la gardent.
        body: IndexedStack(
          index: _index,
          children: [
            const ClientHomeTab(),
            const SafeArea(bottom: false, child: OrderHistoryTab()),
            SafeArea(
              bottom: false,
              // Les chiffres du compte se chargent à l'ouverture de l'onglet,
              // pas au lancement de l'app.
              child: ClientAccountTab(active: _index == 2),
            ),
          ],
        ),
        bottomNavigationBar: CameliaBottomBar(
          currentIndex: _index,
          onChanged: (i) => setState(() => _index = i),
          items: [
            BottomBarItem(
              label: l10n.navHome,
              icon: AppIcons.home,
              activeIcon: AppIcons.homeActive,
            ),
            BottomBarItem(
              label: l10n.navOrders,
              icon: AppIcons.orders,
              activeIcon: AppIcons.ordersActive,
            ),
            BottomBarItem(
              label: l10n.navAccount,
              icon: AppIcons.account,
              activeIcon: AppIcons.accountActive,
            ),
          ],
        ),
      ),
    );
  }
}
