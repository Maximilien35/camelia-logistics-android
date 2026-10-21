/// Vocabulaire d'icônes unique de l'app, bâti sur Phosphor.
///
/// Avant cette table, la V2 mélangeait deux grammaires : les tracés SVG du
/// handoff (dessinés à la main, trop sommaires pour un camion ou un carton) et
/// une soixantaine d'icônes Material. Le mélange se voyait. Tout passe
/// désormais par ici : un écran nomme ce qu'il veut montrer (`AppIcons.truck`),
/// jamais la police qui le dessine.
///
/// ## Pourquoi des polices embarquées et pas le paquet `phosphor_flutter`
///
/// Le paquet n'est plus publié depuis mai 2024 et ne compile plus : il étend
/// `IconData`, devenue une classe `final` dans Flutter. Les polices Phosphor
/// (licence MIT, `assets/fonts/phosphor/LICENSE`) sont donc déclarées dans le
/// `pubspec.yaml` et citées ici par point de code. Le nom Phosphor d'origine
/// figure en commentaire quand il diffère du nom sémantique, pour retrouver le
/// glyphe sur phosphoricons.com.
///
/// Trois graisses, chacune son rôle :
/// - **regular** : icônes d'interface (actions, listes, champs) ;
/// - **fill** : état actif (onglet sélectionné, étoile notée) ;
/// - **bold** : pictogrammes de service, plus présents.
///
/// Toutes les valeurs sont des `const` : la police est élaguée au build
/// release, seules les icônes réellement citées sont embarquées.
library;

import 'package:flutter/widgets.dart';

abstract final class AppIcons {
  static const String _regular = 'PhosphorRegular';
  static const String _fill = 'PhosphorFill';
  static const String _bold = 'PhosphorBold';

  // --- Transport & métier ---
  static const IconData truck = IconData(0xe4b4, fontFamily: _regular);
  static const IconData truckTrailer = IconData(0xe4b6, fontFamily: _regular);
  static const IconData package = IconData(0xe390, fontFamily: _regular);
  static const IconData warehouse = IconData(0xecd4, fontFamily: _regular);
  // globeHemisphereWest
  static const IconData globe = IconData(0xe28c, fontFamily: _regular);
  static const IconData steeringWheel = IconData(0xe9ac, fontFamily: _regular);
  // path
  static const IconData route = IconData(0xe39c, fontFamily: _regular);
  // mapPin
  static const IconData pin = IconData(0xe316, fontFamily: _regular);
  static const IconData pinFilled = IconData(0xe316, fontFamily: _fill);
  // mapPinLine
  static const IconData pinLine = IconData(0xe318, fontFamily: _regular);
  // navigationArrow
  static const IconData navigation = IconData(0xeade, fontFamily: _regular);
  // gpsFix
  static const IconData myLocation = IconData(0xedd6, fontFamily: _regular);
  // arrowUUpLeft
  static const IconData returnParcel = IconData(0xe08a, fontFamily: _regular);
  // ruler
  static const IconData dimensions = IconData(0xe6b8, fontFamily: _regular);
  // password
  static const IconData deliveryCode = IconData(0xe752, fontFamily: _regular);
  // stairs — étage du déménagement
  static const IconData floor = IconData(0xe8ec, fontFamily: _regular);
  // clockCounterClockwise — historique des courses
  static const IconData history = IconData(0xe1a0, fontFamily: _regular);

  // --- Navigation ---
  // arrowLeft
  static const IconData back = IconData(0xe058, fontFamily: _regular);
  // arrowRight
  static const IconData forward = IconData(0xe06c, fontFamily: _regular);
  static const IconData forwardBold = IconData(0xe06c, fontFamily: _bold);
  // caretRight / caretLeft
  static const IconData chevronRight = IconData(0xe13a, fontFamily: _regular);
  static const IconData chevronLeft = IconData(0xe138, fontFamily: _regular);
  // x
  static const IconData close = IconData(0xe4f6, fontFamily: _regular);
  // house
  static const IconData home = IconData(0xe2c2, fontFamily: _regular);
  static const IconData homeActive = IconData(0xe2c2, fontFamily: _fill);
  // package
  static const IconData orders = IconData(0xe390, fontFamily: _regular);
  static const IconData ordersActive = IconData(0xe390, fontFamily: _fill);
  // userCircle
  static const IconData account = IconData(0xe4c4, fontFamily: _regular);
  static const IconData accountActive = IconData(0xe4c4, fontFamily: _fill);
  // steeringWheel
  static const IconData jobs = IconData(0xe9ac, fontFamily: _regular);
  static const IconData jobsActive = IconData(0xe9ac, fontFamily: _fill);
  // wallet
  static const IconData earnings = IconData(0xe68a, fontFamily: _regular);
  static const IconData earningsActive = IconData(0xe68a, fontFamily: _fill);

