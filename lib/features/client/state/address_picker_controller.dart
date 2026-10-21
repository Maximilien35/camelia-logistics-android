/// État de l'écran de sélection d'adresses (A4) — le seul écran à carte.
///
/// Deux usages du même écran :
/// - **trajet** (commande) : un point de départ et un point d'arrivée ;
/// - **point unique** (adresse favorite).
///
/// Chaque adresse est un [PlacedAddress] : coordonnées exactes **et** libellé.
/// Le point vient toujours d'une action sur la carte (déplacement, résultat de
/// recherche, favori, position de l'appareil) — jamais d'un texte seul. Le
/// libellé est proposé par le backend (`POST /geocode/reverse/`) et reste
/// modifiable : le chauffeur a besoin d'un repère lisible.
///
/// Pas de suggestion en direct à chaque frappe (CLAUDE.md § Cartographie) : la
/// recherche part sur une action explicite de l'utilisateur.
///
/// **Révision T2.9 (arbitrage du 7 octobre 2026).** Le géocodage inverse est
/// appelé **à la validation du point** ([resolveActiveLabel]), plus à chaque
/// arrêt de la carte : le fournisseur (Nominatim) est borné à une requête par
/// seconde **pour tout le backend**, et le quota de l'appelant est de 20 par
/// minute pour les deux routes réunies. Un glisser de carte un peu nerveux
/// consommait à lui seul ce quota et privait les autres utilisateurs du
/// limiteur global. [onCameraIdle] ne fait donc plus aucun appel réseau.
library;

import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../shared/models/geo_point.dart';
import '../models/geocode_result.dart';
import '../models/saved_address.dart';
import '../services/address_service.dart';
import '../services/geocode_service.dart';

enum AddressSlot { pickup, dropoff }

enum PickerMode { route, singlePoint }

class AddressPickerController extends ChangeNotifier {
  AddressPickerController({
    required GeocodeService geocode,
    required AddressService addresses,
    required this.mode,
    PlacedAddress? pickup,
    PlacedAddress? dropoff,
  }) : _geocode = geocode,
       _addresses = addresses,
       _pickup = pickup,
       _dropoff = dropoff;

  final GeocodeService _geocode;
  final AddressService _addresses;
  final PickerMode mode;

  /// Longueur maximale du libellé (`pickup_address`, `address` : ≤ 500).
  static const int maxLabelLength = 500;

  PlacedAddress? _pickup;
  PlacedAddress? _dropoff;
  AddressSlot _active = AddressSlot.pickup;

  bool _resolvingLabel = false;
  bool _labelNotFound = false;
  Object? _labelFailure;
  int _labelRequest = 0;

  /// Point vers lequel l'app vient de déplacer la caméra : l'arrêt de caméra
  /// qui suit ne doit pas écraser le libellé choisi par l'utilisateur.
  GeoPoint? _programmaticTarget;

  /// Texte du champ de l'adresse active : libellé **et** requête de recherche.
  String _text = '';
  List<GeocodeResult> _results = const [];
  bool _searching = false;
  bool _searchedWithoutResult = false;
  Object? _searchFailure;
  int _searchRequest = 0;

  List<SavedAddress> _favorites = const [];
  bool _favoritesAvailable = false;
  bool _savingFavorite = false;
  Object? _failure;

  bool _disposed = false;

  PlacedAddress? get pickup => _pickup;
  PlacedAddress? get dropoff => _dropoff;
  AddressSlot get active => _active;
  PlacedAddress? get activeAddress => _slot(_active);

  bool get resolvingLabel => _resolvingLabel;

  /// Le serveur n'a proposé aucun libellé : l'utilisateur doit en saisir un.
  ///
  /// `label: null` est une réponse `200`, **jamais une erreur** : le point
  /// reste parfaitement valide, c'est son libellé qui manque. Distinct de
  /// [labelFailure], qui signale un géocodeur en panne — là où celui-ci
  /// signale un endroit sans adresse connue.
  bool get labelNotFound => _labelNotFound;

  /// Échec de la dernière recherche de libellé (`geocode_busy`,
  /// `geocoding_unavailable`, panne réseau) — `null` si tout va bien.
  ///
  /// Les trois cas sont réessayables : [canResolveLabel] reste donc `true`, et
  /// l'écran garde son bouton de validation actif.
  Object? get labelFailure => _labelFailure;

  /// Le point actif attend son libellé : c'est ce qui active le bouton
  /// « Valider ce point » de l'écran A4.
  ///
  /// `false` quand l'utilisateur a saisi son propre repère, quand le libellé
  /// vient déjà du serveur (résultat de recherche, favori), ou quand le
  /// serveur a répondu qu'il n'en connaissait aucun ([labelNotFound]) — dans
  /// ce dernier cas rappeler la route rendrait la même réponse.
  bool get canResolveLabel {
    final address = activeAddress;
    return !_resolvingLabel &&
        !_labelNotFound &&
        address != null &&
        address.point.isValid &&
        address.label.trim().isEmpty;
  }

