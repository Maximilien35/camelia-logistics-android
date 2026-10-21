/// Service du domaine `payments` : portefeuille chauffeur, tableau ambassadeur,
/// demandes de retrait.
///
/// Routes et champs vérifiés dans `payments/urls.py` et
/// `payments/serializers.py` — voir `docs/backend-contract.md`.
///
/// **Aucun montant n'est calculé ici.** Le solde vient du serveur, les seuils de
/// retrait (minimum 2000 FCFA, plafond au solde disponible) sont appliqués par le
/// serveur et remontent en codes d'erreur. L'app transmet une intention et
/// affiche un résultat (règles non négociables n°3 et n°4).
library;

import '../../../core/api/api_client.dart';
import '../models/wallet.dart';

class WalletService {
  WalletService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// `GET /v1/driver/wallet/` — historique paginé **et** solde.
  ///
  /// Le solde est injecté par le serveur dans l'enveloppe de pagination, à côté
  /// de `results` : on le lit donc dans [PaginatedResponse.envelope], pas dans
  /// les lignes.
  Future<DriverWallet> fetchDriverWallet({int? page, int? pageSize}) async {
    final response = await _client.getPage(
      'driver/wallet',
      LedgerEntry.fromJson,
      page: page,
      pageSize: pageSize,
    );
    return DriverWallet(
      balance: response.envelope['balance']?.toString() ?? '0',
      entries: response.results,
      totalCount: response.count,
      hasMore: response.hasNext,
    );
  }

  /// `POST /v1/driver/wallet/withdraw/` — demande de retrait.
  ///
  /// [amount] est transmis **en chaîne**, comme le `DecimalField` attendu : un
  /// `double` formaté à la volée risquerait une représentation inattendue sur un
  /// montant d'argent.
  ///
  /// Le résultat est `pending` : la confirmation arrive plus tard par le webhook
  /// de décaissement. Ne pas annoncer un virement effectué.
  Future<WithdrawalRequest> requestDriverWithdrawal(String amount) async =>
      WithdrawalRequest.fromJson(
        await _client.post('driver/wallet/withdraw', body: {'amount': amount}),
      );

  /// `GET /v1/me/ambassador-code/` — tableau de bord ambassadeur.
  ///
  /// Accessible à tout compte authentifié, client comme chauffeur.
  Future<AmbassadorDashboard> fetchAmbassadorDashboard() async =>
      AmbassadorDashboard.fromJson(await _client.get('me/ambassador-code'));

  /// `POST /v1/me/ambassador-code/withdraw/` — retrait du solde ambassadeur.
  Future<WithdrawalRequest> requestAmbassadorWithdrawal(String amount) async =>
      WithdrawalRequest.fromJson(
        await _client.post(
          'me/ambassador-code/withdraw',
          body: {'amount': amount},
        ),
      );
}
