/// **Écran A4 · Sélection d'adresses** — maquette « Commande — Client /
/// 2. Adresses ».
///
/// **Le seul écran de toute l'app qui affiche une carte** (règle non négociable
/// n°11), avec le **SDK Google Maps** et **sans Map ID** (CLAUDE.md
/// § Cartographie) : l'affichage mobile est alors gratuit et illimité, là où un
/// Map ID ferait basculer sur un quota limité. Les deux usages passent par
/// lui :
/// - le trajet d'une commande (départ + arrivée) ;
/// - l'ajout ou le déplacement d'une adresse favorite (point unique).
///
/// Mise en page de la maquette : carte en haut, repère fixe au centre, feuille
/// blanche en bas avec les adresses, les puces de favoris et les résultats de
/// recherche. Trois façons de placer le point de l'adresse active :
/// - déplacer la carte sous le repère ;
/// - « Ma position » (géolocalisation, permission demandée à l'appui) ;
/// - taper une adresse approximative puis **Rechercher** (pas de suggestion en
///   direct) : le résultat s'affiche sous le repère pour confirmation.
///
/// La carte s'ouvre sur Douala et son centre reste borné au Cameroun : le
/// repère ne peut pas être posé hors du pays.
///
/// Recherche et libellés passent par le backend (`/geocode/search/`,
/// `/geocode/reverse/`, contrat C5) — aucun appel à un géocodeur tiers. La
/// carte **affiche** et ne résout rien : le SDK Google ne sert qu'au rendu et
/// à la sélection visuelle d'un point.
///
/// Aucune distance ni prix n'est calculé ici : les coordonnées partent au
/// serveur (contrat C1). La distance du devis ne s'affiche pas sur cet écran —
/// elle appartient aux écrans de devis et de récapitulatif.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_error_messages.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/models/geo_point.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../services/address_service.dart';
import '../../services/device_locator.dart';
import '../../services/geocode_service.dart';
import '../../state/address_picker_controller.dart';
import '../../widgets/favorite_label_dialog.dart';
import '../../../../core/theme/app_icons.dart';

/// Résultat d'une sélection : [dropoff] est `null` en mode point unique.
typedef PickedAddresses = ({PlacedAddress pickup, PlacedAddress? dropoff});

/// Caméra par défaut : centre de Douala, à l'échelle de la ville (décision
/// produit du 21 septembre 2026, à la place du Cameroun entier).
const _doualaCenter = LatLng(4.0511, 9.7679);
const _cityZoom = 12.5;

/// Emprise du Cameroun : le centre de la carte, donc le repère, ne peut pas en
/// sortir (décision produit du 21 septembre 2026).
///
/// **Exactement les bornes du serveur** (`orders/geocoding/area.py`, T2.9) :
/// sud-ouest 1,65° N 8,49° E, nord-est 13,08° N 16,19° E. Elles étaient plus
/// larges ici jusqu'au 8 octobre 2026 (1,60–13,10 / 8,40–16,25, héritées de
/// l'ancienne `YandexGeocoder.CAMEROON_BBOX`), si bien qu'une bande de
/// quelques kilomètres en bord de zone laissait poser un repère que le devis
/// refusait ensuite en `400 coordinates_outside_service_area` — un cul-de-sac
/// inexplicable pour l'utilisateur. **Ces quatre valeurs doivent suivre le
/// serveur, jamais le devancer** : plus larges, elles rouvrent ce piège ;
/// plus étroites, elles refusent un point que le serveur accepterait.
///
/// Ce n'est pas une frontière — la boîte déborde sur les pays voisins, île de
/// Bioko comprise — mais un garde-fou contre les coordonnées absurdes.
final _cameroonBounds = LatLngBounds(
  southwest: const LatLng(1.65, 8.49),
  northeast: const LatLng(13.08, 16.19),
);

/// Zoom de rue, pour confirmer visuellement un point placé.
const _streetZoom = 17.0;

/// Zoom minimal : en deçà, le pays entier tient à l'écran et le repère ne
/// désigne plus rien d'utile.
const _minZoom = 6.0;

