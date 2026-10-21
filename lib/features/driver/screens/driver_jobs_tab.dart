/// Onglet **Courses** — maquettes « App chauffeur — Statut & Dashboard » et
/// « 1. Nouvelle course ».
///
/// Trois endpoints réels : `GET /v1/driver/status/`, `POST /v1/driver/online/`,
/// `GET /v1/driver/offers/` (+ accept / decline).
///
/// **Pas de sondage** (règle non négociable n°5) : la liste se charge à
/// l'ouverture et se rafraîchit par tirage vers le bas ou sur notification.
///
/// ## Le minuteur de 12 s de la maquette repose sur un malentendu
///
/// Il n'a aucun support serveur et n'en a jamais eu (§ 2.1, T6.2) : il vient
/// d'un modèle VTC que Camelia n'a pas. La diffusion est **simultanée** à tous
/// les chauffeurs éligibles et le premier qui accepte obtient la course ;
/// aucune offre ne passe d'un chauffeur au suivant, aucune n'expire du seul
/// écoulement du temps.
///
/// Ce que `expires_at` porte est autre chose : l'échéance de **recherche de la
/// commande** (entrée en `searching_driver` + 10 minutes), identique pour
/// toutes les offres d'une même commande. L'écran l'affiche pour ce qu'elle
/// est — « Recherche jusqu'à 15:40 » — et non comme un compte à rebours
/// personnel. Passée l'échéance, tant que la commande cherche encore, l'offre
/// reste acceptable.
///
/// ## Le montant d'une offre est un **gain**, pas le prix client
///
/// `price_total` a été retiré des offres au profit de
/// `driver_earnings_estimate` (§ 2.3, T6.8) — pas ajouté à côté : les deux sur
/// le même objet rendraient la commission calculable par soustraction. C'est
/// une **prévision** totale, sans ventilation ; ce qui sera réellement crédité
/// se lit au portefeuille.
///
/// Accepter une offre ouvre la **course en cours** ([DriverCourseScreen]), qui
/// reste accessible en tête de l'onglet jusqu'à la livraison.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_error_messages.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/models/order.dart';
import '../../shared/state/push_controller.dart';
import '../../../core/theme/app_icons.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/route_decoration.dart';
import '../../shared/widgets/status_ribbon.dart';
import '../../shared/widgets/swipe_to_confirm.dart';
import '../../shared/widgets/money.dart';
import '../../shared/widgets/order_labels.dart';
import '../models/driver_status.dart';
import '../models/order_offer.dart';
import '../services/position_reporter.dart';
import '../widgets/approval_labels.dart';
import '../state/course_controller.dart';
import '../state/driver_controller.dart';
import '../state/position_heartbeat.dart';
import 'course/driver_course_screen.dart';
import 'driver_documents_card.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/package_photo_strip.dart';

class DriverJobsTab extends StatefulWidget {
  const DriverJobsTab({super.key});

  @override
  State<DriverJobsTab> createState() => _DriverJobsTabState();
}

