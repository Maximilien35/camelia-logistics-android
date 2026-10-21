/// Gabarit commun aux écrans d'authentification de la maquette.
///
/// Relevé dans `Camelia V2.dc.html` : fond blanc, 22 px de marge latérale,
/// 74 px de marge haute (sous l'encoche), contenu en colonne avec un
/// [Spacer] qui pousse l'action principale vers le bas.
///
/// Le contenu reste défilable : à 402 × 874 la maquette tient à l'écran, mais
/// un clavier ouvert sur un appareil court déborderait sans cela.
///
/// **Refonte UI** (au-delà du handoff) :
/// - l'écran de connexion ([showBrand]) s'ouvre sur un en-tête encre où un
///   camion parcourt le motif trajet de l'app — la même surface que l'en-tête
///   de l'accueil client ;
/// - les blocs entrent en cascade ([Entrance]), sans que chaque écran ait à
///   l'écrire ;
/// - retour dans une pastille ronde, badge d'icône animé ([AuthIconBadge]) et
///   progression d'inscription en forme de trajet ([AuthStepRoute]).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import 'entrance.dart';
import 'pressable.dart';
import 'route_decoration.dart';
import 'transport_motion.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.children,
    this.showBrand = false,
    this.onBack,
  });

  /// Contenu de la colonne. Insérer un [Spacer] là où la maquette pousse
  /// l'action vers le bas.
  final List<Widget> children;

  /// En-tête de marque animé de l'écran de connexion.
  final bool showBrand;

  /// Flèche de retour. `null` = pas de retour possible (écran racine).
  final VoidCallback? onBack;

  /// Enveloppe chaque bloc dans une [Entrance], dans l'ordre. Les [Spacer] et
  /// les [SizedBox] d'espacement restent nus : un [Spacer] doit rester enfant
  /// direct de la colonne, et un vide n'a rien à animer.
  ///
  /// Chaque [Entrance] porte une clé stable (type du bloc + rang parmi ses
  /// semblables) : quand une bannière d'erreur s'insère au milieu, les blocs
  /// suivants gardent leur état au lieu d'être rattachés à celui du voisin —
  /// ce qui rejouerait leur entrée et recréerait les champs.
  List<Widget> _cascade(List<Widget> blocks, {int from = 0}) {
    var index = from;
    final seen = <Type, int>{};
    return [
      for (final block in blocks)
        if (block is Spacer || block is SizedBox)
          block
        else
          Entrance(
            key: ValueKey((
              block.runtimeType,
              seen.update(block.runtimeType, (n) => n + 1, ifAbsent: () => 0),
            )),
            index: index++,
            child: block,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    final content = Padding(
      padding: EdgeInsets.only(
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        top: showBrand ? AppSpacing.xxl : top + AppSpacing.md,
        bottom: AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!showBrand)
            Align(
              alignment: Alignment.centerLeft,
              // Toujours présent, même sans retour : le titre tombe ainsi au
              // même endroit sur tous les écrans d'authentification.
              child: SizedBox(
                height: 44,
                child: onBack == null ? null : _BackButton(onTap: onBack!),
              ),
            ),
          ..._cascade(children, from: showBrand ? 2 : 0),
        ],
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: showBrand ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                // `IntrinsicHeight` est indispensable, pas décoratif : les
                // écrans placent un `Spacer` pour pousser l'action vers le
                // bas, or un `Spacer` exige une hauteur bornée. Dans un
                // `SingleChildScrollView` la colonne est verticalement infinie
                // et le `Spacer` lève une assertion de layout.
                // `IntrinsicHeight` donne une contrainte ferme ; combiné au
                // `minHeight` ci-dessus, la colonne occupe max(hauteur du
                // contenu, hauteur visible) et le `Spacer` absorbe l'écart,
                // exactement comme dans la maquette.
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showBrand) const _BrandHero(),
                      Expanded(child: content),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: .9,
      semanticLabel: AppLocalizations.of(context)!.authBack,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: const Icon(AppIcons.back, size: 20, color: AppColors.ink),
      ),
    );
  }
}