/// Hauteur recouverte par la feuille d'adresses au bas de la carte. Sert de
/// `padding` au `GoogleMap` pour que **le logo Google et le lien légal restent
/// visibles** au-dessus de la feuille — les masquer n'est pas permis.
const _mapBottomInset = 28.0;

class AddressPickerScreen extends StatefulWidget {
  const AddressPickerScreen({
    super.key,
    required this.mode,
    required this.onConfirm,
    this.pickup,
    this.dropoff,
    this.title,
    this.locator = const GeolocatorDeviceLocator(),
  });

  final PickerMode mode;
  final PlacedAddress? pickup;
  final PlacedAddress? dropoff;
  final String? title;

  /// Géolocalisation native du bouton « Ma position », remplaçable en test.
  final DeviceLocator locator;

  /// Appelé sur appui du bouton de validation, adresses complètes.
  final ValueChanged<PickedAddresses> onConfirm;

  @override
  State<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends State<AddressPickerScreen> {
  late final AddressPickerController _controller;
  late final TextEditingController _text;

  /// Disponible seulement après `onMapCreated` : tout déplacement de caméra
  /// demandé avant est ignoré, la carte n'existe pas encore.
  GoogleMapController? _map;

  /// Dernière position connue de la caméra. Le SDK ne la passe pas à
  /// `onCameraIdle`, il faut donc la retenir au fil de `onCameraMove`.
  CameraPosition? _camera;

  /// Une recherche de position est en cours : le bouton s'anime et ignore les
  /// appuis suivants, au lieu d'empiler des demandes.
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _controller = AddressPickerController(
      geocode: context.read<GeocodeService>(),
      addresses: context.read<AddressService>(),
      mode: widget.mode,
      pickup: widget.pickup,
      dropoff: widget.dropoff,
    );
    _text = TextEditingController(text: widget.pickup?.label ?? '');
    _controller.addListener(_syncText);
    _controller.activate(AddressSlot.pickup);
    _controller.loadFavorites();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_syncText)
      ..dispose();
    _text.dispose();
    _map?.dispose();
    super.dispose();
  }

  /// Recopie le texte du contrôleur dans le champ quand il change hors frappe
  /// (libellé proposé, résultat choisi, changement d'adresse active).
  void _syncText() {
    final value = _controller.text;
    if (_text.text != value) {
      _text.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  static LatLng _latLng(GeoPoint p) => LatLng(p.latitude, p.longitude);

  void _moveTo(GeoPoint point, {double zoom = _streetZoom}) {
    _map?.animateCamera(CameraUpdate.newLatLngZoom(_latLng(point), zoom));
  }

  void _onCameraMove(CameraPosition position) => _camera = position;

  /// La carte s'est immobilisée : son centre devient le point de l'adresse
  /// active.
  ///
  /// Le SDK ne distingue pas un geste de l'utilisateur d'un
  /// `animateCamera` demandé par l'app — c'est
  /// `AddressPickerController.onCameraIdle` qui écarte le second, en
  /// comparant la cible qu'il vient lui-même de viser. Et comme cet arrêt
  /// **ne déclenche plus aucun appel réseau** depuis T2.9, un arrêt de trop ne
  /// coûte plus rien.
  void _onCameraIdle() {
    final camera = _camera;
    if (camera == null) return;
    _controller.onCameraIdle(
      GeoPoint(
        latitude: camera.target.latitude,
        longitude: camera.target.longitude,
      ),
    );
  }

  void _activate(AddressSlot slot) {
    final point = _controller.activate(slot);
    if (point != null) _moveTo(point);
  }

  void _pick(GeoPoint point) {
    FocusScope.of(context).unfocus();
    _moveTo(point);
  }

  /// Position de l'appareil, une fois, sur demande (bouton « Ma position »).
  ///
  /// Le bouton s'anime pendant toute la recherche (permission, fix GPS) et
  /// ignore les appuis répétés. **Chaque échec est dit** — avant, ils étaient
  /// avalés en silence et le bouton passait pour cassé. Aucun n'est bloquant :
  /// la carte et la recherche restent ouvertes.
  ///
  /// Une position hors de la zone desservie n'est **pas** retenue : le serveur
  /// la refuserait au devis (`coordinates_outside_service_area`), et la carte,
  /// bornée, ne pourrait de toute façon pas s'y rendre.
  Future<void> _centerOnDevice() async {
    if (_locating) return;
    FocusScope.of(context).unfocus();
    setState(() => _locating = true);
    final result = await widget.locator.locate();
    if (!mounted) return;
    setState(() => _locating = false);

    final l10n = AppLocalizations.of(context)!;
    final point = result.point;
    if (result.status == DeviceLocationStatus.located && point != null) {
      if (!_cameroonBounds.contains(_latLng(point))) {
        _notify(l10n.addressPickerLocationOutside);
        return;
      }
      _moveTo(_controller.placeDevicePosition(point));
      return;
    }
    switch (result.status) {
      case DeviceLocationStatus.serviceDisabled:
        _notify(
          l10n.addressPickerLocationServiceOff,
          actionLabel: l10n.addressPickerLocationEnable,
          onAction: widget.locator.openLocationSettings,
        );
      case DeviceLocationStatus.deniedForever:
        _notify(
          l10n.addressPickerLocationBlocked,
          actionLabel: l10n.commonSettings,
          onAction: widget.locator.openAppSettings,
        );
      case DeviceLocationStatus.denied:
        _notify(l10n.addressPickerLocationDenied);
      case DeviceLocationStatus.located:
      case DeviceLocationStatus.unavailable:
        _notify(l10n.addressPickerLocationUnavailable);
    }
  }

  void _notify(String message, {String? actionLabel, VoidCallback? onAction}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: actionLabel == null || onAction == null
              ? null
              : SnackBarAction(label: actionLabel, onPressed: onAction),
        ),
      );
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    await _controller.search();
  }

  /// Validation du point posé : c'est **ici** que le géocodage inverse part
  /// (arbitrage du 7 octobre 2026), sur un appui, jamais à l'arrêt de la
  /// carte — le géocodeur est partagé par tout le backend.
  Future<void> _resolveLabel() async {
    FocusScope.of(context).unfocus();
    await _controller.resolveActiveLabel();
  }

  Future<void> _saveFavorite() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final label = await showFavoriteLabelDialog(context);
    if (label == null || label.trim().isEmpty) return;
    final ok = await _controller.saveActiveAsFavorite(label);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? l10n.addressPickerFavoriteSaved
              : messageForFailure(l10n, _controller.failure ?? Object()),
        ),
      ),
    );
  }

  void _confirm() {
    final pickup = _controller.pickup;
    if (!_controller.canConfirm || pickup == null) return;
    widget.onConfirm((
      pickup: pickup.withLabel(pickup.label.trim()),
      dropoff: _controller.dropoff?.withLabel(
        _controller.dropoff!.label.trim(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final start = widget.pickup?.point;

    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mapHeight = constraints.maxHeight * .44;
          // Le corps du Scaffold reçoit des contraintes lâches : sans
          // `SizedBox.expand`, le Stack prendrait la hauteur de son seul
          // enfant non positionné (la rangée de boutons) et couperait la
          // carte, le repère et la feuille d'adresses.
          return SizedBox.expand(
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: mapHeight + 24,
                  // L'autre adresse du trajet, déjà placée, est le seul
                  // marqueur de la carte : le repère de l'adresse **active**
                  // est un widget fixe au centre du Stack, pas un marqueur —
                  // c'est la caméra qui le déplace.
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      final other = _controller.active == AddressSlot.pickup
                          ? _controller.dropoff
                          : _controller.pickup;
                      return GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: start == null
                              ? _doualaCenter
                              : _latLng(start),
                          zoom: start == null ? _cityZoom : _streetZoom,
                        ),
                        onMapCreated: (controller) => _map = controller,
                        // **Aucun `cloudMapId`** : un Map ID ferait basculer
                        // l'affichage sur un quota gratuit limité (T2.9).
                        //
                        // On peut voir au-delà de la frontière, mais pas y
                        // poser le repère : le SDK ramène la caméra dans les
                        // bornes, et ce sont celles du serveur.
                        cameraTargetBounds: CameraTargetBounds(_cameroonBounds),
                        minMaxZoomPreference: const MinMaxZoomPreference(
                          _minZoom,
                          null,
                        ),
                        // Laisse le logo Google et le lien légal au-dessus de
                        // la feuille d'adresses : les masquer n'est pas
                        // permis.
                        padding: const EdgeInsets.only(bottom: _mapBottomInset),
                        onCameraMove: _onCameraMove,
                        onCameraIdle: _onCameraIdle,
                        rotateGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        // Notre propre bouton « Ma position » demande la
                        // permission au moment où l'utilisateur appuie
                        // (CLAUDE.md § Géolocalisation) ; le point bleu du SDK
                        // la réclamerait à l'affichage de la carte.
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        markers: {
                          if (_controller.isRoute && other != null)
                            Marker(
                              markerId: const MarkerId('other-address'),
                              position: _latLng(other.point),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                _controller.active == AddressSlot.pickup
                                    ? BitmapDescriptor.hueCyan
                                    : BitmapDescriptor.hueRose,
                              ),
                              // Informatif : c'est l'autre bout du trajet, on
                              // ne le modifie pas depuis ici.
                              consumeTapEvents: true,
                            ),
                        },
                      );
                    },
                  ),
                ),
                // Repère fixe au centre de la carte : le point de la caméra.
                Positioned(
                  top: (mapHeight + 24) / 2 - 40,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) => _CenterPin(
                        color: _controller.active == AddressSlot.pickup
                            ? AppColors.brand
                            : AppColors.accentCyan,
                      ),
                    ),
                  ),
                ),
                // L'attribution du fond de carte est dessinée par le SDK
                // Google lui-même (logo et lien légal, laissés visibles par le
                // `padding` ci-dessus). Celle des **libellés** d'adresse, qui
                // viennent de Nominatim et donc des données OSM, est affichée
                // par la feuille — voir `_Sheet`.
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        _RoundButton(
                          icon: AppIcons.chevronLeft,
                          onTap: () => Navigator.of(context).maybePop(),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                        ),
                        const Spacer(),
                        _LocateButton(
                          busy: _locating,
                          onTap: _centerOnDevice,
                          tooltip: _locating
                              ? l10n.addressPickerLocatingDevice
                              : l10n.addressPickerMyLocation,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  top: mapHeight,
                  child: _Sheet(
                    controller: _controller,
                    text: _text,
                    onActivate: _activate,
                    onSearch: _search,
                    onPick: _pick,
                    onResolveLabel: _resolveLabel,
                    onSaveFavorite: _saveFavorite,
                    onConfirm: _confirm,
                    title: widget.title,
                    locating: _locating,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.controller,
    required this.text,
    required this.onActivate,
    required this.onSearch,
    required this.onPick,
    required this.onResolveLabel,
    required this.onSaveFavorite,
    required this.onConfirm,
    this.title,
    this.locating = false,
  });

  final AddressPickerController controller;
  final TextEditingController text;
  final ValueChanged<AddressSlot> onActivate;
  final VoidCallback onSearch;
  final ValueChanged<GeoPoint> onPick;

  /// Demande le libellé du point actif (`/geocode/reverse/`).
  final VoidCallback onResolveLabel;
  final VoidCallback onSaveFavorite;
  final VoidCallback onConfirm;
  final String? title;

  /// « Ma position » cherche l'appareil : dit aussi dans la feuille, près du
  /// champ, que quelque chose est en cours.
  final bool locating;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x240E0E10),
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final hasResults = controller.results.isNotEmpty;
          final searchFailure = controller.searchFailure;
          final labelFailure = controller.labelFailure;
          final showsGeocodedLabels =
              hasResults ||
              (controller.activeAddress?.label.trim().isNotEmpty ?? false);
          // Bouton à deux temps : un point tout juste posé n'a pas encore de
          // libellé, et c'est son appui qui déclenche le géocodage inverse.
          final resolving = controller.canResolveLabel;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (title != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          title!,
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: AppFontSize.title,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    _SlotField(
                      slot: AddressSlot.pickup,
                      label: l10n.orderPickupLabel,
                      controller: controller,
                      text: text,
                      onActivate: onActivate,
                      onSearch: onSearch,
                      showRail: controller.isRoute,
                    ),
                    if (controller.isRoute)
                      _SlotField(
                        slot: AddressSlot.dropoff,
                        label: l10n.orderDropoffLabel,
                        controller: controller,
                        text: text,
                        onActivate: onActivate,
                        onSearch: onSearch,
                        showRail: true,
                      ),
                    if (locating)
                      _Hint(text: l10n.addressPickerLocatingDevice, busy: true)
                    else if (controller.searching)
                      _Hint(text: l10n.addressPickerLocating, busy: true)
                    else if (searchFailure != null)
                      _Hint(
                        text: messageForFailure(l10n, searchFailure),
                        warning: true,
                      )
                    else if (controller.searchedWithoutResult)
                      _Hint(text: l10n.addressPickerNoResult, warning: true)
                    else if (controller.resolvingLabel)
                      _Hint(text: l10n.addressPickerLocating, busy: true)
                    // Géocodeur en panne ou saturé : réessayable, et distinct
                    // d'un endroit sans adresse connue (règle n°9).
                    else if (labelFailure != null)
                      _Hint(
                        text: messageForFailure(l10n, labelFailure),
                        warning: true,
                      )
                    else if (controller.labelNotFound)
                      _Hint(text: l10n.addressPickerNoLabel, warning: true)
                    else if (controller.canResolveLabel)
                      _Hint(text: l10n.addressPickerPendingLabel)
                    else if (controller.activeAddress == null)
                      _Hint(text: l10n.addressPickerHint),

                    if (!hasResults &&
                        (controller.favoritesAvailable ||
                            controller.activeAddress != null)) ...[
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final favorite in controller.favorites)
                            _Chip(
                              label: favorite.label,
                              onTap: () =>
                                  onPick(controller.pickFavorite(favorite)),
                            ),
                          if (controller.favoritesAvailable &&
                              controller.activeAddress != null &&
                              controller.activeAddress!.label.trim().isNotEmpty)
                            _Chip(
                              label: l10n.addressPickerSaveFavorite,
                              muted: true,
                              busy: controller.savingFavorite,
                              onTap: onSaveFavorite,
                            ),
                        ],
                      ),
                    ],

                    // Attribution exigée par la licence des données OSM : les
                    // libellés affichés ici (résultat de recherche, libellé
                    // proposé pour le repère) viennent de Nominatim. Le fond
                    // de carte, lui, est attribué par le SDK Google.
                    // Affichée dès qu'un libellé est à l'écran — y compris
                    // quand l'utilisateur l'a réécrit par-dessus : une
                    // mention de trop ne coûte rien, une mention manquante
                    // est un manquement de licence.
                    if (showsGeocodedLabels) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.addressLabelsAttribution,
                        style: const TextStyle(
                          fontSize: AppFontSize.micro,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],

                    for (final result in controller.results)
                      InkWell(
                        onTap: () => onPick(controller.pickResult(result)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppColors.brandTint,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  AppIcons.pin,
                                  size: 15,
                                  color: AppColors.brand,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  result.label,
                                  style: const TextStyle(
                                    fontSize: AppFontSize.label,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: PrimaryButton(
                    label: resolving
                        ? l10n.addressPickerResolvePoint
                        : controller.isRoute
                        ? l10n.addressPickerConfirmRoute
                        : l10n.addressPickerConfirmPoint,
                    onPressed: resolving
                        ? onResolveLabel
                        : controller.canConfirm
                        ? onConfirm
                        : null,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Une adresse du trajet : lecture seule si inactive, champ si active.
class _SlotField extends StatelessWidget {
  const _SlotField({
    required this.slot,
    required this.label,
    required this.controller,
    required this.text,
    required this.onActivate,
    required this.onSearch,
    required this.showRail,
  });

  final AddressSlot slot;
  final String label;
  final AddressPickerController controller;
  final TextEditingController text;
  final ValueChanged<AddressSlot> onActivate;
  final VoidCallback onSearch;
  final bool showRail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final active = controller.active == slot;
    final value = slot == AddressSlot.pickup
        ? controller.pickup
        : controller.dropoff;
    final color = slot == AddressSlot.pickup
        ? AppColors.brand
        : AppColors.accentCyan;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showRail)
            Padding(
              padding: const EdgeInsets.only(top: 20, right: 10),
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: color,
                  shape: slot == AddressSlot.pickup
                      ? BoxShape.circle
                      : BoxShape.rectangle,
                  borderRadius: slot == AddressSlot.pickup
                      ? null
                      : BorderRadius.circular(2),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showRail)
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: AppFontSize.micro,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkMuted,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                if (active)
                  TextField(
                    controller: text,
                    maxLength: AddressPickerController.maxLabelLength,
                    onChanged: controller.updateText,
                    onSubmitted: (_) {
                      if (controller.canSearch) onSearch();
                    },
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      isDense: true,
                      hintText: l10n.addressPickerLabelHint,
                      suffixIcon: IconButton(
                        icon: const Icon(AppIcons.search, size: 20),
                        tooltip: l10n.addressPickerSearch,
                        color: color,
                        onPressed: controller.canSearch ? onSearch : null,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 13,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: color, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: color, width: 1.8),
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: () => onActivate(slot),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        (value?.label.trim().isNotEmpty ?? false)
                            ? value!.label
                            : l10n.addressPickerNotPlaced,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: FontWeight.w700,
                          color: value == null
                              ? AppColors.inkDisabled
                              : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text, this.busy = false, this.warning = false});

  final String text;
  final bool busy;
  final bool warning;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Row(
      children: [
        if (busy) ...[
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.8),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: FontWeight.w600,
              color: warning ? AppColors.warning : AppColors.inkMuted,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Avis de repli posé sur la carte quand les tuiles ne chargent pas.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.onTap,
    this.muted = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool muted;
  final bool busy;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF4F0FF),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        child: busy
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.8),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: FontWeight.w700,
                  color: muted ? AppColors.inkMuted : AppColors.ink,
                ),
              ),
      ),
    ),
  );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: const Color(0x330E0E10),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: AppColors.ink),
        ),
      ),
    ),
  );
}

