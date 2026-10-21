/// Onglet **Commandes** — maquettes « Historique » (rempli et vide), revues par
/// la refonte UI d'octobre 2026.
///
/// Alimenté par `GET /v1/orders/` (§ 7.3.4, T5.5). Jusqu'au lot 5 cet onglet
/// affichait la route manquante plutôt qu'une liste ; il affiche désormais
/// l'historique réel du compte, `draft` compris.
///
/// Trois onglets de filtre, composés **côté app** : le serveur n'a pas de
/// notion de famille de statuts, il accepte une liste de statuts répétée et
/// refuse en `400` tout statut qu'il ne connaît pas. Le découpage « en cours »
/// / « terminées » est donc une décision d'affichage assumée ici, pas une
/// règle métier dupliquée.
///
/// La ligne de liste est volontairement pauvre (dix clés) : pas de ruban, pas
/// de coordonnées, pas de média. Toucher une ligne ouvre le suivi, qui relit
/// la commande par `GET /v1/orders/{id}/`.
///
/// **Refonte UI** : chaque commande est un **bordereau** clair (en-tête,
/// perforation, trajet départ → arrivée) au lieu de la carte noire de
/// l'accueil répétée en liste — la carte sombre reste réservée à ce qui est
/// en cours. Commandes regroupées par jour puis par mois, filtres en pastille
/// glissante, squelettes au chargement, écran vide illustré.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_error_messages.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/models/order.dart';
import '../../../shared/widgets/entrance.dart';
import '../../../shared/widgets/expand_to_screen.dart';
import '../../../shared/widgets/money.dart';
import '../../../shared/widgets/order_labels.dart';
import '../../../shared/widgets/pill_segmented_control.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/route_decoration.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../models/order_summary.dart';
import '../../state/order_history_controller.dart';
import '../order/order_addresses_screen.dart';
import '../order/order_tracking_screen.dart';

class OrderHistoryTab extends StatefulWidget {
  const OrderHistoryTab({super.key});

  @override
  State<OrderHistoryTab> createState() => _OrderHistoryTabState();
}

