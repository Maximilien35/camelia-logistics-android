/// **Suivi de commande** — section « Suivi — Client » de la maquette.
///
/// Un seul écran, piloté par le `status` renvoyé par `GET /v1/orders/{id}/` :
///
/// | Statut serveur | Maquette |
/// |---|---|
/// | `searching_driver` | 1 · Recherche de chauffeur |
/// | `cancelled_by_system` | 1 · Aucun chauffeur |
/// | `driver_assigned` → `in_transit` | 2 · Suivi · ruban de statut |
/// | `delivered` | paiement à déclencher (bouton) |
/// | `completed` | 5 · Livraison confirmée |
/// | `draft`, `cancelled_by_client`, `disputed` | états hors ruban |
///
/// **Pas de carte** sur cet écran (règle non négociable n°11, décision actée) ;
/// **pas de sondage** (règle n°5) : tirage vers le bas et bouton Actualiser.
///
/// ## Ce que le serveur expose depuis les lots 5 et 6
///
/// - **bloc `driver`** (§ 7.3.5) : prénom, initiale du nom, note, véhicule,
///   plaque, et le **numéro réel** pendant la course — arbitrage du
///   17 septembre 2026, ni masquage ni chat. La clé `phone` est toujours
///   présente : on teste sa valeur nulle, jamais son absence, et on ne la
///   mémorise pas d'une lecture à l'autre ;
/// - **`eta_minutes`** (§ 7.3.10) : des **minutes restantes sur l'étape en
///   cours**, jamais une heure d'horloge. Approximation assumée (vol d'oiseau
///   ÷ vitesse moyenne fixe, sans trafic) : « environ 20 min » est plus
///   honnête qu'un horaire. `null` veut dire **ne rien afficher** — ni « 0 min »,
///   ni tiret, ni la valeur de la lecture précédente ;
/// - **`delivery_code`** (§ 7.3.12) : quatre chiffres, lus par le client seul
///   et dictés au chauffeur. Jamais mis en cache — le serveur en tire un
///   nouveau quand le chauffeur épuise ses trois tentatives ;
/// - **`proofs`** (§ 7.3.11) : photos de collecte et de livraison, en **URL
///   signées valables 5 minutes**. Rien n'est conservé au-delà de l'écran, et
///   c'est la position dans la liste qui identifie une photo, jamais l'URL ;
/// - **`relaunch-search/`** (§ 7.3.13) : `cancelled_by_system` n'est plus
///   terminal, trois relances au plus ;
/// - **`rate/`** (§ 7.3.6) : la note du chauffeur, `delivered` ou `completed`.
///
/// **Écarts assumés, toujours valables** :
/// - « Paiement pré-autorisé » : le paiement a lieu **après** la livraison,
///   sur appui explicite (règle n°7) ;
/// - ventilation « Course / Manutention » : jamais exposée (règle n°3) ;
/// - « 3,4 km restants » : le serveur rend bien une distance, mais **à vol
///   d'oiseau** — elle est affichée comme telle, pas comme un kilométrage
///   routier que l'utilisateur comparerait à son GPS ;
/// - « Message » au chauffeur : aucun modèle de messagerie côté serveur, et la
///   règle n°5 interdit le temps réel. Seul l'appel existe.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_error_messages.dart';
import '../../../../core/platform/external_actions.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/order_proof.dart';
import '../../../shared/models/tracked_driver.dart';
import '../../../shared/services/emergency_service.dart';
import '../../../shared/state/auth_controller.dart';
import '../../../shared/state/push_controller.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../../shared/widgets/money.dart';
import '../../../shared/widgets/order_labels.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/route_progress.dart';
import '../../../shared/widgets/status_ribbon.dart';
import '../../models/order_rating.dart';
import '../../services/order_service.dart';
import '../../state/order_tracking_controller.dart';
import '../../widgets/payer_phone_sheet.dart';
import 'order_addresses_screen.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../shared/widgets/skeleton.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key, required this.orderId, this.initial});

  final String orderId;

  /// Commande déjà connue (réponse de création) : affichée pendant la
  /// première lecture du suivi complet.
  final Order? initial;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late final OrderTrackingController _controller;
  late final PushController _push;

  @override
  void initState() {
    super.initState();
    _controller = OrderTrackingController(
      service: context.read<OrderService>(),
      orderId: widget.orderId,
      initial: widget.initial,
    );
    // Lecture à l'ouverture : un GET, jamais un paiement (règle n°7).
    _controller.refresh();
    _push = context.read<PushController>()..addListener(_onPush);
  }

  /// Notification concernant **cette** commande : on la relit. On n'affiche
  /// jamais le contenu de la notification — il ne porte ni prix, ni adresse,
  /// ni statut (§ 2.17) — et on ne relit rien pour une autre commande.
  void _onPush() {
    if (_push.lastHint?.orderId == widget.orderId) _controller.refresh();
  }

  @override
  void dispose() {
    _push.removeListener(_onPush);
    _controller.dispose();
    super.dispose();
  }

  /// Choix du numéro, puis `confirm-delivery` — le seul chemin de paiement.
  ///
  /// En mode USSD (KPay, par défaut) il n'y a rien à ouvrir : l'invite arrive
  /// sur le téléphone du payeur et la carte de paiement passe en attente. Une
  /// page n'est ouverte que si le fournisseur en rend une.
  Future<void> _pay() async {
    final accountPhone =
        context.read<AuthController>().user?.phone ??
        _controller.payerPhone ??
        '';
    final payerPhone = await showPayerPhoneSheet(
      context,
      initialPhone: _controller.payerPhone ?? accountPhone,
    );
    if (payerPhone == null || !mounted) return;
    final invite = await _controller.pay(payerPhone: payerPhone);
    if (invite != null && invite.opensPage) await _openInvitePage(invite);
  }

  Future<void> _openInvitePage(PaymentInvite invite) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (!await ExternalActions.openServerLink(invite.authorizationUrl!)) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.externalOpenFailed)));
    }
  }

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.trackingCancelConfirmTitle),
        content: Text(l10n.trackingCancelConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.trackingCancelKeep),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.trackingCancelConfirmYes),
          ),
        ],
      ),
    );
    if (confirmed == true) await _controller.cancel();
  }

  void _newOrder(ServiceType service) {
    final navigator = Navigator.of(context);
    final rootContext = navigator.context;
    navigator.popUntil((r) => r.isFirst);
    startOrderFlow(rootContext, service);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final order = _controller.order;

        if (order == null) {
          return FlowScaffold(
            backdrop: FlowBackdrop.lavender,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: Column(
                children: [
                  FlowHeader(title: l10n.trackingProgress),
                  Expanded(
                    child: _controller.loading
                        ? const SingleChildScrollView(
                            padding: EdgeInsets.only(top: AppSpacing.lg),
                            child: SkeletonCardList(count: 4),
                          )
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ErrorNotice(
                                  message: messageForFailure(
                                    l10n,
                                    _controller.failure ?? Object(),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                OutlineAction(
                                  label: l10n.commonRetry,
                                  onPressed: _controller.refresh,
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        }

        return switch (order.status) {
          OrderStatus.searchingDriver => _SearchingView(
            order: order,
            controller: _controller,
            onCancel: _cancel,
          ),
          OrderStatus.cancelledBySystem => _NoDriverView(
            order: order,
            controller: _controller,
            onNewOrder: () => _newOrder(order.serviceType),
          ),
          _ => _TrackingView(
            order: order,
            controller: _controller,
            onPay: _pay,
            onOpenInvitePage: _openInvitePage,
            onCancel: _cancel,
          ),
        };
      },
    );
  }
}

// --- Commun --------------------------------------------------------------------

String _time(BuildContext context, DateTime date) => DateFormat.Hm(
  Localizations.localeOf(context).languageCode,
).format(date.toLocal());

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.controller});

  final OrderTrackingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: l10n.commonRefresh,
      onPressed: controller.loading ? null : controller.refresh,
      icon: controller.loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(AppIcons.refresh, color: AppColors.ink),
    );
  }
}

