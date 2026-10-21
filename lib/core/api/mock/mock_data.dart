/// État et jeu de données du faux backend ([MockBackend]).
///
/// L'état est **cohérent** d'un appel à l'autre : se connecter puis appeler
/// `/me/` renvoie le même compte, créer une commande la rend consultable par
/// `/orders/{id}/`, passer en ligne change ce que renvoie `/driver/status/`.
/// Sans cela les écrans sembleraient marcher tout en cachant des erreurs
/// d'enchaînement.
///
/// Les valeurs des énumérations et les noms de champs sont ceux du backend réel
/// (`docs/backend-contract.md`). Les montants décimaux sortent en **chaîne**,
/// comme les `DecimalField` de DRF.
library;

import 'dart:math' as math;

/// Comptes du livre comptable (`LedgerEntry.AccountType`).
enum MockAccount { driverWallet, ambassadorWallet }

class MockUser {
  MockUser({
    required this.id,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.password,
    required this.role,
    required this.emailVerified,
    this.language = 'fr',
    this.socialProviders = const [],
  });

  final String id;
  final String email;

  // Modifiables par `PATCH /me/` et `/me/phone/` (§ 7.3.8).
  String phone;
  String firstName;
  String lastName;

  /// Vide = mot de passe inutilisable (compte créé par Google ou Apple,
  /// § 6c.2). Modifiable par la réinitialisation et le changement (§ 6c.5-6).
  String password;

  /// Fournisseurs rattachés, parmi `google` et `apple` (§ 6c.7). Une
  /// connexion sociale sur un compte existant y ajoute son fournisseur.
  List<String> socialProviders;

  /// `client`, `driver` ou `admin` — valeurs exactes de `User.Role`.
  final String role;

  bool emailVerified;
  String language;

  /// Forme exacte de `MeSerializer`.
  Map<String, dynamic> toMeJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'first_name': firstName,
    'last_name': lastName,
    'role': role,
    'language': language,
    'email_verified': emailVerified,
    'created_at': '2026-08-14T09:12:00+01:00',
    'has_password': password.isNotEmpty,
    'social_providers': socialProviders,
  };
}

class MockState {
  MockState._();

  factory MockState.seeded() => MockState._()..reset();

  final List<MockUser> _users = [];
  final Map<String, String> _accessToken = {}; // jeton -> id utilisateur
  final Map<String, String> _refreshToken = {};
  final Set<String> _blacklistedRefresh = {};
  final List<Map<String, dynamic>> _orders = [];
  final List<Map<String, dynamic>> _offers = [];
  final List<Map<String, dynamic>> _ledger = [];
  int _counter = 0;

  // --- Contrats proposés C3 / C4 (absents du Django actuel) -----------------

  /// Adresses favorites, par identifiant d'utilisateur.
  final Map<String, List<Map<String, dynamic>>> _addresses = {};

  /// Changement de téléphone en attente de code : utilisateur → numéro visé.
  final Map<String, String> _pendingPhones = {};

  List<Map<String, dynamic>> addressesOf(MockUser user) =>
      List<Map<String, dynamic>>.from(_addresses[user.id] ?? const []);