  /// Texte du champ de l'adresse active.
  String get text => _text;

  List<GeocodeResult> get results => _results;
  bool get searching => _searching;

  /// La dernière recherche a abouti sans aucun lieu.
  bool get searchedWithoutResult => _searchedWithoutResult;

  /// Échec de la dernière recherche (réseau, `geocoding_unavailable`…).
  Object? get searchFailure => _searchFailure;

  /// Le bouton « Rechercher » n'est utile qu'avec une requête exploitable.
  bool get canSearch =>
      !_searching && _text.trim().length >= GeocodeService.minQueryLength;

  List<SavedAddress> get favorites => _favorites;

  /// `false` tant que `GET /me/addresses/` ne répond pas (contrat C4 non
  /// livré) : les puces de favoris sont alors simplement masquées.
  bool get favoritesAvailable => _favoritesAvailable;
  bool get savingFavorite => _savingFavorite;
  Object? get failure => _failure;

  bool get isRoute => mode == PickerMode.route;

  bool _isComplete(PlacedAddress? a) =>
      a != null &&
      a.point.isValid &&
      a.label.trim().isNotEmpty &&
      a.label.trim().length <= maxLabelLength;

  bool get canConfirm =>
      _isComplete(_pickup) && (!isRoute || _isComplete(_dropoff));

  PlacedAddress? _slot(AddressSlot slot) =>
      slot == AddressSlot.pickup ? _pickup : _dropoff;

  void _setSlot(AddressSlot slot, PlacedAddress value) {
    if (slot == AddressSlot.pickup) {
      _pickup = value;
    } else {
      _dropoff = value;
    }
  }

  // --- Favoris -------------------------------------------------------------

  Future<void> loadFavorites() async {
    try {
      _favorites = await _addresses.list();
      _favoritesAvailable = true;
    } on ApiException {
      _favoritesAvailable = false;
    } on NetworkException {
      _favoritesAvailable = false;
    }
    notifyListeners();
  }

  /// Enregistre l'adresse active comme favorite. Renvoie `true` si le serveur
  /// l'a acceptée.
  Future<bool> saveActiveAsFavorite(String label) async {
    final address = activeAddress;
    if (address == null || !_isComplete(address) || label.trim().isEmpty) {
      return false;
    }
    _savingFavorite = true;
    _failure = null;
    notifyListeners();
    try {
      final saved = await _addresses.create(
        label: label,
        address: address.label,
        point: address.point,
      );
      _favorites = [saved, ..._favorites];
      _favoritesAvailable = true;
      return true;
    } on ApiException catch (e) {
      _failure = e;
      return false;
    } on NetworkException catch (e) {
      _failure = e;
      return false;
    } finally {
      _savingFavorite = false;
      notifyListeners();
    }
  }

  // --- Sélection -------------------------------------------------------------

  /// Rend [slot] actif. Renvoie le point sur lequel recentrer la carte, s'il
  /// est déjà placé.
  GeoPoint? activate(AddressSlot slot) {
    if (!isRoute && slot == AddressSlot.dropoff) return null;
    _active = slot;
    _clearSearch();
    _text = activeAddress?.label ?? '';
    _labelNotFound = false;
    _labelFailure = null;
    notifyListeners();
    final point = _slot(slot)?.point;
    if (point != null) _programmaticTarget = point;
    return point;
  }

  /// La carte s'est immobilisée sur [target] après un geste : c'est le nouveau
  /// point de l'adresse active.
  ///
  /// **Aucun appel réseau** depuis T2.9 : retenir un point est gratuit, en
  /// obtenir le libellé ne l'est pas. Le libellé précédent est effacé — il
  /// décrivait un autre endroit — et [resolveActiveLabel] prendra la suite
  /// quand l'utilisateur validera ce point.
  void onCameraIdle(GeoPoint target) {
    if (_programmaticTarget != null && _near(_programmaticTarget!, target)) {
      _programmaticTarget = null;
      return;
    }
    _programmaticTarget = null;
    final slot = _active;
    final previous = _slot(slot);
    // Zoom sans déplacement : le point et son libellé restent valables.
    if (previous != null && previous.point == target) return;
    // Une recherche de libellé en cours portait sur le point d'avant : sa
    // réponse ne doit plus être appliquée.
    _labelRequest++;
    _resolvingLabel = false;
    _labelNotFound = false;
    _labelFailure = null;
    _setSlot(slot, PlacedAddress(label: '', point: target));
    if (slot == _active) _text = '';
    _clearSearch();
    notifyListeners();
  }

