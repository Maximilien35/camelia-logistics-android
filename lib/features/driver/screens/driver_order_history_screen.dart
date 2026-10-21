/// **Mes courses passées** — `GET /v1/driver/orders/history/` (§ 7.4.6).
///
/// Ouvert depuis l'onglet Gains. Une ligne par course terminée, annulée ou en
/// litige, la plus récente d'abord, regroupées par mois.
///
/// **Un seul montant par ligne : ce qui a été réellement crédité**
/// (`earned_amount`), lu tel quel. `null` se lit « aucun gain crédité » —
/// jamais « 0 FCFA », qui laisserait croire à une course payée zéro. Ni prix
/// client, ni commission (règle n°3).
///
/// Le statut s'affiche avec les libellés traduits de l'app, le `status_label`
/// du serveur ne servant qu'en repli pour un statut inconnu de ce build.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_error_messages.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/flow_widgets.dart';
import '../../shared/widgets/money.dart';
import '../../shared/widgets/order_labels.dart';
import '../../shared/widgets/package_photo_strip.dart';
import '../../shared/widgets/pill_segmented_control.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/route_decoration.dart';
import '../../shared/widgets/skeleton.dart';
import '../models/driver_order_history.dart';
import '../services/driver_service.dart';
import '../state/driver_order_history_controller.dart';

class DriverOrderHistoryScreen extends StatefulWidget {
  const DriverOrderHistoryScreen({super.key, required this.service});

  final DriverService service;

  @override
  State<DriverOrderHistoryScreen> createState() =>
      _DriverOrderHistoryScreenState();
}

