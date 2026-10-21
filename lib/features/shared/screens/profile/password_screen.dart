/// **Compte → Mot de passe** — commun au client et au chauffeur.
///
/// Aucune maquette dans le handoff : composé avec les blocs d'authentification.
/// Deux modes, décidés par `has_password` relu sur `/me/` (§ 6c.7) :
///
/// - **Changer** (§ 6c.6, `POST /me/password/`) : mot de passe actuel exigé,
///   toujours — un jeton d'accès volé ne doit pas suffire. Les autres appareils
///   sont déconnectés ; celui-ci reçoit un couple de jetons neuf ;
/// - **Définir** (compte créé par Google ou Apple) : pas de mot de passe actuel
///   à présenter, on passe par la réinitialisation par code email (§ 6c.5),
///   qui prouve la possession de l'adresse. Même chemin si le serveur répond
///   `password_not_set` à un profil lu avant le lot 8.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_error_messages.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../state/auth_controller.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/primary_button.dart';
import '../auth/forgot_password_screen.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _passwordError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthController>().clearFailure();
    });
  }

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _current.text.isNotEmpty &&
      _password.text.isNotEmpty &&
      _confirm.text.isNotEmpty;

  Future<void> _change() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _passwordError = _password.text.length >= 8
          ? null
          : l10n.authPasswordTooShort;
      _confirmError = _confirm.text == _password.text
          ? null
          : l10n.passwordMismatch;
    });
    if (_passwordError != null || _confirmError != null) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await context.read<AuthController>().changePassword(
      currentPassword: _current.text,
      newPassword: _password.text,
    );
    if (!ok || !mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.passwordSaved)));
    navigator.pop();
  }

  /// Envoie un code à l'email du compte, puis ouvre la saisie du code et du
  /// nouveau mot de passe — pour « Définir » comme pour « actuel oublié ».
  Future<void> _sendResetCode(String email) async {
    final auth = context.read<AuthController>();
    if (!await auth.requestPasswordReset(email: email) || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResetPasswordScreen(email: email, signedIn: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final user = auth.user;
    final failure = auth.failure;
    final email = user?.email ?? '';

    final notSet =
        user?.hasPassword == false ||
        (failure is ApiException &&
            failure.code == ApiErrorCode.passwordNotSet);
    final serverPasswordError = failure is ApiException
        ? failure.fieldError('new_password')
        : null;
    final currentWrong =
        failure is ApiException &&
        failure.code == ApiErrorCode.invalidCurrentPassword;
    final bannerFailure = serverPasswordError == null && !currentWrong
        ? failure
        : null;

    void edited() {
      if (failure != null) auth.clearFailure();
      setState(() {});
    }

    final back = auth.busy ? null : () => Navigator.of(context).maybePop();

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) auth.clearFailure();
      },
      child: notSet
          ? AuthScaffold(
              onBack: back,
              children: [
                const SizedBox(height: AppSpacing.lg),
                const AuthIconBadge(AppIcons.lock),
                const SizedBox(height: AppSpacing.xl),
                AuthTitle(l10n.setPasswordTitle),
                const SizedBox(height: AppSpacing.sm),
                AuthSubtitle(l10n.setPasswordBody(email)),
                if (failure != null &&
                    !(failure is ApiException &&
                        failure.code == ApiErrorCode.passwordNotSet)) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AuthErrorBanner(messageForFailure(l10n, failure)),
                ],
                const SizedBox(height: AppSpacing.xxl),
                const Spacer(),
                PrimaryButton(
                  label: l10n.forgotSendCode,
                  trailingIcon: AppIcons.forwardBold,
                  busy: auth.busy,
                  onPressed: email.isEmpty ? null : () => _sendResetCode(email),
                ),
              ],
            )
          : AuthScaffold(
              onBack: back,
              children: [
                const SizedBox(height: AppSpacing.lg),
                const AuthIconBadge(AppIcons.lock),
                const SizedBox(height: AppSpacing.xl),
                AuthTitle(l10n.changePasswordTitle),
                const SizedBox(height: AppSpacing.sm),
                AuthSubtitle(l10n.changePasswordSubtitle),
                const SizedBox(height: AppSpacing.xxl),
                AppTextField(
                  label: l10n.currentPasswordLabel,
                  controller: _current,
                  errorText: currentWrong
                      ? l10n.apiErrorInvalidCurrentPassword
                      : null,
                  prefixIcon: AppIcons.lock,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.password],
                  enabled: !auth.busy,
                  onChanged: (_) => edited(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: auth.busy || email.isEmpty
                        ? null
                        : () => _sendResetCode(email),
                    child: Text(l10n.changePasswordForgot),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: l10n.resetNewPasswordLabel,
                  controller: _password,
                  errorText: _passwordError ?? serverPasswordError,
                  prefixIcon: AppIcons.lock,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !auth.busy,
                  onChanged: (_) {
                    _passwordError = null;
                    edited();
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: l10n.resetConfirmPasswordLabel,
                  controller: _confirm,
                  errorText: _confirmError,
                  prefixIcon: AppIcons.lock,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !auth.busy,
                  onChanged: (_) {
                    _confirmError = null;
                    edited();
                  },
                  onSubmitted: (_) => _canSubmit ? _change() : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.passwordOtherDevicesNotice,
                  style: const TextStyle(
                    fontSize: AppFontSize.caption,
                    color: AppColors.inkMuted,
                  ),
                ),
                if (bannerFailure != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AuthErrorBanner(messageForFailure(l10n, bannerFailure)),
                ],
                const SizedBox(height: AppSpacing.xxl),
                const Spacer(),
                PrimaryButton(
                  label: l10n.changePasswordTitle,
                  trailingIcon: AppIcons.forwardBold,
                  busy: auth.busy,
                  onPressed: _canSubmit ? _change : null,
                ),
              ],
            ),
    );
  }
}
