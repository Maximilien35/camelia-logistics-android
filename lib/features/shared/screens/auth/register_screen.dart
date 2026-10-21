/// Écran d'inscription — maquette « 3. Inscription ».
///
/// **Écarts assumés par rapport à la maquette**, tous dictés par
/// `RegisterSerializer` :
/// - la maquette demande un « Nom complet » ; le serveur exige `first_name` et
///   `last_name` séparés — deux champs plutôt qu'un découpage à l'aveugle sur
///   l'espace, qui se tromperait sur « Ngo Bell » ou « Jean-Paul » ;
/// - la maquette ne montre ni email ni mot de passe ; les deux sont
///   **obligatoires** côté serveur (l'email est l'identifiant, le mot de passe
///   fait 8 caractères minimum et passe les validateurs Django) ;
/// - la maquette propose un choix de **ville** (Douala / Yaoundé) ; aucun champ
///   de ville n'existe dans `RegisterSerializer` ni sur le modèle `User`. Il
///   n'est donc pas collecté — inventer un champ que le serveur ignore
///   tromperait l'utilisateur sur ce qui est enregistré.
///
/// Voir `docs/design-api-map.md` § 1.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_error_messages.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/app_user.dart';
import '../../state/auth_controller.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/driver_role_toggle.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/social_sign_in_buttons.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  bool _asDriver = false;

  /// Erreurs par champ. Alimentées d'abord par la validation de forme locale,
  /// puis **écrasées** par la ventilation `details` du serveur, qui a le dernier
  /// mot (un email déjà pris n'est détectable que côté serveur).
  final Map<String, String?> _errors = {};

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canSubmit =>
      _firstName.text.trim().isNotEmpty &&
      _lastName.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _phone.text.trim().isNotEmpty &&
      _password.text.isNotEmpty;

  /// Format E.164, identique au `phone_validator` du backend.
  ///
  /// Dupliqué ici volontairement : c'est une règle de **forme de saisie**, pas
  /// une règle métier, et elle évite un aller-retour réseau certain d'échouer.
  static final RegExp _e164 = RegExp(r'^\+[1-9]\d{7,14}$');

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _phone.text.trim().replaceAll(' ', '');

    setState(() {
      _errors.clear();
      if (!_email.text.trim().contains('@')) {
        _errors['email'] = l10n.authEmailInvalid;
      }
      if (!_e164.hasMatch(phone)) _errors['phone'] = l10n.authPhoneInvalid;
      if (_password.text.length < 8) {
        _errors['password'] = l10n.authPasswordTooShort;
      }
    });
    if (_errors.values.any((e) => e != null)) return;

    final auth = context.read<AuthController>();
    final ok = await auth.register(
      email: _email.text.trim(),
      phone: phone,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      password: _password.text,
      role: _asDriver ? UserRole.driver : UserRole.client,
    );
    if (!mounted) return;

    if (!ok) {
      // Le serveur ventile ses erreurs par champ : on les accroche sous le bon
      // champ plutôt que dans une bannière anonyme.
      final failure = auth.failure;
      if (failure is ApiException && failure.details.isNotEmpty) {
        setState(() {
          for (final field in const [
            'email',
            'phone',
            'password',
            'first_name',
            'last_name',
          ]) {
            final message = failure.fieldError(field);
            if (message != null) _errors[field] = message;
          }
        });
      }
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          email: _email.text.trim(),
          purpose: OtpPurpose.verifyRegistration,
        ),
      ),
    );
  }

  void _onEdit(String field) {
    if (_errors[field] != null) setState(() => _errors[field] = null);
    context.read<AuthController>().clearFailure();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final failure = auth.failure;
    final hasFieldErrors = _errors.values.any((e) => e != null);

    return AuthScaffold(
      onBack: auth.busy ? null : () => Navigator.of(context).maybePop(),
      children: [
        const SizedBox(height: AppSpacing.lg),
        const AuthStepRoute(current: 0),
        const SizedBox(height: AppSpacing.xl),
        AuthTitle(l10n.authRegisterTitle),
        const SizedBox(height: AppSpacing.sm),
        AuthSubtitle(l10n.authRegisterSubtitle),
        const SizedBox(height: AppSpacing.xxxl),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                label: l10n.authFirstNameLabel,
                hintText: l10n.authFirstNameHint,
                controller: _firstName,
                errorText: _errors['first_name'],
                prefixIcon: AppIcons.user,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.givenName],
                enabled: !auth.busy,
                onChanged: (_) => _onEdit('first_name'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: l10n.authLastNameLabel,
                hintText: l10n.authLastNameHint,
                controller: _lastName,
                errorText: _errors['last_name'],
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.familyName],
                enabled: !auth.busy,
                onChanged: (_) => _onEdit('last_name'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        AppTextField(
          label: l10n.authEmailLabel,
          hintText: l10n.authEmailHint,
          controller: _email,
          errorText: _errors['email'],
          prefixIcon: AppIcons.mail,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          enabled: !auth.busy,
          onChanged: (_) => _onEdit('email'),
        ),
        const SizedBox(height: AppSpacing.lg),

        AppTextField(
          label: l10n.authPhoneLabel,
          hintText: l10n.authPhoneHint,
          controller: _phone,
          errorText: _errors['phone'],
          prefixIcon: AppIcons.phone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.telephoneNumber],
          enabled: !auth.busy,
          onChanged: (_) => _onEdit('phone'),
        ),
        const SizedBox(height: AppSpacing.lg),

        AppTextField(
          label: l10n.authPasswordLabel,
          hintText: l10n.authPasswordHint,
          controller: _password,
          errorText: _errors['password'],
          prefixIcon: AppIcons.lock,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          enabled: !auth.busy,
          onChanged: (_) => _onEdit('password'),
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

        // Bannière uniquement si l'échec n'a pas déjà été accroché à un champ.
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
        const SizedBox(height: AppSpacing.lg),
        // Même route qu'à la connexion : le serveur crée le compte s'il
        // n'existe pas (`06c` § 6c.2).
        if (auth.socialProviders.isNotEmpty) ...[
          const AuthOrDivider(),
          const SizedBox(height: AppSpacing.lg),
          const SocialSignInButtons(),
          const SizedBox(height: AppSpacing.lg),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.authHasAccount,
              style: const TextStyle(
                fontSize: AppFontSize.label,
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: auth.busy ? null : () => Navigator.of(context).maybePop(),
              child: Text(
                l10n.authSignInLink,
                style: const TextStyle(
                  fontSize: AppFontSize.label,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