/// Les statuts pour lesquels la machine à états du serveur déclare une
/// transition vers `cancelled_by_client` (`orders/state_machine.py`). Le
/// bouton n'est qu'une invitation : le serveur tranche, frais compris.
bool _offersCancel(OrderStatus status) => const {
  OrderStatus.searchingDriver,
  OrderStatus.driverAssigned,
  OrderStatus.driverEnRoutePickup,
  OrderStatus.pickedUp,
  OrderStatus.inTransit,
}.contains(status);

// --- 1 · Recherche de chauffeur ------------------------------------------------

class _SearchingView extends StatelessWidget {
  const _SearchingView({
    required this.order,
    required this.controller,
    required this.onCancel,
  });

  final Order order;
  final OrderTrackingController controller;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final registeredAt =
        order.statusRibbon
            .where((s) => s.key == 'order_received')
            .firstOrNull
            ?.reachedAt ??
        order.createdAt;

    return FlowScaffold(
      backdrop: FlowBackdrop.lavender,
      bottom: SizedBox(
        height: 52,
        width: double.infinity,
        child: FilledButton(
          onPressed: controller.busy ? null : onCancel,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.error,
            elevation: 4,
            shadowColor: const Color(0x140E0E10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: AppFontSize.body,
            ),
          ),
          child: controller.cancelling
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : Text(l10n.trackingCancel),
        ),
      ),
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
          children: [
            FlowHeader(
              title: l10n.trackingSearchingHeader,
              subtitle: '#${order.reference}',
              trailing: _RefreshButton(controller: controller),
            ),
            const SizedBox(height: AppSpacing.md),
            const Center(child: _Radar()),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              l10n.trackingSearchingTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: AppFontSize.headline,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.trackingSearchingBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppFontSize.label,
                height: 1.55,
                color: Color(0xFF6B6478),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xB8FFFFFF),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x144818F0),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _CheckLine(
                    label: l10n.trackingOrderRegistered,
                    trailing: _time(context, registeredAt),
                    done: true,
                  ),
                  if (order.priceTotal != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _CheckLine(
                      label: l10n.trackingToPayOnDelivery,
                      trailing: formatAmount(order.priceTotal, locale: locale),
                      done: true,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _CheckLine(
                    label: l10n.trackingSearchingTitle,
                    trailing: '',
                    done: false,
                  ),
                ],
              ),
            ),
            if (controller.failure != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ErrorNotice(
                message: messageForFailure(l10n, controller.failure!),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.trackingPullToRefresh,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppFontSize.caption,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({
    required this.label,
    required this.trailing,
    required this.done,
  });

  final String label;
  final String trailing;
  final bool done;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (done)
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: AppColors.ink,
            shape: BoxShape.circle,
          ),
          child: const Icon(AppIcons.check, size: 12, color: AppColors.white),
        )
      else
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.brand,
          ),
        ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.label,
            fontWeight: done ? FontWeight.w600 : FontWeight.w700,
            color: done ? AppColors.ink : AppColors.brand,
          ),
        ),
      ),
      Text(
        trailing,
        style: const TextStyle(
          fontSize: AppFontSize.micro,
          fontWeight: FontWeight.w600,
          color: AppColors.inkMuted,
        ),
      ),
    ],
  );
}