class _DriverJobsTabState extends State<DriverJobsTab> {
  late final PushController _push;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DriverController>().refresh();
    });
    _push = context.read<PushController>()..addListener(_onPush);
  }

  /// Une notification arrive : nouvelle offre, ou course modifiée (annulation
  /// client, paiement). On relit les offres et la course — c'est tout ce que
  /// la notification apprend à l'app (§ 2.17). Pas de sondage (règle n°5).
  void _onPush() {
    if (!mounted) return;
    context.read<DriverController>().refresh();
    final course = context.read<CourseController>();
    if (course.hasCourse) course.refresh();
  }

  @override
  void dispose() {
    _push.removeListener(_onPush);
    super.dispose();
  }

  Future<void> _openCourse() {
    final course = context.read<CourseController>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DriverCourseScreen(controller: course),
      ),
    );
  }

  /// Passer en ligne est le geste qui justifie la demande de localisation :
  /// sans position, le backend ne propose aucune course (§ 6.4.1).
  Future<void> _toggleOnline(bool value) async {
    final heartbeat = context.read<PositionHeartbeat>();
    final ok = await context.read<DriverController>().toggleOnline(value);
    if (ok && value) await heartbeat.pingNow(mayPrompt: true);
  }

  Future<void> _accept(String offerId) async {
    final driver = context.read<DriverController>();
    final course = context.read<CourseController>();
    final accepted = await driver.acceptOffer(offerId);
    if (accepted == null || !mounted) return;
    await course.startFrom(accepted);
    if (mounted) await _openCourse();
    if (mounted) await driver.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final driver = context.watch<DriverController>();
    final course = context.watch<CourseController>();
    final heartbeat = context.watch<PositionHeartbeat>();

    if (driver.loading && driver.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        children: const [SkeletonCardList(count: 3)],
      );
    }
    if (driver.isEmpty && driver.failure != null) {
      return _LoadError(
        message: messageForFailure(l10n, driver.failure!),
        retryLabel: l10n.commonRetry,
        onRetry: driver.refresh,
      );
    }

    final status = driver.status;
    final offers = driver.offers;

    return RefreshIndicator(
      onRefresh: driver.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.screenPadding,
          20,
          AppDimens.screenPadding,
          24,
        ),
        children: _cascade([
          if (course.hasCourse) ...[
            _CurrentCourseCard(controller: course, onOpen: _openCourse),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (status != null) ...[
            _ApprovalBanner(status: status, l10n: l10n),
            const SizedBox(height: AppSpacing.lg),
            // Tant que le compte n'est pas validé : les pièces à fournir et
            // l'état de leur vérification. Un compte validé n'en a plus besoin.
            if (status.approval != DriverApproval.approved) ...[
              DriverDocumentsCard(status: status),
              const SizedBox(height: AppSpacing.lg),
            ],
            _OnlineToggle(
              status: status,
              busy: driver.busy,
              l10n: l10n,
              onChanged: _toggleOnline,
            ),
          ],

          if (heartbeat.locationUnavailable) ...[
            const SizedBox(height: AppSpacing.lg),
            _ErrorNotice(
              message:
                  heartbeat.lastOutcome == PositionReportOutcome.serviceDisabled
                  ? l10n.driverLocationServiceOff
                  : l10n.driverLocationPermissionNeeded,
            ),
          ],

          if (driver.failure != null && !driver.isEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _ErrorNotice(message: messageForFailure(l10n, driver.failure!)),
          ],

          const SizedBox(height: AppSpacing.xxl),
          Text(
            l10n.driverOffersTitle,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: AppFontSize.bodyLarge,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (offers.isEmpty)
            _EmptyOffers(
              // Le message dépend de la disponibilité : hors ligne, l'absence de
              // proposition est normale et non un problème à signaler.
              message: (status?.isOnline ?? false)
                  ? l10n.driverOffersEmptyOnline
                  : l10n.driverOffersEmptyOffline,
            )
          else
            for (final offer in offers)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OfferCard(
                  offer: offer,
                  l10n: l10n,
                  busy: driver.busy && driver.pendingOfferId == offer.id,
                  disabled: driver.busy,
                  onAccept: () => _accept(offer.id),
                  onDecline: () =>
                      context.read<DriverController>().declineOffer(offer.id),
                ),
              ),
        ]),
      ),
    );
  }

  /// Chaque bloc de l'onglet entre à son tour ; les espacements restent fixes.
  static List<Widget> _cascade(List<Widget> blocks) {
    var rank = 0;
    return [
      for (final block in blocks)
        block is SizedBox ? block : Entrance(index: rank++, child: block),
    ];
  }
}

/// Bandeau d'état de validation du compte.
class _ApprovalBanner extends StatelessWidget {
  const _ApprovalBanner({required this.status, required this.l10n});

  final DriverStatus status;
  final AppLocalizations l10n;

  // Statut inconnu de l'app : valeur brute du serveur, et le passage en
  // ligne reste bloqué.
  String get _label => approvalLabel(l10n, status);

  Color get _tint => approvalColor(status.approval);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.field),
        border: Border.all(color: _tint.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status.approval == DriverApproval.approved
                    ? AppIcons.verified
                    : AppIcons.pending,
                size: 18,
                color: _tint,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: AppFontSize.body,
                    color: _tint,
                  ),
                ),
              ),
            ],
          ),
          if (status.vehicleCode != null || status.ratingAverage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (status.vehicleCode != null)
                  Expanded(
                    child: _MetaLine(
                      label: l10n.driverVehicleLabel,
                      value: [
                        status.vehicleCode!,
                        if (status.vehiclePlate != null) status.vehiclePlate!,
                      ].join(' · '),
                    ),
                  ),
                if (status.ratingAverage != null)
                  _MetaLine(
                    label: l10n.driverRatingLabel,
                    value: '${status.ratingAverage} (${status.ratingCount})',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: AppColors.inkMuted,
        ),
      ),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: AppFontSize.label,
          color: AppColors.ink,
        ),
      ),
    ],
  );
}

