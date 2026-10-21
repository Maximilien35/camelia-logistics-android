/// **Mot de passe oublié** — réinitialisation par code email (`06c` § 6c.5,
/// lot 8). Aucune maquette dans le handoff : composé avec le gabarit et les
/// blocs des écrans d'authentification existants.
///
/// Deux étapes, deux écrans :
/// 1. [ForgotPasswordScreen] — l'email, puis `POST /auth/password/reset/` ;
/// 2. [ResetPasswordScreen] — le code à 6 chiffres et le nouveau mot de passe,
///    puis `POST /auth/password/reset/confirm/`, qui **ouvre la session**.
///
/// Un code plutôt qu'un lien : l'app est mobile seule, et le mécanisme OTP
/// existant (10 min, 5 tentatives, 5 demandes par heure) est réutilisé tel quel
/// côté serveur. Sert aussi à **définir** un premier mot de passe sur un
/// compte créé par Google ou Apple (voir `password_screen.dart`).
library;

import 'dart:async';

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
import '../../widgets/otp_input.dart';
import '../../widgets/primary_button.dart';

/// Longueur minimale vérifiée **localement** pour éviter un aller-retour
/// évident ; les validateurs Django du serveur (`AUTH_PASSWORD_VALIDATORS`)
/// restent seuls juges, et leur refus s'affiche sous le champ.
const int _minPasswordLength = 8;

/// Efface l'erreur d'authentification en quittant l'écran, pour qu'elle ne
/// réapparaisse pas sur l'écran d'en dessous (connexion, onglet Compte).
class _ClearFailureOnPop extends StatelessWidget {
  const _ClearFailureOnPop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) context.read<AuthController>().clearFailure();
    },
    child: child,
  );
}

bool _looksLikeEmail(String value) {
  final at = value.indexOf('@');
  return at > 0 && value.indexOf('.', at) > at + 1 && !value.contains(' ');
}

// --- Étape 1 : l'email ---------------------------------------------------------

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _email = TextEditingController(
    text: widget.initialEmail,
  );
  String? _emailError;

  @override
  void initState() {
    super.initState();
    // L'erreur de l'écran de connexion (mauvais mot de passe) n'a rien à
    // faire ici.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthController>().clearFailure();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _email.text.trim();
    if (!_looksLikeEmail(email)) {
      setState(() => _emailError = l10n.authEmailInvalid);
      return;
    }
    final auth = context.read<AuthController>();
    if (!await auth.requestPasswordReset(email: email) || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResetPasswordScreen(email: email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();

    return _ClearFailureOnPop(
      child: AuthScaffold(
        onBack: auth.busy ? null : () => Navigator.of(context).maybePop(),
        children: [
          const SizedBox(height: AppSpacing.lg),
          const AuthIconBadge(AppIcons.lock),
          const SizedBox(height: AppSpacing.xl),
          AuthTitle(l10n.forgotTitle),
          const SizedBox(height: AppSpacing.sm),
          AuthSubtitle(l10n.forgotSubtitle),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(
            label: l10n.authEmailLabel,
            hintText: l10n.authEmailHint,
            controller: _email,
            errorText: _emailError,
            prefixIcon: AppIcons.mail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            enabled: !auth.busy,
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
              auth.clearFailure();
            },
            onSubmitted: (_) => _submit(),
          ),
          if (auth.failure != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AuthErrorBanner(messageForFailure(l10n, auth.failure!)),
          ],
          const SizedBox(height: AppSpacing.xxl),
          const Spacer(),
          PrimaryButton(
            label: l10n.forgotSendCode,
            trailingIcon: AppIcons.forwardBold,
            busy: auth.busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// --- Étape 2 : le code et le nouveau mot de passe ------------------------------

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.email,
    this.signedIn = false,
  });

  final String email;

  /// Ouvert depuis le compte (« Définir un mot de passe ») : la session existe
  /// déjà, le SessionGate ne changera pas d'état — l'écran revient lui-même à
  /// la racine une fois le mot de passe enregistré. Hors session, c'est le
  /// SessionGate qui ouvre l'expérience du rôle et vide la pile.
  final bool signedIn;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const int _codeLength = 6;

  /// Courtoisie d'interface avant « Renvoyer le code » ; le plafond réel est
  /// serveur (`otp_rate_limited`).
  static const Duration _resendDelay = Duration(seconds: 60);

  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _code = '';
  String? _passwordError;
  String? _confirmError;
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendDelay.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  bool get _canSubmit =>
      _code.length == _codeLength &&
      _password.text.isNotEmpty &&
      _confirm.text.isNotEmpty;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _passwordError = _password.text.length >= _minPasswordLength
          ? null
          : l10n.authPasswordTooShort;
      _confirmError = _confirm.text == _password.text
          ? null
          : l10n.passwordMismatch;
    });
    if (_passwordError != null || _confirmError != null) return;

    final auth = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await auth.resetPassword(
      email: widget.email,
      code: _code,
      newPassword: _password.text,
    );
    if (!ok || !mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.passwordSaved)));
    if (widget.signedIn) navigator.popUntil((r) => r.isFirst);
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final sent = await context.read<AuthController>().requestPasswordReset(
      email: widget.email,
    );
    if (!sent || !mounted) return;
    _startCountdown();
    messenger.showSnackBar(SnackBar(content: Text(l10n.authOtpResent)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final failure = auth.failure;

    // Refus d'un validateur de mot de passe : sous le champ, pas en bannière.
    // Il ne consomme aucune tentative du code (§ 6c.5) — on corrige et on
    // renvoie le même code.
    final serverPasswordError = failure is ApiException
        ? failure.fieldError('new_password')
        : null;
    final bannerFailure = serverPasswordError == null ? failure : null;
    final codeFailed =
        failure is ApiException &&
        const {
          ApiErrorCode.invalidOtp,
          ApiErrorCode.otpExpired,
          ApiErrorCode.otpMaxAttempts,
        }.contains(failure.code);

    void edited() {
      if (failure != null) auth.clearFailure();
      setState(() {});
    }

    return _ClearFailureOnPop(
      child: AuthScaffold(
        onBack: auth.busy ? null : () => Navigator.of(context).maybePop(),
        children: [
          const SizedBox(height: AppSpacing.lg),
          const AuthIconBadge(AppIcons.lock),
          const SizedBox(height: AppSpacing.xl),
          AuthTitle(l10n.resetTitle),
          const SizedBox(height: AppSpacing.sm),
          AuthSubtitle(l10n.resetSubtitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.email,
            style: const TextStyle(
              fontSize: AppFontSize.body,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text(
            l10n.resetCodeLabel,
            style: const TextStyle(
              fontSize: AppFontSize.label,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OtpInput(
            length: _codeLength,
            hasError: codeFailed,
            enabled: !auth.busy,
            onChanged: (value) {
              _code = value;
              edited();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: auth.busy || _secondsLeft > 0 ? null : _resend,
              child: Text(
                _secondsLeft > 0
                    ? '${l10n.authOtpResendIn} '
                          '${(_secondsLeft ~/ 60).toString().padLeft(2, '0')}:'
                          '${(_secondsLeft % 60).toString().padLeft(2, '0')}'
                    : l10n.authOtpResendAction,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

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
            onSubmitted: (_) => _canSubmit ? _submit() : null,
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
            label: l10n.resetSubmit,
            trailingIcon: AppIcons.forwardBold,
            busy: auth.busy,
            onPressed: _canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}
