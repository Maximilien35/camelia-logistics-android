/// Tokens de design de la V2, relevés dans la maquette Claude Design
/// `Camelia V2.dc.html` (projet `d597ae46-93ab-4a9f-a686-314e927bfd40`).
///
/// Les valeurs de [AppColors], [AppRadii] et [AppDimens] sont reportées
/// **telles quelles** depuis le handoff — voir `docs/design-api-map.md`
/// § Tokens pour le relevé et le nombre d'occurrences de chacune.
///
/// La refonte UI d'octobre 2026 a ajouté, avec l'accord du produit, des
/// échelles que le handoff ne fixait pas : [AppSpacing], [AppFontSize],
/// [AppGradients], [AppShadows]. Un écran pioche dans ces échelles plutôt que
/// d'écrire une valeur littérale.
library;

import 'package:flutter/material.dart';

/// Palette de la maquette V2.
abstract final class AppColors {
  /// Encre principale : titres, texte appuyé, boutons primaires. (421 usages)
  static const Color ink = Color(0xFF0E0E10);

  /// Texte secondaire, légendes, libellés de champ. (297 usages)
  static const Color inkMuted = Color(0xFF5B5B63);

  /// Violet de marque Camelia : liens, accents, sélection. (114 usages)
  static const Color brand = Color(0xFF4818F0);

  /// Fond de surface posée sur la page (badges neutres, cartes). (91 usages)
  static const Color surface = Color(0xFFF0F0F3);

  /// Bordure de champ et de carte au repos. (80 usages)
  static const Color border = Color(0xFFE7E7EB);

  /// Bordure appuyée, séparateurs, flèches de parcours. (45 usages)
  static const Color borderStrong = Color(0xFFD7D7DE);

  /// Erreur : bordure de champ invalide, message d'échec. (42 usages)
  static const Color error = Color(0xFFE5483A);

  /// Accent cyan : survol de lien, éléments de progression. (34 usages)
  static const Color accentCyan = Color(0xFF30B4FC);

  /// Teinte violette très claire : fond de bloc mis en avant. (33 usages)
  static const Color brandTint = Color(0xFFF8F5FF);

  /// Teinte chaude très claire, pendant de [brandTint]. (33 usages)
  static const Color warmTint = Color(0xFFFBF8F6);

  /// Texte désactivé sur fond clair. (33 usages)
  static const Color inkDisabled = Color(0xFF9A9AA2);

  /// Texte d'invite de saisie (placeholder). (17 usages)
  static const Color inkPlaceholder = Color(0xFFC3C3CA);

  /// Avertissement : états d'attente, mentions à vérifier. (28 usages)
  static const Color warning = Color(0xFFE0A100);

  /// Succès : confirmation, étape franchie du ruban. (22 usages)
  static const Color success = Color(0xFF1FA463);

  /// Accent magenta, second accent de marque. (19 usages)
  static const Color accentMagenta = Color(0xFFC018D8);

  /// Fond de page de l'app.
  static const Color background = Color(0xFFFAFAFA);

  /// Surface de carte / feuille.
  static const Color white = Color(0xFFFFFFFF);

  /// Ombre portée standard des cartes : `rgba(14,14,16,.06)`. (44 usages)
  static const Color shadow = Color(0x0F0E0E10);

  /// Halo violet des éléments actifs : `rgba(72,24,240,.08)`.
  static const Color brandHalo = Color(0x144818F0);
}

/// Rayons de bordure relevés dans la maquette.
abstract final class AppRadii {
  /// Badges et puces d'état. (108 usages)
  static const double badge = 6;

  /// Cases de saisie OTP, petites cartes. (33 usages)
  static const double small = 12;

  /// Champs de saisie et cartes. (68 usages)
  static const double field = 14;

  /// Boutons principaux. (54 usages)
  static const double button = 16;

  /// Feuilles modales et grandes surfaces.
  static const double sheet = 22;
}

/// Hauteurs et espacements relevés dans la maquette.
abstract final class AppDimens {
  /// Hauteur des champs de saisie et des boutons principaux. (43 usages)
  static const double controlHeight = 56;

  /// Hauteur des boutons secondaires. (11 usages)
  static const double controlHeightCompact = 52;

  /// Case de saisie OTP : 44 × 56.
  static const double otpBoxWidth = 44;
  static const double otpBoxHeight = 56;

