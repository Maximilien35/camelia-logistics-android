/// Brouillon du parcours de commande — maquettes « Commande — Client » 2 à 7.
///
/// Le backend expose **un seul** endpoint de création (`POST /v1/orders/`,
/// § 6.2.1) : « le front Flutter gère la navigation multi-écrans ; cette vue
/// n'est appelée qu'une fois toutes les données réunies ». Ce contrôleur est
/// cette réunion : il vit le temps du parcours, puis disparaît.
///
/// La validation locale se limite à la **forme** du formulaire (champ vide,
/// longueur maximale du serializer, numéro au format E.164) pour éviter un
/// aller-retour inutile. Toute règle métier — poids admissible, distance
/// maximale, code promo, prix — reste décidée par le serveur, dont les erreurs
/// sont accrochées au champ concerné.
///
/// ## Le prix vient du serveur, avant comme après
///
/// Depuis T5.4, `POST /v1/orders/quote/` accepte les **quatre coordonnées** du
/// trajet et résout la distance lui-même : le client voit donc un prix avant
/// de commander (§ 7.3.3). L'app n'envoie aucun montant et n'en recompose
/// aucun — elle affiche `price_total` tel quel, sans ventilation (règles n°3
/// et n°4).
///
/// Le devis n'applique **pas** le code promo : celui-ci est validé et déduit à
/// la création, où son quota se joue. Le prix facturé peut donc être
/// **inférieur** au devis, jamais supérieur — c'est dit à l'écran.
///
/// ## Ce que le serveur exige, par service
///
/// | Service | Devis | Création |
/// |---|---|---|
/// | `delivery` | `vehicle_code` | 1 à 3 photos + poids ; véhicule facultatif (auto-sélectionné sur le poids) |
/// | `moving` | `housing_type` | `housing_type` **et** `vehicle_code` |
/// | `shipping` / `storage` | aucun devis | `package_description` |
library;

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../shared/models/geo_point.dart';
import '../../shared/models/order.dart';
import '../../shared/models/phone_number.dart';
import '../models/pricing_catalogue.dart';
import '../models/quote.dart';
import '../services/catalogue_service.dart';
import '../services/order_service.dart';

/// Nature du colis — puces « Type de colis » de la maquette.
///
/// Le backend n'a **pas** de champ dédié : la nature est portée en tête de
/// `package_description`, le texte libre que le chauffeur lit. Aucune règle
/// tarifaire n'en dépend côté serveur, donc aucune n'en dépend ici.
enum ParcelKind { document, standard, fragile, bulky }

/// Erreurs de formulaire, par champ. Les valeurs sont des codes internes que
/// l'écran traduit ; les messages du serveur, eux, arrivent déjà rédigés.
enum DraftError {
  required,
  tooLong,
  invalidPhone,
  photoRequired,
  tooManyPhotos,
  weightRequired,
  notPlaced,
}

/// Étapes du parcours, dans l'ordre de la maquette.
enum DraftStep { addresses, details, options, review }

class OrderDraft extends ChangeNotifier {
  OrderDraft({
    required OrderService service,
    required CatalogueService catalogue,
    required this.serviceType,
  }) : _service = service,
       _catalogue = catalogue;

  final OrderService _service;
  final CatalogueService _catalogue;
  final ServiceType serviceType;

  // Longueurs maximales d'`OrderCreateSerializer`.
  static const int maxAddressLength = 500;
  static const int maxRecipientNameLength = 150;
  static const int maxDescriptionLength = 2000;
  static const int maxCodeLength = 32;

  /// Bornes du curseur de poids de la maquette (« 0 kg · 50 kg »). Ce n'est pas
  /// un plafond métier : un poids refusé par le serveur remonte en
  /// `no_vehicle_for_declared_weight`.
  static const double minWeightKg = 0.5;
  static const double maxWeightKg = 50;

  /// Adresses placées sur la carte (écran A4) : libellé **et** coordonnées.
  PlacedAddress? pickup;
  PlacedAddress? dropoff;
  String recipientName = '';
  String recipientPhone = '';

  /// De 1 à [OrderRequest.maxPhotos] photos en livraison (contrat C2).
  List<ApiFileField> packagePhotos = const [];
  double weightKg = 1;
  ParcelKind parcelKind = ParcelKind.standard;
  String instructions = '';
  String promoCode = '';

  /// Codes choisis dans le **catalogue du serveur** (`GET /v1/vehicle-types/`)
  /// — jamais des valeurs écrites en dur ici.
  String? vehicleCode;
  String? housingType;
  String? handlingType;

