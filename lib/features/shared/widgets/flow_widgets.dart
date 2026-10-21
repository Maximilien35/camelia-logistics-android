/// Briques visuelles récurrentes des maquettes « Commande », « Suivi » et
/// « Course » : fond dégradé, en-tête avec retour, étiquette de section,
/// carte blanche, puce de statut, bandeaux d'information et d'erreur.
///
/// Valeurs relevées dans `Camelia V2.dc.html` (dégradés, rayons, ombres).
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_icons.dart';

/// Les deux fonds dégradés de la maquette.
enum FlowBackdrop {
  /// Lavande → pêche → crème (suivi, récapitulatif, détail de course).
  lavender,

  /// Lavande pâle → blanc (formulaires, preuves).
  soft,

  /// Blanc uni (confirmation).
  plain,
}

class FlowScaffold extends StatelessWidget {
  const FlowScaffold({
    super.key,
    required this.child,
    this.backdrop = FlowBackdrop.soft,
    this.bottom,
  });

  final Widget child;
  final FlowBackdrop backdrop;

  /// Zone d'action collée en bas (bouton principal).
  final Widget? bottom;

  static const _lavender = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFE7DCFF),
      Color(0xFFEFE6FB),
      Color(0xFFF9F1EB),
      Color(0xFFFBF8F6),
    ],
    stops: [0, .22, .56, .82],
  );

  static const _soft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF3ECFF), Color(0xFFFBF6F2), AppColors.white],
    stops: [0, .34, .72],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: switch (backdrop) {
            FlowBackdrop.lavender => _lavender,
            FlowBackdrop.soft => _soft,
            FlowBackdrop.plain => null,
          },
          color: backdrop == FlowBackdrop.plain ? AppColors.white : null,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(child: child),
              if (bottom != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: bottom,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// En-tête : bouton retour 28 px, titre, sous-titre et puce facultatifs.
class FlowHeader extends StatelessWidget {
  const FlowHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
    this.large = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Par défaut, dépile la route courante.
  final VoidCallback? onBack;

  /// Titre de formulaire (21 px) plutôt que titre de suivi (15 px).
  final bool large;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (onBack != null || canPop) ...[
            _BackButton(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: large ? 21 : 15,
                    color: AppColors.ink,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: AppFontSize.micro,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkMuted,
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(9),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140E0E10),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: const Icon(
            AppIcons.chevronLeft,
            size: 20,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

/// Étiquette de section en capitales (11 px, gris, espacée).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color = AppColors.inkMuted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: AppFontSize.micro,
        fontWeight: FontWeight.w700,
        letterSpacing: .5,
        color: color,
      ),
    ),
  );
}

/// Carte blanche à ombre douce double (rayon 18–22 px dans la maquette).
class FlowCard extends StatelessWidget {
  const FlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.color = AppColors.white,
    this.bordered = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final bool bordered;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: bordered ? Border.all(color: AppColors.border, width: 1.5) : null,
      boxShadow: bordered || color != AppColors.white
          ? null
          : const [
              BoxShadow(
                color: Color(0x0D0E0E10),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
              BoxShadow(
                color: Color(0x124818F0),
                blurRadius: 26,
                offset: Offset(0, 10),
              ),
            ],
    ),
    child: child,
  );
}

/// Puce de statut colorée (fond teinté à 12 %).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: AppFontSize.micro,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

/// Ligne « libellé ······ valeur ».
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: emphasize ? 14 : 13,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            color: emphasize ? AppColors.ink : AppColors.inkMuted,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: emphasize
                ? const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w800,
                    fontSize: AppFontSize.headline,
                    color: AppColors.ink,
                  )
                : const TextStyle(
                    fontSize: AppFontSize.label,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
          ),
        ),
      ],
    ),
  );
}

/// Bandeau d'information violet pâle.
class InfoNotice extends StatelessWidget {
  const InfoNotice({
    super.key,
    required this.message,
    this.icon = AppIcons.info,
    this.title,
  });

  final String message;
  final String? title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.brandTint,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppColors.border, width: 1.5),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.brand),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    title!,
                    style: const TextStyle(
                      fontSize: AppFontSize.label,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              Text(
                message,
                style: const TextStyle(
                  fontSize: AppFontSize.caption,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Bandeau d'erreur rouge.
class ErrorNotice extends StatelessWidget {
  const ErrorNotice({super.key, required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0x1AE5483A),
      borderRadius: BorderRadius.circular(AppRadii.small),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: const TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
            fontSize: AppFontSize.label,
            height: 1.4,
          ),
        ),
        if (action != null) ...[const SizedBox(height: AppSpacing.sm), action!],
      ],
    ),
  );
}

/// Bouton principal violet (actions chauffeur, maquette « Course »).
class BrandButton extends StatelessWidget {
  const BrandButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return SizedBox(
      width: double.infinity,
      height: AppDimens.controlHeight,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.inkDisabled,
          elevation: enabled ? 6 : 0,
          shadowColor: const Color(0x594818F0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: AppFontSize.bodyLarge,
          ),
        ),
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
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                ],
              ),
      ),
    );
  }
}

/// Bouton secondaire à bordure (52 px).
class OutlineAction extends StatelessWidget {
  const OutlineAction({
    super.key,
    required this.label,
    this.onPressed,
    this.color = AppColors.ink,
    this.icon,
    this.height = AppDimens.controlHeightCompact,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final double height;
  final bool busy;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: height,
    child: OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: AppFontSize.body,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    ),
  );
}

/// Pastille de départ (rond violet) / d'arrivée (carré cyan) des adresses.
class RoutePoints extends StatelessWidget {
  const RoutePoints({
    super.key,
    required this.pickupLabel,
    required this.pickup,
    required this.dropoffLabel,
    required this.dropoff,
    this.pickupNote,
    this.dropoffNote,
    this.pickupColor = AppColors.brand,
    this.dropoffColor = AppColors.accentCyan,
  });

  final String pickupLabel;
  final String pickup;
  final String? pickupNote;
  final String dropoffLabel;
  final String dropoff;
  final String? dropoffNote;
  final Color pickupColor;
  final Color dropoffColor;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _point(pickupLabel, pickup, pickupNote, pickupColor, round: true),
      const SizedBox(height: AppSpacing.md),
      _point(dropoffLabel, dropoff, dropoffNote, dropoffColor, round: false),
    ],
  );

  Widget _point(
    String label,
    String value,
    String? note,
    Color color, {
    required bool round,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        margin: const EdgeInsets.only(top: 4),
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: color,
          shape: round ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: round ? null : BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: AppFontSize.micro,
                fontWeight: FontWeight.w700,
                letterSpacing: .4,
                color: AppColors.inkMuted,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: AppFontSize.label,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            if (note != null && note.isNotEmpty)
              Text(
                note,
                style: const TextStyle(
                  fontSize: AppFontSize.caption,
                  color: AppColors.inkMuted,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
