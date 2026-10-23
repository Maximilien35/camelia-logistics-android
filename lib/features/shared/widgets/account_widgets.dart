/// Briques des écrans de compte — refonte UI.
///
/// Partagées par l'onglet **Compte** du client et l'onglet **Profil** du
/// chauffeur, pour que les deux parlent la même langue visuelle : carte de
/// membre sombre (motif trajet), chiffres en tuiles, menus groupés par section
/// avec pictogrammes teintés.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../models/app_user.dart';
import '../state/auth_controller.dart';
import 'pill_segmented_control.dart';
import 'pressable.dart';
import 'route_decoration.dart';

// ---------------------------------------------------------------------------
// Carte de membre
// ---------------------------------------------------------------------------

class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.user,
    required this.editLabel,
    required this.onEdit,
    this.badge,
  });

  final AppUser user;
  final String editLabel;
  final VoidCallback onEdit;

  /// Pastille sous le nom (état de validation du chauffeur, par exemple).
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final name = user.fullName.isEmpty ? user.email : user.fullName;
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final contact = user.phone.isNotEmpty ? user.phone : user.email;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.inkPanel,
        borderRadius: BorderRadius.circular(AppRadii.sheet),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330E0E10),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            // Départ hors cadre, arrivée sous le bouton d'édition : la route
            // ne croise ni l'avatar, ni le bouton, ni la ligne du bas.
            child: CustomPaint(
              painter: RouteDecorationPainter(
                start: Offset(.40, 1.15),
                end: Offset(.80, .34),
              ),
            ),
          ),
          Positioned(
            right: -14,
            bottom: -18,
            child: Icon(
              AppIcons.package,
              size: 120,
              color: AppColors.white.withValues(alpha: .05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: .18),
                          width: 3,
                        ),
                      ),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w800,
                          fontSize: AppFontSize.headline,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Pressable(
                      onTap: onEdit,
                      pressedScale: .9,
                      semanticLabel: editLabel,
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: .1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: .14),
                          ),
                        ),
                        child: const Icon(
                          AppIcons.edit,
                          size: 18,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w800,
                    fontSize: AppFontSize.headline,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  contact,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white.withValues(alpha: .7),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  badge!,
                ],
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Icon(
                      AppIcons.verified,
                      size: 16,
                      color: AppColors.white.withValues(alpha: .55),
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Expanded(
                      child: Text(
                        l10n.accountMemberSince(
                          DateFormat.yMMMM(
                            locale,
                          ).format(user.createdAt.toLocal()),
                        ),
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white.withValues(alpha: .55),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.accent = AppColors.brand,
  });

  final IconData icon;

  /// Valeur déjà mise en forme ; `null` affiche un tiret, jamais un zéro
  /// inventé.
  final String? value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.field + 4),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(height: AppSpacing.sm),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              value ?? '—',
              key: ValueKey(value),
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w800,
                fontSize: AppFontSize.headline,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Menus
// ---------------------------------------------------------------------------

class AccountSectionLabel extends StatelessWidget {
  const AccountSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: AppSpacing.xxl,
      bottom: AppSpacing.md,
      left: AppSpacing.xs,
    ),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: AppFontSize.micro,
        fontWeight: FontWeight.w800,
        letterSpacing: .8,
        color: AppColors.inkDisabled,
      ),
    ),
  );
}

class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.xs),
  });

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadii.sheet),
      boxShadow: AppShadows.card,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class TintedIcon extends StatelessWidget {
  const TintedIcon({
    super.key,
    required this.icon,
    this.tint = AppColors.brand,
  });

  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: tint.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(AppRadii.small),
    ),
    child: Icon(icon, size: 20, color: tint),
  );
}

class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.detail,
    this.tint = AppColors.brand,
    this.busy = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final VoidCallback? onTap;
  final Color tint;
  final bool busy;
  final bool showChevron;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadii.sheet),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          TintedIcon(icon: icon, tint: tint),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: FontWeight.w700,
                    color: tint == AppColors.brand ? AppColors.ink : tint,
                  ),
                ),
                if (detail != null && detail!.isNotEmpty)
                  Text(
                    detail!,
                    style: const TextStyle(
                      fontSize: AppFontSize.caption,
                      color: AppColors.inkMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (showChevron)
            const Icon(
              AppIcons.chevronRight,
              size: 18,
              color: AppColors.inkDisabled,
            ),
        ],
      ),
    ),
  );
}

/// Choix de la langue de l'app et des notifications (`PATCH /v1/me/`), en
/// pastille glissante.
class LanguagePreferenceCard extends StatelessWidget {
  const LanguagePreferenceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    return MenuCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            const TintedIcon(icon: AppIcons.language),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.accountLanguage,
                    style: const TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    l10n.accountLanguageHint,
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
        const SizedBox(height: AppSpacing.md),
        PillSegmentedControl<AppLanguage>(
          segments: [
            (AppLanguage.fr, l10n.homeLanguageFrench),
            (AppLanguage.en, l10n.homeLanguageEnglish),
          ],
          selected: auth.user?.language ?? AppLanguage.fr,
          onChanged: auth.busy
              ? null
              : (language) =>
                    context.read<AuthController>().changeLanguage(language),
        ),
      ],
    );
  }
}

/// Consentement aux campagnes push (`PATCH /v1/me/ {marketing_opt_in}`,
/// § 6.7.5, lot 10).
///
/// Un vrai choix, désactivé par défaut et retirable d'un geste (Guideline
/// Apple 4.5.4). L'interrupteur suit la valeur du serveur : il ne bascule
/// qu'une fois le `PATCH` accepté.
class MarketingConsentCard extends StatelessWidget {
  const MarketingConsentCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final optedIn = auth.user?.marketingOptIn ?? false;
    return MenuCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        MergeSemantics(
          child: Row(
            children: [
              TintedIcon(icon: optedIn ? AppIcons.bellFilled : AppIcons.bell),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.accountMarketingOptIn,
                      style: const TextStyle(
                        fontSize: AppFontSize.body,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      l10n.accountMarketingOptInHint,
                      style: const TextStyle(
                        fontSize: AppFontSize.caption,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Switch.adaptive(
                value: optedIn,
                onChanged: auth.busy || auth.user == null
                    ? null
                    : (value) => context
                          .read<AuthController>()
                          .changeMarketingOptIn(value),
                activeTrackColor: AppColors.brand,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
