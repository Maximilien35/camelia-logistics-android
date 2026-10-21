/// Feuille « Numéro Mobile Money » — avant `confirm-delivery/` (§ 7.3.14).
///
/// Depuis le passage à KPay (21 octobre 2026), l'invite de paiement est
/// poussée **en USSD** sur le téléphone du payeur. Un numéro erroné est coûteux :
/// KPay identifie la transaction par la référence de la commande et refuse
/// toute nouvelle demande tant que la première est active
/// (`payment_already_pending`), quel que soit le numéro — la demande partie
/// vers le mauvais numéro bloque le paiement. D'où deux garde-fous :
///
/// 1. **saisie en cases** (`pinput`) derrière un `+237` fixe, groupées comme on
///    lit un numéro (6 · 70 · 00 · 00 · 01), et refus local de ce qui n'a pas
///    la forme d'un mobile camerounais (9 chiffres commençant par 6) ;
/// 2. **vérification** : le numéro est réaffiché en grand avant l'envoi, et
///    seul le bouton de cette étape rend le numéro à l'appelant.
///
/// La feuille ne fait **aucun appel** : c'est l'appui final qui déclenche le
/// paiement (règle n°7). L'opérateur n'est pas demandé : le fournisseur le
/// déduit du numéro.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/models/phone_number.dart';
import '../../shared/widgets/primary_button.dart';

/// Ouvre la feuille ; rend le numéro vérifié en E.164 (`+2376…`), ou `null`
/// si elle est fermée sans confirmation.
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
  static const int _digits = 9;

  /// Préremplie avec le numéro du compte s'il est camerounais.
  late final TextEditingController _digitsController = TextEditingController(
    text: PhoneNumber.cameroonLocal(widget.initialPhone) ?? '',
  );
  bool _formatError = false;

  /// Numéro saisi et valide, en attente de la vérification visuelle.
  String? _toConfirm;

  @override
  void dispose() {
    _digitsController.dispose();
    super.dispose();
  }

  void _review() {
    final digits = _digitsController.text;
    if (!PhoneNumber.isCameroonMobile(digits)) {
      setState(() => _formatError = true);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _toConfirm = digits);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final confirming = _toConfirm;

    return Padding(
      padding: EdgeInsets.only(
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        top: 22,
        // Laisse la place au clavier.
        bottom: MediaQuery.viewInsetsOf(context).bottom + 22,
      ),
      // `Pinput` exige un ancêtre `Material` au plus près.
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: confirming == null
              ? _entry(l10n)
              : _confirmation(l10n, confirming),
        ),
      ),
    );
  }

  Widget _entry(AppLocalizations l10n) => Column(
    key: const ValueKey('saisie'),
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Title(l10n.payerSheetTitle),
      const SizedBox(height: AppSpacing.sm),
      _Body(l10n.payerSheetBody),
      const SizedBox(height: AppSpacing.xl),
      Row(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.field),
            ),
            child: const Text(
              '+237',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: AppFontSize.body,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Grand écart après les chiffres 1, 3, 5 et 7 : 6 70 00 00 01.
                const groupGap = 8.0;
                const innerGap = 3.0;
                final cell =
                    ((constraints.maxWidth - 4 * groupGap - 4 * innerGap) /
                            _digits)
                        .clamp(20.0, 40.0);
                PinTheme theme(Color border, Color fill) => PinTheme(
                  width: cell,
                  height: 48,
                  textStyle: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: AppFontSize.title,
                    color: AppColors.ink,
                  ),
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border, width: 1.5),
                  ),
                );
                return Pinput(
                  length: _digits,
                  controller: _digitsController,
                  autofocus: _digitsController.text.isEmpty,
                  keyboardType: TextInputType.phone,
                  // Par défaut `pinput` propose un code à usage unique : ici
                  // c'est un numéro, sans indicatif (le +237 est fixe).
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  forceErrorState: _formatError,
                  defaultPinTheme: theme(AppColors.border, AppColors.white),
                  focusedPinTheme: theme(AppColors.brand, AppColors.white),
                  submittedPinTheme: theme(AppColors.border, AppColors.surface),
                  errorPinTheme: theme(AppColors.error, AppColors.white),
                  separatorBuilder: (index) => SizedBox(
                    width: index.isEven && index < 8 ? groupGap : innerGap,
                  ),
                  onChanged: (_) {
                    if (_formatError) setState(() => _formatError = false);
                  },
                  onCompleted: (_) => _review(),
                );
              },
            ),
          ),
        ],
      ),
      if (_formatError) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.payerPhoneInvalid,
          style: const TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
            fontSize: AppFontSize.caption,
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.xxl),
      PrimaryButton(
        label: l10n.commonContinue,
        trailingIcon: AppIcons.forwardBold,
        onPressed: _review,
      ),
    ],
  );

  Widget _confirmation(AppLocalizations l10n, String digits) => Column(
    key: const ValueKey('vérification'),
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Title(l10n.payerConfirmTitle),
      const SizedBox(height: AppSpacing.lg),
      Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.brandTint,
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            PhoneNumber.displayCameroon(digits),
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: AppFontSize.headline,
              letterSpacing: .5,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      _Body(l10n.payerConfirmBody),
      const SizedBox(height: AppSpacing.xxl),
      PrimaryButton(
        label: l10n.payerConfirmSend,
        onPressed: () => Navigator.of(context).pop('+237$digits'),
      ),
      const SizedBox(height: AppSpacing.sm),
      TextButton(
        onPressed: () => setState(() => _toConfirm = null),
        child: Text(l10n.payerConfirmEdit),
      ),
    ],
  );
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: AppFonts.display,
      fontWeight: FontWeight.w700,
      fontSize: AppFontSize.title,
      color: AppColors.ink,
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: AppFontSize.label,
      height: 1.5,
      color: AppColors.inkMuted,
    ),
  );
}
