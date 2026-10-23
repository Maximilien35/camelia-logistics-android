import 'package:camelia/core/api/api_client.dart';
import 'package:camelia/core/api/api_exception.dart';
import 'package:camelia/core/api/mock/mock_backend.dart';
import 'package:camelia/core/auth/token_store.dart';
import 'package:camelia/features/shared/models/app_user.dart';
import 'package:camelia/features/shared/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Coffre en mémoire : `flutter_secure_storage` n'a pas de canal sous
/// `flutter test`.
class _FakeTokenStore extends TokenStore {
  String? access;
  String? refresh;

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    access = tokens.access;
    refresh = tokens.refresh;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

void main() {
  late MockBackend backend;
  late _FakeTokenStore store;
  late ApiClient client;
  late AuthService auth;

  setUp(() {
    // Sans latence : les tests n'ont pas à attendre les états de chargement.
    backend = MockBackend(latency: Duration.zero);
    store = _FakeTokenStore();
    client = ApiClient(tokenStore: store, httpClient: backend);
    auth = AuthService(client: client, tokenStore: store);
  });

  /// Ouvre une session pour un des comptes semés.
  Future<AppUser> signIn(String email) async {
    await auth.loginWithPassword(email: email, password: 'motdepasse8');
    return auth.fetchMe();
  }

  group('Authentification', () {
    test('le compte client semé se connecte et /me/ se parse', () async {
      final user = await signIn('aicha@camelia.test');

      // Si un nom de champ divergeait du contrat, `AppUser.fromJson` casserait.
      expect(user.role, UserRole.client);
      expect(user.email, 'aicha@camelia.test');
      expect(user.fullName, 'Aïcha Ngo Bell');
      expect(user.emailVerified, isTrue);
      expect(store.access, isNotNull);
    });

    test('le compte chauffeur semé renvoie le rôle driver', () async {
      final user = await signIn('jeanpaul@camelia.test');
      expect(user.role, UserRole.driver);
    });

    test('le compte admin semé renvoie le rôle admin', () async {
      final user = await signIn('admin@camelia.test');
      expect(user.role, UserRole.admin);
    });

    test('mot de passe faux → invalid_credentials', () async {
      await expectLater(
        auth.loginWithPassword(email: 'aicha@camelia.test', password: 'faux'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.invalidCredentials,
          ),
        ),
      );
    });

    test('compte non vérifié → email_not_verified', () async {
      await expectLater(
        auth.loginWithPassword(
          email: 'nonverifie@camelia.test',
          password: 'motdepasse8',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.emailNotVerified,
          ),
        ),
      );
    });

    test('les codes OTP spéciaux produisent chaque erreur attendue', () async {
      Future<void> expectCode(String otp, String expected) => expectLater(
        auth.verifyOtp(email: 'nonverifie@camelia.test', code: otp),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', expected)),
      );

      await expectCode('000000', ApiErrorCode.invalidOtp);
      await expectCode('111111', ApiErrorCode.otpExpired);
      await expectCode('222222', ApiErrorCode.otpMaxAttempts);
      await expectCode('999999', ApiErrorCode.otpRateLimited);
    });

    test('un code quelconque valide le compte et ouvre la session', () async {
      final tokens = await auth.verifyOtp(
        email: 'nonverifie@camelia.test',
        code: '482109',
      );

      expect(tokens.access, isNotEmpty);
      // Le compte est désormais vérifié : la connexion par mot de passe passe.
      final user = await signIn('nonverifie@camelia.test');
      expect(user.emailVerified, isTrue);
    });

    test('inscription en doublon : erreurs ventilées par champ', () async {
      try {
        await auth.register(
          email: 'aicha@camelia.test',
          phone: '+237690000001',
          firstName: 'Autre',
          lastName: 'Personne',
          password: 'motdepasse8',
        );
        fail('aurait dû échouer');
      } on ApiException catch (e) {
        expect(e.statusCode, 400);
        expect(e.fieldError('email'), contains('existe déjà'));
        expect(e.fieldError('phone'), contains('existe déjà'));
      }
    });

    test('le refresh tourne et met l\'ancien jeton en liste noire', () async {
      await signIn('aicha@camelia.test');
      final premierRefresh = store.refresh!;

      final rotated = await client.post(
        'auth/refresh',
        authenticated: false,
        body: {'refresh': premierRefresh},
      );
      expect(rotated['refresh'], isNot(premierRefresh));

      // Rejouer l'ancien doit échouer, comme BLACKLIST_AFTER_ROTATION.
      await expectLater(
        client.post(
          'auth/refresh',
          authenticated: false,
          body: {'refresh': premierRefresh},
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('la langue change par PATCH /me/', () async {
      await signIn('aicha@camelia.test');
      final updated = await auth.updateLanguage(AppLanguage.en);
      expect(updated.language, AppLanguage.en);
    });

    test('le consentement aux campagnes est faux par défaut et se pose par '
        'PATCH /me/', () async {
      await signIn('aicha@camelia.test');
      expect((await auth.fetchMe()).marketingOptIn, isFalse);
      expect((await auth.updateMarketingOptIn(true)).marketingOptIn, isTrue);
      expect((await auth.updateMarketingOptIn(false)).marketingOptIn, isFalse);
    });
  });

  group('Tarification', () {
    test('le devis livraison ne renvoie que le total et la distance', () async {
      await signIn('aicha@camelia.test');

      final quote = await client.post(
        'orders/quote',
        body: {
          'service_type': 'delivery',
          'pickup_latitude': '4.043000',
          'pickup_longitude': '9.692100',
          'dropoff_latitude': '4.050300',
          'dropoff_longitude': '9.700500',
          'vehicle_code': 'fourgonnette',
        },
      );

      // Règle non négociable n°3 : aucun détail de prix ne doit exister dans la
      // réponse, même en simulation — sinon un écran pourrait s'y adosser.
      // `distance_km` est la distance retenue, affichée sans rien en déduire.
      expect(quote.keys, unorderedEquals(['price_total', 'distance_km']));
      expect(quote['price_total'], isA<int>());
      expect(quote['price_total'] as int, greaterThan(0));
    });

    test(
      'une distance envoyée par le client est ignorée, pas refusée',
      () async {
        // T2.9 : le mode `distance_km` du devis est supprimé, sur ce canal comme
        // sur l'API partenaire. Le serveur calcule la distance lui-même ; un
        // `distance_km` dans le corps n'atteint jamais le calcul, exactement
        // comme un montant (règles n°3 et n°4). Le refuser laisserait croire à
        // un contrat qui n'existe plus.
        await signIn('aicha@camelia.test');

        Future<Map<String, dynamic>> quote({String? distanceKm}) => client.post(
          'orders/quote',
          body: {
            'service_type': 'delivery',
            'pickup_latitude': '4.043000',
            'pickup_longitude': '9.692100',
            'dropoff_latitude': '4.050300',
            'dropoff_longitude': '9.700500',
            'vehicle_code': 'fourgonnette',
            if (distanceKm != null) 'distance_km': distanceKm,
          },
        );

        final honest = await quote();
        // Une distance absurde : si elle était lue, le prix changerait.
        final lying = await quote(distanceKm: '999.0');

        expect(lying['distance_km'], honest['distance_km']);
        expect(lying['price_total'], honest['price_total']);
      },
    );

    test('un point hors du Cameroun est refusé au devis', () async {
      await signIn('aicha@camelia.test');

      await expectLater(
        client.post(
          'orders/quote',
          body: {
            'service_type': 'delivery',
            // Latitude et longitude inversées : l'erreur classique.
            'pickup_latitude': '9.692100',
            'pickup_longitude': '4.043000',
            'dropoff_latitude': '4.050300',
            'dropoff_longitude': '9.700500',
            'vehicle_code': 'fourgonnette',
          },
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statut', 400)
              .having(
                (e) => e.code,
                'code',
                ApiErrorCode.coordinatesOutsideServiceArea,
              ),
        ),
      );
    });

    test('distance indisponible : aucun prix annoncé', () async {
      // Aucun repli approximatif (règle n°3) : sans distance exacte il n'y a
      // ni devis ni commande — deux commandes identiques auraient sinon deux
      // prix différents.
      await signIn('aicha@camelia.test');
      backend.distanceUnavailable = true;
      addTearDown(() => backend.distanceUnavailable = false);

      await expectLater(
        client.post(
          'orders/quote',
          body: {
            'service_type': 'delivery',
            'pickup_latitude': '4.043000',
            'pickup_longitude': '9.692100',
            'dropoff_latitude': '4.050300',
            'dropoff_longitude': '9.700500',
            'vehicle_code': 'fourgonnette',
          },
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statut', 503)
              .having((e) => e.code, 'code', ApiErrorCode.distanceUnavailable),
        ),
      );
    });

    test('le catalogue est un objet à trois listes, sans montant', () async {
      await signIn('aicha@camelia.test');

      final catalogue = await client.get('vehicle-types');

      expect(
        catalogue.keys,
        unorderedEquals(['vehicle_types', 'housing_types', 'handling_types']),
      );
      final vehicle = (catalogue['vehicle_types'] as List).first as Map;
      expect(vehicle.containsKey('delivery_multiplier'), isFalse);
      expect(vehicle.containsKey('available_for_delivery'), isTrue);
    });

    test('livraison sans vehicle_code → erreur de validation', () async {
      await signIn('aicha@camelia.test');

      try {
        await client.post(
          'orders/quote',
          body: {
            'service_type': 'delivery',
            'pickup_latitude': '4.043000',
            'pickup_longitude': '9.692100',
            'dropoff_latitude': '4.050300',
            'dropoff_longitude': '9.700500',
          },
        );
        fail('aurait dû échouer');
      } on ApiException catch (e) {
        expect(e.fieldError('vehicle_code'), isNotNull);
      }
    });

    test('un véhicule non proposé en livraison est refusé', () async {
      await signIn('aicha@camelia.test');

      await expectLater(
        client.post(
          'orders/quote',
          body: {
            'service_type': 'delivery',
            'pickup_latitude': '4.043000',
            'pickup_longitude': '9.692100',
            'dropoff_latitude': '4.050300',
            'dropoff_longitude': '9.700500',
            // Déménagement uniquement : aucun tarif de livraison.
            'vehicle_code': 'grand_camion',
          },
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.vehicleTypeNotAvailableForDelivery,
          ),
        ),
      );
    });

    test(
      'le devis déménagement dépend du logement et de la manutention',
      () async {
        await signIn('aicha@camelia.test');

        Future<double> quote(String handling) async {
          final body = await client.post(
            'orders/quote',
            body: {
              'service_type': 'moving',
              'pickup_latitude': '4.043000',
              'pickup_longitude': '9.692100',
              'dropoff_latitude': '4.050300',
              'dropoff_longitude': '9.700500',
              'housing_type': 'apartment',
              'handling_type': handling,
            },
          );
          return (body['price_total'] as num).toDouble();
        }

        expect(await quote('round_trip'), greaterThan(await quote('none')));
      },
    );
  });

  group('Commandes', () {
    Future<Map<String, dynamic>> createDelivery({
      String pickup = 'Rue Njo-Njo, Bonanjo, Douala',
      String dropoff = 'Boulevard de la Liberté, Akwa, Douala',
      // Bonanjo → Akwa par défaut ; un point lointain déclenche le plafond.
      String dropoffLatitude = '4.050300',
      String dropoffLongitude = '9.700500',
      String? promo,
      int photos = 1,
    }) => client.multipart(
      'orders',
      fields: {
        'service_type': 'delivery',
        'pickup_address': pickup,
        'pickup_latitude': '4.043000',
        'pickup_longitude': '9.692100',
        'dropoff_address': dropoff,
        'dropoff_latitude': dropoffLatitude,
        'dropoff_longitude': dropoffLongitude,
        'recipient_name': 'Mme Aïcha N.',
        'recipient_phone': '+237690000009',
        'package_weight_kg': '8.00',
        if (promo != null) 'promo_code': promo,
      },
      files: [
        for (var i = 0; i < photos; i++)
          ApiFileField(
            field: 'package_photos',
            filename: 'colis-$i.webp',
            bytes: const [1, 2, 3],
            contentType: 'image/webp',
          ),
      ],
    );

    test('création en multipart : champs du contrat, prix serveur', () async {
      await signIn('aicha@camelia.test');

      final order = await createDelivery();

      expect(order['reference'], isA<String>());
      expect(order['service_type'], 'delivery');
      expect(order['status'], 'searching_driver');
      expect(order['price_total'], isA<String>());
      expect(order['tracking_token'], isA<String>());
      // Véhicule auto-sélectionné depuis le poids (8 kg → tricycle) :
      // `vehicle_code` n'était pas envoyé, facultatif en livraison.
      expect(order['vehicle_type'], 'tricycle');
      // Jamais de détail de prix, ici non plus.
      expect(order.containsKey('price_breakdown'), isFalse);
      // `whatsapp_redirect` est réservé à `shipping`.
      expect(order['whatsapp_redirect'], isNull);
    });

    test('photo absente → 400 ventilé sur package_photos', () async {
      await signIn('aicha@camelia.test');

      try {
        await client.multipart(
          'orders',
          fields: {
            'service_type': 'delivery',
            'pickup_address': 'A',
            'dropoff_address': 'B',
            'pickup_latitude': '4.043000',
            'pickup_longitude': '9.692100',
            'dropoff_latitude': '4.050300',
            'dropoff_longitude': '9.700500',
            'recipient_name': 'C',
            'recipient_phone': '+237690000009',
            'package_weight_kg': '8.00',
          },
        );
        fail('aurait dû échouer');
      } on ApiException catch (e) {
        expect(e.fieldError('package_photos'), isNotNull);
      }
    });

    test('coordonnées absentes → 400 ventilé (contrat proposé C1)', () async {
      await signIn('aicha@camelia.test');

      try {
        await client.multipart(
          'orders',
          fields: {
            'service_type': 'storage',
            'pickup_address': 'Douala',
            'dropoff_address': 'Douala',
            'recipient_name': 'X',
            'recipient_phone': '+237690000009',
            'package_description': 'Stockage',
          },
        );
        fail('aurait dû échouer');
      } on ApiException catch (e) {
        expect(e.fieldError('pickup_latitude'), isNotNull);
        expect(e.fieldError('dropoff_longitude'), isNotNull);
      }
    });

    test('plus de trois photos → 400 (contrat proposé C2)', () async {
      await signIn('aicha@camelia.test');

      try {
        await createDelivery(photos: 4);
        fail('aurait dû échouer');
      } on ApiException catch (e) {
        expect(e.fieldError('package_photos'), isNotNull);
      }
    });

    test('la réponse porte coordonnées et liste de photos', () async {
      await signIn('aicha@camelia.test');

      final order = await createDelivery(photos: 3);

      expect(order['pickup_latitude'], '4.043000');
      expect(order['dropoff_longitude'], '9.700500');
      expect(order['package_photo_urls'], hasLength(3));
    });

    test('trajet trop long → distance_exceeds_maximum', () async {
      await signIn('aicha@camelia.test');

      await expectLater(
        // Douala → Yaoundé : bien au-delà du plafond simulé.
        createDelivery(
          dropoffLatitude: '3.848000',
          dropoffLongitude: '11.502100',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.distanceExceedsMaximum,
          ),
        ),
      );
    });

    test('code promo invalide fait échouer la création', () async {
      await signIn('aicha@camelia.test');

      await expectLater(
        createDelivery(promo: 'EXPIRE'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.promoCodeExpired,
          ),
        ),
      );
    });

    test('un code promo valide réduit le total renvoyé', () async {
      await signIn('aicha@camelia.test');

      final sansPromo = await createDelivery();
      final avecPromo = await createDelivery(promo: 'BIENVENUE10');

      // Le prix reste décidé par le serveur : on constate, on ne recalcule pas.
      expect(
        double.parse(avecPromo['price_total'] as String),
        lessThan(double.parse(sansPromo['price_total'] as String)),
      );
    });

    test(
      'une commande shipping reste en brouillon et porte le lien WhatsApp',
      () async {
        await signIn('aicha@camelia.test');

        final order = await client.multipart(
          'orders',
          fields: {
            'service_type': 'shipping',
            'pickup_address': 'Douala',
            'dropoff_address': 'Paris',
            'pickup_latitude': '4.043000',
            'pickup_longitude': '9.692100',
            'dropoff_latitude': '4.050300',
            'dropoff_longitude': '9.700500',
            'recipient_name': 'Destinataire',
            'recipient_phone': '+237690000009',
            'package_description': 'Deux cartons de documents',
          },
        );

        expect(order['status'], 'draft');
        // Devis manuel : aucun prix calculé.
        expect(order['price_total'], isNull);
        expect(order['whatsapp_redirect'], isNotNull);
        expect(
          (order['whatsapp_redirect'] as Map)['wa_link'],
          startsWith('https://wa.me/'),
        );
      },
    );

    test('le suivi expose le ruban à 5 étapes et eta_minutes nul', () async {
      await signIn('aicha@camelia.test');
      final created = await createDelivery();

      final tracking = await client.get('orders/${created['id']}');

      final ribbon = tracking['status_ribbon'] as List;
      expect(ribbon, hasLength(5));
      expect(ribbon.map((s) => s['key']), [
        'order_received',
        'driver_assigned',
        'picked_up',
        'en_route',
        'delivered',
      ]);
      expect(ribbon.first['done'], isTrue);
      expect(ribbon.first['current'], isTrue);
      expect(ribbon.last['done'], isFalse);
      // Aucune formule d'ETA n'est arbitrée : l'UI ne doit pas promettre d'heure.
      expect(tracking['eta_minutes'], isNull);
      expect(tracking['status_label'], isNotNull);
    });

    test('le suivi public ne fuit ni adresse ni prix', () async {
      await signIn('aicha@camelia.test');
      final created = await createDelivery();

      final public = await client.get(
        'track/${created['tracking_token']}',
        authenticated: false,
      );

      expect(public['reference'], created['reference']);
      expect(public['status_ribbon'], isA<List>());
      for (final interdit in const [
        'pickup_address',
        'dropoff_address',
        'price_total',
        'recipient_name',
        'recipient_phone',
        'tracking_token',
      ]) {
        expect(
          public.containsKey(interdit),
          isFalse,
          reason: '$interdit ne doit pas apparaître dans le suivi public',
        );
      }
    });

    test('payer avant la livraison est refusé', () async {
      await signIn('aicha@camelia.test');
      final created = await createDelivery();

      await expectLater(
        client.post('orders/${created['id']}/confirm-delivery'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.invalidOrderTransition,
          ),
        ),
      );
    });

    test('annuler tôt est gratuit et ne déclenche aucun paiement', () async {
      await signIn('aicha@camelia.test');
      final created = await createDelivery();

      final result = await client.post('orders/${created['id']}/cancel');

      expect(result['fee_charged'], isFalse);
      expect(result['payment'], isNull);
      expect((result['order'] as Map)['status'], 'cancelled_by_client');
    });
  });

  group('Chauffeur', () {
    test('un client ne peut pas lire le statut chauffeur', () async {
      await signIn('aicha@camelia.test');

      await expectLater(
        client.get('driver/status'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.driverProfileRequired,
          ),
        ),
      );
    });

    test('la bascule en ligne change ce que renvoie /driver/status/', () async {
      await signIn('jeanpaul@camelia.test');

      expect((await client.get('driver/status'))['is_online'], isFalse);
      final afterToggle = await client.post(
        'driver/online',
        body: {'is_online': true},
      );
      expect(afterToggle['is_online'], isTrue);
      // L'état persiste d'un appel à l'autre.
      expect((await client.get('driver/status'))['is_online'], isTrue);
    });

    test('le statut porte les documents avec leur motif de rejet', () async {
      await signIn('jeanpaul@camelia.test');

      final status = await client.get('driver/status');
      final documents = status['documents'] as List;

      expect(documents, hasLength(3));
      // Aucune URL de fichier ne doit être exposée (règle backend n°7).
      for (final doc in documents) {
        expect((doc as Map).containsKey('cloudinary_public_id'), isFalse);
        expect(doc.keys, contains('status'));
        expect(doc.keys, contains('rejection_reason'));
      }
    });

    test('les offres portent le gain, jamais le prix client', () async {
      await signIn('jeanpaul@camelia.test');

      final page = await client.get('driver/offers');

      expect(page.keys, containsAll(['count', 'next', 'previous', 'results']));
      final offer = (page['results'] as List).first as Map;
      expect(offer['status'], 'sent');
      expect(offer.containsKey('expires_at'), isTrue);
      final order = offer['order'] as Map;
      // T6.8 : le gain **à la place** du prix — les deux ensemble rendraient
      // la commission calculable par soustraction.
      expect(order.keys, contains('driver_earnings_estimate'));
      expect(order.containsKey('price_total'), isFalse);
      expect(order.containsKey('price_breakdown'), isFalse);
    });

    test('accepter une offre deux fois est refusé', () async {
      await signIn('jeanpaul@camelia.test');
      final page = await client.get('driver/offers');
      final offerId = ((page['results'] as List).first as Map)['id'];

      final accepted = await client.post('driver/offers/$offerId/accept');
      expect(accepted['status'], 'accepted');

      await expectLater(
        client.post('driver/offers/$offerId/accept'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.offerNoLongerAvailable,
          ),
        ),
      );
    });
  });

  group('Portefeuille', () {
    test('le solde vit dans l\'enveloppe, pas dans les lignes', () async {
      await signIn('jeanpaul@camelia.test');

      final page = await client.get('driver/wallet');

      expect(page['balance'], isA<String>());
      final lignes = page['results'] as List;
      expect(lignes, isNotEmpty);
      for (final ligne in lignes) {
        expect((ligne as Map).containsKey('balance'), isFalse);
        expect(ligne.keys, contains('entry_type'));
        expect(ligne.keys, contains('currency'));
      }
    });

    test('un retrait sous le minimum est refusé par le serveur', () async {
      await signIn('jeanpaul@camelia.test');

      await expectLater(
        client.post('driver/wallet/withdraw', body: {'amount': '500.00'}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.withdrawalAmountBelowMinimum,
          ),
        ),
      );
    });

    test('un retrait au-dessus du solde est refusé par le serveur', () async {
      await signIn('jeanpaul@camelia.test');

      await expectLater(
        client.post('driver/wallet/withdraw', body: {'amount': '9999999.00'}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.withdrawalAmountExceedsBalance,
          ),
        ),
      );
    });

    test('un retrait valide sort en pending et diminue le solde', () async {
      await signIn('jeanpaul@camelia.test');
      final avant = double.parse(
        (await client.get('driver/wallet'))['balance'] as String,
      );

      final demande = await client.post(
        'driver/wallet/withdraw',
        body: {'amount': '2000.00'},
      );

      expect(demande['status'], 'pending');
      expect(demande['recipient_phone'], '+237690000002');
      final apres = double.parse(
        (await client.get('driver/wallet'))['balance'] as String,
      );
      expect(apres, avant - 2000);
    });

    test('le tableau ambassadeur distingue solde et cumul gagné', () async {
      await signIn('aicha@camelia.test');

      final dashboard = await client.get('me/ambassador-code');

      expect(
        dashboard.keys,
        containsAll([
          'balance',
          'usage_count',
          'conversion_count',
          'total_earned',
          'recent_conversions',
        ]),
      );
      expect(dashboard['recent_conversions'], isA<List>());
    });
  });

  group('Routes livrées par les lots 5 et 6', () {
    test('GET /orders/ liste l\'historique paginé du compte', () async {
      await signIn('aicha@camelia.test');

      final page = await client.get('orders');

      expect(page.keys, containsAll(['count', 'next', 'previous', 'results']));
    });

    test('GET /orders/ refuse un statut inconnu en 400', () async {
      await signIn('aicha@camelia.test');

      await expectLater(
        client.get('orders', query: {'status': 'active'}),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statut', 400)),
      );
    });

    test('noter une commande non livrée → order_not_ratable', () async {
      await signIn('aicha@camelia.test');
      final created = await client.multipart(
        'orders',
        fields: {
          'service_type': 'storage',
          'pickup_address': 'Douala',
          'dropoff_address': 'Douala',
          'pickup_latitude': '4.043000',
          'pickup_longitude': '9.692100',
          'dropoff_latitude': '4.050300',
          'dropoff_longitude': '9.700500',
          'recipient_name': 'X',
          'recipient_phone': '+237690000009',
          'package_description': 'Stockage court',
        },
      );

      await expectLater(
        client.post('orders/${created['id']}/rate', body: {'rating': 5}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.orderNotRatable,
          ),
        ),
      );
    });
  });

  group('Isolation entre comptes', () {
    test('un autre client ne voit pas la commande, et reçoit 404', () async {
      await signIn('aicha@camelia.test');
      final created = await client.multipart(
        'orders',
        fields: {
          'service_type': 'storage',
          'pickup_address': 'Douala',
          'dropoff_address': 'Douala',
          'pickup_latitude': '4.043000',
          'pickup_longitude': '9.692100',
          'dropoff_latitude': '4.050300',
          'dropoff_longitude': '9.700500',
          'recipient_name': 'X',
          'recipient_phone': '+237690000009',
          'package_description': 'Stockage',
        },
      );

      // Bascule vers un autre compte client.
      await auth.verifyOtp(email: 'nonverifie@camelia.test', code: '482109');

      await expectLater(
        client.get('orders/${created['id']}'),
        // 404 et non 403 : l'ownership est un filtre de queryset côté serveur.
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statut', 404)),
      );
    });
  });
}