  Map<String, dynamic> addAddress(
    MockUser user, {
    required String label,
    required String address,
    required double latitude,
    required double longitude,
  }) {
    final item = {
      'id': 'addr-${++_counter}',
      'label': label,
      'address': address,
      'latitude': latitude.toStringAsFixed(6),
      'longitude': longitude.toStringAsFixed(6),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    (_addresses[user.id] ??= []).insert(0, item);
    return item;
  }

  Map<String, dynamic>? findAddress(MockUser user, String id) {
    for (final a in _addresses[user.id] ?? const <Map<String, dynamic>>[]) {
      if (a['id'] == id) return a;
    }
    return null;
  }

  void removeAddress(MockUser user, String id) =>
      _addresses[user.id]?.removeWhere((a) => a['id'] == id);

  void requestPhoneChange(MockUser user, String phone) =>
      _pendingPhones[user.id] = phone;

  String? pendingPhoneFor(MockUser user) => _pendingPhones[user.id];

  void confirmPhoneChange(MockUser user) {
    final phone = _pendingPhones.remove(user.id);
    if (phone != null) user.phone = phone;
  }

  // --- Profil chauffeur ---------------------------------------------------
  String driverStatus = 'approved';
  bool _isOnline = false;
  String? _lastPositionAt;
  final List<Map<String, dynamic>> _documents = [];

  void reset() {
    _users
      ..clear()
      ..addAll([
        MockUser(
          id: 'c1a7e4d0-0000-4000-8000-000000000001',
          email: 'aicha@camelia.test',
          phone: '+237690000001',
          firstName: 'Aïcha',
          lastName: 'Ngo Bell',
          password: 'motdepasse8',
          role: 'client',
          emailVerified: true,
        ),
        MockUser(
          id: 'd2b8f5e1-0000-4000-8000-000000000002',
          email: 'jeanpaul@camelia.test',
          phone: '+237690000002',
          firstName: 'Jean-Paul',
          lastName: 'Mbarga',
          password: 'motdepasse8',
          role: 'driver',
          emailVerified: true,
        ),
        MockUser(
          id: 'a3c9a6f2-0000-4000-8000-000000000003',
          email: 'admin@camelia.test',
          phone: '+237690000003',
          firstName: 'Admin',
          lastName: 'Camelia',
          password: 'motdepasse8',
          role: 'admin',
          emailVerified: true,
        ),
        MockUser(
          id: 'e4dab703-0000-4000-8000-000000000004',
          email: 'nonverifie@camelia.test',
          phone: '+237690000004',
          firstName: 'Compte',
          lastName: 'À vérifier',
          password: 'motdepasse8',
          role: 'client',
          emailVerified: false,
        ),
      ]);

    _accessToken.clear();
    _refreshToken.clear();
    _blacklistedRefresh.clear();
    _orders.clear();
    _offers.clear();
    _addresses.clear();
    _pendingPhones.clear();
    _ledger.clear();
    _documents
      ..clear()
      ..addAll([
        _document('id_card', 'approved'),
        _document('driving_licence', 'approved'),
        _document('vehicle_registration', 'pending'),
      ]);
    _counter = 0;
    driverStatus = 'approved';
    _isOnline = false;
    _lastPositionAt = null;

    _seedLedger();
    _seedDriverHistory();
    _seedOffers();
  }

  // --- Utilisateurs et jetons ---------------------------------------------

  MockUser? findByEmail(String email) {
    for (final u in _users) {
      if (u.email == email.toLowerCase().trim()) return u;
    }
    return null;
  }

  MockUser? findByPhone(String phone) {
    for (final u in _users) {
      if (u.phone == phone) return u;
    }
    return null;
  }

  void addUser(MockUser user) => _users.add(user);

  void deleteUser(MockUser user) {
    _users.remove(user);
    revokeTokens(user);
  }

  void markVerified(MockUser user) => user.emailVerified = true;

  void setLanguage(MockUser user, String language) => user.language = language;

  /// Émet une paire de jetons. [rotateFrom] met l'ancien `refresh` en liste
  /// noire, comme `ROTATE_REFRESH_TOKENS` + `BLACKLIST_AFTER_ROTATION`.
  Map<String, dynamic> issueTokens(MockUser user, {String? rotateFrom}) {
    if (rotateFrom != null) {
      _refreshToken.remove(rotateFrom);
      _blacklistedRefresh.add(rotateFrom);
    }
    final n = ++_counter;
    final access = 'mock-access-${user.id}-$n';
    final refresh = 'mock-refresh-${user.id}-$n';
    _accessToken[access] = user.id;
    _refreshToken[refresh] = user.id;
    return {'access': access, 'refresh': refresh};
  }

  /// Utilisateur derrière un en-tête `Authorization: Bearer <access>`.
  MockUser? userForAccessToken(String? authorization) {
    if (authorization == null || !authorization.startsWith('Bearer ')) {
      return null;
    }
    final id = _accessToken[authorization.substring(7)];
    if (id == null) return null;
    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }

  MockUser? userForRefreshToken(String refresh) {
    if (_blacklistedRefresh.contains(refresh)) return null;
    final id = _refreshToken[refresh];
    if (id == null) return null;
    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }

  void revokeTokens(MockUser user) {
    _accessToken.removeWhere((_, id) => id == user.id);
    _refreshToken.removeWhere((token, id) {
      if (id == user.id) _blacklistedRefresh.add(token);
      return id == user.id;
    });
  }

  // --- Chauffeur ----------------------------------------------------------

  Map<String, dynamic> _document(String type, String status) => {
    'id': 'doc-$type',
    'document_type': type,
    'status': status,
    'rejection_reason': status == 'rejected' ? 'Document illisible.' : null,
    'reviewed_at': status == 'pending' ? null : '2026-08-20T11:00:00+01:00',
    'created_at': '2026-08-19T08:30:00+01:00',
    'updated_at': '2026-08-20T11:00:00+01:00',
  };

  /// Forme exacte de `DriverStatusSerializer`. Pas de solde ici : il vit sur
  /// `/driver/wallet/`.
  Map<String, dynamic> driverStatusJson() => {
    'status': driverStatus,
    'is_online': _isOnline,
    'vehicle_type': 'fourgonnette',
    'vehicle_plate': 'LT 4821 AB',
    'rating_average': '4.90',
    'rating_count': 312,
    'last_position_at': _lastPositionAt,
    'documents': List<Map<String, dynamic>>.from(_documents),
  };

  void setOnline(bool value) => _isOnline = value;

  void touchPosition() =>
      _lastPositionAt = DateTime.now().toUtc().toIso8601String();

  Map<String, dynamic> submitDocument(String type) {
    _documents.removeWhere((d) => d['document_type'] == type);
    final doc = _document(type, 'pending');
    _documents.add(doc);
    return doc;
  }

  // --- Offres de course ---------------------------------------------------

  void _seedOffers() {
    final order = _buildOrder(
      clientId: _users.first.id,
      serviceType: 'delivery',
      pickupAddress: 'Rue Njo-Njo, Bonanjo, Douala',
      dropoffAddress: 'Boulevard de la Liberté, Akwa, Douala',
      pickupPoint: (4.0430, 9.6921),
      dropoffPoint: (4.0503, 9.7005),
      recipientName: 'Mme Aïcha N.',
      recipientPhone: '+237690000009',
      distanceKm: 6.4,
      priceTotal: 2529,
      status: 'searching_driver',
      weightKg: 8,
      vehicleCode: 'fourgonnette',
    );
    _orders.add(order);
    _sendOffer(order, sentAt: '2026-09-12T14:02:00+01:00');
  }

  /// Simule le dispatch (`dispatch.services`) : une proposition part vers le
  /// chauffeur de démonstration dès qu'une commande cherche un chauffeur.
  ///
  /// Écart assumé avec le vrai serveur : celui-ci ne sollicite que des
  /// chauffeurs **en ligne et proches**. Ici l'offre part quel que soit l'état
  /// du chauffeur, pour pouvoir dérouler une course de bout en bout sur un seul
  /// appareil (client puis chauffeur).
  void _sendOffer(Map<String, dynamic> order, {String? sentAt}) {
    _offers.add({
      'id': 'offer-${(_offers.length + 1).toString().padLeft(4, '0')}',
      // Résumé de `OfferOrderSummarySerializer` : jamais de détail de prix.
      'order': {
        'id': order['id'],
        'reference': order['reference'],
        'service_type': order['service_type'],
        'pickup_address': order['pickup_address'],
        'dropoff_address': order['dropoff_address'],
        'distance_km': order['distance_km'],
        'vehicle_type': order['vehicle_type'],
        // § 7.4.2 (18 octobre 2026) : le colis se juge avant d'accepter.
        'package_photo_url': order['package_photo_url'] ?? '',
        'package_photo_urls': order['package_photo_urls'] ?? const [],
        // T6.8 : le gain du chauffeur, **à la place** du prix client — pas à
        // côté, sans quoi la commission se lirait par soustraction.
        'driver_earnings_estimate': _earningsEstimate(order),
      },
      'status': 'sent',
      'sent_at': sentAt ?? DateTime.now().toUtc().toIso8601String(),
      'responded_at': null,
    });
  }

  /// `GET /v1/driver/offers/` : **uniquement** les offres `sent`, les plus
  /// récentes d'abord — filtre exact de `DriverOfferListView`. Une offre
  /// acceptée disparaît donc de la liste.
  List<Map<String, dynamic>> offersJson() => _offers.reversed
      .where((o) => o['status'] == 'sent')
      .map(offerJson)
      .toList();

  /// Forme d'`OrderOfferSerializer`, `expires_at` compris (T6.2).
  ///
  /// `expires_at` est l'échéance de **recherche de la commande** — son entrée
  /// en `searching_driver` + 10 minutes —, identique pour toutes les offres
  /// d'une même commande, et `null` dès que la commande ne cherche plus. Ce
  /// n'est pas un délai de réponse par offre.
  Map<String, dynamic> offerJson(Map<String, dynamic> offer) {
    final order = findOrder(offer['order']['id'] as String);
    final started = order?['_search_started_at'] as String?;
    final searching = order?['status'] == 'searching_driver';
    return Map<String, dynamic>.from(offer)
      ..['expires_at'] = searching && started != null
          ? DateTime.parse(
              started,
            ).add(const Duration(minutes: 10)).toIso8601String()
          : null;
  }

  /// Gain prévisionnel du chauffeur : 90 % du prix (§ 6.5.2), total sans
  /// ventilation. `null` sans prix (devis manuel) — jamais `0`.
  static String? _earningsEstimate(Map<String, dynamic> order) {
    final price = double.tryParse('${order['price_total']}');
    if (price == null) return null;
    return (price * 0.9).toStringAsFixed(2);
  }

  Map<String, dynamic>? findOffer(String id) {
    for (final o in _offers) {
      if (o['id'] == id) return o;
    }
    return null;
  }

  /// Acceptation ou refus. À l'acceptation, comme `dispatch.services.
  /// accept_offer` : le chauffeur est assigné, la commande enchaîne
  /// `driver_assigned → driver_en_route_pickup` dans la même transaction, et
  /// les autres offres de la commande expirent.
  Map<String, dynamic> respondToOffer(
    String id, {
    required MockUser driver,
    required bool accepted,
  }) {
    final offer = findOffer(id)!;
    final now = DateTime.now().toUtc().toIso8601String();
    offer['status'] = accepted ? 'accepted' : 'declined';
    offer['responded_at'] = now;
    if (accepted) {
      final order = findOrder(offer['order']['id'] as String);
      if (order != null) {
        order['_driver_id'] = driver.id;
        advanceOrder(order, 'driver_assigned');
        advanceOrder(order, 'driver_en_route_pickup');
        _expireOffersFor(order['id'] as String, except: id);
      }
    }
    return offerJson(offer);
  }

  void _expireOffersFor(String orderId, {String? except}) {
    for (final o in _offers) {
      if (o['id'] != except &&
          o['status'] == 'sent' &&
          o['order']['id'] == orderId) {
        o['status'] = 'expired';
        o['responded_at'] = DateTime.now().toUtc().toIso8601String();
      }
    }
  }

  // --- Tarification -------------------------------------------------------

  /// Multiplicateurs par véhicule. Le faux serveur joue le rôle du serveur :
  /// c'est **lui** qui calcule, jamais l'app (règle non négociable n°3).
  static const Map<String, double> _vehicleMultiplier = {
    'tricycle': 0.8,
    'petite_camionnette': 1.0,
    'fourgonnette': 1.25,
    'camion_dina': 1.8,
    // `grand_camion` n'est pas proposé en livraison : multiplicateur absent.
  };

  static const Map<String, double> _movingBase = {
    'room': 25000,
    'apartment': 60000,
  };

  /// Plus de `one_way` depuis le 14 octobre 2026 (§ 6.6.2) : la manutention
  /// couvre toujours chargement **et** déchargement.
  static const Map<String, double> _handlingFee = {
    'none': 0,
    'round_trip': 14000,
  };

  /// Supplément par étage, départ et arrivée cumulés, **seulement avec
  /// manutention** (`PricingConfig.handling_fee_per_floor`).
  static const double _feePerFloor = 500;

  double? deliveryPrice({
    required double distanceKm,
    required String vehicleCode,
  }) {
    final multiplier = _vehicleMultiplier[vehicleCode];
    if (multiplier == null) return null;
    final raw = (1200 + distanceKm * 150) * multiplier;
    // Plancher D'ABORD, arrondi à la centaine ENSUITE. Une première version
    // appliquait le plancher et la division par 100 dans le même ternaire, ce
    // qui renvoyait 150 000 au lieu de 1 500 sous le plancher.
    final floored = raw < 1500 ? 1500.0 : raw;
    return (floored / 100).ceilToDouble() * 100;
  }

  double? movingPrice({
    required String housingType,
    required double distanceKm,
    required String handling,
    int pickupFloor = 0,
    int dropoffFloor = 0,
  }) {
    final base = _movingBase[housingType];
    if (base == null) return null;
    final fee = _handlingFee[handling] ?? 0;
    // Sans manutention, le client porte lui-même : étages ignorés.
    final floors = handling == 'none'
        ? 0.0
        : (pickupFloor + dropoffFloor) * _feePerFloor;
    return ((base + distanceKm * 400 + fee + floors) / 100).ceilToDouble() *
        100;
  }

  // --- Commandes ----------------------------------------------------------

  Map<String, dynamic> createOrder({
    required MockUser client,
    required String serviceType,
    required String pickupAddress,
    required String dropoffAddress,
    required String recipientName,
    required String recipientPhone,
    required double distanceKm,
    (double, double)? pickupPoint,
    (double, double)? dropoffPoint,
    int photoCount = 0,
    double? weightKg,
    String? vehicleCode,
    String? housingType,
    String handlingType = 'none',
    int pickupFloor = 0,
    int dropoffFloor = 0,
    String? description,
    bool promoApplied = false,
  }) {
    // Véhicule auto-sélectionné depuis le poids si le client n'en impose pas
    // (`OrderCreateSerializer` : `vehicle_code` facultatif en livraison).
    final resolvedVehicle =
        vehicleCode ??
        (serviceType == 'delivery' ? _vehicleForWeight(weightKg ?? 0) : null);

    double? price;
    if (serviceType == 'delivery') {
      price = deliveryPrice(
        distanceKm: distanceKm,
        vehicleCode: resolvedVehicle!,
      );
    } else if (serviceType == 'moving') {
      price = movingPrice(
        housingType: housingType!,
        distanceKm: distanceKm,
        handling: handlingType,
        pickupFloor: pickupFloor,
        dropoffFloor: dropoffFloor,
      );
    }
    // `shipping` / `storage` : devis manuel, aucun prix calculé.
    if (price != null && promoApplied) {
      price = (price * 0.9 / 100).ceilToDouble() * 100;
    }

    final order = _buildOrder(
      clientId: client.id,
      serviceType: serviceType,
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      distanceKm: distanceKm,
      pickupPoint: pickupPoint,
      dropoffPoint: dropoffPoint,
      photoCount: photoCount,
      priceTotal: price,
      // `shipping` / `storage` restent en brouillon : traitement manuel.
      status: price == null ? 'draft' : 'searching_driver',
      weightKg: weightKg,
      vehicleCode: resolvedVehicle,
      description: description,
      pickupFloor: serviceType == 'moving' ? pickupFloor : null,
      dropoffFloor: serviceType == 'moving' ? dropoffFloor : null,
    );
    _orders.add(order);
    if (order['status'] == 'searching_driver') _sendOffer(order);
    return detailJson(order);
  }

  /// Distance routière simulée à partir des **coordonnées** (contrat C1) :
  /// distance à vol d'oiseau × 1,3, arrondie au dixième. Le faux serveur joue
  /// le rôle du serveur — l'app, elle, ne calcule jamais de distance.
  static double distanceBetween((double, double) a, (double, double) b) {
    const earthKm = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(b.$1 - a.$1);
    final dLng = rad(b.$2 - a.$2);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(a.$1)) *
            math.cos(rad(b.$1)) *
            math.pow(math.sin(dLng / 2), 2);
    final straight = 2 * earthKm * math.asin(math.sqrt(h));
    return ((straight * 1.3) * 10).roundToDouble() / 10;
  }

