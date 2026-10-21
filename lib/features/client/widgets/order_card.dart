/// Carte de commande du client — celle de l'accueil (« Commande en cours »),
/// reprise telle quelle par l'historique pour que les deux écrans parlent la
/// même langue visuelle.
///
/// Un seul widget, deux alimentations : l'accueil passe une commande complète
/// (avec son ruban), l'historique une ligne de liste (`OrderSummary`, sans
/// ruban). La carte ne décide de rien : libellés, ruban et prix viennent de
/// l'appelant — le prix, notamment, est le total du serveur affiché tel quel
/// (règle n°3).
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/models/order.dart';
import '../../shared/widgets/order_labels.dart';
import '../../shared/widgets/route_progress.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.eyebrow,
    required this.reference,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.serviceLabel,
    required this.status,
    required this.statusText,
    required this.onTap,
    this.ribbon = const [],
    this.trailing,
  });

  /// Petite ligne en capitales au-dessus du trajet (« Commande en cours »,
  /// date de la commande…).
  final String eyebrow;
  final String reference;
  final String pickupAddress;
  final String dropoffAddress;
  final String serviceLabel;

  final OrderStatus status;

  /// Libellé du bandeau d'état en coin, déjà localisé.
  final String statusText;

  /// Ruban de suivi ; vide quand la source n'en porte pas (historique).
  final List<RibbonStep> ribbon;

  /// Texte à droite de la ligne du service — le total du serveur en
  /// historique.
  final String? trailing;

  final VoidCallback onTap;

  /// Rayon de la carte, repris par la transition d'ouverture.
  static const double radius = 22;

  /// Ombre portée, à poser par le conteneur de la carte.
  static const List<BoxShadow> shadows = [
    BoxShadow(color: Color(0x380E0E10), blurRadius: 20, offset: Offset(0, 8)),
  ];

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);

    // Pas d'ombre ici : la carte est posée dans un [ExpandToScreen], qui la
    // porte — une ombre propre serait rognée par la transition d'ouverture.
    return Pressable(
      onTap: onTap,
      child: Material(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 60),
                    child: Text(
                      eyebrow.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSize.micro,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .6,
                        color: Color(0x80FFFFFF),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(right: 60),
                    child: Text(
                      '#$reference · ${shortAddress(pickupAddress)}'
                      ' → ${shortAddress(dropoffAddress)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSize.body,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          serviceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: AppFontSize.caption,
                            fontWeight: FontWeight.w600,
                            color: Color(0x99FFFFFF),
                          ),
                        ),
                      ),
                      if (trailing != null)
                        Text(
                          trailing!,
                          style: const TextStyle(
                            fontSize: AppFontSize.body,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                    ],
                  ),
                  if (ribbon.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    RouteProgress(
                      steps: ribbon,
                      onDark: true,
                      showLabels: false,
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: -34,
              child: Transform.rotate(
                angle: 0.66,
                child: Container(
                  width: 120,
                  color: color,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    statusText.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