  /// Étages du déménagement (§ 6.6.2 « Étages »), `0` = rez-de-chaussée.
  /// Saisis même sans manutention : le chauffeur doit les connaître, même
  /// quand le serveur ne les facture pas.
  int pickupFloor = 0;
  int dropoffFloor = 0;

  bool _submitting = false;
  Object? _failure;
  Map<String, String> _serverFieldErrors = const {};

  PricingCatalogue? _catalogueData;
  bool _loadingCatalogue = false;
  Object? _catalogueFailure;

  Quote? _quote;
  bool _quoting = false;
  Object? _quoteFailure;

  bool get submitting => _submitting;

  // --- Catalogue et devis --------------------------------------------------

  /// Véhicules, types de logement et types de manutention, tels que le serveur
  /// les rend. `null` tant que la première lecture n'a pas abouti.
  PricingCatalogue? get catalogue => _catalogueData;
  bool get loadingCatalogue => _loadingCatalogue;
  Object? get catalogueFailure => _catalogueFailure;

  /// Devis renvoyé par le serveur, ou `null` s'il n'a pas encore été demandé.
  Quote? get quote => _quote;
  bool get quoting => _quoting;
  Object? get quoteFailure => _quoteFailure;

  /// Les services à devis manuel (`shipping`, `storage`) n'ont pas de prix
  /// calculable : aucune route de devis ne les accepte.
  bool get needsVehicleStep =>
      serviceType == ServiceType.delivery || serviceType == ServiceType.moving;

  bool get needsHousingType => serviceType == ServiceType.moving;

  /// Véhicules proposables pour ce service, d'après le catalogue seul.
  List<VehicleTypeOption> get vehicleOptions {
    final data = _catalogueData;
    if (data == null) return const [];
    if (serviceType == ServiceType.moving) {
      final housing = housingType;
      return housing == null ? const [] : data.vehiclesForHousing(housing);
    }
    return data.deliveryVehicles;
  }

  VehicleTypeOption? get selectedVehicle => _catalogueData?.byCode(vehicleCode);

  /// Le poids saisi dépasse ce qu'un véhicule de livraison peut porter.
  ///
  /// Le serveur refuserait la commande en
  /// `vehicle_type_not_available_for_delivery` (§ 2.6) : on le dit pendant que
  /// l'utilisateur saisit encore, plutôt que de le laisser buter dessus. Le
  /// seuil vient du catalogue, il n'est pas écrit ici.
  bool get weightExceedsDelivery {
    if (serviceType != ServiceType.delivery) return false;
    final ceiling = _catalogueData?.deliveryWeightCeilingKg;
    return ceiling != null && weightKg > ceiling;
  }

  /// `GET /v1/vehicle-types/` — une fois par parcours, pas à chaque écran.
  Future<void> loadCatalogue() async {
    if (_loadingCatalogue || _catalogueData != null) return;
    _loadingCatalogue = true;
    _catalogueFailure = null;
    notifyListeners();
    try {
      final data = await _catalogue.fetch();
      _catalogueData = data;
      // Le serveur applique `none` par défaut : on aligne l'écran dessus
      // plutôt que de laisser un choix vide — explicitement, sans dépendre de
      // l'ordre du catalogue.
      handlingType ??= data.handlingTypes.isEmpty
          ? null
          : data.handlingTypes
                .firstWhere(
                  (c) => c.code == handlingNone,
                  orElse: () => data.handlingTypes.first,
                )
                .code;
    } on Object catch (e) {
      _catalogueFailure = e;
    } finally {
      _loadingCatalogue = false;
      notifyListeners();
    }
  }

  void setVehicle(String? code) {
    vehicleCode = code;
    _quote = null;
    _serverFieldErrors = Map.of(_serverFieldErrors)..remove('vehicle_code');
    notifyListeners();
  }

  void setHousingType(String? code) {
    housingType = code;
    // Un véhicule choisi pour un autre logement peut ne plus être autorisé :
    // on oublie le choix plutôt que d'envoyer un couple que le serveur
    // refuserait en `vehicle_not_allowed_for_housing_type`.
    final stillAllowed =
        _catalogueData?.byCode(vehicleCode)?.allowsHousing(code ?? '') ?? false;
    if (vehicleCode != null && !stillAllowed) vehicleCode = null;
    _quote = null;
    notifyListeners();
  }

  void setHandlingType(String? code) {
    handlingType = code;
    _quote = null;
    notifyListeners();
  }

  /// Code serveur de « manutention non demandée » (`HandlingFee.HandlingType`).
  static const String handlingNone = 'none';