  /// Sélection automatique sur le poids, aux **seuils du catalogue** (T6.1) :
  /// la valeur affichée dans le sélecteur est exactement celle qui déclenche
  /// la sélection. Au-delà de 3 t, c'est le Grand Camion — refusé en livraison.
  static String _vehicleForWeight(double kg) {
    for (final vehicle in _catalogue) {
      final max = vehicle['max_weight_kg'] as String?;
      if (max != null && kg <= double.parse(max)) {
        return vehicle['code'] as String;
      }
    }
    return 'grand_camion';
  }

  /// Poids au-delà duquel aucun véhicule de livraison ne convient.
  static const double deliveryWeightCeilingKg = 3000;

  /// `GET /v1/vehicle-types/` — capacités de T6.1, aucun montant.
  static const List<Map<String, Object?>> _catalogue = [
    {
      'code': 'tricycle',
      'label': 'Tricycle',
      'available_for_delivery': true,
      'max_weight_kg': '500.00',
      'max_volume_m3': '2.00',
      'allowed_housing_types': <String>[],
    },
    {
      'code': 'petite_camionnette',
      'label': 'Petite camionnette',
      'available_for_delivery': true,
      'max_weight_kg': '1000.00',
      'max_volume_m3': '2.50',
      'allowed_housing_types': ['room'],
    },
    {
      'code': 'fourgonnette',
      'label': 'Fourgonnette',
      'available_for_delivery': true,
      'max_weight_kg': '1200.00',
      'max_volume_m3': '6.00',
      'allowed_housing_types': ['room', 'apartment'],
    },
    {
      'code': 'camion_dina',
      'label': 'Camion Dina',
      'available_for_delivery': true,
      'max_weight_kg': '3000.00',
      'max_volume_m3': '12.00',
      'allowed_housing_types': ['apartment'],
    },
    {
      'code': 'grand_camion',
      'label': 'Grand Camion',
      'available_for_delivery': false,
      'max_weight_kg': null,
      'max_volume_m3': '30.00',
      'allowed_housing_types': ['apartment'],
    },
  ];