class _OrderHistoryTabState extends State<OrderHistoryTab> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderHistoryController>().refresh();
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining = _scroll.position.maxScrollExtent - _scroll.offset;
    if (remaining < 400) context.read<OrderHistoryController>().loadMore();
  }

  /// Vrai tant que la liste affichée n'a pas encore joué sa cascade
  /// d'entrée. Relevé à chaque changement de filtre : la nouvelle liste entre
  /// à son tour ; les lignes qui reviennent au défilement, elles, ne rejouent
  /// rien.
  bool _cascadePending = true;
  OrderHistoryFilter? _cascadeFilter;

  bool _takeCascade() {
    if (!_cascadePending) return false;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _cascadePending = false,
    );
    return true;
  }

  Future<void> _newOrder() async {
    final history = context.read<OrderHistoryController>();
    await startOrderFlow(context, ServiceType.delivery);
    await history.refresh();
  }

  String _emptyBody(AppLocalizations l10n, OrderHistoryFilter filter) =>
      switch (filter) {
        OrderHistoryFilter.all => l10n.ordersEmptyBody,
        OrderHistoryFilter.ongoing => l10n.ordersEmptyOngoing,
        OrderHistoryFilter.finished => l10n.ordersEmptyFinished,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final history = context.watch<OrderHistoryController>();
    if (history.filter != _cascadeFilter || !history.hasLoaded) {
      _cascadeFilter = history.filter;
      _cascadePending = true;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.screenPadding,
            AppSpacing.xl,
            AppDimens.screenPadding,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Entrance(
                child: Text(
                  l10n.ordersTitle,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w800,
                    fontSize: AppFontSize.display,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              // Compte du serveur pour le filtre courant ; rien tant que la
              // première page n'est pas arrivée, plutôt qu'un « 0 » trompeur.
              AnimatedOpacity(
                opacity: history.hasLoaded ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  l10n.ordersCount(history.total),
                  style: const TextStyle(
                    fontSize: AppFontSize.label,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Entrance(
                index: 1,
                child: PillSegmentedControl<OrderHistoryFilter>(
                  segments: [
                    (OrderHistoryFilter.all, l10n.ordersFilterAll),
                    (OrderHistoryFilter.ongoing, l10n.ordersFilterOngoing),
                    (OrderHistoryFilter.finished, l10n.ordersFilterFinished),
                  ],
                  selected: history.filter,
                  onChanged: history.select,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: history.refresh,
            color: AppColors.brand,
            child: _Body(
              history: history,
              scroll: _scroll,
              l10n: l10n,
              emptyBody: _emptyBody(l10n, history.filter),
              // Inviter à commander n'a de sens que sur « Toutes » : un filtre
              // vide ne dit pas que le compte n'a jamais rien commandé.
              onNewOrder: history.filter == OrderHistoryFilter.all
                  ? _newOrder
                  : null,
              cascade: _takeCascade,
            ),
          ),
        ),
      ],
    );
  }
}

/// Élément de liste : un intertitre de période ou une commande.
sealed class _Item {}

class _Header extends _Item {
  _Header(this.label);
  final String label;
}

class _Row extends _Item {
  _Row(this.summary);
  final OrderSummary summary;
}

class _Body extends StatelessWidget {
  const _Body({
    required this.history,
    required this.scroll,
    required this.l10n,
    required this.emptyBody,
    required this.onNewOrder,
    required this.cascade,
  });

  final OrderHistoryController history;
  final ScrollController scroll;
  final AppLocalizations l10n;
  final String emptyBody;
  final VoidCallback? onNewOrder;

  /// Demandé à chaque ligne construite : vrai seulement pendant la première
  /// image d'une liste fraîchement affichée.
  final bool Function() cascade;

  /// Seules les premières lignes entrent en cascade ; au-delà, elles sont
  /// hors de l'écran au premier affichage.
  static const int _cascadeRows = 7;

  /// Regroupe par jour (« Aujourd'hui », « Hier ») puis par mois. Le serveur
  /// trie déjà en `-created_at` : on ne fait qu'insérer des intertitres.
  List<_Item> _grouped(String locale) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final items = <_Item>[];
    String? last;
    for (final summary in history.orders) {
      final local = summary.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final label = switch (today.difference(day).inDays) {
        0 => l10n.ordersGroupToday,
        1 => l10n.ordersGroupYesterday,
        _ => toBeginningOfSentenceCase(
          DateFormat.yMMMM(locale).format(local),
          locale,
        ),
      };
      if (label != last) {
        items.add(_Header(label));
        last = label;
      }
      items.add(_Row(summary));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (history.loading && !history.hasLoaded) return const _LoadingTickets();

    if (!history.hasLoaded && history.failure != null) {
      return _EmptyState(
        icon: AppIcons.offline,
        title: l10n.ordersLoadErrorTitle,
        body: messageForFailure(l10n, history.failure!),
        actionLabel: l10n.commonRetry,
        onAction: history.refresh,
      );
    }

    if (history.isEmpty) {
      return _EmptyState(
        icon: AppIcons.truck,
        title: l10n.ordersEmptyTitle,
        body: emptyBody,
        actionLabel: onNewOrder == null ? null : l10n.ordersEmptyCta,
        onAction: onNewOrder,
      );
    }

    final locale = Localizations.localeOf(context).languageCode;
    final items = _grouped(locale);

    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(
        AppDimens.screenPadding,
        0,
        AppDimens.screenPadding,
        AppSpacing.xxl,
      ),
      itemCount: items.length + (history.hasNext ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return const Padding(
            padding: EdgeInsets.only(top: AppSpacing.md),
            child: _LoadingTickets(count: 1, scrollable: false),
          );
        }
        final animate = index < _cascadeRows && cascade();
        final item = switch (items[index]) {
          _Header(:final label) => Padding(
            padding: EdgeInsets.only(
              top: index == 0 ? AppSpacing.xs : AppSpacing.xl,
              bottom: AppSpacing.md,
            ),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: AppFontSize.micro,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
                color: AppColors.inkDisabled,
              ),
            ),
          ),
          _Row(:final summary) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _OrderTicket(summary: summary, onClosed: history.refresh),
          ),
        };
        return Entrance(
          key: ValueKey(switch (items[index]) {
            _Header(:final label) => 'h:$label',
            _Row(:final summary) => 'o:${summary.id}',
          }),
          index: index,
          enabled: animate,
          child: item,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Bordereau de commande
// ---------------------------------------------------------------------------

class _OrderTicket extends StatelessWidget {
  const _OrderTicket({required this.summary, required this.onClosed});

  final OrderSummary summary;

  /// Retour du suivi : le statut a pu changer (paiement, annulation, note).
  final VoidCallback onClosed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final created = summary.createdAt.toLocal();
    final when =
        '${DateFormat.MMMd(locale).format(created)} · '
        '${DateFormat.Hm(locale).format(created)}';

    // Le bordereau grandit jusqu'à devenir l'écran de suivi.
    return ExpandToScreen(
      closedColor: AppColors.white,
      radius: AppRadii.sheet,
      onClosed: onClosed,
      openBuilder: (_) => OrderTrackingScreen(orderId: summary.id),
      closedBuilder: (context, open) => Pressable(
        onTap: open,
        child: _TicketShape(
          // L'ombre est portée par le conteneur d'ouverture, qui rogne tout ce
          // qui dépasse de la carte.
          shadow: false,
          top: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brandTint,
                  borderRadius: BorderRadius.circular(AppRadii.small),
                ),
                child: Icon(
                  serviceIcon(summary.serviceType),
                  size: 22,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${summary.reference}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: AppFontSize.bodyLarge,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${serviceLabel(l10n, summary.serviceType)} · $when',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusPill(
                color: statusColor(summary.status),
                // Libellé du serveur en repli : l'app ne porte aucun libellé en
                // dur pour un statut qu'elle ne connaîtrait pas.
                label: statusLabelFor(
                  l10n,
                  summary.status,
                  fallback: summary.statusLabel ?? summary.rawStatus,
                ),
              ),
            ],
          ),
          bottom: RouteStops(
            pickup: summary.pickupAddress,
            dropoff: summary.dropoffAddress,
            // Total du serveur, jamais recomposé (règle n°3) ; absent sur un
            // devis manuel resté en `draft`.
            trailing: summary.priceTotal == null
                ? null
                : Text(
                    formatAmount(summary.priceTotal, locale: locale),
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w800,
                      fontSize: AppFontSize.bodyLarge,
                      color: AppColors.ink,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Silhouette de bordereau : deux volets séparés par une perforation en
/// pointillés, avec une encoche de chaque côté — comme un ticket détachable.
class _TicketShape extends StatelessWidget {
  const _TicketShape({
    required this.top,
    required this.bottom,
    this.shadow = true,
  });

  final Widget top;
  final Widget bottom;

  /// Faux quand un conteneur parent porte déjà l'ombre.
  final bool shadow;

  static const double _notch = 16;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.sheet),
        boxShadow: shadow ? AppShadows.card : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: top,
          ),
          SizedBox(
            height: _notch,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(
                  left: _notch,
                  right: _notch,
                  child: CustomPaint(
                    painter: DashedLinePainter(
                      color: AppColors.border,
                      dash: 6,
                      gap: 5,
                      strokeWidth: 1.5,
                    ),
                  ),
                ),
                for (final left in [true, false])
                  Positioned(
                    left: left ? -_notch / 2 : null,
                    right: left ? null : -_notch / 2,
                    child: Container(
                      width: _notch,
                      height: _notch,
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: bottom,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(AppRadii.badge + 4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xs + 1),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppFontSize.micro,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chargement et états vides
// ---------------------------------------------------------------------------

class _LoadingTickets extends StatelessWidget {
  const _LoadingTickets({this.count = 3, this.scrollable = true});

  final int count;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final tickets = [
      for (var i = 0; i < count; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _TicketShape(
            top: const Row(
              children: [
                SkeletonBox(width: 42, height: 42, radius: AppRadii.small),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 110, height: 14),
                      SizedBox(height: AppSpacing.sm),
                      SkeletonBox(width: 160, height: 10),
                    ],
                  ),
                ),
                SkeletonBox(width: 64, height: 22, radius: 10),
              ],
            ),
            bottom: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 180, height: 12),
                SizedBox(height: AppSpacing.md),
                SkeletonBox(width: 220, height: 12),
              ],
            ),
          ),
        ),
    ];
    final body = Skeleton(child: Column(children: tickets));
    if (!scrollable) return body;
    // Défilable pour que le tirage vers le bas reste possible au chargement.
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.screenPadding,
        AppSpacing.xs,
        AppDimens.screenPadding,
        AppSpacing.xxl,
      ),
      children: [body],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(
      AppDimens.screenPadding,
      AppSpacing.xxxl,
      AppDimens.screenPadding,
      AppSpacing.xxl,
    ),
    children: [
      // Illustration : pastille du pictogramme posée sur une route en
      // pointillés, entre un point de départ et une épingle d'arrivée.
      SizedBox(
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned(
              left: 24,
              right: 24,
              bottom: 22,
              height: 4,
              child: CustomPaint(
                painter: DashedLinePainter(
                  color: AppColors.borderStrong,
                  dash: 10,
                  gap: 8,
                  strokeWidth: 3,
                ),
              ),
            ),
            const Positioned(
              left: 16,
              bottom: 16,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: AppColors.warning,
              ),
            ),
            const Positioned(
              right: 12,
              bottom: 14,
              child: Icon(AppIcons.pinFilled, size: 26, color: AppColors.brand),
            ),
            Positioned(
              top: 0,
              child: Container(
                width: 112,
                height: 112,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.card,
                  border: Border.all(color: AppColors.brandTint, width: 10),
                ),
                child: Icon(icon, size: 44, color: AppColors.brand),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xxl),
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppFonts.display,
          fontWeight: FontWeight.w700,
          fontSize: AppFontSize.headline,
          color: AppColors.ink,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        body,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: AppFontSize.body,
          height: 1.55,
          color: AppColors.inkMuted,
        ),
      ),
      if (actionLabel != null && onAction != null) ...[
        const SizedBox(height: AppSpacing.xxl),
        PrimaryButton(label: actionLabel!, onPressed: onAction),
      ],
    ],
  );
}
