/// Champ de saisie de la maquette : 56 px, rayon 14, bordure 1,5 px.
///
/// L'état d'erreur de la maquette (« Connexion [Erreur] ») colore la bordure en
/// [AppColors.error] et affiche le message **sous** le champ, en 12 px gras —
/// pas une bannière globale. Le message vient du backend, mappé par
/// `messageForApiError` ou tiré de `ApiException.fieldError`.
///
/// **Refonte UI** (au-delà du handoff) :
/// - icône facultative en tête de champ, qui prend la couleur de marque au
///   focus ;
/// - halo violet léger autour du champ actif, pour qu'on voie d'un coup d'œil
///   où l'on tape ;
/// - œil afficher / masquer sur les mots de passe ;
/// - message d'erreur qui glisse en place au lieu de surgir.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import 'animated_reveal.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.autofillHints,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.inputFormatters,
    this.prefixIcon,
  });

  /// Libellé affiché au-dessus du champ (la maquette ne met pas de libellé
  /// flottant à l'intérieur).
  final String label;

  final TextEditingController? controller;
  final String? hintText;

  /// Message d'erreur sous le champ. `null` = pas d'erreur.
  final String? errorText;

  final TextInputType? keyboardType;

  /// Saisie masquée. Ajoute d'office l'œil afficher / masquer, sauf si un
  /// [suffix] est fourni.
  final bool obscureText;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  /// Icône en tête de champ (enveloppe, cadenas…).
  final IconData? prefixIcon;

  /// Contraintes de saisie appliquées **à la frappe** (chiffres seuls,
  /// longueur fixe). Purement ergonomique : le serveur revalide toujours —
  /// le code de remise, par exemple, reste vérifié par `^\d{4}$` côté API.
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _focus = FocusNode();
  late bool _obscured = widget.obscureText;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    super.dispose();
  }

  bool get _hasError =>
      widget.errorText != null && widget.errorText!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus && widget.enabled;
    final accent = _hasError
        ? AppColors.error
        : focused
        ? AppColors.brand
        : AppColors.inkDisabled;

    Widget? suffix = widget.suffix;
    if (suffix == null && widget.obscureText) {
      final l10n = AppLocalizations.of(context)!;
      suffix = IconButton(
        onPressed: () => setState(() => _obscured = !_obscured),
        tooltip: _obscured ? l10n.authShowPassword : l10n.authHidePassword,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            _obscured ? AppIcons.eye : AppIcons.eyeOff,
            key: ValueKey(_obscured),
            size: 20,
            color: focused ? AppColors.ink : AppColors.inkMuted,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          // Fusionné avec le style hérité : un `TextStyle` nu remplacerait
          // tout, police du thème comprise.
          style: DefaultTextStyle.of(context).style.merge(
            TextStyle(
              color: focused ? AppColors.ink : AppColors.inkMuted,
              fontWeight: FontWeight.w600,
              fontSize: AppFontSize.label,
            ),
          ),
          child: Text(widget.label),
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.field),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: (_hasError ? AppColors.error : AppColors.brand)
                          .withValues(alpha: .12),
                      spreadRadius: 4,
                    ),
                  ]
                : const [],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            keyboardType: widget.keyboardType,
            obscureText: _obscured,
            textInputAction: widget.textInputAction,
            autofillHints: widget.autofillHints,
            enabled: widget.enabled,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            inputFormatters: widget.inputFormatters,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: AppFontSize.bodyLarge,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: widget.prefixIcon == null
                  ? null
                  : TweenAnimationBuilder<Color?>(
                      tween: ColorTween(end: accent),
                      duration: const Duration(milliseconds: 200),
                      builder: (context, color, _) =>
                          Icon(widget.prefixIcon, size: 20, color: color),
                    ),
              suffixIcon: suffix,
              // `errorText` est géré à la main juste en dessous : le faire
              // porter par InputDecoration décalerait la hauteur du champ, que
              // la maquette fixe à 56 px.
              enabledBorder: _hasError ? _border(AppColors.error) : null,
              focusedBorder: _hasError ? _border(AppColors.error) : null,
            ),
          ),
        ),
        // Pas d'`AnimatedSize` : ce champ vit sous l'`IntrinsicHeight` du
        // gabarit d'authentification, qu'il ferait déborder au repli.
        AnimatedReveal(
          duration: const Duration(milliseconds: 200),
          child: _hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          AppIcons.error,
                          size: 14,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          widget.errorText!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: AppFontSize.caption,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.field),
    borderSide: BorderSide(color: color, width: 1.5),
  );
}