  Map<String, dynamic> catalogueJson() => {
    'vehicle_types': _catalogue,
    'housing_types': [
      {'code': 'room', 'label': 'Chambre'},
      {'code': 'apartment', 'label': 'Appartement'},
    ],
    'handling_types': [
      {'code': 'none', 'label': 'Non demandée'},
      {'code': 'round_trip', 'label': 'Aller-retour'},
    ],
  };

  static bool vehicleAllowsHousing(String vehicle, String housing) =>
      _catalogue.any(
        (v) =>
            v['code'] == vehicle &&
            (v['allowed_housing_types'] as List).contains(housing),
      );

  Map<String, dynamic> _buildOrder({
    required String clientId,
    required String serviceType,
    required String pickupAddress,
    required String dropoffAddress,
    required String recipientName,
    required String recipientPhone,
    required double distanceKm,
    required double? priceTotal,
    required String status,
    (double, double)? pickupPoint,
    (double, double)? dropoffPoint,
    int? photoCount,
    double? weightKg,
    String? vehicleCode,
    String? description,
    int? pickupFloor,
    int? dropoffFloor,
  }) {
    final n = ++_counter;
    final id = 'order-${n.toString().padLeft(4, '0')}';
    final now = DateTime.now().toUtc();
    final photos = photoCount ?? (weightKg == null ? 0 : 1);
    final photoUrls = [
      for (var i = 1; i <= photos; i++)
        'https://example.invalid/mock/colis-$n-$i.webp',
    ];
    return {
      'id': id,
      'reference': 'CM-${4800 + n}',
      'service_type': serviceType,
      'status': status,
      'pickup_address': pickupAddress,
      'dropoff_address': dropoffAddress,
      'distance_km': distanceKm.toStringAsFixed(2),
      'vehicle_type': vehicleCode,
      // Coordonnées en chaîne à 6 décimales (§ 7.3.1, T5.3).
      'pickup_latitude': pickupPoint?.$1.toStringAsFixed(6),
      'pickup_longitude': pickupPoint?.$2.toStringAsFixed(6),
      'dropoff_latitude': dropoffPoint?.$1.toStringAsFixed(6),
      'dropoff_longitude': dropoffPoint?.$2.toStringAsFixed(6),
      // Liste (T5.9) ; `package_photo_url` vaut la première photo.
      'package_photo_urls': photoUrls,
      'package_photo_url': photoUrls.isEmpty ? null : photoUrls.first,
      'package_description': description,
      'package_weight_kg': weightKg?.toStringAsFixed(2),
      // Déménagement uniquement (§ 6.6.2 « Étages »), `null` ailleurs.
      'pickup_floor': pickupFloor,
      'dropoff_floor': dropoffFloor,
      'price_total': priceTotal?.toStringAsFixed(2),
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'tracking_token': 'trk-${id.hashCode.abs()}',
      // Lien WhatsApp uniquement pour `shipping` (§ 2.2).
      'whatsapp_redirect': serviceType == 'shipping'
          ? {
              'phone_number': '+237657519744',
              'wa_link': 'https://wa.me/237657519744',
            }
          : null,
      'created_at': now.toIso8601String(),
      '_client_id': clientId,
      // Code de remise (T6.6) : chaîne, zéro de tête conservé. Interne au
      // faux serveur, servi au seul suivi client dans sa fenêtre.
      '_delivery_code': (1000 + (n * 7919) % 9000).toString().padLeft(4, '0'),
      '_delivery_attempts': 0,
      '_search_started_at': now.toIso8601String(),
      '_proofs': <Map<String, dynamic>>[],
      '_relaunches': 0,
      '_events': <Map<String, String>>[
        {'to_status': status, 'at': now.toIso8601String()},
      ],
    };
  }

  Map<String, dynamic>? findOrder(String id) {
    for (final o in _orders) {
      if (o['id'] == id) return o;
    }
    return null;
  }

