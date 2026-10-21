/// Étape 7 · **Confirmation** — maquette « Commande — Client / 7 ».
///
/// Tout vient de la réponse `201` de `POST /v1/orders/` : référence, trajet,
/// **total calculé par le serveur** (`price_total`, `null` en devis manuel).
///
/// Écart assumé : la ligne « Paiement · Orange Money » devient « À la
/// livraison · Mobile Money » — aucun moyen de paiement n'est choisi avant la
/// course côté backend.
///
/// Pour `shipping`, la réponse porte `whatsapp_redirect` : le lien ne s'ouvre
/// que sur appui du bouton, jamais automatiquement.
library;

import 'package:flutter/material.dart';

import '../../../../core/platform/external_actions.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/models/order.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../../shared/widgets/money.dart';
import '../../../shared/widgets/order_labels.dart';
import '../../../shared/widgets/primary_button.dart';
import 'order_tracking_screen.dart';
import '../../../../core/theme/app_icons.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.order});

  final Order order;

  Future<void> _openWhatsApp(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ExternalActions.openServerLink(
      order.whatsappRedirect!.waLink,
    );
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.externalOpenFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final manual = order.serviceType.isManualQuote;
    final redirect = order.whatsappRedirect;

    return FlowScaffold(
      backdrop: FlowBackdrop.plain,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (redirect != null && redirect.waLink.isNotEmpty) ...[
            PrimaryButton(
              label: l10n.orderOpenWhatsApp,
              onPressed: () => _openWhatsApp(context),
            ),
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            PrimaryButton(
              label: l10n.orderTrack,
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      OrderTrackingScreen(orderId: order.id, initial: order),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: Text(
              l10n.commonBackHome,
              style: const TextStyle(
                fontSize: AppFontSize.label,
                fontWeight: FontWeight.w700,
                color: AppColors.brand,
              ),
            ),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 12),
        children: [
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0x1A4818F0),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.brand,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x594818F0),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  AppIcons.check,
                  color: AppColors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            manual ? l10n.orderManualConfirmedTitle : l10n.orderConfirmedTitle,
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
            l10n.orderReference(order.reference),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppFontSize.label,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          FlowCard(
            color: AppColors.brandTint,
            radius: 16,
            child: Column(
              children: [
                KeyValueRow(
                  label: l10n.orderConfirmRoute,
                  value:
                      '${shortAddress(order.pickupAddress)} → '
                      '${shortAddress(order.dropoffAddress)}',
                ),
                KeyValueRow(
                  label: l10n.orderConfirmType,
                  value: serviceLabel(l10n, order.serviceType),
                ),
                if (!manual)
                  KeyValueRow(
                    label: l10n.orderConfirmPayment,
                    value: l10n.orderConfirmPaymentValue,
                  ),
                const Divider(height: 18, color: AppColors.border),
                KeyValueRow(
                  label: l10n.orderConfirmTotal,
                  // Total du serveur, tel quel (règle non négociable n°3).
                  value: order.priceTotal == null
                      ? l10n.orderConfirmQuote
                      : formatAmount(order.priceTotal, locale: locale),
                  emphasize: true,
                ),
              ],
            ),
          ),
          if (redirect != null) ...[
            const SizedBox(height: AppSpacing.lg),
            InfoNotice(
              icon: AppIcons.whatsapp,
              message: l10n.orderWhatsAppNote,
            ),
          ],
        ],
      ),
    );
  }
}
