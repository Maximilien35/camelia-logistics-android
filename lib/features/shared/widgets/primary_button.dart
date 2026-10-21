/// Bouton principal de la maquette : 56 px de haut, rayon 16.
///
/// Trois états relevés dans `Camelia V2.dc.html` :
/// - **actif** : fond [AppColors.ink], texte blanc, ombre portée ;
/// - **inactif** : fond [AppColors.border], texte gris — la maquette grise le
///   bouton tant que le formulaire est incomplet (écran « Connexion [Nominal] »
///   contre « Connexion [Erreur] ») ;
/// - **en cours** : indicateur de progression à la place du libellé.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.expanded = true,
    this.trailingIcon,
  });

  final String label;

  /// `null` grise le bouton, conformément à l'état inactif de la maquette.
  final VoidCallback? onPressed;

  /// Masque le libellé au profit d'un indicateur, et neutralise l'appui.
  ///
  /// Important sur `confirm-delivery` (règle non négociable n°7) : un double
  /// appui ne doit pas lancer deux fois le paiement.
  final bool busy;

  final bool expanded;

  /// Icône après le libellé (flèche « Suivant ») — refonte UI.
  final IconData? trailingIcon;

  bool get _enabled => onPressed != null && !busy;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: AppDimens.controlHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _enabled ? AppColors.ink : AppColors.border,
          borderRadius: BorderRadius.circular(AppRadii.button),
          boxShadow: _enabled
              ? const [
                  BoxShadow(
                    color: Color(0x330E0E10),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.button),
          child: InkWell(
            onTap: _enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppRadii.button),
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Le libellé change de page en page (« Suivant » →
                        // « Commencer ») : il glisse au lieu de sauter.
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Text(
                            label,
                            key: ValueKey(label),
                            style: TextStyle(
                              color: _enabled
                                  ? AppColors.white
                                  : AppColors.inkDisabled,
                              fontWeight: FontWeight.w700,
                              fontSize: AppFontSize.bodyLarge,
                            ),
                          ),
                        ),
                        if (trailingIcon != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            trailingIcon,
                            size: 18,
                            color: _enabled
                                ? AppColors.white
                                : AppColors.inkDisabled,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