  void setPickupFloor(int floor) {
    final next = floor.clamp(0, OrderRequest.maxFloor);
    if (next == pickupFloor) return;
    pickupFloor = next;
    _quote = null;
    _serverFieldErrors = Map.of(_serverFieldErrors)..remove('pickup_floor');
    notifyListeners();
  }

  void setDropoffFloor(int floor) {
    final next = floor.clamp(0, OrderRequest.maxFloor);
    if (next == dropoffFloor) return;
    dropoffFloor = next;
    _quote = null;
    _serverFieldErrors = Map.of(_serverFieldErrors)..remove('dropoff_floor');
    notifyListeners();
  }

  /// `POST /v1/orders/quote/` — mode **coordonnées**.
  ///
  /// Silencieusement ignoré tant que le serveur n'a pas de quoi répondre : les
  /// quatre coordonnées vont ensemble (en envoyer trois est un `400`), une
  /// livraison exige un véhicule et un déménagement un type de logement.
  ///
  /// Au-delà de 50 km le serveur répond `distance_exceeds_maximum`, le même
  /// code qu'à la création : l'impossibilité s'affiche donc ici, pendant que
  /// l'utilisateur peut encore changer d'adresse.
  Future<void> fetchQuote() async {
    final from = pickup;
    final to = dropoff;
    if (_quoting || from == null || to == null || !needsVehicleStep) return;
    if (serviceType == ServiceType.delivery && vehicleCode == null) return;
    if (serviceType == ServiceType.moving && housingType == null) return;

    _quoting = true;
    _quoteFailure = null;
    notifyListeners();
    try {
      _quote = await _service.quote(
        serviceType: serviceType,
        pickup: from.point,
        dropoff: to.point,
        vehicleCode: vehicleCode,
        housingType: housingType,
        handlingType: handlingType,
        pickupFloor: needsHousingType ? pickupFloor : null,
        dropoffFloor: needsHousingType ? dropoffFloor : null,
      );
    } on Object catch (e) {
      _quote = null;
      _quoteFailure = e;
    } finally {
      _quoting = false;
      notifyListeners();
    }
  }

  /// Erreur globale de la dernière soumission (non rattachée à un champ).
  Object? get failure => _failure;

  bool get needsPhotoAndWeight => serviceType == ServiceType.delivery;

  /// Erreur renvoyée par le serveur pour un champ du serializer.
  String? serverError(String field) => _serverFieldErrors[field];

  void touch() => notifyListeners();

  bool get canAddPhoto => packagePhotos.length < OrderRequest.maxPhotos;

  void addPhoto(ApiFileField photo) {
    if (!canAddPhoto) return;
    packagePhotos = [...packagePhotos, photo];
    _serverFieldErrors = Map.of(_serverFieldErrors)..remove('package_photos');
    notifyListeners();
  }

  void removePhotoAt(int index) {
    if (index < 0 || index >= packagePhotos.length) return;
    packagePhotos = [...packagePhotos]..removeAt(index);
    notifyListeners();
  }

  void setRoute({
    required PlacedAddress pickup,
    required PlacedAddress dropoff,
  }) {
    this.pickup = pickup;
    this.dropoff = dropoff;
    _serverFieldErrors = Map.of(_serverFieldErrors)
      ..removeWhere(
        (key, _) => key.startsWith('pickup_') || key.startsWith('dropoff_'),
      );
    notifyListeners();
  }

  void setWeight(double value) {
    weightKg = value;
    notifyListeners();
  }

  void setParcelKind(ParcelKind kind) {
    parcelKind = kind;
    notifyListeners();
  }

  /// Préremplit le destinataire avec le titulaire du compte.
  void useAccountHolderAsRecipient({
    required String fullName,
    required String phone,
  }) {
    recipientName = fullName;
    recipientPhone = phone;
    notifyListeners();
  }

  // --- Validation de forme ------------------------------------------------

  /// Voir [PhoneNumber.normalize].
  static String normalizePhone(String input) => PhoneNumber.normalize(input);

