/// Présentation de l'app au premier lancement — refonte UI (hors handoff).
///
/// Quatre pages, chacune une promesse que le produit tient réellement :
/// 1. les quatre services (`service_type` du serveur) ;
/// 2. le trajet en deux adresses, avec un prix affiché avant de commander
///    pour le colis et le déménagement — les deux services à prix immédiat ;
/// 3. le suivi par étapes, rafraîchi sur notification (règle n°5 : jamais de
///    connexion ouverte) — le backend pousse à chaque changement de statut ;
/// 4. l'inscription chauffeur, soumise à validation par Camelia.
///
/// Montrée **une seule fois** par appareil ([OnboardingController]), avant la
/// connexion. Elle n'ouvre aucune expérience : l'aiguillage Client / Chauffeur
/// reste celui du `role` renvoyé par le serveur.
///
/// Mise en page : la surface encre du haut est **fixe** ; seules les
/// illustrations et les textes glissent par-dessus, avec un léger décalage
/// (parallaxe) qui donne de la profondeur au geste.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/route_decoration.dart';
import '../../widgets/transport_motion.dart';
import 'onboarding_illustrations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  /// Fin de la présentation : « Commencer » ou « Passer ».
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _pageCount = 4;

  final PageController _pages = PageController();
  int _current = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool get _isLast => _current == _pageCount - 1;

  void _next() {
    if (_isLast) {
      widget.onDone();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  /// Position continue de la page, y compris pendant le geste.
  double get _page => _pages.hasClients && _pages.position.haveDimensions
      ? _pages.page ?? _current.toDouble()
      : _current.toDouble();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final height = media.size.height;
    // La surface sombre occupe un peu plus de la moitié de l'écran, sans
    // écraser le texte sur un petit téléphone.
    final panelHeight = (height * .54).clamp(300.0, 480.0);
    final top = media.padding.top;

    final pages = [
      _PageData(
        eyebrow: l10n.onboardingEyebrow1,
        title: l10n.onboardingTitle1,
        body: l10n.onboardingBody1,
        illustration: const NetworkIllustration(),
      ),
      _PageData(
        eyebrow: l10n.onboardingEyebrow2,
        title: l10n.onboardingTitle2,
        body: l10n.onboardingBody2,
        illustration: RouteIllustration(
          pickupLabel: l10n.onboardingPickupChip,
          dropoffLabel: l10n.onboardingDropoffChip,
          instantLabel: l10n.onboardingInstantChip,
        ),
      ),
      _PageData(
        eyebrow: l10n.onboardingEyebrow3,
        title: l10n.onboardingTitle3,
        body: l10n.onboardingBody3,
        illustration: TrackingIllustration(
          steps: [
            l10n.orderStatusDriverAssigned,
            l10n.orderStatusPickedUp,
            l10n.orderStatusInTransit,
            l10n.orderStatusDelivered,
          ],
        ),
      ),
      _PageData(
        eyebrow: l10n.onboardingEyebrow4,
        title: l10n.onboardingTitle4,
        body: l10n.onboardingBody4,
        illustration: DriverIllustration(
          verifiedLabel: l10n.onboardingVerifiedChip,
        ),
      ),
    ];

    // Surface sombre en haut : icônes de la barre d'état en clair.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Stack(
          children: [
            // Surface fixe : encre neutre (pas d'aplat violet), route estompée
            // en filigrane.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: panelHeight,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppGradients.inkPanel,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: CustomPaint(
                  painter: RouteDecorationPainter(
                    lineColor: Color(0x0FFFFFFF),
                    start: Offset(-.1, .35),
                    end: Offset(1.1, .95),
                  ),
                ),
              ),
            ),

            PageView.builder(
              controller: _pages,
              itemCount: _pageCount,
              onPageChanged: (i) {
                HapticFeedback.selectionClick();
                setState(() => _current = i);
              },
              itemBuilder: (context, i) => AnimatedBuilder(
                animation: _pages,
                builder: (context, _) => _OnboardingPage(
                  data: pages[i],
                  delta: i - _page,
                  panelHeight: panelHeight,
                  topInset: top + 64,
                ),
              ),
            ),

            // Barre du haut : marque à gauche, « Passer » à droite.
            Positioned(
              left: AppDimens.screenPadding,
              right: AppSpacing.md,
              top: top + AppSpacing.md,
              child: Row(
                children: [
                  const BrandMark(size: 34, elevated: false),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.authBrandName,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w800,
                      fontSize: AppFontSize.title,
                      color: AppColors.white,
                    ),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: _isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: _isLast,
                      child: TextButton(
                        onPressed: widget.onDone,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.white,
                        ),
                        child: Text(
                          l10n.onboardingSkip,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: AppFontSize.body,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bas d'écran fixe : progression et action.
            Positioned(
              left: AppDimens.screenPadding,
              right: AppDimens.screenPadding,
              bottom: media.padding.bottom + AppSpacing.xxl,
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pages,
                    builder: (context, _) => Semantics(
                      label: l10n.onboardingProgress(_current + 1, _pageCount),
                      child: _RouteIndicator(page: _page, count: _pageCount),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: PrimaryButton(
                      label: _isLast
                          ? l10n.onboardingStart
                          : l10n.onboardingNext,
                      trailingIcon: AppIcons.forwardBold,
                      onPressed: _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  const _PageData({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.illustration,
  });

  final String eyebrow;
  final String title;
  final String body;
  final Widget illustration;
}

/// Une page : l'illustration sur la surface sombre, le texte en dessous.
///
/// [delta] est l'écart à la page affichée (0 = centrée, ±1 = à côté) : il
/// pilote la parallaxe — l'illustration glisse moins vite que la page et
/// rétrécit un peu, le texte prend un léger retard et s'estompe.
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.delta,
    required this.panelHeight,
    required this.topInset,
  });

  final _PageData data;
  final double delta;
  final double panelHeight;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final d = delta.clamp(-1.0, 1.0);
    final fade = (1 - d.abs() * 1.4).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: panelHeight,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              topInset,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            child: Transform.translate(
              offset: Offset(d * width * .35, 0),
              child: Transform.scale(
                scale: 1 - d.abs() * .12,
                child: Opacity(opacity: fade, child: data.illustration),
              ),
            ),
          ),
        ),
        Expanded(
          child: Transform.translate(
            offset: Offset(d * width * .18, 0),
            child: Opacity(
              opacity: fade,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                // Le bas d'écran (progression + bouton) est posé par-dessus.
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.screenPadding,
                  AppSpacing.xxl,
                  AppDimens.screenPadding,
                  AppDimens.controlHeight + AppSpacing.xxxl * 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.eyebrow.toUpperCase(),
                      style: const TextStyle(
                        fontSize: AppFontSize.micro,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.brand,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: AppFontSize.display,
                        height: 1.15,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      data.body,
                      style: const TextStyle(
                        fontSize: AppFontSize.body,
                        height: 1.55,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Indicateur de progression en forme de trajet : une route en pointillés,
/// un arrêt par page, et un petit camion qui roule d'arrêt en arrêt en
/// suivant le doigt.
class _RouteIndicator extends StatelessWidget {
  const _RouteIndicator({required this.page, required this.count});

  final double page;
  final int count;

  static const double _gap = 26;
  static const double _truck = 26;

  @override
  Widget build(BuildContext context) {
    final width = _gap * (count - 1) + _truck;
    final x = page.clamp(0.0, count - 1.0) * _gap;

    return SizedBox(
      width: width,
      height: _truck,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Route à venir, en pointillés.
          Positioned(
            left: _truck / 2,
            right: _truck / 2,
            top: _truck / 2 - 1,
            height: 2,
            child: const CustomPaint(
              painter: DashedLinePainter(
                color: AppColors.borderStrong,
                dash: 3,
                gap: 3,
              ),
            ),
          ),
          // Route parcourue, en trait plein.
          Positioned(
            left: _truck / 2,
            width: x,
            top: _truck / 2 - 1.5,
            height: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          for (var i = 0; i < count; i++)
            Positioned(
              left: _truck / 2 + i * _gap - 4,
              top: _truck / 2 - 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i <= page + .01 ? AppColors.ink : AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: i <= page + .01
                        ? AppColors.ink
                        : AppColors.borderStrong,
                    width: 2,
                  ),
                ),
              ),
            ),
          Positioned(
            left: x,
            top: 0,
            child: Container(
              width: _truck,
              height: _truck,
              decoration: const BoxDecoration(
                color: AppColors.brand,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.truck,
                size: 14,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