  // --- Actions ---
  // magnifyingGlass
  static const IconData search = IconData(0xe30c, fontFamily: _regular);
  static const IconData searchBold = IconData(0xe30c, fontFamily: _bold);
  // arrowClockwise
  static const IconData refresh = IconData(0xe036, fontFamily: _regular);
  static const IconData check = IconData(0xe182, fontFamily: _regular);
  static const IconData plus = IconData(0xe3d4, fontFamily: _regular);
  static const IconData minus = IconData(0xe32a, fontFamily: _regular);
  static const IconData checkCircle = IconData(0xe184, fontFamily: _regular);
  // phone
  static const IconData call = IconData(0xe3b8, fontFamily: _regular);
  // whatsappLogo
  static const IconData whatsapp = IconData(0xe5d0, fontFamily: _regular);
  // signOut
  static const IconData logout = IconData(0xe42a, fontFamily: _regular);
  // bookmarkSimple
  static const IconData bookmark = IconData(0xe0ea, fontFamily: _regular);
  static const IconData calculator = IconData(0xe538, fontFamily: _regular);
  static const IconData camera = IconData(0xe10e, fontFamily: _regular);
  // cameraPlus
  static const IconData cameraAdd = IconData(0xec58, fontFamily: _regular);
  // images
  static const IconData gallery = IconData(0xe836, fontFamily: _regular);
  // fileArrowUp
  static const IconData upload = IconData(0xe61e, fontFamily: _regular);
  static const IconData arrowUp = IconData(0xe08e, fontFamily: _regular);
  static const IconData arrowDown = IconData(0xe03e, fontFamily: _regular);
  // circle / radioButton
  static const IconData radioOff = IconData(0xe18a, fontFamily: _regular);
  static const IconData radioOn = IconData(0xeb08, fontFamily: _fill);
  static const IconData star = IconData(0xe46a, fontFamily: _regular);
  static const IconData starFilled = IconData(0xe46a, fontFamily: _fill);

  // --- Information & état ---
  static const IconData info = IconData(0xe2ce, fontFamily: _regular);
  // warningCircle
  static const IconData error = IconData(0xe4e2, fontFamily: _regular);
  static const IconData clock = IconData(0xe19a, fontFamily: _regular);
  // hourglassMedium
  static const IconData pending = IconData(0xe2b8, fontFamily: _regular);
  // sealCheck
  static const IconData verified = IconData(0xe606, fontFamily: _regular);
  // shieldCheck
  static const IconData shield = IconData(0xe40c, fontFamily: _regular);
  // siren
  static const IconData emergency = IconData(0xe9b8, fontFamily: _regular);
  // cloudSlash
  static const IconData offline = IconData(0xe1b6, fontFamily: _regular);
  // tray
  static const IconData emptyInbox = IconData(0xe4aa, fontFamily: _regular);
  static const IconData imageBroken = IconData(0xe7a8, fontFamily: _regular);
  // tag
  static const IconData priceChanged = IconData(0xe478, fontFamily: _regular);
  static const IconData receipt = IconData(0xe3ec, fontFamily: _regular);
  // question
  static const IconData help = IconData(0xe3e8, fontFamily: _regular);
  // headset
  static const IconData support = IconData(0xe584, fontFamily: _regular);
  static const IconData gift = IconData(0xe276, fontFamily: _regular);
  static const IconData wallet = IconData(0xe68a, fontFamily: _regular);
  static const IconData bell = IconData(0xe0ce, fontFamily: _regular);
  static const IconData bellFilled = IconData(0xe0ce, fontFamily: _fill);
  static const IconData sparkle = IconData(0xe6a2, fontFamily: _fill);
  // lightning — « prix immédiat »
  static const IconData instant = IconData(0xe2de, fontFamily: _fill);

  // --- Compte ---
  static const IconData user = IconData(0xe4c2, fontFamily: _regular);
  // userMinus
  static const IconData userOff = IconData(0xe4ce, fontFamily: _regular);
  // deviceMobile
  static const IconData phone = IconData(0xe1e0, fontFamily: _regular);
  // envelopeSimple
  static const IconData mail = IconData(0xe218, fontFamily: _regular);
  // lockSimple
  static const IconData lock = IconData(0xe308, fontFamily: _regular);
  // eye / eyeSlash — afficher ou masquer le mot de passe
  static const IconData eye = IconData(0xe220, fontFamily: _regular);
  static const IconData eyeOff = IconData(0xe224, fontFamily: _regular);
  // pencilSimple
  static const IconData edit = IconData(0xe3b4, fontFamily: _regular);
  // translate
  static const IconData language = IconData(0xe4a2, fontFamily: _regular);

  // --- Pictogrammes de service (graisse bold) ---
  static const IconData serviceDelivery = IconData(0xe390, fontFamily: _bold);
  static const IconData serviceMoving = IconData(0xe4b4, fontFamily: _bold);
  static const IconData serviceShipping = IconData(0xe28c, fontFamily: _bold);
  static const IconData serviceStorage = IconData(0xecd4, fontFamily: _bold);
}
