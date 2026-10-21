/// Écran de vérification du code — maquette « 2. Vérification OTP »,
/// états **En cours** et **Erreur**.
///
/// Le code arrive **par email** (`OTP_CODE_SENDER = EmailCodeSender`), pas par
/// SMS : l'écran affiche donc l'adresse, là où la maquette affichait le numéro.
///
/// La maquette écrit « Code incorrect. Il vous reste 2 tentatives. » Le backend
/// **ne communique pas** le nombre de tentatives restantes : il renvoie
/// `invalid_otp`, puis `otp_max_attempts` quand le quota est épuisé
/// (`OTP_MAX_ATTEMPTS = 5`). On affiche le message du code, jamais un décompte
/// inventé.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_error_messages.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../state/auth_controller.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/primary_button.dart';

/// Ce que le code doit accomplir.
///
/// Deux endpoints distincts partagent le même écran :
/// - [verifyRegistration] → `POST /auth/verify-otp/` (valide une inscription) ;
/// - [signIn] → `POST /auth/login/` avec `code` (connexion sans mot de passe).
enum OtpPurpose { verifyRegistration, signIn }

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.purpose,
  });

  final String email;
  final OtpPurpose purpose;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _codeLength = 6;

  /// Délai avant de pouvoir redemander un code.
  ///
  /// Aligné sur la maquette (compte à rebours visible). Le serveur plafonne de
  /// son côté à 5 demandes par heure et par email
  /// (`OTP_MAX_REQUESTS_PER_HOUR`) : ce minuteur est une courtoisie d'interface,
  /// pas la règle — c'est le serveur qui refuse, et `otp_rate_limited`
  /// s'affiche alors.
  static const Duration _resendDelay = Duration(seconds: 60);

  String _code = '';
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

  bool get _complete => _code.length == _codeLength;

  Future<void> _verify() async {
    final auth = context.read<AuthController>();
    final ok = switch (widget.purpose) {
      OtpPurpose.verifyRegistration => await auth.verifyOtp(
        email: widget.email,
        code: _code,
      ),
      OtpPurpose.signIn => await auth.loginWithCode(
        email: widget.email,
        code: _code,
      ),
    };
    // En cas de succès, le SessionGate observe le statut et remplace l'arbre :
    // rien à pousser, et surtout aucun `pop` qui ramènerait à la connexion.
    if (ok && mounted) return;
  }

  Future<void> _resend() async {
    final auth = context.read<AuthController>();
    final l10n = AppLocalizations.of(context)!;
    final sent = await auth.resendOtp(email: widget.email);
    if (!mounted) return;
    if (sent) {
      _startCountdown();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.authOtpResent)));
    }
  }

  String get _countdown {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final failure = auth.failure;

    return AuthScaffold(
      onBack: auth.busy ? null : () => Navigator.of(context).maybePop(),
      children: [
        const SizedBox(height: AppSpacing.lg),
        // Inscription : le trajet compte → vérification → arrivée. Connexion
        // par code : une simple enveloppe, il n'y a pas d'étapes à montrer.
        if (widget.purpose == OtpPurpose.verifyRegistration)
          const AuthStepRoute(current: 1)
        else
          const AuthIconBadge(AppIcons.mail),
        const SizedBox(height: AppSpacing.xl),
        AuthTitle(l10n.authOtpTitle),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.authOtpSentTo,
          style: const TextStyle(
            fontSize: AppFontSize.body,
            height: 1.5,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AppIcons.mail, size: 16, color: AppColors.brand),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    widget.email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),

        OtpInput(
          length: _codeLength,
          hasError: failure != null,
          enabled: !auth.busy,
          onChanged: (value) {
            setState(() => _code = value);
            auth.clearFailure();
          },
        ),
        const SizedBox(height: AppSpacing.xl),

        if (failure != null)
          AuthErrorBanner(messageForFailure(l10n, failure))
        else
          Center(
            child: _secondsLeft > 0
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        AppIcons.clock,
                        size: 16,
                        color: AppColors.inkMuted,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: AppFontSize.label,
                            color: AppColors.inkMuted,
                          ),
                          children: [
                            TextSpan(text: '${l10n.authOtpResendIn} '),
                            TextSpan(
                              text: _countdown,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: auth.busy ? null : _resend,
                    child: Text(
                      l10n.authOtpResendAction,
                      style: const TextStyle(
                        fontSize: AppFontSize.label,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
          ),

        if (failure != null && _secondsLeft <= 0) ...[
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: GestureDetector(
              onTap: auth.busy ? null : _resend,
              child: Text(
                l10n.authOtpResendAction,
                style: const TextStyle(
                  fontSize: AppFontSize.label,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand,
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xxxl),
        const Spacer(),

        PrimaryButton(
          label: l10n.authOtpVerifyAction,
          trailingIcon: AppIcons.forwardBold,
          busy: auth.busy,
          onPressed: _complete ? _verify : null,
        ),
      ],
    );
  }
}
