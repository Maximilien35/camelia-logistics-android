/// **Informations personnelles** — maquette « Compte — Client / 3. Profil ».
///
/// Modifiable (décision produit du 13 septembre 2026) : prénom, nom, et
/// téléphone **vérifié par code**. L'email reste en lecture seule : c'est
/// l'identifiant de connexion.
///
/// `PATCH /v1/me/`, `POST /v1/me/phone/` et `/me/phone/verify/` (§ 7.3.8,
/// livrés par T5.10). Le changement de téléphone dépend d'un canal SMS côté
/// serveur (`OTP_CODE_SENDER`) : tant que ce réglage vaut l'email, le code
/// n'arrive pas au nouveau numéro — prérequis de déploiement, pas de code.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_error_messages.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../services/profile_service.dart';
import '../../state/auth_controller.dart';
import '../../state/profile_edit_controller.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/primary_button.dart';
import '../../../../core/theme/app_icons.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final ProfileEditController _controller;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  final TextEditingController _newPhone = TextEditingController();
  String _code = '';
  bool _showNameErrors = false;
  bool _phoneFormatError = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    final user = auth.user;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _controller = ProfileEditController(
      service: context.read<ProfileService>(),
      onProfileUpdated: auth.applyServerProfile,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _newPhone.dispose();
    super.dispose();
  }

  String? _nameError(AppLocalizations l10n, TextEditingController field) {
    if (!_showNameErrors) return null;
    return switch (ProfileEditController.nameProblem(field.text)) {
      'required' => l10n.fieldRequired,
      'too_long' => l10n.fieldTooLong,
      _ => null,
    };
  }

  String? _serverFieldError(Object? failure, String field) =>
      failure is ApiException ? failure.fieldError(field) : null;

  Future<void> _saveName() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _showNameErrors = true);
    final ok = await _controller.saveName(
      firstName: _firstName.text,
      lastName: _lastName.text,
    );
    if (ok) {
      setState(() => _showNameErrors = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
    }
  }

  Future<void> _requestCode() async {
    final ok = await _controller.requestCode(_newPhone.text);
    setState(() {
      _phoneFormatError = !ok && _controller.phoneFailure == null;
      _code = '';
    });
  }

  Future<void> _confirmCode() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _controller.confirmCode(_code);
    if (ok) {
      _newPhone.clear();
      messenger.showSnackBar(SnackBar(content: Text(l10n.profilePhoneUpdated)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthController>().user;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final nameFailure = _controller.nameFailure;
        final phoneFailure = _controller.phoneFailure;
        return FlowScaffold(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              FlowHeader(title: l10n.accountPersonalInfo, large: true),

              FlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: l10n.authFirstNameLabel,
                      controller: _firstName,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.givenName],
                      errorText:
                          _nameError(l10n, _firstName) ??
                          _serverFieldError(nameFailure, 'first_name'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: l10n.authLastNameLabel,
                      controller: _lastName,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.familyName],
                      errorText:
                          _nameError(l10n, _lastName) ??
                          _serverFieldError(nameFailure, 'last_name'),
                      onSubmitted: (_) => _saveName(),
                    ),
                    if (nameFailure != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      ErrorNotice(
                        message: messageForFailure(l10n, nameFailure),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: l10n.profileSaveName,
                      busy: _controller.savingName,
                      onPressed: _saveName,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              FlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(l10n.profileEmailLabel),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        fontSize: AppFontSize.body,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.profileEmailReadOnly,
                      style: const TextStyle(
                        fontSize: AppFontSize.caption,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              FlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(l10n.profilePhoneSection),
                    Text(
                      (user?.phone.isNotEmpty ?? false) ? user!.phone : '—',
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: AppFontSize.bodyLarge,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.profilePhoneWhy,
                      style: const TextStyle(
                        fontSize: AppFontSize.caption,
                        height: 1.45,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ..._phoneSection(l10n, phoneFailure),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _phoneSection(AppLocalizations l10n, Object? failure) {
    switch (_controller.phoneStep) {
      case PhoneChangeStep.idle:
        return [
          OutlineAction(
            label: l10n.profilePhoneChange,
            icon: AppIcons.phone,
            onPressed: _controller.startPhoneChange,
          ),
        ];
      case PhoneChangeStep.enteringNumber:
        return [
          AppTextField(
            label: l10n.profilePhoneNew,
            controller: _newPhone,
            hintText: l10n.authPhoneHint,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            errorText: _phoneFormatError
                ? l10n.fieldInvalidPhone
                : _serverFieldError(failure, 'phone'),
            onSubmitted: (_) => _requestCode(),
          ),
          if (failure != null) ...[
            const SizedBox(height: AppSpacing.md),
            ErrorNotice(message: messageForFailure(l10n, failure)),
          ],
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: l10n.profilePhoneSendCode,
            busy: _controller.phoneBusy,
            onPressed: _requestCode,
          ),
          TextButton(
            onPressed: _controller.cancelPhoneChange,
            child: Text(l10n.commonCancel),
          ),
        ];
      case PhoneChangeStep.awaitingCode:
        return [
          Text(
            l10n.profilePhoneCodeSent(_controller.pendingPhone),
            style: const TextStyle(
              fontSize: AppFontSize.label,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionLabel(l10n.profilePhoneCodeLabel),
          OtpInput(
            hasError: failure != null,
            enabled: !_controller.phoneBusy,
            onChanged: (value) => setState(() => _code = value),
            onCompleted: (value) {
              _code = value;
              _confirmCode();
            },
          ),
          if (failure != null) ...[
            const SizedBox(height: AppSpacing.md),
            ErrorNotice(message: messageForFailure(l10n, failure)),
          ],
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: l10n.profilePhoneVerify,
            busy: _controller.phoneBusy,
            onPressed: _code.length == ProfileEditController.codeLength
                ? _confirmCode
                : null,
          ),
          TextButton(
            onPressed: _controller.phoneBusy ? null : _requestCode,
            child: Text(l10n.authOtpResendAction),
          ),
          TextButton(
            onPressed: _controller.cancelPhoneChange,
            child: Text(l10n.commonCancel),
          ),
        ];
    }
  }
}
