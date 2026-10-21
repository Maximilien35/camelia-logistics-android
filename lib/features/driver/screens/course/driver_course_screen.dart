/// **Course en cours** — maquettes « App chauffeur — Course » 2, 3, 5 et
/// « Gains & Profil / 1. Fin de course ».
///
/// Un écran, trois étapes pilotées par le dernier statut **renvoyé par le
/// serveur** (voir [CourseController], qui relit
/// `GET /v1/driver/orders/current/`) :
/// - vers la collecte (`driver_en_route_pickup`) → « J'ai récupéré » ouvre la
///   preuve de collecte ;
/// - vers la livraison (`in_transit`) → « Je suis arrivé » ouvre la preuve de
///   livraison, code à quatre chiffres compris ;
/// - livrée (`delivered`) → fin de course, le client paie.
///
/// ## Le montant affiché est un **gain**, jamais le prix client
///
/// `price_total` a été retiré de tous les canaux chauffeur (§ 2.3, T6.8) : le
/// servir à côté du gain rendrait la commission Camelia calculable de tête par
/// soustraction. L'écran affiche donc `GET /v1/driver/orders/{id}/earnings/`
/// (§ 7.4.5, T7.1), et dit explicitement si c'est une **prévision** ou le
/// montant **crédité** — les deux divergent sur une annulation avec frais, un
/// litige ou un ajustement. Toujours un total, jamais une ventilation
/// (règle n°3).
///
/// **Écarts assumés, toujours valables** :
/// - **aucune carte** ni guidage (« 400 m · Continuer sur… ») : la navigation
///   est déléguée à l'application de cartes du téléphone (« Ouvrir dans
///   Maps »), la carte intégrée étant réservée à l'écran A4 (règle n°11) ;
/// - fiche client notée (« Serge B. ★ 4,7 ») : le serveur n'expose pas de note
///   de client, seulement celle du chauffeur ;
/// - « Le bouton s'active dans un rayon de 150 m » : aucune règle serveur de
///   proximité, et l'app n'en invente pas ;
/// - durées « ~7 min » côté chauffeur : `eta_minutes` est volontairement
///   absent des routes chauffeur — c'est lui qui roule, on n'estime pas son
///   propre trajet.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_error_messages.dart';
import '../../../../core/platform/external_actions.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/models/geo_point.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../../shared/widgets/money.dart';
import '../../../shared/widgets/order_labels.dart';
import '../../../shared/widgets/package_photo_strip.dart';
import '../../state/course_controller.dart';
import 'delivery_proof_screen.dart';
import 'pickup_proof_screen.dart';
import 'return_proof_screen.dart';
import '../../../../core/theme/app_icons.dart';

class DriverCourseScreen extends StatefulWidget {
  const DriverCourseScreen({super.key, required this.controller});

  final CourseController controller;

  @override
  State<DriverCourseScreen> createState() => _DriverCourseScreenState();
}

class _DriverCourseScreenState extends State<DriverCourseScreen> {
  @override
  void initState() {
    super.initState();
    // Relecture à l'ouverture : la course a pu changer d'état pendant que
    // l'app était fermée. Pas de sondage en boucle (règle n°5).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final course = widget.controller.course;
        if (course == null) {
          // Course libérée : rien à afficher, retour à la liste.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).maybePop();
          });
          return const Scaffold(backgroundColor: AppColors.background);
        }
        return switch (widget.controller.stage) {
          CourseStage.finished => _FinishedView(controller: widget.controller),
          _ => _InProgressView(controller: widget.controller),
        };
      },
    );
  }
}

class _InProgressView extends StatelessWidget {
  const _InProgressView({required this.controller});

  final CourseController controller;