  /// « 4.5 » ou « 8 », sans zéro superflu.
  static String formatWeight(double kg) =>
      kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);

  /// Voir [PhoneNumber.isE164].
  static bool isE164(String value) => PhoneNumber.isE164(value);

  Map<String, DraftError> errorsFor(DraftStep step) {
    final errors = <String, DraftError>{};
    void text(String field, String value, int max) {
      if (value.trim().isEmpty) {
        errors[field] = DraftError.required;
      } else if (value.trim().length > max) {
        errors[field] = DraftError.tooLong;
      }
    }

    switch (step) {
      case DraftStep.addresses:
        void placed(String field, PlacedAddress? address) {
          if (address == null || !address.point.isValid) {
            errors[field] = DraftError.notPlaced;
          } else {
            text(field, address.label, maxAddressLength);
          }
        }
        placed('pickup_address', pickup);
        placed('dropoff_address', dropoff);
      case DraftStep.details:
        text('recipient_name', recipientName, maxRecipientNameLength);
        if (recipientPhone.trim().isEmpty) {
          errors['recipient_phone'] = DraftError.required;
        } else if (!isE164(normalizePhone(recipientPhone))) {
          errors['recipient_phone'] = DraftError.invalidPhone;
        }
        if (needsPhotoAndWeight) {
          if (packagePhotos.isEmpty) {
            errors['package_photos'] = DraftError.photoRequired;
          } else if (packagePhotos.length > OrderRequest.maxPhotos) {
            errors['package_photos'] = DraftError.tooManyPhotos;
          }
          if (weightKg <= 0) {
            errors['package_weight_kg'] = DraftError.weightRequired;
          }
        }
        if (serviceType.isManualQuote) {
          text('package_description', instructions, maxDescriptionLength);
        } else if (instructions.length > maxDescriptionLength) {
          errors['package_description'] = DraftError.tooLong;
        }
      case DraftStep.options:
        // Ce que le serveur exige, et rien de plus : un déménagement veut un
        // logement **et** un véhicule, une livraison veut un véhicule pour
        // obtenir son devis (le serveur l'auto-sélectionnerait à la création,
        // mais pas au devis).
        if (needsHousingType && (housingType ?? '').isEmpty) {
          errors['housing_type'] = DraftError.required;
        }
        if (needsVehicleStep && (vehicleCode ?? '').isEmpty) {
          errors['vehicle_code'] = DraftError.required;
        }
      case DraftStep.review:
        if (promoCode.trim().length > maxCodeLength) {
          errors['promo_code'] = DraftError.tooLong;
        }
    }
    return errors;
  }

  /// Texte envoyé dans `package_description`.
  ///
  /// [kindLabel] est le libellé localisé de la nature du colis : le chauffeur
  /// lit ce texte tel quel.
  String describe(String Function(ParcelKind) kindLabel) {
    final note = instructions.trim();
    if (serviceType != ServiceType.delivery) return note;
    final kind = kindLabel(parcelKind);
    return note.isEmpty ? kind : '$kind · $note';
  }

  // --- Soumission ---------------------------------------------------------

  /// Crée la commande. Renvoie `null` en cas d'échec : [failure] et
  /// [serverError] disent pourquoi.
  Future<Order?> submit({
    required String Function(ParcelKind) kindLabel,
  }) async {
    if (_submitting || pickup == null || dropoff == null) return null;
    _submitting = true;
    _failure = null;
    _serverFieldErrors = const {};
    notifyListeners();
    try {
      return await _service.createOrder(
        OrderRequest(
          serviceType: serviceType,
          pickup: pickup!,
          dropoff: dropoff!,
          recipientName: recipientName,
          recipientPhone: normalizePhone(recipientPhone),
          packagePhotos: needsPhotoAndWeight ? packagePhotos : const [],
          packageWeightKg: needsPhotoAndWeight ? weightKg : null,
          packageDescription: describe(kindLabel),
          vehicleCode: needsVehicleStep ? vehicleCode : null,
          housingType: needsHousingType ? housingType : null,
          handlingType: needsHousingType ? handlingType : null,
          pickupFloor: needsHousingType ? pickupFloor : null,
          dropoffFloor: needsHousingType ? dropoffFloor : null,
          promoCode: promoCode,
        ),
      );
    } on ApiException catch (e) {
      _serverFieldErrors = {
        for (final field in e.details.keys)
          if (e.fieldError(field) != null) field: e.fieldError(field)!,
      };
      _failure = e;
      return null;
    } on NetworkException catch (e) {
      _failure = e;
      return null;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  /// Étape à rouvrir pour corriger une erreur renvoyée par le serveur.
  DraftStep? stepForServerErrors() {
    const addressFields = {
      'pickup_address',
      'pickup_latitude',
      'pickup_longitude',
      'dropoff_address',
      'dropoff_latitude',
      'dropoff_longitude',
    };
    const detailFields = {
      'recipient_name',
      'recipient_phone',
      'package_photos',
      'package_weight_kg',
      'package_description',
    };
    const optionFields = {
      'vehicle_code',
      'housing_type',
      'handling_type',
      'pickup_floor',
      'dropoff_floor',
    };
    final fields = _serverFieldErrors.keys;
    if (fields.any(addressFields.contains)) return DraftStep.addresses;
    if (fields.any(detailFields.contains)) return DraftStep.details;
    if (fields.any(optionFields.contains)) return DraftStep.options;
    return null;
  }
}
