/// « Supprimer mon compte » — commun aux onglets Compte du client et du
/// chauffeur.
///
/// Exigence App Store (guideline 5.1.1(v)) : la suppression doit être
/// possible **depuis l'app**, pas seulement en écrivant au support. La V1
/// l'offrait ; la V2 en avait le service (`DELETE /auth/account/`) sans
/// l'écran.
///
/// Double confirmation : l'appui ouvre une boîte de dialogue qui dit ce qui
/// disparaît et ce qui reste (l'historique, anonymisé), et seul son bouton
/// rouge appelle le serveur. Un refus (`account_deletion_blocked` : course en
/// cours, solde à retirer) laisse la session ouverte, l'erreur s'affiche sur
/// l'onglet. Un compte rattaché à Apple voit ensuite, sur l'écran de
/// connexion, comment retirer Camelia de ses apps Apple (`06c` § 6c.4).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../state/auth_controller.dart';
import 'account_widgets.dart';

class DeleteAccountTile extends StatelessWidget {
  const DeleteAccountTile({super.key});

  Future<void> _confirm(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.accountDeleteTitle),
        content: Text(l10n.accountDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.accountDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) await auth.deleteAccount();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    return MenuTile(
      icon: AppIcons.userOff,
      label: l10n.accountDelete,
      tint: AppColors.error,
      showChevron: false,
      onTap: auth.busy ? null : () => _confirm(context),
    );
  }
}