  Map<String, dynamic>? findOrderByTrackingToken(String token) {
    for (final o in _orders) {
      if (o['tracking_token'] == token) return o;
    }
    return null;
  }

  /// Filtre `client=request.user` des vues client (`OrderDetailView`,
  /// `ConfirmDeliveryView`, `CancelOrderView`). **Aucun chauffeur** ne passe,
  /// même assigné : le vrai serveur lui répond 404.
  bool isOwner(MockUser user, Map<String, dynamic> order) =>
      order['_client_id'] == user.id;

  /// `_assert_driver_assigned_to_order` des preuves de course.
  bool isAssignedDriver(MockUser user, Map<String, dynamic> order) =>
      user.role == 'driver' && order['_driver_id'] == user.id;

  /// Forme d'`OrderDetailSerializer` : sans ruban ni champs internes.
  Map<String, dynamic> detailJson(Map<String, dynamic> order) =>
      Map<String, dynamic>.from(order)
        ..removeWhere((key, _) => key.startsWith('_'));

  Map<String, dynamic> advanceOrder(
    Map<String, dynamic> order,
    String nextStatus,
  ) {
    order['status'] = nextStatus;
    (order['_events'] as List).add({
      'to_status': nextStatus,
      'at': DateTime.now().toUtc().toIso8601String(),
    });
    return order;
  }

  /// Transitions vers `cancelled_by_client` déclarées par
  /// `orders/state_machine.py`.
  bool isCancellable(Map<String, dynamic> order) => const {
    'searching_driver',
    'driver_assigned',
    'driver_en_route_pickup',
    'picked_up',
    'in_transit',
  }.contains(order['status']);

  Map<String, dynamic> cancelOrder(Map<String, dynamic> order) {
    // Frais seulement si un chauffeur était déjà engagé (§ 6.10bis). Le vrai
    // serveur applique en plus un délai de grâce de 2 minutes, non simulé.
    final feeCharged = order['status'] != 'searching_driver';
    advanceOrder(order, 'cancelled_by_client');
    _expireOffersFor(order['id'] as String);
    return {
      'order': detailJson(order),
      'fee_charged': feeCharged,
      'payment': feeCharged
          ? {
              'provider': 'kpay',
              'transaction_reference': 'trx-annul-${order['reference']}',
              'authorization_url': null,
            }
          : null,
    };
  }

  /// Réponse de `confirm-delivery` : une **invite** de paiement Mobile Money,
  /// pas une confirmation. L'issue réelle arrive par webhook côté serveur.
  ///
  /// Forme de KPay, fournisseur par défaut depuis le 21 octobre 2026 (§ 6.5.7) :
  /// mode USSD, donc `authorization_url` nul — l'invite est censée arriver sur
  /// le téléphone. Une seconde demande avant le « webhook » répond
  /// `payment_already_pending`, comme le vrai serveur.
  ///
  /// Simulation du webhook : la commande passe à `completed` à la **relecture
  /// suivante** (voir [trackingJson]), jamais dans la réponse elle-même —
  /// l'app doit rester incapable de conclure seule au paiement.
  Map<String, dynamic>? initiatePayment(Map<String, dynamic> order) {
    if (order['_payment_initiated'] == true) return null;
    order['_payment_initiated'] = true;
    return {
      'provider': 'kpay',
      'transaction_reference': 'trx-${order['reference']}',
      'authorization_url': null,
    };
  }

  // --- Suivi --------------------------------------------------------------

  /// Les 5 étapes fixes du ruban, dans l'ordre du serveur.
  static const List<(String, String)> _ribbon = [
    ('order_received', 'Commande reçue'),
    ('driver_assigned', 'Chauffeur assigné'),
    ('picked_up', 'Colis récupéré'),
    ('en_route', 'En route'),
    ('delivered', 'Livré'),
  ];

  static const Map<String, String> _statusToStep = {
    'searching_driver': 'order_received',
    'driver_assigned': 'driver_assigned',
    'driver_en_route_pickup': 'driver_assigned',
    'picked_up': 'picked_up',
    'in_transit': 'en_route',
    'delivered': 'delivered',
    'completed': 'delivered',
  };

  static const Map<String, String> _statusLabel = {
    'draft': 'Brouillon',
    'searching_driver': 'Recherche de chauffeur',
    'driver_assigned': 'Chauffeur assigné',
    'driver_en_route_pickup': 'En route vers la collecte',
    'picked_up': 'Colis récupéré',
    'in_transit': 'En transit',
    'delivered': 'Livré',
    'completed': 'Terminée',
    'cancelled_by_client': 'Annulée par le client',
    'cancelled_by_system': 'Annulée automatiquement',
    'disputed': 'Litige',
  };

  List<Map<String, dynamic>> _buildRibbon(Map<String, dynamic> order) {
    final reached = <String, String>{};
    for (final event
        in (order['_events'] as List).cast<Map<String, String>>()) {
      final step = _statusToStep[event['to_status']];
      if (step != null) reached.putIfAbsent(step, () => event['at']!);
    }
    final current = _statusToStep[order['status']];
    return [
      for (final (key, label) in _ribbon)
        {
          'key': key,
          'label': label,
          'done': reached.containsKey(key),
          'current': key == current,
          'reached_at': reached[key],
        },
    ];
  }

  /// Forme exacte d'`OrderTrackingSerializer`.
  Map<String, dynamic> trackingJson(Map<String, dynamic> order) {
    // Webhook de paiement simulé : arrivé « entre deux lectures ».
    if (order['status'] == 'delivered' && order['_payment_initiated'] == true) {
      advanceOrder(order, 'completed');
    }
    return _trackingShape(order);
  }

  Map<String, dynamic> _trackingShape(Map<String, dynamic> order) =>
      detailJson(order)..addAll({
        'status_label': _statusLabel[order['status']],
        'status_ribbon': _buildRibbon(order),
        'eta_minutes': _eta(order),
        'remaining_straight_line_distance_km': _remainingKm(order),
        'driver': _trackedDriver(order),
        'proofs': [
          for (final p in (order['_proofs'] as List))
            Map<String, dynamic>.from(p as Map),
        ],
        'delivery_code': _deliveryCodeWindow.contains(order['status'])
            ? order['_delivery_code']
            : null,
      });

  /// Statuts où le client lit son code de remise (§ 7.3.12). `null` partout
  /// ailleurs, **dès** `delivered`.
  static const Set<String> _deliveryCodeWindow = {
    'searching_driver',
    'driver_assigned',
    'driver_en_route_pickup',
    'picked_up',
    'in_transit',
  };

