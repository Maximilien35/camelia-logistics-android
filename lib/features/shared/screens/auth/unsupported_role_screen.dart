/// Écran pour un compte dont le rôle n'a pas d'expérience mobile.
///
/// Aujourd'hui : `admin` uniquement. Le back-office est une application web
/// distincte (CLAUDE.md : « `admin` hors périmètre de cette app mobile »).
///
/// Mieux vaut le dire franchement que d'ouvrir un parcours client à moitié vide
/// — ce que ferait un aiguillage qui retomberait silencieusement sur `client`.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../state/auth_controller.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/primary_button.dart';
import '../../../../core/theme/app_icons.dart';

class UnsupportedRoleScreen extends StatelessWidget {
  const UnsupportedRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();

    return AuthScaffold(
      children: [
        const SizedBox(height: 40),
        const Icon(AppIcons.shield, size: 44, color: AppColors.inkMuted),
        const SizedBox(height: AppSpacing.xxl),
        AuthTitle(l10n.authUnsupportedRoleTitle),
        const SizedBox(height: AppSpacing.md),
        AuthSubtitle(l10n.authUnsupportedRoleBody),
        if (auth.user != null) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(
            auth.user!.email,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: AppFontSize.label,
              color: AppColors.ink,
            ),
          ),
        ],
        const Spacer(),
        PrimaryButton(
          label: l10n.authSignOutAction,
          busy: auth.busy,
          onPressed: () => context.read<AuthController>().logout(),
        ),
      ],
    );
  }
}