  /// Puce d'état / numéro d'étape. (52 usages)
  static const double chipSize = 22;

  /// Marge latérale d'écran dans le gabarit iPhone de la maquette.
  static const double screenPadding = 22;

  /// Marge haute d'écran, sous l'encoche (gabarit `ios-frame.jsx`).
  static const double screenPaddingTop = 74;

  /// Gabarit de référence des maquettes : iPhone 402 × 874 (`IOSDevice`).
  static const Size referenceDevice = Size(402, 874);
}

/// Échelle d'espacement — **refonte UI** (au-delà du handoff).
///
/// La V2 comptait quinze valeurs d'écart vertical (2, 3, 4, 5, 6, 7, 8, 10,
/// 12, 14, 16, 18, 20, 22, 28…) : à l'œil, aucun rythme ne se dégageait. Tout
/// espacement entre blocs prend désormais une marche de cette échelle, et
/// rien d'autre.
abstract final class AppSpacing {
  /// Entre un titre et son sous-titre collé.
  static const double xxs = 2;

  /// Entre deux lignes d'un même bloc.
  static const double xs = 4;

  /// Entre éléments liés (libellé → champ, icône → texte).
  static const double sm = 8;

  /// Entre éléments d'une liste, entre cartes.
  static const double md = 12;

  /// Entre groupes d'un même écran.
  static const double lg = 16;

  /// Entre sections.
  static const double xl = 20;

  /// Avant un titre de section, après un en-tête.
  static const double xxl = 24;

  /// Grandes respirations (fin d'écran, héros).
  static const double xxxl = 32;
}

/// Échelle typographique — **refonte UI** (au-delà du handoff).
///
/// Vingt tailles cohabitaient, la moitié entre 11 et 13,5 px : tout avait le
/// même poids et rien ne ressortait. Neuf marches, assez écartées pour qu'un
/// changement de niveau se voie.
abstract final class AppFontSize {
  /// Pastilles, capitales d'en-tête, libellés de la barre du bas.
  static const double micro = 11;

  /// Légendes, mentions secondaires.
  static const double caption = 12;

  /// Texte secondaire, sous-titres de carte.
  static const double label = 13;

  /// Corps de texte.
  static const double body = 14;

  /// Corps appuyé, boutons.
  static const double bodyLarge = 16;

  /// Titres de section, titres de carte.
  static const double title = 18;

  /// Titres d'écran.
  static const double headline = 22;

  /// Montants mis en avant, grands titres.
  static const double display = 28;

  /// En-tête d'accueil.
  static const double hero = 32;
}

/// Dégradés et ombres de marque — **refonte UI** (au-delà du handoff).
///
/// **Pas de grand aplat saturé** : un premier en-tête en dégradé violet → bleu
/// a été rejeté (« fatigue les yeux »). Les grandes surfaces restent neutres —
/// encre sombre ou blanc — et le violet de marque n'y figure qu'en accent.
abstract final class AppGradients {
  /// Surface sombre des en-têtes et cartes signature (accueil, carte de
  /// membre) : l'encre de la maquette, à peine éclaircie en haut à gauche pour
  /// donner du relief sans couleur.
  static const LinearGradient inkPanel = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF26262E), AppColors.ink],
  );

  /// Voile posé sur les photos de service pour que le texte blanc reste
  /// lisible quelle que soit l'image.
  static const LinearGradient photoScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x000E0E10), Color(0x330E0E10), Color(0xD90E0E10)],
    stops: [0, .45, 1],
  );
}

abstract final class AppShadows {
  /// Carte posée : ombre douce et large plutôt qu'une bordure grise.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D0E0E10), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x080E0E10), blurRadius: 4, offset: Offset(0, 1)),
  ];

  /// Élément flottant à cheval sur un en-tête (barre de recherche).
  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x290E0E10), blurRadius: 30, offset: Offset(0, 14)),
  ];
}

/// Familles et graisses typographiques de la maquette.
///
/// `Space Grotesk` porte les titres, les montants et la marque ;
/// `Plus Jakarta Sans` porte le corps de texte. Les deux arrivent par
/// `google_fonts`, déjà présent au `pubspec.yaml`.
abstract final class AppFonts {
  static const String display = 'Space Grotesk';
  static const String body = 'Plus Jakarta Sans';
}
