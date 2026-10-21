/// Thème Flutter de la V2, construit sur les tokens relevés dans la maquette.
///
/// Voir [AppColors], [AppRadii], [AppDimens], [AppFonts] dans `app_tokens.dart`
/// pour l'origine de chaque valeur. Ce fichier ne fait que les câbler dans un
/// [ThemeData] : aucune couleur littérale ne doit apparaître ici.
///
/// La maquette est intégralement en mode clair. Aucun thème sombre n'a été
/// fourni au handoff : en déduire une palette sombre serait inventer du design,
/// donc [AppTheme.light] est le seul thème exposé pour l'instant.
library;

import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  /// Thème clair, le seul fourni par le handoff.
  static ThemeData get light {
    final colors = const ColorScheme.light(
      primary: AppColors.brand,
      onPrimary: AppColors.white,
      secondary: AppColors.accentCyan,
      onSecondary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.ink,
      error: AppColors.error,
      onError: AppColors.white,
      outline: AppColors.border,
      outlineVariant: AppColors.borderStrong,
    );

    final body = GoogleFonts.plusJakartaSansTextTheme();
    final display = GoogleFonts.spaceGroteskTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppFonts.body,

      // `Space Grotesk` porte les titres et les montants, `Plus Jakarta Sans`
      // le corps de texte — partage relevé dans la maquette.
      textTheme: body
          .copyWith(
            displayLarge: display.displayLarge,
            displayMedium: display.displayMedium,
            displaySmall: display.displaySmall,
            headlineLarge: display.headlineLarge,
            headlineMedium: display.headlineMedium,
            headlineSmall: display.headlineSmall,
            titleLarge: display.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          )
          .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.ink),
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontFamily: AppFonts.display,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        // Hauteur de 56 px obtenue par le padding vertical, cohérent avec
        // `AppDimens.controlHeight`.
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        hintStyle: const TextStyle(
          color: AppColors.inkPlaceholder,
          fontWeight: FontWeight.w500,
        ),
        border: _fieldBorder(AppColors.border),
        enabledBorder: _fieldBorder(AppColors.border),
        focusedBorder: _fieldBorder(AppColors.brand),
        errorBorder: _fieldBorder(AppColors.error),
        focusedErrorBorder: _fieldBorder(AppColors.error),
        disabledBorder: _fieldBorder(AppColors.border),
        errorStyle: const TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.small),
        ),
      ),

      // Transitions d'écran — refonte UI. Sur Android, axe partagé
      // horizontal (`animations`, paquet de l'équipe Flutter) : l'écran
      // suivant glisse et se fond depuis la droite, le parcours de commande
      // se lit comme une progression. Sur iOS, la transition native, qui porte
      // le geste de retour par balayage — à ne pas casser.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
            fillColor: AppColors.background,
          ),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.field),
    // 1,5 px dans la maquette.
    borderSide: BorderSide(color: color, width: 1.5),
  );
}