  /// Validation du point actif : demande son libellé au serveur
  /// (`POST /geocode/reverse/`).
  ///
  /// **Le seul endroit de l'app qui déclenche un géocodage inverse**, et
  /// uniquement sur un geste explicite (§ 6.2.1bis, arbitrage du 7 octobre
  /// 2026). Trois issues, toutes sans blocage :
  /// - un libellé : il remplit le champ et reste modifiable à la main ;
  /// - `label: null` ([labelNotFound]) : l'endroit n'a pas d'adresse connue,
  ///   l'utilisateur saisit son propre repère ;
  /// - une panne ([labelFailure]) : réessayable, et la saisie manuelle reste
  ///   ouverte de toute façon.
  ///
  /// Dans les trois cas le **point** est déjà retenu : seul son libellé est en
  /// jeu, jamais la possibilité de commander.
  Future<void> resolveActiveLabel() async {
    if (!canResolveLabel) return;
    final slot = _active;
    final target = _slot(slot)!.point;
    _resolvingLabel = true;
    _labelNotFound = false;
    _labelFailure = null;
    notifyListeners();

    final request = ++_labelRequest;
    String? label;
    Object? failure;
    try {
      label = await _geocode.reverse(target);
    } on ApiException catch (e) {
      failure = e;
    } on NetworkException catch (e) {
      failure = e;
    }
    // Un autre point a été choisi entre-temps : réponse périmée.
    if (request != _labelRequest) return;
    _resolvingLabel = false;
    final current = _slot(slot);
    // Le point a changé sous nos pieds : on n'y recopie pas le libellé d'un
    // autre endroit.
    if (current == null || current.point != target) {
      notifyListeners();
      return;
    }
    if (failure != null) {
      _labelFailure = failure;
    } else if (label != null) {
      _setSlot(slot, current.withLabel(label));
      if (slot == _active) _text = label;
    } else {
      _labelNotFound = true;
    }
    notifyListeners();
  }

  /// Saisie dans le champ de l'adresse active : modifie le libellé si le
  /// point est placé, et prépare la recherche — sans la lancer.
  void updateText(String text) {
    _text = text;
    final current = activeAddress;
    if (current != null) _setSlot(_active, current.withLabel(text));
    _labelNotFound = false;
    _labelFailure = null;
    _results = const [];
    _searchedWithoutResult = false;
    _searchFailure = null;
    notifyListeners();
  }

  /// Recherche explicite (bouton ou touche « Rechercher » du clavier).
  Future<void> search() async {
    final query = _text.trim();
    if (query.length < GeocodeService.minQueryLength || _searching) return;
    final request = ++_searchRequest;
    _searching = true;
    _results = const [];
    _searchedWithoutResult = false;
    _searchFailure = null;
    notifyListeners();
    try {
      final found = await _geocode.search(
        query.length > GeocodeService.maxQueryLength
            ? query.substring(0, GeocodeService.maxQueryLength)
            : query,
      );
      if (request != _searchRequest) return;
      _results = found;
      _searchedWithoutResult = found.isEmpty;
    } on ApiException catch (e) {
      if (request != _searchRequest) return;
      _searchFailure = e;
    } on NetworkException catch (e) {
      if (request != _searchRequest) return;
      _searchFailure = e;
    }
    _searching = false;
    notifyListeners();
  }

  /// Choix d'un résultat de recherche. Renvoie le point sur lequel centrer la
  /// carte pour confirmation visuelle.
  GeoPoint pickResult(GeocodeResult result) => _place(result.placed);

  GeoPoint pickFavorite(SavedAddress favorite) => _place(favorite.placed);

  /// Position de l'appareil (« Ma position ») : devient le point de l'adresse
  /// active, **sans libellé** — il s'obtient à la validation, comme pour un
  /// point posé à la main (arbitrage du 7 octobre 2026).
  ///
  /// Passe par [_place] pour que l'arrêt de la carte à la fin de l'animation
  /// soit reconnu comme le nôtre et n'écrase pas le point.
  GeoPoint placeDevicePosition(GeoPoint point) =>
      _place(PlacedAddress(label: '', point: point));

  /// Le résultat reste sur l'adresse active, affiché sous le repère : si le
  /// point est faux, l'utilisateur déplace la carte au lieu de retaper du texte
  /// (CLAUDE.md § Flux de sélection d'adresse, étape 4).
  GeoPoint _place(PlacedAddress address) {
    _labelRequest++; // invalide une recherche de libellé en cours
    _resolvingLabel = false;
    _labelNotFound = false;
    _labelFailure = null;
    _setSlot(_active, address);
    _clearSearch();
    _programmaticTarget = address.point;
    _text = address.label;
    notifyListeners();
    return address.point;
  }

  void _clearSearch() {
    _searchRequest++; // invalide une recherche en cours
    _searching = false;
    _results = const [];
    _searchedWithoutResult = false;
    _searchFailure = null;
  }

  /// Deux positions de caméra égales au mètre près.
  static bool _near(GeoPoint a, GeoPoint b) =>
      (a.latitude - b.latitude).abs() < 1e-5 &&
      (a.longitude - b.longitude).abs() < 1e-5;

  /// Les appels au serveur peuvent répondre après la fermeture de l'écran :
  /// on se tait alors.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