  Future<void> _openMaps(
    BuildContext context,
    String address,
    GeoPoint? point,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final opened = await ExternalActions.navigateTo(
      address,
      latitude: point?.latitude,
      longitude: point?.longitude,
    );
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.externalOpenFailed)));
    }
  }

  Future<void> _call(BuildContext context, String phone) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (!await ExternalActions.call(phone)) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.externalOpenFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final current = controller.course!;
    final order = controller.order!;
    final toPickup = controller.stage == CourseStage.toPickup;

    final stageLabel = toPickup
        ? l10n.driverCourseToPickup
        : l10n.driverCourseToDropoff;
    final stageColor = toPickup
        ? AppColors.accentMagenta
        : AppColors.accentCyan;
    final target = toPickup ? order.pickupAddress : order.dropoffAddress;
    // Coordonnées exactes : obligatoires à la création depuis T5.3, donc
    // toujours présentes sur une commande passée depuis l'app.
    final targetPoint = toPickup ? order.pickupPoint : order.dropoffPoint;

    // `client_phone` (l'expéditeur) et `recipient_phone` (celui qui reçoit)
    // sont deux personnes distinctes. Le premier n'est servi que pendant la
    // fenêtre de contact, et n'est jamais mémorisé d'une lecture à l'autre.
    final clientPhone = order.clientPhone;
    final recipientPhone = order.recipientPhone.trim();

    return FlowScaffold(
      backdrop: FlowBackdrop.lavender,
      bottom: controller.isStale
          ? null
          : BrandButton(
              label: toPickup
                  ? l10n.driverArrivedPickup
                  : l10n.driverArrivedDropoff,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => toPickup
                      ? PickupProofScreen(controller: controller)
                      : DeliveryProofScreen(controller: controller),
                ),
              ),
            ),
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          children: [
            FlowHeader(
              title: '#${order.reference}',
              subtitle: l10n.driverCourseAcceptedAt(
                DateFormat.Hm(locale).format(current.acceptedAt.toLocal()),
              ),
              trailing: StatusChip(label: stageLabel, color: stageColor),
            ),

            if (controller.isStale) ...[
              _StaleCard(controller: controller),
              const SizedBox(height: AppSpacing.md),
            ] else if (controller.failure != null) ...[
              ErrorNotice(
                message: messageForFailure(l10n, controller.failure!),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            _EarningsCard(controller: controller, locale: locale),
            const SizedBox(height: AppSpacing.md),

            // Destination de l'étape en cours.
            FlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color:
                              (toPickup ? AppColors.brand : AppColors.success)
                                  .withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: toPickup
                                ? AppColors.brand
                                : AppColors.success,
                            shape: toPickup
                                ? BoxShape.circle
                                : BoxShape.rectangle,
                            borderRadius: toPickup
                                ? null
                                : BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              target,
                              style: const TextStyle(
                                fontSize: AppFontSize.body,
                                height: 1.3,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            // Visible **dès l'acceptation** depuis T5.1, et
                            // non plus seulement après la collecte.
                            if (!toPickup && order.recipientName.isNotEmpty)
                              Text(
                                order.recipientName,
                                style: const TextStyle(
                                  fontSize: AppFontSize.caption,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlineAction(
                          label: l10n.driverOpenInMaps,
                          icon: AppIcons.navigation,
                          height: 44,
                          onPressed: () =>
                              _openMaps(context, target, targetPoint),
                        ),
                      ),
                      // Vers la collecte on appelle l'expéditeur, vers la
                      // livraison le destinataire : ce sont deux numéros.
                      if (toPickup && clientPhone != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlineAction(
                            label: l10n.driverCallClient,
                            icon: AppIcons.call,
                            height: 44,
                            onPressed: () => _call(context, clientPhone),
                          ),
                        ),
                      ] else if (!toPickup && recipientPhone.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlineAction(
                            label: l10n.driverCallRecipient,
                            icon: AppIcons.call,
                            height: 44,
                            onPressed: () => _call(context, recipientPhone),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Trajet complet.
            FlowCard(
              child: RoutePoints(
                pickupLabel: l10n.trackingPickupLabel,
                pickup: order.pickupAddress,
                pickupColor: toPickup ? AppColors.brand : AppColors.success,
                dropoffLabel: order.distanceKm == null
                    ? l10n.trackingDropoffLabel
                    : '${l10n.trackingDropoffLabel} · '
                          '${l10n.driverDistanceKm(order.distanceKm!)}',
                dropoff: order.dropoffAddress,
                dropoffColor: AppColors.ink,
              ),
            ),

            if ((order.packageDescription?.isNotEmpty ?? false) ||
                order.packageWeightKg != null ||
                order.packagePhotoUrls.isNotEmpty ||
                order.pickupFloor != null ||
                order.dropoffFloor != null) ...[
              const SizedBox(height: AppSpacing.md),
              FlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.packagePhotoUrls.isNotEmpty) ...[
                      PackagePhotoStrip(urls: order.packagePhotoUrls),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if ((order.packageDescription?.isNotEmpty ?? false) ||
                        order.packageWeightKg != null)
                      KeyValueRow(
                        label: l10n.driverParcelLabel,
                        value: [
                          if (order.packageWeightKg != null)
                            l10n.orderWeightValue(order.packageWeightKg!),
                          if (order.packageDescription?.isNotEmpty ?? false)
                            order.packageDescription!,
                        ].join(' · '),
                      ),
                    // Déménagement : étages à monter ou descendre de chaque
                    // côté (§ 6.6.2 « Étages »), `null` hors `moving`.
                    if (order.pickupFloor != null || order.dropoffFloor != null)
                      KeyValueRow(
                        label: l10n.orderFloorsLabel,
                        value: l10n.orderFloorsSummary(
                          l10n.floorValue(order.pickupFloor ?? 0),
                          l10n.floorValue(order.dropoffFloor ?? 0),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            Text(
              serviceLabel(l10n, order.serviceType),
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

/// Le gain de la course, et **seulement** le gain : le prix payé par le client
/// n'est servi sur aucun canal chauffeur (§ 2.3).
class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.controller, required this.locale});

  final CourseController controller;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amount = controller.earningsAmount;
    final note = amount == null
        ? l10n.driverCourseEarningsUnknown
        : (controller.earningsAreEstimated
              ? l10n.driverCourseEarningsEstimated
              : l10n.driverCourseEarningsCredited);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x400E0E10),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.driverCourseEarnings.toUpperCase(),
            style: const TextStyle(
              fontSize: AppFontSize.micro,
              fontWeight: FontWeight.w700,
              letterSpacing: .6,
              color: Color(0x8CFFFFFF),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatAmount(amount, locale: locale),
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: AppFontSize.display,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            note,
            style: const TextStyle(
              fontSize: AppFontSize.caption,
              height: 1.45,
              color: Color(0x99FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaleCard extends StatelessWidget {
  const _StaleCard({required this.controller});

  final CourseController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.error.withValues(alpha: .35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.driverCourseStaleTitle,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: AppFontSize.bodyLarge,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${l10n.driverCourseStaleBody}\n'
            '${messageForFailure(l10n, controller.failure!)}',
            style: const TextStyle(
              fontSize: AppFontSize.label,
              height: 1.5,
              color: AppColors.inkMuted,
            ),
          ),
          // Une annulation client **après collecte** laisse un colis à rendre
          // (`confirm-return/`). On ne le devine pas : le serveur tranche, et
          // `return_not_required` dira que non.
          if (controller.mayNeedReturn) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.driverReturnBody,
              style: const TextStyle(
                fontSize: AppFontSize.label,
                height: 1.5,
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlineAction(
              label: l10n.driverConfirmReturn,
              icon: AppIcons.returnParcel,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ReturnProofScreen(controller: controller),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          OutlineAction(
            label: l10n.driverCourseRelease,
            color: AppColors.error,
            onPressed: controller.release,
          ),
        ],
      ),
    );
  }
}

class _FinishedView extends StatelessWidget {
  const _FinishedView({required this.controller});

  final CourseController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final order = controller.order!;

    return FlowScaffold(
      bottom: BrandButton(
        label: l10n.driverFinishedContinue,
        onPressed: controller.release,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 48, 22, 16),
        children: [
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                AppIcons.check,
                size: 38,
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.driverFinishedTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w800,
              fontSize: AppFontSize.display,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '#${order.reference}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppFontSize.label,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          FlowCard(
            color: AppColors.brandTint,
            child: Column(
              children: [
                KeyValueRow(
                  label: l10n.driverCourseEarnings,
                  value: formatAmount(
                    controller.earningsAmount,
                    locale: locale,
                  ),
                  emphasize: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoNotice(
            icon: AppIcons.wallet,
            // `delivered` est un statut **actif** côté serveur : le chauffeur
            // attend sur place que le client paie, et c'est ce paiement qui
            // transforme la prévision en crédit.
            message: controller.earningsAreEstimated
                ? l10n.driverCourseEarningsEstimated
                : l10n.driverCourseEarningsCredited,
          ),
        ],
      ),
    );
  }
}