class _DriverOrderHistoryScreenState extends State<DriverOrderHistoryScreen> {
  late final DriverOrderHistoryController _history =
      DriverOrderHistoryController(service: widget.service);
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _history.refresh();
    });
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _history.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining = _scroll.position.maxScrollExtent - _scroll.offset;
    if (remaining < 400) _history.loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FlowScaffold(
      child: ListenableBuilder(
        listenable: _history,
        builder: (context, _) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.screenPadding,
                AppSpacing.md,
                AppDimens.screenPadding,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FlowHeader(
                    title: l10n.driverHistoryTitle,
                    subtitle: _history.hasLoaded
                        ? l10n.ordersCount(_history.total)
                        : l10n.driverHistorySubtitle,
                    large: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PillSegmentedControl<DriverHistoryFilter>(
                    segments: [
                      (DriverHistoryFilter.all, l10n.driverHistoryFilterAll),
                      (
                        DriverHistoryFilter.completed,
                        l10n.driverHistoryFilterCompleted,
                      ),
                      (
                        DriverHistoryFilter.cancelled,
                        l10n.driverHistoryFilterCancelled,
                      ),
                      (
                        DriverHistoryFilter.disputed,
                        l10n.driverHistoryFilterDisputed,
                      ),
                    ],
                    selected: _history.filter,
                    onChanged: _history.select,
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _history.refresh,
                color: AppColors.brand,
                child: _Body(history: _history, scroll: _scroll, l10n: l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

sealed class _Item {}

class _Header extends _Item {
  _Header(this.label);
  final String label;
}

class _Row extends _Item {
  _Row(this.entry);
  final DriverOrderHistoryEntry entry;
}

class _Body extends StatelessWidget {
  const _Body({
    required this.history,
    required this.scroll,
    required this.l10n,
  });

  final DriverOrderHistoryController history;
  final ScrollController scroll;
  final AppLocalizations l10n;

  /// Regroupe par mois. Le serveur trie déjà du plus récent au plus ancien.
  List<_Item> _grouped(String locale) {
    final items = <_Item>[];
    String? last;
    for (final entry in history.entries) {
      final label = toBeginningOfSentenceCase(
        DateFormat.yMMMM(locale).format(entry.createdAt.toLocal()),
        locale,
      );
      if (label != last) {
        items.add(_Header(label));
        last = label;
      }
      items.add(_Row(entry));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    // Un `ListView` dans chaque état, pour que le tirage vers le bas marche
    // aussi sur l'écran vide ou en erreur.
    Widget scrollable(Widget child) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.screenPadding),
      children: [child],
    );

    if (history.loading && !history.hasLoaded) {
      return scrollable(const SkeletonCardList());
    }

    if (!history.hasLoaded && history.failure != null) {
      return scrollable(
        _EmptyState(
          icon: AppIcons.offline,
          title: l10n.driverHistoryLoadError,
          body: messageForFailure(l10n, history.failure!),
          actionLabel: l10n.commonRetry,
          onAction: history.refresh,
        ),
      );
    }

    if (history.isEmpty) {
      return scrollable(
        _EmptyState(
          icon: AppIcons.history,
          title: l10n.driverHistoryTitle,
          body: history.filter == DriverHistoryFilter.all
              ? l10n.driverHistoryEmpty
              : l10n.driverHistoryEmptyFiltered,
        ),
      );
    }

    final locale = Localizations.localeOf(context).languageCode;
    final items = _grouped(locale);

    return ListView.builder(
      controller: scroll,
      physics: const AlwaysScrollableScrollPhysics(),
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
            child: SkeletonCardList(count: 1),
          );
        }
        return switch (items[index]) {
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
          _Row(:final entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Entrance(
              key: ValueKey(entry.id),
              index: index,
              enabled: index < 7 && !history.loadingMore,
              child: _HistoryCard(entry: entry),
            ),
          ),
        };
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final DriverOrderHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final created = entry.createdAt.toLocal();
    final when =
        '${DateFormat.MMMd(locale).format(created)} · '
        '${DateFormat.Hm(locale).format(created)}';
    final details = [
      serviceLabel(l10n, entry.serviceType),
      if (entry.distanceKm != null) l10n.driverDistanceKm(entry.distanceKm!),
      when,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.sheet),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  serviceIcon(entry.serviceType),
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
                      '#${entry.reference}',
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
                      details,
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
              StatusChip(
                color: statusColor(entry.status),
                label: statusLabelFor(
                  l10n,
                  entry.status,
                  fallback: entry.statusLabel ?? entry.rawStatus,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          RouteStops(
            pickup: entry.pickupAddress,
            dropoff: entry.dropoffAddress,
          ),
          if (entry.packagePhotoUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            PackagePhotoStrip(urls: entry.packagePhotoUrls, size: 48),
          ],
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.wasCredited
                      ? l10n.driverHistoryEarned
                      : l10n.driverHistoryNotCredited,
                  style: const TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
              // Montant crédité du serveur, tel quel (règle n°3) ; rien du
              // tout quand il n'y a pas eu de crédit.
              if (entry.wasCredited)
                Text(
                  formatAmount(entry.earnedAmount, locale: locale),
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w800,
                    fontSize: AppFontSize.bodyLarge,
                    color: AppColors.ink,
                  ),
                ),
            ],
          ),
        ],
      ),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xxl),
    child: Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.brandTint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: AppColors.brand),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w700,
            fontSize: AppFontSize.bodyLarge,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: AppFontSize.caption,
            height: 1.45,
            color: AppColors.inkMuted,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.lg),
          OutlineAction(label: actionLabel!, onPressed: onAction),
        ],
      ],
    ),
  );
}

/// Entrée « Mes courses passées », posée dans l'onglet Gains sous le
/// récapitulatif de période.
class DriverHistoryEntryCard extends StatelessWidget {
  const DriverHistoryEntryCard({super.key, required this.service});

  final DriverService service;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Pressable(
      semanticLabel: l10n.driverHistoryTitle,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DriverOrderHistoryScreen(service: service),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.sheet),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.brandTint,
                borderRadius: BorderRadius.circular(AppRadii.small),
              ),
              child: const Icon(
                AppIcons.history,
                size: 20,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.driverHistoryTitle,
                    style: const TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    l10n.driverHistorySubtitle,
                    style: const TextStyle(
                      fontSize: AppFontSize.caption,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              AppIcons.chevronRight,
              size: 18,
              color: AppColors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}