  /// Fenêtre de contact (§ 6.12) : le numéro réel est servi de
  /// `driver_assigned` à `delivered`, plus `disputed`.
  static const Set<String> _contactWindow = {
    'driver_assigned',
    'driver_en_route_pickup',
    'picked_up',
    'in_transit',
    'delivered',
    'disputed',
  };

  /// ETA simulée, en minutes restantes sur l'étape en cours (T6.4). `null`
  /// hors trajet : l'app ne doit alors rien afficher.
  static int? _eta(Map<String, dynamic> order) => switch (order['status']) {
    'driver_assigned' || 'driver_en_route_pickup' => 12,
    'picked_up' || 'in_transit' => 18,
    _ => null,
  };

  /// Distance à vol d'oiseau restante (T7.2), `null` aux mêmes moments.
  static double? _remainingKm(Map<String, dynamic> order) =>
      switch (order['status']) {
        'driver_assigned' || 'driver_en_route_pickup' => 3.4,
        'picked_up' || 'in_transit' => 5.1,
        _ => null,
      };

  /// Bloc `driver` (`TrackedDriverSerializer`) : sept clés, clé `phone`
  /// toujours présente.
  Map<String, dynamic>? _trackedDriver(Map<String, dynamic> order) {
    final driver = _userById(order['_driver_id'] as String?);
    if (driver == null) return null;
    final last = driver.lastName.trim();
    return {
      'first_name': driver.firstName,
      'last_name_initial': last.isEmpty ? '' : '${last[0].toUpperCase()}.',
      'phone': _contactWindow.contains(order['status']) ? driver.phone : null,
      'rating_average': _driverRatingAverage(driver.id),
      'rating_count': _ratingsOf(driver.id).length,
      'vehicle_type': 'fourgonnette',
      'vehicle_plate': 'LT 4821 AB',
    };
  }

  MockUser? _userById(String? id) {
    if (id == null) return null;
    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }

  // --- Canal chauffeur ----------------------------------------------------

  /// `DriverOrderSerializer` (T6.8) : **aucun montant**, ruban et
  /// `client_phone` en plus.
  Map<String, dynamic> driverOrderJson(Map<String, dynamic> order) {
    final client = _userById(order['_client_id'] as String?);
    return detailJson(order)
      ..remove('price_total')
      ..remove('whatsapp_redirect')
      ..addAll({
        'status_label': _statusLabel[order['status']],
        'status_ribbon': _buildRibbon(order),
        'client_phone': _contactWindow.contains(order['status'])
            ? client?.phone
            : null,
      });
  }

  /// `GET /v1/driver/orders/current/` : statuts actifs, `delivered` compris.
  List<Map<String, dynamic>> driverActiveOrdersJson(MockUser driver) => [
    for (final o in _orders.reversed)
      if (o['_driver_id'] == driver.id &&
          const {
            'driver_assigned',
            'driver_en_route_pickup',
            'picked_up',
            'in_transit',
            'delivered',
          }.contains(o['status']))
        driverOrderJson(o),
  ];

  /// Statuts de `GET /v1/driver/orders/history/` (§ 7.4.6) : le complément
  /// exact des statuts actifs.
  static const Set<String> driverHistoryStatuses = {
    'completed',
    'cancelled_by_client',
    'cancelled_by_system',
    'disputed',
  };

  /// `DriverOrderHistorySerializer` : la plus récente d'abord, un seul
  /// montant (`earned_amount`).
  ///
  /// `earned_amount` : somme des crédits chauffeur du livre portant la
  /// référence de la course, comme la sous-requête du serveur. Écart assumé :
  /// le faux serveur ne crédite pas le livre à la clôture d'une course jouée
  /// en démo, une course `completed` sans écriture rend donc son gain
  /// prévisionnel. Sans crédit, `null` — jamais `0`.
  List<Map<String, dynamic>> driverHistoryJson(
    MockUser driver,
    List<String> statuses,
  ) {
    final wanted = statuses.isEmpty
        ? driverHistoryStatuses
        : statuses.toSet().intersection(driverHistoryStatuses);
    final rows = [
      for (final o in _orders)
        if (o['_driver_id'] == driver.id && wanted.contains(o['status'])) o,
    ]..sort((a, b) => '${b['created_at']}'.compareTo('${a['created_at']}'));
    return [
      for (final o in rows)
        {
          'id': o['id'],
          'reference': o['reference'],
          'service_type': o['service_type'],
          'status': o['status'],
          'status_label': _statusLabel[o['status']],
          'pickup_address': o['pickup_address'],
          'dropoff_address': o['dropoff_address'],
          'distance_km': o['distance_km'],
          'vehicle_type': o['vehicle_type'],
          'package_photo_url': o['package_photo_url'] ?? '',
          'package_photo_urls': o['package_photo_urls'] ?? const [],
          'earned_amount': _creditedFor(o),
          'created_at': o['created_at'],
        },
    ];
  }

  String? _creditedFor(Map<String, dynamic> order) {
    final credits = _ledger.where(
      (e) =>
          e['entry_type'] == 'driver_credit' &&
          e['external_reference'] == order['reference'],
    );
    if (credits.isEmpty) {
      return order['status'] == 'completed' ? _earningsEstimate(order) : null;
    }
    final sum = credits.fold<double>(
      0,
      (a, e) => a + double.parse('${e['amount']}'),
    );
    return sum.toStringAsFixed(2);
  }

