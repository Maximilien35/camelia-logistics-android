/// Écran de connexion — maquette « Authentification — Client / 1. Connexion »,
/// états **Nominal** et **Erreur**.
///
/// **Écart assumé par rapport à la maquette** : elle demande un numéro
/// camerounais et un code par SMS. Le backend s'authentifie par **email**
/// (`LoginSerializer` : `email` + `password` ou `code`), et aucun endpoint
/// n'accepte un téléphone comme identifiant. Arbitrage du 12 septembre 2026 —
/// voir `docs/design-api-map.md` § 1. La mise en page, la typographie et les
/// états de la maquette sont conservés tels quels ; seul le champ change.
///
/// **Refonte UI** : en-tête encre animé (camion sur le motif trajet), champs
/// à icône, et l'autre moyen de connexion en bouton secondaire sous un « ou »
/// plutôt qu'un lien perdu en bas d'écran.
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
import 'login_method_screen.dart';
import 'otp_verification_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  /// Erreurs de saisie locales, affichées sous le champ concerné.
  ///
  /// Validation de **forme** uniquement (email plausible, mot de passe assez
  /// long) : elle évite un aller-retour réseau inutile. Les règles métier
  /// restent côté serveur, jamais dupliquées ici.
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _email.text.trim();

    setState(() {
      _emailError = _looksLikeEmail(email) ? null : l10n.authEmailInvalid;
      _passwordError = _password.text.length >= 8
          ? null
          : l10n.authPasswordTooShort;
    });
    if (_emailError != null || _passwordError != null) return;

    final auth = context.read<AuthController>();
    final ok = await auth.loginWithPassword(
      email: email,
      password: _password.text,
    );
    if (!ok || !mounted) return;
    // La navigation est portée par le SessionGate, qui observe le statut : une
    // session ouverte remplace tout l'arbre. Rien à pousser ici.
  }

  /// Contrôle de forme volontairement permissif.
  ///
  /// La vérité sur la validité d'un email appartient au serveur
  /// (`EmailField` de DRF) : un contrôle local trop strict refuserait des
  /// adresses légitimes. On ne filtre que l'évidence.
  static bool _looksLikeEmail(String value) {
    final at = value.indexOf('@');
    return at > 0 && value.indexOf('.', at) > at + 1 && !value.contains(' ');
  }

  void _openMethodChoice() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginMethodScreen(initialEmail: _email.text.trim()),
      ),
    );
  }

  void _openRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();

    // Un compte non vérifié doit finir son inscription : le serveur le dit
    // explicitement par `email_not_verified`, on l'emmène sur la vérification
    // plutôt que de le laisser buter sur le même écran.
    final failure = auth.failure;
    final needsVerification =
        failure is ApiException &&
        failure.code == ApiErrorCode.emailNotVerified;

    return AuthScaffold(
      showBrand: true,
      children: [
        AuthTitle(l10n.authWelcomeBack),
        const SizedBox(height: AppSpacing.xs),
        AuthSubtitle(l10n.authSignInSubtitle),
        const SizedBox(height: AppSpacing.xxl),

        AppTextField(
          label: l10n.authEmailLabel,
          hintText: l10n.authEmailHint,
          controller: _email,
          errorText: _emailError,
          prefixIcon: AppIcons.mail,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          enabled: !auth.busy,
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
            auth.clearFailure();
            setState(() {});
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: l10n.authPasswordLabel,
          hintText: l10n.authPasswordHint,
          controller: _password,
          errorText: _passwordError,
          prefixIcon: AppIcons.lock,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          enabled: !auth.busy,
          onChanged: (_) {
            if (_passwordError != null) setState(() => _passwordError = null);
            auth.clearFailure();
            setState(() {});
          },
          onSubmitted: (_) => _canSubmit ? _submit() : null,
        ),

        if (failure != null && !needsVerification) ...[
          const SizedBox(height: AppSpacing.lg),
          AuthErrorBanner(messageForFailure(l10n, failure)),
        ],
        if (needsVerification) ...[
          const SizedBox(height: AppSpacing.lg),
          AuthErrorBanner(messageForFailure(l10n, failure)),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: auth.busy ? null : _goVerifyEmail,
            child: Text(l10n.authOtpResendAction),
          ),
        ],

        const SizedBox(height: AppSpacing.xxl),
        // La maquette laisse respirer jusqu'au bas de l'écran.
        const Spacer(),

        PrimaryButton(
          label: l10n.authSignInAction,
          trailingIcon: AppIcons.forwardBold,
          busy: auth.busy,
          onPressed: _canSubmit ? _submit : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        const AuthOrDivider(),
        const SizedBox(height: AppSpacing.lg),
        AuthOutlineButton(
          label: l10n.authOtherMethod,
          icon: AppIcons.mail,
          onTap: auth.busy ? null : _openMethodChoice,
        ),
        const SizedBox(height: AppSpacing.xl),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.authNoAccount,
              style: const TextStyle(
                fontSize: AppFontSize.label,
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            TextButton(
              onPressed: auth.busy ? null : _openRegister,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brand,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.authCreateAccountLink,
                style: const TextStyle(
                  fontSize: AppFontSize.label,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _TermsLine(l10n: l10n),
      ],
    );
  }

  Future<void> _goVerifyEmail() async {
    final auth = context.read<AuthController>();
    final email = _email.text.trim();
    final sent = await auth.resendOtp(email: email);
    if (!sent || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          email: email,
          purpose: OtpPurpose.verifyRegistration,
        ),
      ),
    );
  }
}

class _TermsLine extends StatelessWidget {
  const _TermsLine({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            fontSize: AppFontSize.caption,
            color: AppColors.inkMuted,
          ),
          children: [
            TextSpan(text: l10n.authTermsPrefix),
            TextSpan(
              text: l10n.authTermsLink,
              style: const TextStyle(
                color: AppColors.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