/// Bascule disponible / hors ligne — maquette « 2. Bascule », revue par la
/// refonte UI : un « cockpit » sombre.
///
/// Hors ligne, on passe en ligne en **glissant** ([SwipeToConfirm]) : au
/// volant, un interrupteur se déclenche d'un effleurement, pas un glissement
/// jusqu'au bout. En ligne, un pouls vert dit que l'app écoute ; repasser
/// hors ligne reste un simple appui — c'est le geste prudent, il n'a pas à
/// être difficile.
class _OnlineToggle extends StatelessWidget {
  const _OnlineToggle({
    required this.status,
    required this.busy,
    required this.l10n,
    required this.onChanged,
  });

  final DriverStatus status;
  final bool busy;
  final AppLocalizations l10n;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    // Le seuil est appliqué par le serveur (`driver_not_approved`) ; on désactive
    // aussi le contrôle pour ne pas proposer une action vouée à l'échec.
    final allowed = status.canGoOnline;
    final online = status.isOnline;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppGradients.inkPanel,
        borderRadius: BorderRadius.circular(AppRadii.sheet + 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330E0E10),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (online)
                const PulsingDot(color: AppColors.success)
              else
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: .35),
                      width: 2.5,
                    ),
                  ),
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  online ? l10n.driverOnlineLabel : l10n.driverOfflineLabel,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w800,
                    fontSize: AppFontSize.headline,
                    color: AppColors.white,
                  ),
                ),
              ),
              if (online)
                busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.white,
                        ),
                      )
                    : Pressable(
                        onTap: () => onChanged(false),
                        pressedScale: .94,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: .18),
                            ),
                          ),
                          child: Text(
                            l10n.driverGoOffline,
                            style: const TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            allowed
                ? (online ? l10n.driverOnlineHint : l10n.driverOfflineHint)
                : l10n.driverCannotGoOnline,
            style: TextStyle(
              fontSize: AppFontSize.label,
              height: 1.4,
              color: AppColors.white.withValues(alpha: .7),
            ),
          ),
          if (!online) ...[
            const SizedBox(height: AppSpacing.xl),
            SwipeToConfirm(
              label: l10n.driverSwipeOnline,
              color: AppColors.success,
              onDark: true,
              busy: busy,
              onConfirmed: allowed ? () => onChanged(true) : null,
            ),
          ],
        ],
      ),
    );
  }
}

