/// Boutons « Continuer avec Google » et « Continuer avec Apple » (`06c`,
/// lot 8), sur la connexion et l'inscription.
///
/// Une seule route par fournisseur couvre inscription **et** connexion : au
/// moment de l'appui, l'app ne sait pas si un compte existe — le serveur
/// tranche. Un compte inconnu ouvre l'écran de complétion (téléphone).
///
/// Chartes des fournisseurs, non négociables :
/// - Apple : le bouton est celui du paquet `sign_in_with_apple`, conforme aux
///   Human Interface Guidelines (logo, fond noir, libellé localisé) ;
/// - Google : le « G » quatre couleurs officiel sur fond blanc, jamais
///   recoloré aux couleurs de l'app.
///
/// N'affiche rien si aucun fournisseur n'est configuré pour cette plate-forme
/// (voir `socialProvidersFor`) : l'écran garde alors exactement sa forme
/// d'avant le lot 8.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/platform/social_sign_in.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../screens/auth/social_completion_screen.dart';
import '../state/auth_controller.dart';
import 'pressable.dart';

class SocialSignInButtons extends StatelessWidget {
  const SocialSignInButtons({super.key});

  Future<void> _start(BuildContext context, SocialProvider provider) async {
    final auth = context.read<AuthController>();
    final navigator = Navigator.of(context);
    final outcome = await auth.signInWithProvider(provider);
    if (outcome == SocialSignInOutcome.needsCompletion) {
      await navigator.push(
        MaterialPageRoute<void>(builder: (_) => const SocialCompletionScreen()),
      );
    }
    // signedIn : le SessionGate ouvre l'expérience du rôle relu sur `/me/`.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final providers = auth.socialProviders;
    if (providers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final provider in providers) ...[
          switch (provider) {
            SocialProvider.apple => SizedBox(
              height: 52,
              child: SignInWithAppleButton(
                text: l10n.socialContinueApple,
                height: 52,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadii.field),
                ),
                onPressed: auth.busy
                    ? null
                    : () => _start(context, SocialProvider.apple),
              ),
            ),
            SocialProvider.google => _GoogleButton(
              label: l10n.socialContinueGoogle,
              onTap: auth.busy
                  ? null
                  : () => _start(context, SocialProvider.google),
            ),
          },
          if (provider != providers.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

/// Message d'un échec de connexion sociale, ou `null` s'il n'en est pas un.
///
/// Un fournisseur non configuré côté serveur rend `404` sur sa route
/// (`06c` § 6c.2) : un message dédié plutôt que « ressource introuvable ».
String? socialFailureMessage(AppLocalizations l10n, Object? failure) =>
    failure is ApiException && failure.statusCode == 404
    ? l10n.socialProviderDisabled
    : null;

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: Opacity(
      opacity: onTap == null ? .5 : 1,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.field),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(_googleG, width: 20, height: 20),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: AppFontSize.body,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Logo « G » de Google, couleurs officielles — tel que fourni dans les
/// ressources du bouton de connexion Google.
const String _googleG = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
<path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
<path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
<path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
<path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';
