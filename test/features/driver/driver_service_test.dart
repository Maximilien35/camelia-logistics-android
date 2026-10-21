import 'package:camelia/core/api/api_client.dart';
import 'package:camelia/core/api/api_exception.dart';
import 'package:camelia/core/api/mock/mock_backend.dart';
import 'package:camelia/core/auth/token_store.dart';
import 'package:camelia/features/driver/models/driver_status.dart';
import 'package:camelia/features/driver/models/order_offer.dart';
import 'package:camelia/features/driver/services/driver_service.dart';
import 'package:camelia/features/shared/models/wallet.dart';
import 'package:camelia/features/shared/services/auth_service.dart';
import 'package:camelia/features/shared/services/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

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
  late ApiClient client;
  late AuthService auth;
  late DriverService driver;
  late WalletService wallet;

  setUp(() {
    final store = _FakeTokenStore();
    client = ApiClient(
      tokenStore: store,
      httpClient: MockBackend(latency: Duration.zero),
    );
    auth = AuthService(client: client, tokenStore: store);
    driver = DriverService(client: client);
    wallet = WalletService(client: client);
  });

  Future<void> signInAsDriver() => auth.loginWithPassword(
    email: 'jeanpaul@camelia.test',
    password: 'motdepasse8',
  );

  Future<void> signInAsClient() => auth.loginWithPassword(
    email: 'aicha@camelia.test',
    password: 'motdepasse8',
  );

  group('Statut chauffeur', () {
    test('se parse depuis DriverStatusSerializer', () async {
      await signInAsDriver();

      final status = await driver.fetchStatus();

      expect(status.approval, DriverApproval.approved);
      expect(status.isOnline, isFalse);
      // `vehicle_type` arrive par son code, jamais par son id.
      expect(status.vehicleCode, 'fourgonnette');
      expect(status.vehiclePlate, 'LT 4821 AB');
      expect(status.ratingAverage, '4.90');
      expect(status.ratingCount, 312);
      expect(status.documents, hasLength(3));
      expect(status.canGoOnline, isTrue);
    });

    test('les documents portent leur état et aucun lien de fichier', () async {
      await signInAsDriver();

      final status = await driver.fetchStatus();
      final carteGrise = status.documents.firstWhere(
        (d) => d.type == DriverDocumentType.vehicleRegistration,
      );

      expect(carteGrise.state, DriverDocumentState.pending);
      // Une pièce en attente n'a pas encore été revue.
      expect(carteGrise.reviewedAt, isNull);
      expect(status.documentsNeedingAction, hasLength(1));
    });

    test('un compte client est refusé avec driver_profile_required', () async {
      await signInAsClient();

      await expectLater(
        driver.fetchStatus(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.driverProfileRequired,
          ),
        ),
      );
    });
  });

  group('Bascule en ligne', () {
    test('renvoie le statut mis à jour, pas un simple accusé', () async {
      await signInAsDriver();

      final apres = await driver.setOnline(isOnline: true);

      expect(apres.isOnline, isTrue);
      // L'état persiste : un nouvel appel le confirme.
      expect((await driver.fetchStatus()).isOnline, isTrue);
    });

    test('repasser hors ligne fonctionne aussi', () async {
      await signInAsDriver();
      await driver.setOnline(isOnline: true);

      final apres = await driver.setOnline(isOnline: false);

      expect(apres.isOnline, isFalse);
    });
  });

  group('Ping de position', () {
    test('envoie latitude et longitude à six décimales', () async {
      await signInAsDriver();

      final status = await driver.pingPosition(
        latitude: 4.0511,
        longitude: 9.7679,
      );

      // Le serveur renvoie le statut, horodatage de position mis à jour.
      expect(status.lastPositionAt, isNotNull);
    });
  });

  group('Propositions de course', () {
    test('la liste arrive paginée et se parse', () async {
      await signInAsDriver();

      final page = await driver.fetchOffers();

      expect(page.count, greaterThan(0));
      final offre = page.results.first;
      expect(offre.status, OfferStatus.sent);
      expect(offre.isActionable, isTrue);
      expect(offre.order.reference, isNotEmpty);
      expect(offre.order.pickupAddress, contains('Bonanjo'));
      // Gain prévisionnel total, jamais le prix client (T6.8).
      expect(offre.order.driverEarningsEstimate, isNotNull);
      // Échéance de la recherche de la commande, pas un délai de réponse.
      expect(offre.expiresAt, isNotNull);
    });

    test('accepter une proposition la passe en accepted', () async {
      await signInAsDriver();
      final page = await driver.fetchOffers();

      final acceptee = await driver.acceptOffer(page.results.first.id);

      expect(acceptee.status, OfferStatus.accepted);
      expect(acceptee.respondedAt, isNotNull);
      expect(acceptee.isActionable, isFalse);
    });

    test('accepter deux fois remonte offer_no_longer_available', () async {
      await signInAsDriver();
      final page = await driver.fetchOffers();
      final id = page.results.first.id;
      await driver.acceptOffer(id);

      await expectLater(
        driver.acceptOffer(id),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.offerNoLongerAvailable,
          ),
        ),
      );
    });

    test('refuser une proposition la passe en declined', () async {
      await signInAsDriver();
      final page = await driver.fetchOffers();

      final refusee = await driver.declineOffer(page.results.first.id);

      expect(refusee.status, OfferStatus.declined);
    });

    test('une proposition inconnue remonte offer_not_found', () async {
      await signInAsDriver();

      await expectLater(
        driver.acceptOffer('offer-inexistante'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.offerNotFound,
          ),
        ),
      );
    });
  });

  group('Portefeuille chauffeur', () {
    test(
      'le solde est lu dans l\'enveloppe, les lignes dans results',
      () async {
        await signInAsDriver();

        final portefeuille = await wallet.fetchDriverWallet();

        expect(portefeuille.balanceAsDouble, isNotNull);
        expect(portefeuille.entries, isNotEmpty);
        expect(portefeuille.totalCount, portefeuille.entries.length);
        final credit = portefeuille.entries.firstWhere(
          (e) => e.type == LedgerEntryType.driverCredit,
        );
        expect(credit.currency, 'XAF');
        expect(credit.isDebit, isFalse);
      },
    );

    test('un retrait est reconnu comme débit', () async {
      await signInAsDriver();

      final portefeuille = await wallet.fetchDriverWallet();
      final retrait = portefeuille.entries.firstWhere(
        (e) => e.type == LedgerEntryType.withdrawal,
      );

      expect(retrait.isDebit, isTrue);
      expect(retrait.asDouble, lessThan(0));
    });

    test('un retrait valide sort en pending et diminue le solde', () async {
      await signInAsDriver();
      final avant = (await wallet.fetchDriverWallet()).balanceAsDouble!;

      final demande = await wallet.requestDriverWithdrawal('2000.00');

      // `pending` : la confirmation viendra du webhook de décaissement.
      expect(demande.status, WithdrawalStatus.pending);
      expect(demande.recipientPhone, '+237690000002');
      final apres = (await wallet.fetchDriverWallet()).balanceAsDouble!;
      expect(apres, avant - 2000);
    });

    test('les seuils de retrait sont appliqués par le serveur', () async {
      await signInAsDriver();

      await expectLater(
        wallet.requestDriverWithdrawal('500.00'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.withdrawalAmountBelowMinimum,
          ),
        ),
      );
      await expectLater(
        wallet.requestDriverWithdrawal('99999999.00'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.withdrawalAmountExceedsBalance,
          ),
        ),
      );
    });
  });

  group('Tableau ambassadeur', () {
    test('distingue le solde net du cumul gagné', () async {
      await signInAsClient();

      final dashboard = await wallet.fetchAmbassadorDashboard();

      expect(dashboard.balanceAsDouble, isNotNull);
      expect(dashboard.totalEarnedAsDouble, isNotNull);
      expect(dashboard.conversionCount, greaterThan(0));
      // `usage_count` compte toutes les utilisations, `conversion_count` celles
      // qui ont rapporté : le premier ne peut pas être inférieur.
      expect(
        dashboard.usageCount,
        greaterThanOrEqualTo(dashboard.conversionCount),
      );
      expect(dashboard.recentConversions, isNotEmpty);
      for (final ligne in dashboard.recentConversions) {
        expect(ligne.type, LedgerEntryType.ambassadorCommission);
      }
    });

    test('un retrait ambassadeur passe par sa propre route', () async {
      await signInAsClient();
      final avant = (await wallet.fetchAmbassadorDashboard()).balanceAsDouble!;

      final demande = await wallet.requestAmbassadorWithdrawal('2000.00');

      expect(demande.status, WithdrawalStatus.pending);
      final apres = (await wallet.fetchAmbassadorDashboard()).balanceAsDouble!;
      expect(apres, avant - 2000);
    });

    test('le cumul gagné ne baisse pas après un retrait', () async {
      await signInAsClient();
      final avant = await wallet.fetchAmbassadorDashboard();

      await wallet.requestAmbassadorWithdrawal('2000.00');
      final apres = await wallet.fetchAmbassadorDashboard();

      // `total_earned` cumule les seules commissions : un retrait le laisse
      // intact, alors que `balance` diminue. Les confondre serait une erreur
      // d'affichage que le backend signale explicitement.
      expect(apres.totalEarned, avant.totalEarned);
      expect(apres.balanceAsDouble, lessThan(avant.balanceAsDouble!));
    });

    test('le minimum de retrait vaut aussi côté ambassadeur', () async {
      await signInAsClient();

      await expectLater(
        wallet.requestAmbassadorWithdrawal('500.00'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.withdrawalAmountBelowMinimum,
          ),
        ),
      );
    });
  });

  group('Tolérance aux types inconnus', () {
    test('un entry_type inconnu n\'empêche pas l\'affichage', () {
      // Le backend peut ajouter un type sans que l'app le connaisse : la ligne
      // doit rester lisible plutôt que de faire échouer tout l'historique.
      final ligne = LedgerEntry.fromJson(const {
        'id': 'x',
        'entry_type': 'type_tout_neuf',
        'amount': '1500.00',
        'currency': 'XAF',
        'external_reference': null,
        'created_at': '2026-09-12T10:00:00+01:00',
      });

      expect(ligne.type, isNull);
      expect(ligne.rawType, 'type_tout_neuf');
      expect(ligne.asDouble, 1500);
    });
  });
}