/// Carte de proposition — maquette « 1. Nouvelle course », revue par la
/// refonte UI : gain en très grand (il défile jusqu'à sa valeur), trajet en
/// pointillés, acceptation en **glissant**.
///
/// Montant = gain prévisionnel du serveur (`driver_earnings_estimate`), sans
/// « gain net » ni ventilation : ni l'un ni l'autre n'est exposé (règle n°3).
/// Durées estimées et distance jusqu'à la collecte absentes pour la même
/// raison : seule `distance_km` (collecte → livraison) existe.
class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.l10n,
    required this.busy,
    required this.disabled,
    required this.onAccept,
    required this.onDecline,
  });

  final OrderOffer offer;
  final AppLocalizations l10n;
  final bool busy;
  final bool disabled;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  String get _statusLabel => switch (offer.status) {
    OfferStatus.sent => l10n.driverOfferStatusSent,
    OfferStatus.accepted => l10n.driverOfferStatusAccepted,
    OfferStatus.declined => l10n.driverOfferStatusDeclined,
    OfferStatus.expired => l10n.driverOfferStatusExpired,
  };

  ServiceType? get _service {
    try {
      return ServiceType.fromWire(offer.order.serviceType);
    } on ArgumentError {
      return null;
    }
  }

  String get _serviceLabel {
    final service = _service;
    return service == null
        ? offer.order.serviceType
        : serviceLabel(l10n, service);
  }

  /// Échéance de recherche de la **commande**, affichée comme une heure et
  /// jamais comme un compte à rebours : ce n'est pas un délai de réponse
  /// personnel, et une offre passée l'échéance reste acceptable tant que la
  /// commande cherche (§ 2.1).
  ///
  /// `null` dès que la commande ne cherche plus — le serveur rend alors
  /// `expires_at: null`, et on n'affiche rien plutôt qu'une heure périmée.
  String? get _searchDeadline {
    final deadline = offer.expiresAt;
    if (deadline == null) return null;
    final local = deadline.toLocal();
    if (local.isBefore(DateTime.now())) return l10n.driverOfferSearchEnded;
    return l10n.driverOfferSearchUntil(
      DateFormat.Hm(l10n.localeName).format(local),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = offer.order;
    final locale = Localizations.localeOf(context).languageCode;
    final deadline = _searchDeadline;
    final service = _service;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.sheet + 2),
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
                  service == null ? AppIcons.package : serviceIcon(service),
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
                      '${offer.isActionable ? l10n.driverOfferNewCourse : _statusLabel}'
                              ' · $_serviceLabel'
                          .toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppFontSize.micro,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .6,
                        color: offer.isActionable
                            ? AppColors.brand
                            : AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '#${order.reference}',
                      style: const TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Gain prévisionnel renvoyé par le serveur, jamais recomposé
          // (règle n°3). `null` sur un devis manuel : un tiret, sans animation.
          AnimatedAmount(
            order.driverEarningsEstimate,
            locale: locale,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w800,
              fontSize: AppFontSize.hero,
              height: 1,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.driverCourseEarningsEstimated,
            style: const TextStyle(
              fontSize: AppFontSize.micro,
              height: 1.4,
              color: AppColors.inkMuted,
            ),
          ),
          if (deadline != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(AppIcons.clock, size: 14, color: AppColors.inkMuted),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  deadline,
                  style: const TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ],
          if (order.distanceKm != null || order.vehicleCode != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                if (order.distanceKm != null)
                  Expanded(
                    child: _MetricTile(
                      label: l10n.driverOfferDistance,
                      value: l10n.driverDistanceKm(order.distanceKm!),
                    ),
                  ),
                if (order.distanceKm != null && order.vehicleCode != null)
                  const SizedBox(width: AppSpacing.sm),
                if (order.vehicleCode != null)
                  Expanded(
                    child: _MetricTile(
                      label: l10n.driverVehicleLabel,
                      value: order.vehicleCode!,
                    ),
                  ),
              ],
            ),
          ],
          // Photos du colis, pour juger avant d'accepter (§ 7.4.2). URL
          // signées relues à chaque rafraîchissement des offres.
          if (order.packagePhotoUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.driverOfferPhotos,
              style: const TextStyle(
                fontSize: AppFontSize.caption,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            PackagePhotoStrip(urls: order.packagePhotoUrls),
          ],
          const SizedBox(height: AppSpacing.lg),
          RouteStops(
            pickup: order.pickupAddress,
            dropoff: order.dropoffAddress,
            pickupLabel: l10n.driverOfferPickup,
            dropoffLabel: l10n.driverOfferDropoff,
            full: true,
          ),
          if (offer.isActionable) ...[
            const SizedBox(height: AppSpacing.xl),
            SwipeToConfirm(
              label: l10n.driverSwipeAccept,
              busy: busy,
              onConfirmed: disabled ? null : onAccept,
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: TextButton(
                onPressed: disabled ? null : onDecline,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.inkMuted,
                ),
                child: Text(
                  l10n.driverOfferDecline,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: AppFontSize.label,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.brandTint,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: AppFontSize.micro,
            fontWeight: FontWeight.w700,
            letterSpacing: .4,
            color: AppColors.inkMuted,
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: AppFontSize.body,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    ),
  );
}

/// Course acceptée, en tête de l'onglet tant qu'elle n'est pas libérée.
class _CurrentCourseCard extends StatelessWidget {
  const _CurrentCourseCard({required this.controller, required this.onOpen});

  final CourseController controller;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final order = controller.order!;
    final stageLabel = switch (controller.stage) {
      CourseStage.toPickup => l10n.driverCourseToPickup,
      CourseStage.toDropoff => l10n.driverCourseToDropoff,
      CourseStage.finished => l10n.driverFinishedTitle,
      CourseStage.unknown => l10n.driverCurrentCourseTitle,
    };

    return Pressable(
      onTap: onOpen,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.inkPanel,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x380E0E10),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.driverCurrentCourseTitle.toUpperCase(),
                      style: const TextStyle(
                        fontSize: AppFontSize.micro,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .6,
                        color: Color(0x80FFFFFF),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '#${order.reference} · ${shortAddress(order.pickupAddress)}'
                      ' → ${shortAddress(order.dropoffAddress)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSize.body,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      stageLabel,
                      style: const TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentCyan,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(AppIcons.chevronRight, color: AppColors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyOffers extends StatelessWidget {
  const _EmptyOffers({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadii.field),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        const Icon(
          AppIcons.emptyInbox,
          size: 30,
          color: AppColors.borderStrong,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: AppFontSize.label,
            height: 1.5,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    ),
  );
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0x1AE5483A),
      borderRadius: BorderRadius.circular(AppRadii.small),
    ),
    child: Text(
      message,
      style: const TextStyle(
        color: AppColors.error,
        fontWeight: FontWeight.w600,
        fontSize: AppFontSize.label,
        height: 1.4,
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppDimens.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(AppIcons.error, size: 36, color: AppColors.borderStrong),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppFontSize.body,
              height: 1.5,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    ),
  );
}