/// Bouton « Ma position ». Pendant la recherche : l'icône laisse place à un
/// anneau qui tourne, un halo pulse autour du bouton, et les appuis sont
/// ignorés — sans ce retour, l'utilisateur rappuie en croyant à un bug.
class _LocateButton extends StatefulWidget {
  const _LocateButton({
    required this.busy,
    required this.onTap,
    required this.tooltip,
  });

  final bool busy;
  final VoidCallback onTap;
  final String tooltip;

  @override
  State<_LocateButton> createState() => _LocateButtonState();
}

class _LocateButtonState extends State<_LocateButton>
    with SingleTickerProviderStateMixin {
  static const double _size = 40;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.busy) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant _LocateButton old) {
    super.didUpdateWidget(old);
    if (widget.busy && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.busy && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final busy = widget.busy;

    return Semantics(
      button: true,
      liveRegion: busy,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Halo : s'élargit et s'efface, en boucle, tant que ça cherche.
              if (busy && !reduceMotion)
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    final t = Curves.easeOut.transform(_pulse.value);
                    return IgnorePointer(
                      child: Container(
                        width: _size * (1 + .8 * t),
                        height: _size * (1 + .8 * t),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.brand.withValues(
                            alpha: .28 * (1 - t),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              AnimatedScale(
                scale: busy ? 1.08 : 1,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: Material(
                  color: busy ? AppColors.brandTint : AppColors.white,
                  shape: const CircleBorder(),
                  elevation: busy ? 5 : 3,
                  shadowColor: const Color(0x330E0E10),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: busy ? null : widget.onTap,
                    child: SizedBox(
                      width: _size,
                      height: _size,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: busy
                            ? const Padding(
                                key: ValueKey('busy'),
                                padding: EdgeInsets.all(11),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.brand,
                                ),
                              )
                            : const Icon(
                                AppIcons.myLocation,
                                key: ValueKey('idle'),
                                size: 20,
                                color: AppColors.ink,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Repère : pastille cerclée de blanc et sa pointe, ancrée sur le centre.
class _CenterPin extends StatelessWidget {
  const _CenterPin({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        Container(width: 3, height: 18, color: color),
      ],
    ),
  );
}

/// L'autre adresse du trajet, déjà placée.