  /// Courses passées du chauffeur de démonstration, pour que l'historique ne
  /// soit pas vide au premier lancement. Références `CM-47xx`, hors de la
  /// plage des commandes créées en démo (`CM-48xx`), reliées aux crédits du
  /// livre amorcé par [_seedLedger].
  void _seedDriverHistory() {
    final driver = _users.firstWhere((u) => u.role == 'driver');
    final now = DateTime.now().toUtc();
    void past({
      required String reference,
      required String serviceType,
      required String status,
      required int daysAgo,
      required String pickup,
      required String dropoff,
      required double distanceKm,
      required double price,
      String? vehicleCode,
      int photos = 0,
      int? pickupFloor,
      int? dropoffFloor,
    }) {
      final order = _buildOrder(
        // Client hors des comptes de démo : ces courses n'encombrent pas
        // l'historique du client de démonstration.
        clientId: 'client-historique',
        serviceType: serviceType,
        pickupAddress: pickup,
        dropoffAddress: dropoff,
        recipientName: 'M. Client D.',
        recipientPhone: '+237690000010',
        distanceKm: distanceKm,
        priceTotal: price,
        status: status,
        photoCount: photos,
        vehicleCode: vehicleCode,
        pickupFloor: pickupFloor,
        dropoffFloor: dropoffFloor,
      );
      _counter--; // Ne consomme pas la numérotation des commandes de démo.
      order
        ..['id'] = 'order-hist-$reference'
        ..['reference'] = reference
        ..['created_at'] = now
            .subtract(Duration(days: daysAgo))
            .toIso8601String()
        ..['_driver_id'] = driver.id;
      _orders.add(order);
    }

    past(
      reference: 'CM-4701',
      serviceType: 'delivery',
      status: 'completed',
      daysAgo: 2,
      pickup: 'Marché Central, Douala',
      dropoff: 'Carrefour Ndokoti, Douala',
      distanceKm: 5.2,
      price: 2200,
      vehicleCode: 'tricycle',
      photos: 2,
    );
    past(
      reference: 'CM-4702',
      serviceType: 'moving',
      status: 'completed',
      daysAgo: 9,
      pickup: 'Bonamoussadi, Douala',
      dropoff: 'Logpom, Douala',
      distanceKm: 7.8,
      price: 33000,
      vehicleCode: 'fourgonnette',
      pickupFloor: 2,
      dropoffFloor: 3,
    );
    past(
      reference: 'CM-4703',
      serviceType: 'delivery',
      status: 'cancelled_by_client',
      daysAgo: 15,
      pickup: 'Akwa, Douala',
      dropoff: 'Bali, Douala',
      distanceKm: 3.1,
      price: 1800,
      vehicleCode: 'tricycle',
      photos: 1,
    );
    past(
      reference: 'CM-4704',
      serviceType: 'delivery',
      status: 'disputed',
      daysAgo: 40,
      pickup: 'Deido, Douala',
      dropoff: 'Bonaberi, Douala',
      distanceKm: 9.4,
      price: 3400,
      vehicleCode: 'petite_camionnette',
      photos: 1,
    );
    past(
      reference: 'CM-4705',
      serviceType: 'delivery',
      status: 'completed',
      daysAgo: 21,
      pickup: 'Bépanda, Douala',
      dropoff: 'Makepe, Douala',
      distanceKm: 8.6,
      price: 3500,
      vehicleCode: 'fourgonnette',
    );
  }

