/// **Complétion d'une inscription Google / Apple** (`06c` § 6c.2, lot 8).
///
/// Google et Apple ne fournissent jamais de téléphone ; or il est obligatoire
/// et unique sur un compte Camelia (le chauffeur joint le client par lui, le
/// portefeuille Mobile Money y est adossé). Le serveur a répondu
/// `social_signup_incomplete` sans rien créer : cet écran recueille le
/// téléphone (et le nom, prérempli depuis le jeton ou le SDK), puis rappelle la
/// même route avec le même jeton. Le rôle se choisit ici, à la création, et
/// nulle part ailleurs ; l'expérience ouverte reste celle du rôle relu sur
/// `GET /me/`.
///
/// Aucune maquette dans le handoff : composé avec les blocs de l'inscription.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_error_messages.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/app_user.dart';
import '../../models/phone_number.dart';
import '../../state/auth_controller.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/driver_role_toggle.dart';
import '../../widgets/primary_button.dart';

class SocialCompletionScreen extends StatefulWidget {
  const SocialCompletionScreen({super.key});

  @override
  State<SocialCompletionScreen> createState() => _SocialCompletionScreenState();
}

class _SocialCompletionScreenState extends State<SocialCompletionScreen> {
  late final AuthController _auth = context.read<AuthController>();
  late final TextEditingController _firstName = TextEditingController(
    text: _auth.socialSignup?.firstName ?? '',
  );
  late final TextEditingController _lastName = TextEditingController(
    text: _auth.socialSignup?.lastName ?? '',
  );
  final _phone = TextEditingController();
  bool _asDriver = false;
  final Map<String, String?> _localErrors = {};

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _phone.text.trim().isNotEmpty &&
      _firstName.text.trim().isNotEmpty &&
      _lastName.text.trim().isNotEmpty;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = PhoneNumber.normalize(_phone.text.trim());
    setState(() {
      _localErrors['phone'] = PhoneNumber.isE164(phone)
          ? null
          : l10n.fieldInvalidPhone;
    });
    if (_localErrors['phone'] != null) return;

    await _auth.completeSocialSignUp(
      phone: phone,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      role: _asDriver ? UserRole.driver : UserRole.client,
    );
    // Succès : le SessionGate ouvre l'expérience et revient à la racine.
  }

  void _onEdit(String field) {
    if (_localErrors[field] != null) _localErrors[field] = null;
    _auth.clearFailure();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final failure = auth.failure;
    final email = auth.socialSignup?.email ?? '';

    String? serverError(String field) =>
        failure is ApiException ? failure.fieldError(field) : null;
    final hasFieldErrors =
        serverError('phone') != null ||
        serverError('first_name') != null ||
        serverError('last_name') != null;

    return PopScope(
      // Retour : l'inscription est abandonnée, le jeton oublié — rien
      // n'existe côté serveur.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _auth.cancelSocialSignUp();
      },
      child: AuthScaffold(
        onBack: auth.busy ? null : () => Navigator.of(context).maybePop(),
        children: [
          const SizedBox(height: AppSpacing.lg),
          const AuthIconBadge(AppIcons.phone),
          const SizedBox(height: AppSpacing.xl),
          AuthTitle(l10n.socialCompleteTitle),
          const SizedBox(height: AppSpacing.sm),
          AuthSubtitle(l10n.socialCompleteSubtitle),
          if (email.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              email,
              style: const TextStyle(
                fontSize: AppFontSize.body,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),

          AppTextField(
            label: l10n.authPhoneLabel,
            hintText: l10n.authPhoneHint,
            controller: _phone,
            errorText: _localErrors['phone'] ?? serverError('phone'),
            prefixIcon: AppIcons.phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            enabled: !auth.busy,
            onChanged: (_) => _onEdit('phone'),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: l10n.authFirstNameLabel,
            controller: _firstName,
            errorText: serverError('first_name'),
            prefixIcon: AppIcons.user,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.givenName],
            enabled: !auth.busy,
            onChanged: (_) => _onEdit('first_name'),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: l10n.authLastNameLabel,
            controller: _lastName,
            errorText: serverError('last_name'),
            prefixIcon: AppIcons.user,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.familyName],
            enabled: !auth.busy,
            onChanged: (_) => _onEdit('last_name'),
          ),
          const SizedBox(height: AppSpacing.xl),
          DriverRoleToggle(
            value: _asDriver,
            onChanged: auth.busy
                ? null
                : (value) => setState(() => _asDriver = value),
            label: l10n.authRegisterAsDriver,
            notice: l10n.authRegisterDriverNotice,
          ),

          if (failure != null && !hasFieldErrors) ...[
            const SizedBox(height: AppSpacing.xl),
            AuthErrorBanner(messageForFailure(l10n, failure)),
          ],
          const SizedBox(height: AppSpacing.xxxl),
          const Spacer(),
          PrimaryButton(
            label: l10n.authRegisterAction,
            trailingIcon: AppIcons.forwardBold,
            busy: auth.busy,
            onPressed: _canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}