/// Trois ondes violettes qui s'élargissent autour de l'illustration du colis.
class _Radar extends StatefulWidget {
  const _Radar();

  @override
  State<_Radar> createState() => _RadarState();
}

class _RadarState extends State<_Radar> with SingleTickerProviderStateMixin {
  // Animation purement visuelle : aucune requête n'y est liée (règle n°5).
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 190,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) => Stack(
          alignment: Alignment.center,
          children: [
            for (final delay in const [0.0, .33, .66])
              Builder(
                builder: (context) {
                  final t = (_pulse.value + delay) % 1;
                  return Transform.scale(
                    scale: .3 + t * 2.3 / 2.6,
                    child: Opacity(
                      opacity: (.55 * (1 - t)).clamp(0, 1),
                      child: Container(
                        width: 190,
                        height: 190,
                        decoration: const BoxDecoration(
                          color: Color(0x2E4818F0),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            child!,
          ],
        ),
        // Le carton se ferme et devient un camion qui roule
        // (`assets/car.json`) : « votre colis attend son chauffeur ».
        child: Container(
          width: 128,
          height: 128,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x334818F0),
                blurRadius: 36,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Lottie.asset(
            'assets/car.json',
            animate: !MediaQuery.disableAnimationsOf(context),
            errorBuilder: (_, _, _) =>
                const Icon(AppIcons.truck, size: 52, color: AppColors.brand),
          ),
        ),
      ),
    );
  }
}

// --- 1 · Aucun chauffeur ---------------------------------------------------------

class _NoDriverView extends StatelessWidget {
  const _NoDriverView({
    required this.order,
    required this.controller,
    required this.onNewOrder,
  });

  final Order order;
  final OrderTrackingController controller;
  final VoidCallback onNewOrder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final relaunch = controller.relaunch;
    // Le plafond est une règle serveur : on ne la duplique pas, on grise le
    // bouton une fois qu'il a dit combien de relances il reste (§ 7.3.13).
    final exhausted = relaunch != null && relaunch.relaunchesRemaining == 0;

    return FlowScaffold(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // `cancelled_by_system` n'est plus terminal depuis T6.7 : relancer
          // la recherche évite de refaire tout le parcours, photo comprise.
          PrimaryButton(
            label: l10n.trackingRelaunch,
            busy: controller.relaunching,
            onPressed: exhausted ? null : controller.relaunchSearch,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlineAction(
            label: l10n.trackingNoDriverRetry,
            onPressed: onNewOrder,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlineAction(
            label: l10n.commonBackHome,
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
        children: [
          FlowHeader(title: '#${order.reference}'),
          const SizedBox(height: AppSpacing.xl),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0x17E5483A),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                AppIcons.userOff,
                color: AppColors.error,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.trackingNoDriverTitle,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: AppFontSize.headline,
              height: 1.25,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.trackingNoDriverBody,
            style: const TextStyle(
              fontSize: AppFontSize.label,
              height: 1.6,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          FlowCard(
            color: AppColors.brandTint,
            radius: 16,
            child: RoutePoints(
              pickupLabel: l10n.orderPickupLabel,
              pickup: order.pickupAddress,
              dropoffLabel: l10n.orderDropoffLabel,
              dropoff: order.dropoffAddress,
            ),
          ),

          if (relaunch != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.trackingRelaunchRemaining(relaunch.relaunchesRemaining),
              style: const TextStyle(
                fontSize: AppFontSize.caption,
                color: AppColors.inkMuted,
              ),
            ),
            // Le serveur recalcule le prix au tarif en vigueur : quand il a
            // bougé, on le signale au lieu de le laisser passer en silence.
            if (relaunch.priceChanged) ...[
              const SizedBox(height: AppSpacing.md),
              InfoNotice(
                icon: AppIcons.priceChanged,
                message: l10n.trackingRelaunchPriceChanged,
              ),
            ],
          ],

          if (controller.failure != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ErrorNotice(message: messageForFailure(l10n, controller.failure!)),
          ],
        ],
      ),
    );
  }
}

// --- 2 · Suivi, paiement, fin -------------------------------------------------------

class _TrackingView extends StatelessWidget {
  const _TrackingView({
    required this.order,
    required this.controller,
    required this.onPay,
    required this.onOpenInvitePage,
    required this.onCancel,
  });

  final Order order;
  final OrderTrackingController controller;
  final VoidCallback onPay;
  final ValueChanged<PaymentInvite> onOpenInvitePage;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final status = order.status;
    final invite = controller.pendingInvite;
    final cancellation = controller.cancellation;

    final subtitle = [
      serviceLabel(l10n, order.serviceType),
      if (order.packageWeightKg != null)
        l10n.orderWeightValue(_trimDecimal(order.packageWeightKg!)),
    ].join(' · ');

    return FlowScaffold(
      backdrop: FlowBackdrop.lavender,
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            FlowHeader(
              title: '#${order.reference}',
              subtitle: subtitle,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // L'en-tête de suivi porte déjà le statut en grand.
                  if (!_showsRouteHero(order))
                    StatusChip(
                      label: statusLabel(l10n, order),
                      color: statusColor(status),
                    ),
                  _RefreshButton(controller: controller),
                ],
              ),
            ),

            if (controller.failure != null) ...[
              ErrorNotice(
                message: messageForFailure(l10n, controller.failure!),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // En-tête de suivi : où en est la commande, d'un coup d'œil. Pas
            // pour une commande livrée et payée — la carte de confirmation
            // prend le relais.
            if (_showsRouteHero(order)) ...[
              _RouteHero(order: order),
              const SizedBox(height: AppSpacing.md),
            ],

            // État hors ruban : explication en tête.
            if (_outOfRibbonMessage(l10n, order) case (
              final title,
              final body,
            )) ...[
              _StateBanner(
                title: title,
                body: body,
                color: status == OrderStatus.draft
                    ? AppColors.brand
                    : AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Frais d'annulation : en USSD l'invite est déjà sur le téléphone,
            // on le dit ; seule une invite à page hébergée a un bouton.
            if (status == OrderStatus.cancelledByClient)
              if (cancellation?.payment case final fee?) ...[
                if (fee.opensPage)
                  OutlineAction(
                    label: l10n.trackingPayFee,
                    icon: AppIcons.phone,
                    onPressed: () => onOpenInvitePage(fee),
                  )
                else
                  _StateBanner(
                    title: l10n.trackingPayFee,
                    body: l10n.trackingCancelFeePromptSent,
                    color: AppColors.brand,
                  ),
                const SizedBox(height: AppSpacing.md),
              ],
            if (status == OrderStatus.cancelledByClient &&
                controller.cancelFeePromptFailed) ...[
              _StateBanner(
                title: l10n.trackingCancelledTitle,
                body: l10n.trackingCancelFeePromptFailed,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            if (status == OrderStatus.draft &&
                order.whatsappRedirect?.waLink.isNotEmpty == true) ...[
              OutlineAction(
                label: l10n.orderOpenWhatsApp,
                icon: AppIcons.whatsapp,
                onPressed: () => ExternalActions.openServerLink(
                  order.whatsappRedirect!.waLink,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Livré, non payé : l'action de paiement, et elle seule.
            if (status == OrderStatus.delivered) ...[
              _PayCard(
                order: order,
                invite: invite,
                awaiting: controller.awaitingValidation,
                payerPhone: controller.payerPhone,
                paying: controller.paying,
                onPay: onPay,
                onOpenInvitePage: onOpenInvitePage,
                onRefresh: controller.refresh,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            if (status == OrderStatus.completed) ...[
              _CompletedCard(
                title: l10n.trackingCompletedTitle,
                body: l10n.trackingCompletedBody,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Chauffeur : présent à partir de `driver_assigned` seulement.
            if (order.driver != null) ...[
              _DriverCard(driver: order.driver!),
              const SizedBox(height: AppSpacing.md),
            ],

            // Code de remise : servi de `searching_driver` à `in_transit`,
            // `null` dès `delivered`. Jamais mis en cache (§ 2.2).
            if (order.deliveryCode != null) ...[
              _DeliveryCodeCard(code: order.deliveryCode!),
              const SizedBox(height: AppSpacing.md),
            ],

            if (order.hasRibbon) ...[
              FlowCard(
                radius: 22,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(l10n.trackingProgress),
                    const SizedBox(height: AppSpacing.sm),
                    StatusRibbon(steps: order.statusRibbon),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            FlowCard(
              radius: 20,
              child: RoutePoints(
                pickupLabel: l10n.trackingPickupLabel,
                pickup: order.pickupAddress,
                pickupColor: _pickupDone(order)
                    ? AppColors.success
                    : AppColors.brand,
                dropoffLabel: l10n.trackingDropoffLabel,
                dropoff: order.dropoffAddress,
                dropoffNote: order.recipientName.isEmpty
                    ? null
                    : '${l10n.trackingRecipient} · ${order.recipientName}',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            FlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.packagePhotoUrls.isNotEmpty ||
                      (order.packageDescription?.isNotEmpty ?? false)) ...[
                    if (order.packagePhotoUrls.isNotEmpty) ...[
                      Row(
                        children: [
                          for (final url in order.packagePhotoUrls.take(3)) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Image.network(
                                url,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 64,
                                  height: 64,
                                  color: AppColors.surface,
                                  child: const Icon(
                                    AppIcons.package,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.trackingParcel,
                                style: const TextStyle(
                                  fontSize: AppFontSize.label,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              if (order.packageDescription?.isNotEmpty ?? false)
                                Text(
                                  order.packageDescription!,
                                  style: const TextStyle(
                                    fontSize: AppFontSize.caption,
                                    height: 1.45,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.surface),
                  ],
                  // Un total, et rien d'autre (règle non négociable n°3).
                  KeyValueRow(
                    label: status == OrderStatus.completed
                        ? l10n.trackingTotalPaid
                        : (order.priceTotal == null
                              ? l10n.orderConfirmTotal
                              : l10n.trackingToPayOnDelivery),
                    value: order.priceTotal == null
                        ? l10n.orderConfirmQuote
                        : formatAmount(order.priceTotal, locale: locale),
                    emphasize: true,
                  ),
                ],
              ),
            ),

            // Preuves de collecte et de livraison. Les URL sont signées et
            // expirent en 5 minutes : rien n'est conservé, une image qui ne
            // charge plus se corrige en relisant la commande (§ 2.5).
            if (order.proofs.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _ProofsCard(proofs: order.proofs),
            ],

            // Notation : `delivered` ou `completed`, sans limite de temps.
            if (order.isRatable) ...[
              const SizedBox(height: AppSpacing.md),
              _RateCard(controller: controller),
            ],

            if (_offersCancel(status)) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlineAction(
                label: l10n.trackingCancel,
                color: AppColors.error,
                busy: controller.cancelling,
                onPressed: controller.busy ? null : onCancel,
              ),
            ],

            // Bouton d'urgence : masqué si aucune ligne n'est configurée en
            // back-office (`emergency_contact_not_configured`, § 7.3.9).
            if (_offersCancel(status)) ...[
              const SizedBox(height: AppSpacing.md),
              const _EmergencyButton(),
            ],
          ],
        ),
      ),
    );
  }

  static bool _showsRouteHero(Order order) =>
      order.hasRibbon && order.status != OrderStatus.completed;

  static bool _pickupDone(Order order) =>
      order.statusRibbon.any((s) => s.key == 'picked_up' && s.done);

  static String _trimDecimal(String raw) {
    final value = double.tryParse(raw);
    if (value == null) return raw;
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  static (String, String)? _outOfRibbonMessage(
    AppLocalizations l10n,
    Order order,
  ) => switch (order.status) {
    OrderStatus.draft => (l10n.trackingDraftTitle, l10n.trackingDraftBody),
    OrderStatus.cancelledByClient => (
      l10n.trackingCancelledTitle,
      l10n.trackingCancelledBody,
    ),
    OrderStatus.disputed => (
      l10n.trackingDisputedTitle,
      l10n.trackingDisputedBody,
    ),
    OrderStatus.unknown => (statusLabel(l10n, order), ''),
    _ => null,
  };
}

/// En-tête de suivi — refonte UI : statut en grand, temps restant, et la
/// route sur laquelle le camion avance jusqu'à l'étape en cours.
class _RouteHero extends StatelessWidget {
  const _RouteHero({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            statusLabel(l10n, order),
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w800,
              fontSize: AppFontSize.headline,
              color: AppColors.white,
            ),
          ),
          // `null` veut dire « ne rien afficher » : pas de « 0 min », pas de
          // tiret, et surtout pas la valeur de la lecture précédente. Des
          // minutes, jamais une heure d'horloge.
          if (order.etaMinutes != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    AppIcons.clock,
                    size: 16,
                    color: AppColors.white.withValues(alpha: .7),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Expanded(
                  child: Text(
                    [
                      l10n.trackingEta(order.etaMinutes!),
                      if (order.remainingDistanceKm != null)
                        l10n.trackingRemainingKm(
                          order.remainingDistanceKm!.toStringAsFixed(1),
                        ),
                    ].join(' · '),
                    style: TextStyle(
                      fontSize: AppFontSize.label,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white.withValues(alpha: .75),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          RouteProgress(steps: order.statusRibbon, onDark: true),
        ],
      ),
    );
  }
}

/// Livraison confirmée et payée : la coche animée (`assets/Success.json`),
/// jouée une fois.
class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.md,
      AppSpacing.xl,
      AppSpacing.xl,
    ),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadii.sheet + 2),
      boxShadow: AppShadows.card,
    ),
    child: Column(
      children: [
        SizedBox(
          width: 150,
          height: 130,
          child: Lottie.asset(
            'assets/Success.json',
            repeat: false,
            animate: !MediaQuery.disableAnimationsOf(context),
            errorBuilder: (_, _, _) => const Icon(
              AppIcons.checkCircle,
              size: 64,
              color: AppColors.success,
            ),
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w800,
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
            height: 1.5,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    ),
  );
}

class _StateBanner extends StatelessWidget {
  const _StateBanner({
    required this.title,
    required this.body,
    required this.color,
  });

  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withValues(alpha: .3), width: 1.5),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(AppIcons.info, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: AppFontSize.bodyLarge,
                  color: AppColors.ink,
                ),
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: AppFontSize.label,
                    height: 1.5,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// Carte de paiement après livraison — le seul déclencheur de
/// `confirm-delivery` de toute l'app (règle non négociable n°7).
///
/// Deux états : « payer » (bouton), puis « en attente de validation » dès
/// qu'une invite est partie ou que le serveur signale qu'une invite attend
/// déjà (`payment_already_pending`). En attente, le second bouton rouvre la
/// page de paiement si le fournisseur en a rendu une, et sinon **renvoie la
/// demande** (USSD) — un nouvel appui, donc un nouvel appel explicite.
class _PayCard extends StatelessWidget {
  const _PayCard({
    required this.order,
    required this.invite,
    required this.awaiting,
    required this.payerPhone,
    required this.paying,
    required this.onPay,
    required this.onOpenInvitePage,
    required this.onRefresh,
  });

  final Order order;
  final PaymentInvite? invite;
  final bool awaiting;
  final String? payerPhone;
  final bool paying;
  final VoidCallback onPay;
  final ValueChanged<PaymentInvite> onOpenInvitePage;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final page = invite != null && invite!.opensPage ? invite : null;
    final phone = payerPhone;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, Color(0xFF3A0FD0)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x524818F0),
            blurRadius: 32,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            awaiting ? l10n.trackingPayPendingTitle : l10n.trackingPayTitle,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: AppFontSize.title,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            !awaiting
                ? l10n.trackingPayBody
                : page == null && phone != null
                ? l10n.trackingPayPromptSentBody(phone)
                : l10n.trackingPayPendingBody,
            style: const TextStyle(
              fontSize: AppFontSize.label,
              height: 1.5,
              color: Color(0xCCFFFFFF),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!awaiting)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: paying ? null : onPay,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.brand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: AppFontSize.bodyLarge,
                  ),
                ),
                child: paying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Text(
                        l10n.trackingPayButton(
                          formatAmount(order.priceTotal, locale: locale),
                        ),
                      ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: page != null
                      ? _LightButton(
                          label: l10n.trackingPayOpenAgain,
                          onTap: () => onOpenInvitePage(page),
                        )
                      : _LightButton(
                          label: l10n.trackingPaySendAgain,
                          onTap: paying ? null : onPay,
                        ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _LightButton(
                    label: l10n.commonRefresh,
                    onTap: onRefresh,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LightButton extends StatelessWidget {
  const _LightButton({required this.label, required this.onTap});

  final String label;

  /// `null` grise le bouton (paiement en cours d'envoi).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.white,
        side: const BorderSide(color: Color(0x66FFFFFF), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: AppFontSize.label,
        ),
      ),
      child: Text(label, textAlign: TextAlign.center),
    ),
  );
}
// --- Blocs ouverts par les lots 5 et 6 ------------------------------------------

/// Bloc `driver` du suivi (§ 7.3.5, T5.6 puis T6.3).
///
/// Sept clés, pas une de plus : le nom de famille complet ne quitte jamais la
/// base, seule son initiale sort. Le numéro est le **numéro réel** du
/// chauffeur, servi pendant la course seulement — arbitrage du 17 septembre
/// 2026, le masquage ayant été écarté pour son coût récurrent.
///
/// On teste `phone == null`, jamais l'absence de la clé, et on ne mémorise
/// jamais ce numéro : la fenêtre de contact se referme à `completed`.
class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver});

  final TrackedDriver driver;

  Future<void> _call(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (!await ExternalActions.call(driver.phone!)) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.externalOpenFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plate = driver.vehiclePlate ?? '';

    return FlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(l10n.trackingDriverTitle),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.brandTint,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  driver.firstName.isEmpty
                      ? '?'
                      : driver.firstName.characters.first.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w800,
                    fontSize: AppFontSize.title,
                    color: AppColors.brand,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.displayName,
                      style: const TextStyle(
                        fontSize: AppFontSize.body,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      // Sans aucune note, `rating_average` vaut 0.00 :
                      // l'afficher comme une note serait mensonger.
                      driver.hasRating
                          ? l10n.trackingDriverRating(
                              driver.ratingAverage,
                              driver.ratingCount,
                            )
                          : l10n.trackingDriverNoRating,
                      style: const TextStyle(
                        fontSize: AppFontSize.caption,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    if (plate.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        plate,
                        style: const TextStyle(
                          fontSize: AppFontSize.caption,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Pas de bouton « Message » : aucun modèle de messagerie n'existe
          // côté serveur, et la règle n°5 interdit le temps réel.
          if (driver.canBeCalled) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlineAction(
              label: l10n.trackingCall,
              icon: AppIcons.call,
              height: 44,
              onPressed: () => _call(context),
            ),
          ],
        ],
      ),
    );
  }
}

/// Code de remise à quatre chiffres (§ 7.3.12, T6.6).
///
/// Affiché en grand : le client le dicte au chauffeur au moment de la remise.
/// Il **change** quand le chauffeur épuise ses trois tentatives, donc rien
/// n'en est mis en cache — c'est la relecture de la commande qui fait foi.
class _DeliveryCodeCard extends StatelessWidget {
  const _DeliveryCodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FlowCard(
      color: AppColors.brandTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(l10n.trackingDeliveryCodeTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            // Chaîne et non entier : « 0471 » est un code valide.
            code.split('').join(' '),
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: AppFontSize.hero,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              height: 1,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.trackingDeliveryCodeBody,
            style: const TextStyle(
              fontSize: AppFontSize.caption,
              height: 1.5,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Heure d'arrivée estimée (§ 7.3.10, T6.4) et distance restante (T7.2).
///
/// Des **minutes**, jamais une heure d'horloge, et une distance annoncée pour
/// ce qu'elle est : du vol d'oiseau, pas un kilométrage routier.

/// Preuves de collecte et de livraison (§ 7.3.11, T6.5).
///
/// Les URL sont **signées et valables 5 minutes**, recalculées à chaque
/// lecture : deux lectures rendent deux URL différentes. On n'en conserve
/// aucune, et c'est la **position** dans la liste qui identifie une photo.
/// `photo_url` peut valoir `null` — preuve antérieure à la bascule en privé,
/// ou média purgé à six mois : la livraison reste constatée, seule l'image a
/// disparu.
class _ProofsCard extends StatelessWidget {
  const _ProofsCard({required this.proofs});

  final List<OrderProof> proofs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return FlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(l10n.trackingProofsTitle),
          const SizedBox(height: AppSpacing.md),
          for (final proof in proofs) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: proof.hasPhoto
                      ? Image.network(
                          proof.photoUrl!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _ProofPlaceholder(),
                        )
                      : const _ProofPlaceholder(),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        switch (proof.type) {
                          ProofType.pickup => l10n.trackingProofPickup,
                          ProofType.delivery => l10n.trackingProofDelivery,
                          ProofType.unknown => proof.rawType,
                        },
                        style: const TextStyle(
                          fontSize: AppFontSize.label,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      if (proof.capturedAt != null)
                        Text(
                          DateFormat.yMMMd(
                            locale,
                          ).add_Hm().format(proof.capturedAt!.toLocal()),
                          style: const TextStyle(
                            fontSize: AppFontSize.micro,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      if (proof.hasSignatureName)
                        Text(
                          l10n.trackingProofReceivedBy(
                            proof.recipientSignatureName,
                          ),
                          style: const TextStyle(
                            fontSize: AppFontSize.caption,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      if (!proof.hasPhoto)
                        Text(
                          l10n.trackingProofNoPhoto,
                          style: const TextStyle(
                            fontSize: AppFontSize.micro,
                            color: AppColors.inkMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _ProofPlaceholder extends StatelessWidget {
  const _ProofPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    color: AppColors.surface,
    child: const Icon(
      AppIcons.imageBroken,
      size: 20,
      color: AppColors.inkMuted,
    ),
  );
}

/// Notation du chauffeur (§ 7.3.6, T5.7 puis T6.12).
///
/// Une note par commande, garantie **en base** côté serveur : l'app propose,
/// le serveur tranche. Trois conflits distincts en `409` que l'écran ne
/// présente pas de la même façon — déjà notée, pas encore notable, aucun
/// chauffeur à noter.
///
/// La réponse porte la moyenne du chauffeur **après** la note : aucun second
/// appel à faire.
class _RateCard extends StatefulWidget {
  const _RateCard({required this.controller});

  final OrderTrackingController controller;

  @override
  State<_RateCard> createState() => _RateCardState();
}

class _RateCardState extends State<_RateCard> {
  final _comment = TextEditingController();
  int _stars = 0;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rating = widget.controller.rating;

    if (rating != null) {
      return FlowCard(
        color: AppColors.brandTint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(l10n.trackingRateTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.trackingRateThanks,
              style: const TextStyle(
                fontSize: AppFontSize.label,
                color: AppColors.ink,
              ),
            ),
            if (rating.driverRatingAverage != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.trackingRateAverage(rating.driverRatingAverage!),
                style: const TextStyle(
                  fontSize: AppFontSize.caption,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return FlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(l10n.trackingRateTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.trackingRateBody,
            style: const TextStyle(
              fontSize: AppFontSize.caption,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (
                var star = OrderRating.minRating;
                star <= OrderRating.maxRating;
                star++
              )
                IconButton(
                  onPressed: () => setState(() => _stars = star),
                  icon: Icon(
                    star <= _stars ? AppIcons.starFilled : AppIcons.star,
                    color: star <= _stars
                        ? AppColors.warning
                        : AppColors.borderStrong,
                    size: 30,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AppTextField(
            label: l10n.trackingRateCommentLabel,
            controller: _comment,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlineAction(
            label: l10n.trackingRateSubmit,
            busy: widget.controller.ratingBusy,
            // Le serveur refuse `0` comme toute note hors 1–5 : on n'envoie
            // rien tant qu'une étoile n'est pas choisie.
            onPressed: _stars == 0
                ? null
                : () => widget.controller.rate(
                    stars: _stars,
                    comment: _comment.text,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Bouton « Urgence » (§ 7.3.9, T6.3).
///
/// `GET /v1/emergency-contact/` rend un numéro, ou
/// `503 emergency_contact_not_configured` s'il n'y a pas de ligne active : le
/// bouton est alors **masqué**, plutôt que d'ouvrir un appel vers rien.
class _EmergencyButton extends StatefulWidget {
  const _EmergencyButton();

  @override
  State<_EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<_EmergencyButton> {
  String? _number;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final service = context.read<EmergencyContactService>();
      final number = await service.phoneNumber();
      if (mounted) setState(() => _number = number);
    } on Object {
      // Pas de numéro connu : pas de bouton. Rien à signaler à l'utilisateur.
    }
  }

  @override
  Widget build(BuildContext context) {
    final number = _number;
    if (number == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return OutlineAction(
      label: l10n.trackingEmergency,
      icon: AppIcons.emergency,
      color: AppColors.error,
      onPressed: () => ExternalActions.call(number),
    );
  }
}
