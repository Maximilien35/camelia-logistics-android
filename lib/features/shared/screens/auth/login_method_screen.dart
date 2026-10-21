/// Choix de la méthode de connexion — maquette « 4. Choix méthode ».
///
/// La maquette propose « SMS (OTP) » et « Email ». Le backend n'offre pas ce
/// choix-là : `LoginSerializer` accepte **soit** un `password` **soit** un
/// `code` envoyé par email, et jamais les deux. Les deux cartes de la maquette
/// portent donc les deux modes réellement disponibles — mot de passe, ou code
/// par email. Aucun canal SMS n'existe côté serveur.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_error_messages.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../state/auth_controller.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/pressable.dart';
import '../../widgets/primary_button.dart';
import 'otp_verification_screen.dart';
import '../../../../core/theme/app_icons.dart';

enum _Method { password, emailCode }

class LoginMethodScreen extends StatefulWidget {
  const LoginMethodScreen({super.key, this.initialEmail = ''});

  /// Email déjà saisi sur l'écran de connexion, repris tel quel.
  final String initialEmail;

  @override
  State<LoginMethodScreen> createState() => _LoginMethodScreenState();
}

class _LoginMethodScreenState extends State<LoginMethodScreen> {
  late final TextEditingController _email = TextEditingController(
    text: widget.initialEmail,
  );
  _Method _method = _Method.emailCode;
  String? _emailError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool get _canSubmit => _email.text.trim().isNotEmpty;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _emailError = l10n.authEmailInvalid);
      return;
    }
    setState(() => _emailError = null);

    if (_method == _Method.password) {
      // Le mot de passe se saisit sur l'écran de connexion : on y retourne.
      Navigator.of(context).pop();
      return;
    }

    final auth = context.read<AuthController>();
    final sent = await auth.startCodeLogin(email: email);
    if (!sent || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            OtpVerificationScreen(email: email, purpose: OtpPurpose.signIn),
      ),
    );
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
        const AuthIconBadge(AppIcons.shield),
        const SizedBox(height: AppSpacing.xl),
        AuthTitle(l10n.authMethodTitle),
        const SizedBox(height: AppSpacing.sm),
        AuthSubtitle(l10n.authMethodSubtitle),
        const SizedBox(height: AppSpacing.xxxl),

        AppTextField(
          label: l10n.authEmailLabel,
          hintText: l10n.authEmailHint,
          controller: _email,
          errorText: _emailError,
          prefixIcon: AppIcons.mail,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          enabled: !auth.busy,
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
            auth.clearFailure();
            setState(() {});
          },
        ),
        const SizedBox(height: AppSpacing.xxl),

        _MethodCard(
          title: l10n.authMethodCodeTitle,
          subtitle: l10n.authMethodCodeSubtitle,
          icon: AppIcons.mail,
          selected: _method == _Method.emailCode,
          onTap: auth.busy
              ? null
              : () => setState(() => _method = _Method.emailCode),
        ),
        const SizedBox(height: AppSpacing.md),
        _MethodCard(
          title: l10n.authMethodPasswordTitle,
          subtitle: l10n.authMethodPasswordSubtitle,
          icon: AppIcons.lock,
          selected: _method == _Method.password,
          onTap: auth.busy
              ? null
              : () => setState(() => _method = _Method.password),
        ),

        if (failure != null) ...[
          const SizedBox(height: AppSpacing.xl),
          AuthErrorBanner(messageForFailure(l10n, failure)),
        ],

        const SizedBox(height: AppSpacing.xxxl),
        const Spacer(),

        PrimaryButton(
          label: l10n.authContinue,
          trailingIcon: AppIcons.forwardBold,
          busy: auth.busy,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }
}

/// Carte de sélection de la maquette : bordure violette et fond teinté quand
/// l'option est retenue.
///
/// **Refonte UI** : la carte s'enfonce à l'appui ([Pressable]), l'icône passe
/// dans une pastille qui se colore, et la coche apparaît en rebondissant.
class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  static const Duration _motion = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: _motion,
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandTint : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.field),
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.border,
              width: 1.5,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AppColors.brandHalo,
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: _motion,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? AppColors.brand : AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.white : AppColors.inkMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: AppFontSize.body,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: AppFontSize.label,
                        color: AppColors.inkMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedSwitcher(
                duration: _motion,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: child,
                ),
                child: Icon(
                  selected ? AppIcons.radioOn : AppIcons.radioOff,
                  key: ValueKey(selected),
                  size: 22,
                  color: selected ? AppColors.brand : AppColors.borderStrong,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