/// En-tête de l'écran de connexion : surface encre, camion qui parcourt la
/// route, marque et accroche.
///
/// Le camion fait trois trajets puis se gare à destination : l'en-tête reste
/// vivant à l'arrivée sans distraire pendant la saisie.
class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final top = MediaQuery.paddingOf(context).top;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppGradients.inkPanel,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        child: SizedBox(
          height: top + 236,
          child: Stack(
            children: [
              // Le trajet passe au-dessus de la marque, à droite du logo :
              // jamais derrière le texte.
              Positioned(
                left: 92,
                right: AppSpacing.sm,
                top: top + AppSpacing.sm,
                height: 112,
                child: const TravellingRoute(
                  start: Offset(.04, .92),
                  end: Offset(.86, .34),
                  cycles: 3,
                ),
              ),
              Positioned(
                left: AppDimens.screenPadding,
                right: AppDimens.screenPadding,
                bottom: AppSpacing.xxl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Entrance(
                      offset: 10,
                      child: BrandMark(size: 52, elevated: false),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Entrance(
                      index: 1,
                      child: Text.rich(
                        TextSpan(
                          text: l10n.authBrandName,
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w800,
                            fontSize: AppFontSize.display,
                            height: 1.1,
                            color: AppColors.white,
                          ),
                          children: [
                            TextSpan(
                              text: ' ${l10n.authBrandTagline}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.white.withValues(alpha: .6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Entrance(
                      index: 2,
                      child: Text(
                        l10n.authHeroTagline,
                        style: TextStyle(
                          fontSize: AppFontSize.label,
                          height: 1.4,
                          color: AppColors.white.withValues(alpha: .72),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastille d'icône en tête d'écran, entourée d'ondes qui s'élargissent.
///
/// Les ondes font trois tours puis s'arrêtent : un repère vivant à l'arrivée,
/// pas un clignotement permanent pendant la saisie.
class AuthIconBadge extends StatelessWidget {
  const AuthIconBadge(this.icon, {super.key, this.color = AppColors.brand});

  final IconData icon;
  final Color color;

  static const double _size = 64;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: _size,
        height: _size,
        child: MotionLoop(
          period: const Duration(milliseconds: 1800),
          cycles: 3,
          restAt: 0,
          builder: (context, t, child) => CustomPaint(
            painter: _RipplePainter(t: t, color: color),
            child: child,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: color == AppColors.brand
                  ? AppColors.brandTint
                  : color.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final center = size.center(Offset.zero);
    final base = size.shortestSide / 2;
    for (var i = 0; i < 2; i++) {
      final phase = (t - i * .25).clamp(0.0, 1.0);
      if (phase <= 0) continue;
      canvas.drawCircle(
        center,
        base + 18 * phase,
        Paint()
          ..color = color.withValues(alpha: .22 * (1 - phase))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.t != t;
}

/// Progression de l'inscription en forme de trajet : trois arrêts (compte,
/// vérification, arrivée), le camion posé sur l'étape en cours.
class AuthStepRoute extends StatelessWidget {
  const AuthStepRoute({super.key, required this.current});

  /// Étape en cours : 0 = compte, 1 = vérification, 2 = terminé.
  final int current;

  static const double _chip = 28;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.authStepAccount,
      l10n.authStepVerify,
      l10n.authStepReady,
    ];

    return Semantics(
      label: l10n.onboardingProgress(current + 1, labels.length),
      excludeSemantics: true,
      // Hauteur fixée **hors** du `LayoutBuilder` : le gabarit mesure ses
      // blocs par `IntrinsicHeight`, que `LayoutBuilder` ne sait pas fournir.
      child: SizedBox(
        height: _chip + AppSpacing.sm + 16,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const chip = _chip;
            final span = constraints.maxWidth - chip;
            final step = span / (labels.length - 1);
            return TweenAnimationBuilder<double>(
              // Le camion arrive de l'étape précédente à l'ouverture.
              tween: Tween(
                begin: math.max(0, current - 1).toDouble(),
                end: current.toDouble(),
              ),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOutCubic,
              builder: (context, position, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: chip / 2,
                    right: chip / 2,
                    top: chip / 2 - 1,
                    height: 2,
                    child: const CustomPaint(
                      painter: DashedLinePainter(
                        color: AppColors.borderStrong,
                        dash: 4,
                        gap: 4,
                      ),
                    ),
                  ),
                  Positioned(
                    left: chip / 2,
                    width: step * position,
                    top: chip / 2 - 1.5,
                    height: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  for (final (i, label) in labels.indexed) ...[
                    Positioned(
                      left: chip / 2 + step * i - 5,
                      top: chip / 2 - 5,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: i <= position
                              ? AppColors.ink
                              : AppColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: i <= position
                                ? AppColors.ink
                                : AppColors.borderStrong,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: chip + AppSpacing.sm,
                      left: i == 0 ? 0 : null,
                      right: i == labels.length - 1 ? 0 : null,
                      child: i == 0 || i == labels.length - 1
                          ? _StepLabel(label: label, active: i == current)
                          : SizedBox(
                              width: constraints.maxWidth,
                              child: Center(
                                child: _StepLabel(
                                  label: label,
                                  active: i == current,
                                ),
                              ),
                            ),
                    ),
                  ],
                  Positioned(
                    left: step * position,
                    top: 0,
                    child: Container(
                      width: chip,
                      height: chip,
                      decoration: const BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        AppIcons.truck,
                        size: 15,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      fontSize: AppFontSize.caption,
      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      color: active ? AppColors.ink : AppColors.inkDisabled,
    ),
  );
}

/// Titre d'écran : Space Grotesk 25 px, interligne 1,25.
class AuthTitle extends StatelessWidget {
  const AuthTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: AppFonts.display,
      fontWeight: FontWeight.w700,
      fontSize: AppFontSize.display,
      height: 1.25,
      color: AppColors.ink,
    ),
  );
}

/// Sous-titre d'écran : 14 px, interligne 1,5, gris.
class AuthSubtitle extends StatelessWidget {
  const AuthSubtitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: AppFontSize.body,
      height: 1.5,
      color: AppColors.inkMuted,
    ),
  );
}

/// Séparateur « ou » entre deux façons de se connecter.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context)!.authOrDivider;
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: FontWeight.w600,
              color: AppColors.inkDisabled,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border, height: 1)),
      ],
    );
  }
}

/// Bouton secondaire à contour, avec icône : autre moyen de connexion.
class AuthOutlineButton extends StatelessWidget {
  const AuthOutlineButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: AppDimens.controlHeightCompact,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.button),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.ink),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppFontSize.body,
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

/// Bannière d'erreur, pour un échec qui ne se rattache à aucun champ
/// (identifiants refusés, panne réseau, quota dépassé).
///
/// Elle entre en secouant légèrement de gauche à droite : le refus se sent,
/// comme un « non » de la tête.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // Clé sur le message : un nouveau refus rejoue la secousse.
      key: ValueKey(message),
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 480),
      builder: (context, t, child) => Transform.translate(
        offset: Offset(math.sin(t * math.pi * 4) * 6 * (1 - t), 0),
        child: child,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x1AE5483A),
          borderRadius: BorderRadius.circular(AppRadii.small),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(AppIcons.error, size: 18, color: AppColors.error),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: AppFontSize.label,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
