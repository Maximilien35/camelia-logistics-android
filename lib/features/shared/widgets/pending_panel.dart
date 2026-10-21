/// Panneaux honnêtes pour les onglets dont le contenu n'est pas encore livrable.
///
/// Deux situations à ne pas confondre, d'où deux panneaux :
/// - [BackendMissingPanel] — **le serveur n'expose pas l'endpoint**. On nomme la
///   route manquante plutôt que d'afficher une liste vide, qui laisserait croire
///   que l'utilisateur n'a simplement rien.
/// - [ScreenComingPanel] — l'endpoint répond, c'est l'écran de la maquette qui
///   reste à construire.
///
/// Dans les deux cas, **aucune donnée fictive** : même en mode simulé, inventer
/// des commandes ici donnerait l'illusion d'une fonctionnalité livrée.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_icons.dart';

class BackendMissingPanel extends StatelessWidget {
  const BackendMissingPanel({super.key, required this.endpoint, this.note});

  /// Route attendue, telle qu'elle figure dans `07-api.md` — affichée brute,
  /// c'est une référence technique, pas une chaîne à traduire.
  final String endpoint;

  /// Précision optionnelle sur ce qui manque exactement.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Frame(
      icon: AppIcons.offline,
      title: l10n.backendMissingTitle,
      body: l10n.backendMissingBody,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.backendMissingEndpointLabel.toUpperCase(),
          style: const TextStyle(
            fontSize: AppFontSize.micro,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.badge),
          ),
          child: Text(
            endpoint,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: AppFontSize.label,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            note!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppFontSize.label,
              height: 1.5,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class ScreenComingPanel extends StatelessWidget {
  const ScreenComingPanel({super.key, required this.endpoint});

  final String endpoint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Frame(
      icon: AppIcons.dimensions,
      title: l10n.screenComingTitle,
      body: l10n.screenComingBody,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.brandTint,
            borderRadius: BorderRadius.circular(AppRadii.badge),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            endpoint,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: AppFontSize.label,
              fontWeight: FontWeight.w600,
              color: AppColors.brand,
            ),
          ),
        ),
      ],
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.icon,
    required this.title,
    required this.body,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.screenPadding,
          vertical: 32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.borderStrong),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: AppFontSize.title,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppFontSize.body,
                height: 1.55,
                color: AppColors.inkMuted,
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