  void recordProof(
    Map<String, dynamic> order,
    String type, {
    String signatureName = '',
  }) {
    (order['_proofs'] as List).add({
      'proof_type': type,
      // URL « signée » factice : recalculée à chaque lecture côté serveur.
      'photo_url':
          'https://example.invalid/mock/preuve-${order['id']}-$type.webp',
      'recipient_signature_name': signatureName,
      'captured_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Vérifie un code de remise. Renvoie `null` si bon, sinon le code d'erreur
  /// serveur. À la troisième erreur, un **nouveau** code est tiré.
  String? checkDeliveryCode(Map<String, dynamic> order, String code) {
    if (code == order['_delivery_code']) return null;
    final attempts = (order['_delivery_attempts'] as int) + 1;
    if (attempts >= 3) {
      order['_delivery_attempts'] = 0;
      final next =
          (int.parse(order['_delivery_code'] as String) + 4321) % 10000;
      order['_delivery_code'] = next.toString().padLeft(4, '0');
      return 'delivery_code_attempts_exhausted';
    }
    order['_delivery_attempts'] = attempts;
    return 'invalid_delivery_code';
  }

  /// Gain d'une course (§ 7.4.5) : prévision avant paiement, crédité après.
  Map<String, dynamic> orderEarningsJson(Map<String, dynamic> order) => {
    'order_id': order['id'],
    'amount': _earningsEstimate(order),
    'nature': order['status'] == 'completed' ? 'earned' : 'estimate',
    'currency': 'XAF',
  };

  // --- Canal client : historique, note, relance --------------------------

  /// `OrderListSerializer` : dix clés, tri `-created_at`.
  List<Map<String, dynamic>> clientOrdersJson(
    MockUser client,
    List<String> statuses,
  ) => [
    for (final o in _orders.reversed)
      if (o['_client_id'] == client.id &&
          (statuses.isEmpty || statuses.contains(o['status'])))
        {
          'id': o['id'],
          'reference': o['reference'],
          'service_type': o['service_type'],
          'status': o['status'],
          'status_label': _statusLabel[o['status']],
          'pickup_address': o['pickup_address'],
          'dropoff_address': o['dropoff_address'],
          'vehicle_type': o['vehicle_type'],
          'price_total': o['price_total'],
          'created_at': o['created_at'],
        },
  ];

  static bool isKnownStatus(String status) => _statusLabel.containsKey(status);

  final Map<String, List<Map<String, dynamic>>> _ratings = {};

  List<Map<String, dynamic>> _ratingsOf(String driverId) =>
      _ratings[driverId] ?? const [];

  String _driverRatingAverage(String driverId) {
    final list = _ratingsOf(driverId);
    if (list.isEmpty) return '0.00';
    final sum = list.fold<int>(0, (a, r) => a + (r['rating'] as int));
    return (sum / list.length).toStringAsFixed(2);
  }

  /// `POST /orders/{id}/rate/`. Renvoie le code d'erreur, ou la réponse.
  Object rateOrder(Map<String, dynamic> order, int rating, String comment) {
    if (!const {'delivered', 'completed'}.contains(order['status'])) {
      return 'order_not_ratable';
    }
    final driverId = order['_driver_id'] as String?;
    if (driverId == null) return 'order_has_no_driver_to_rate';
    if (order['_rated'] == true) return 'order_already_rated';
    order['_rated'] = true;
    final entry = {
      'rating': rating,
      'comment': comment,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    (_ratings[driverId] ??= []).add(entry);
    return {...entry, 'driver_rating_average': _driverRatingAverage(driverId)};
  }

  /// `POST /orders/{id}/relaunch-search/`. Renvoie le code d'erreur, ou la
  /// réponse. Trois relances au plus ; prix recalculé, ici inchangé.
  Object relaunchSearch(Map<String, dynamic> order) {
    if (order['status'] != 'cancelled_by_system') {
      return 'order_not_relaunchable';
    }
    final used = (order['_relaunches'] as int) + 1;
    if (used > 3) return 'search_relaunch_limit_reached';
    order['_relaunches'] = used;
    order['_search_started_at'] = DateTime.now().toUtc().toIso8601String();
    advanceOrder(order, 'searching_driver');
    _sendOffer(order);
    return {
      'order': detailJson(order),
      'relaunches_used': used,
      'relaunches_remaining': 3 - used,
      'price_changed': false,
    };
  }

  /// Récapitulatif chauffeur (§ 7.4.4) : période en cours, crédits seuls.
  Map<String, dynamic> earningsSummaryJson(String period) {
    final credits = _ledger.where((e) => e['entry_type'] == 'driver_credit');
    final total = credits.fold<double>(
      0,
      (a, e) => a + double.parse('${e['amount']}'),
    );
    final now = DateTime.now().toUtc();
    final start = period == 'month'
        ? DateTime.utc(now.year, now.month)
        : DateTime.utc(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: now.weekday - 1));
    final end = period == 'month'
        ? DateTime.utc(now.year, now.month + 1)
        : start.add(const Duration(days: 7));
    return {
      'period': period,
      'period_start': start.toIso8601String(),
      'period_end': end.toIso8601String(),
      'total_earned': total.toStringAsFixed(2),
      'trip_count': credits.length,
      'currency': 'XAF',
    };
  }

  /// `OrderPublicTrackingSerializer` : volontairement réduit — aucune adresse,
  /// aucun prix, aucune donnée personnelle.
  Map<String, dynamic> publicTrackingJson(Map<String, dynamic> order) => {
    'reference': order['reference'],
    'service_type': order['service_type'],
    'status': order['status'],
    'status_label': _statusLabel[order['status']],
    'status_ribbon': _buildRibbon(order),
    'eta_minutes': null,
  };

  // --- Portefeuille -------------------------------------------------------

  void _seedLedger() {
    _ledger.addAll([
      // Crédits des courses passées amorcées par [_seedDriverHistory].
      _entry('driver_credit', 1950, 'CM-4701'),
      _entry('driver_credit', 2480, 'CM-4702'),
      _entry('driver_credit', 3120, 'CM-4705'),
      _entry('withdrawal', -2000, 'retrait-0001'),
      // Assez de commissions pour que le minimum de retrait (2000 FCFA) soit
      // atteignable : un tableau ambassadeur où aucun retrait n'est jamais
      // possible ne permet pas d'éprouver l'écran.
      _entry('ambassador_commission', 500, 'CM-4802', ambassador: true),
      _entry('ambassador_commission', 500, 'CM-4803', ambassador: true),
      _entry('ambassador_commission', 500, 'CM-4804', ambassador: true),
      _entry('ambassador_commission', 500, 'CM-4805', ambassador: true),
      _entry('ambassador_commission', 1000, 'CM-4806', ambassador: true),
      _entry('ambassador_commission', 1000, 'CM-4807', ambassador: true),
    ]);
  }

  Map<String, dynamic> _entry(
    String type,
    double amount,
    String reference, {
    bool ambassador = false,
  }) => {
    'id': 'ledger-${_ledger.length + 1}',
    'entry_type': type,
    'amount': amount.toStringAsFixed(2),
    'currency': 'XAF',
    'external_reference': reference,
    'created_at': '2026-09-0${(_ledger.length % 9) + 1}T10:00:00+01:00',
    '_account': ambassador
        ? MockAccount.ambassadorWallet.name
        : MockAccount.driverWallet.name,
  };

  List<Map<String, dynamic>> ledgerJson(MockAccount account) => [
    for (final e in _ledger)
      if (e['_account'] == account.name)
        Map<String, dynamic>.from(e)..remove('_account'),
  ];

  double balance(MockAccount account) {
    var total = 0.0;
    for (final e in _ledger) {
      if (e['_account'] == account.name) {
        total += double.parse(e['amount'] as String);
      }
    }
    return total;
  }

  /// `WalletBalanceSerializer`. `total_earned` est le cumul des seules
  /// commissions (ne baisse jamais) ; `balance` est le solde net.
  Map<String, dynamic> ambassadorDashboardJson() {
    var earned = 0.0;
    var conversions = 0;
    for (final e in _ledger) {
      if (e['_account'] == MockAccount.ambassadorWallet.name &&
          e['entry_type'] == 'ambassador_commission') {
        earned += double.parse(e['amount'] as String);
        conversions++;
      }
    }
    return {
      'balance': balance(MockAccount.ambassadorWallet).toStringAsFixed(2),
      'usage_count': conversions + 3,
      'conversion_count': conversions,
      'total_earned': earned.toStringAsFixed(2),
      'recent_conversions': ledgerJson(MockAccount.ambassadorWallet),
    };
  }

  /// `WithdrawalRequestSerializer` : la demande reste `pending`, confirmée plus
  /// tard de façon asynchrone par le webhook de décaissement.
  Map<String, dynamic> requestWithdrawal(
    MockUser user,
    MockAccount account,
    double amount,
  ) {
    _ledger.add(
      _entry(
        'withdrawal',
        -amount,
        'retrait-${_ledger.length + 1}',
        ambassador: account == MockAccount.ambassadorWallet,
      ),
    );
    return {
      'id': 'withdrawal-${_ledger.length}',
      'amount': amount.toStringAsFixed(2),
      'status': 'pending',
      'recipient_phone': user.phone,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}

/// Lieu connu du faux géocodeur (§ 7.8).
class MockPlace {
  const MockPlace(this.label, this.latitude, this.longitude);

  final String label;
  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() => {
    'label': label,
    'latitude': latitude.toStringAsFixed(6),
    'longitude': longitude.toStringAsFixed(6),
  };
}

/// Faux géocodeur : quelques repères de Douala et Yaoundé, pour éprouver la
/// recherche explicite et le libellé proposé de l'écran A4 sans backend.
/// `PANNE` comme recherche → `geocoding_unavailable`.
abstract final class MockGeocoder {
  static const places = <MockPlace>[
    MockPlace('Rue Njo-Njo, Bonanjo, Douala', 4.0430, 9.6921),
    MockPlace('Boulevard de la Liberté, Akwa, Douala', 4.0503, 9.7005),
    MockPlace('Carrefour Ndokoti, Douala', 4.0467, 9.7458),
    MockPlace('Marché Central, Douala', 4.0489, 9.7066),
    MockPlace('Rond-point Deïdo, Douala', 4.0633, 9.7117),
    MockPlace('Aéroport international de Douala', 4.0061, 9.7195),
    MockPlace('Carrefour Bonamoussadi, Douala', 4.0931, 9.7399),
    MockPlace('Poste centrale, Yaoundé', 3.8667, 11.5167),
    MockPlace('Carrefour Bastos, Yaoundé', 3.8966, 11.5098),
  ];

  /// Comparaison insensible à la casse et aux accents courants.
  static String normalize(String value) {
    const accents = {
      'à': 'a', 'â': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
      'ï': 'i', 'î': 'i', 'ô': 'o', 'ù': 'u', 'û': 'u', 'ç': 'c',
    };
    final lower = value.toLowerCase();
    return [for (final c in lower.split('')) accents[c] ?? c].join();
  }
}
