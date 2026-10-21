/// Feuille « Numéro Mobile Money » — avant `confirm-delivery/` (§ 7.3.14).
///
/// Depuis le passage à KPay (21 octobre 2026), l'invite de paiement est
/// poussée **en USSD** sur le téléphone du payeur : il faut donc savoir quel
/// numéro débiter. Préremplie avec le téléphone du compte, modifiable — le
/// client peut payer depuis un autre portefeuille que celui de son compte.
///
/// La feuille ne fait **aucun appel** : elle rend le numéro choisi, et c'est
/// l'appui sur son bouton qui déclenche le paiement (règle n°7). L'opérateur
/// (MTN, Orange) n'est pas demandé : le fournisseur le déduit du numéro.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/models/phone_number.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';

/// Ouvre la feuille ; rend le numéro en E.164, ou `null` si elle est fermée
/// sans validation.
Future<String?> showPayerPhoneSheet(
  BuildContext context, {
  required String initialPhone,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.white,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
  ),
  builder: (_) => _PayerPhoneSheet(initialPhone: initialPhone),
);

class _PayerPhoneSheet extends StatefulWidget {
  const _PayerPhoneSheet({required this.initialPhone});

  final String initialPhone;

  @override
  State<_PayerPhoneSheet> createState() => _PayerPhoneSheetState();
}

class _PayerPhoneSheetState extends State<_PayerPhoneSheet> {
  late final TextEditingController _phone = TextEditingController(
    text: widget.initialPhone,
  );
  bool _formatError = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    // Mise en forme de saisie seulement : le serveur revalide le format
    // (`phone_validator`) et décide seul si l'opérateur est pris en charge.
    final phone = PhoneNumber.normalize(_phone.text.trim());
    if (!PhoneNumber.isE164(phone)) {
      setState(() => _formatError = true);
      return;
    }
    Navigator.of(context).pop(phone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        top: 22,
        // Laisse la place au clavier.
        bottom: MediaQuery.viewInsetsOf(context).bottom + 22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.payerSheetTitle,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: AppFontSize.title,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.payerSheetBody,
            style: const TextStyle(
              fontSize: AppFontSize.label,
              height: 1.5,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: l10n.payerSheetPhoneLabel,
            controller: _phone,
            hintText: l10n.authPhoneHint,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            prefixIcon: AppIcons.phone,
            errorText: _formatError ? l10n.fieldInvalidPhone : null,
            onChanged: (_) {
              if (_formatError) setState(() => _formatError = false);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(label: l10n.payerSheetSend, onPressed: _submit),
        ],
      ),
    );
  }
}
