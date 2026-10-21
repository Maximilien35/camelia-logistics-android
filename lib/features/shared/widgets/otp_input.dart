/// Saisie du code OTP : six cases de 44 × 56, rayon 12.
///
/// États relevés dans la maquette :
/// - case **remplie** : fond [AppColors.ink], chiffre blanc 20 px ;
/// - case **active** : bordure [AppColors.brand] ;
/// - case **vide** : bordure [AppColors.border].
///
/// **Refonte UI** : un chiffre saisi fait « rebondir » sa case, la case active
/// porte un halo, et la rangée secoue quand le serveur refuse le code.
///
/// Six chiffres exactement : `OTP_CODE_LENGTH = 6` côté backend, et
/// `VerifyOtpSerializer` impose `min_length == max_length == 6`.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_tokens.dart';

class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.onChanged,
    this.onCompleted,
    this.length = 6,
    this.hasError = false,
    this.enabled = true,
    this.autofocus = true,
  });

  final ValueChanged<String> onChanged;

  /// Déclenché dès que les six chiffres sont saisis.
  ///
  /// Ne **valide pas** tout seul : l'appel réseau reste déclenché par le bouton
  /// « Vérifier », comme dans la maquette.
  final ValueChanged<String>? onCompleted;

  final int length;
  final bool hasError;
  final bool enabled;
  final bool autofocus;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput>
    with SingleTickerProviderStateMixin {
  /// Un seul champ invisible porte la saisie : gérer six contrôleurs séparés
  /// casse le collage du code et le remplissage automatique par SMS/email.
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  /// Secousse d'erreur, rejouée à chaque passage de `hasError` à `true`.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() => setState(() {});

  @override
  void didUpdateWidget(OtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError &&
        !oldWidget.hasError &&
        !MediaQuery.disableAnimationsOf(context)) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    _controller.dispose();
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    super.dispose();
  }

  String get _value => _controller.text;

  void _handleChange(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits != raw) {
      _controller.value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    setState(() {});
    widget.onChanged(digits);
    if (digits.length == widget.length) widget.onCompleted?.call(digits);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Champ réel, invisible mais bien présent dans l'arbre : c'est lui qui
        // reçoit le clavier, le collage et l'autofill.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofillHints: const [AutofillHints.oneTimeCode],
              onChanged: _handleChange,
              decoration: const InputDecoration(counterText: ''),
            ),
          ),
        ),
        GestureDetector(
          onTap: widget.enabled ? () => _focus.requestFocus() : null,
          child: AnimatedBuilder(
            animation: _shake,
            builder: (context, child) => Transform.translate(
              offset: Offset(
                math.sin(_shake.value * math.pi * 5) * 8 * (1 - _shake.value),
                0,
              ),
              child: child,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.length, (i) {
                final filled = i < _value.length;
                final active = i == _value.length && _focus.hasFocus;
                return Padding(
                  padding: EdgeInsets.only(
                    right: i == widget.length - 1 ? 0 : 9,
                  ),
                  child: _Box(
                    digit: filled ? _value[i] : null,
                    active: active,
                    hasError: widget.hasError,
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({this.digit, required this.active, required this.hasError});

  final String? digit;
  final bool active;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final filled = digit != null;
    final Color borderColor;
    if (hasError) {
      borderColor = AppColors.error;
    } else if (active) {
      borderColor = AppColors.brand;
    } else {
      borderColor = AppColors.border;
    }
    final dark = filled && !hasError;

    return TweenAnimationBuilder<double>(
      // Rejoué à chaque nouveau chiffre : la case rebondit à la saisie.
      key: ValueKey(digit),
      tween: Tween(begin: filled ? .82 : 1, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: AppDimens.otpBoxWidth,
        height: AppDimens.otpBoxHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: dark ? AppColors.ink : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.small),
          border: Border.all(
            color: dark ? AppColors.ink : borderColor,
            width: 1.5,
          ),
          boxShadow: active && !hasError
              ? const [BoxShadow(color: AppColors.brandHalo, spreadRadius: 4)]
              : null,
        ),
        child: Text(
          digit ?? '',
          style: TextStyle(
            color: dark ? AppColors.white : AppColors.ink,
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w700,
            fontSize: AppFontSize.headline,
          ),
        ),
      ),
    );
  }
}
