/// État d'un portefeuille : solde, historique, demande de retrait.
///
/// Un seul contrôleur sert les deux portefeuilles réels, qui ont la même forme
/// mais pas les mêmes routes : celui du **chauffeur** et le solde
/// **ambassadeur**. D'où [WalletKind], plutôt que deux classes jumelles.
///
/// **Aucun calcul de montant ici** : le solde vient du serveur, les seuils de
/// retrait y sont appliqués et remontent en codes d'erreur (règles non
/// négociables n°3 et n°4).
library;

import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';

enum WalletKind {
  /// `GET /v1/driver/wallet/` + `POST /v1/driver/wallet/withdraw/`.
  driver,

  /// `GET /v1/me/ambassador-code/` + `POST /v1/me/ambassador-code/withdraw/`.
  ambassador,
}

class WalletController extends ChangeNotifier {
  WalletController({required WalletService service, required this.kind})
    : _service = service;

  final WalletService _service;
  final WalletKind kind;

  String? _balance;
  String? _totalEarned;
  int _usageCount = 0;
  int _conversionCount = 0;
  List<LedgerEntry> _entries = const [];
  bool _loading = false;
  bool _busy = false;
  Object? _failure;
  WithdrawalRequest? _lastWithdrawal;

  /// Solde net disponible, en chaîne telle que le serveur l'a renvoyée.
  String? get balance => _balance;

  /// Cumul historique des commissions — **ambassadeur uniquement**, `null` pour
  /// le portefeuille chauffeur. Ce n'est pas un alias du solde : il ne baisse
  /// jamais, même après un retrait confirmé.
  String? get totalEarned => _totalEarned;

  int get usageCount => _usageCount;
  int get conversionCount => _conversionCount;
  List<LedgerEntry> get entries => _entries;
  bool get loading => _loading;
  bool get busy => _busy;
  Object? get failure => _failure;

  /// Dernière demande de retrait acceptée par le serveur, encore `pending`.
  WithdrawalRequest? get lastWithdrawal => _lastWithdrawal;

  bool get hasLoaded => _balance != null;

  Future<void> refresh() async {
    _loading = true;
    _failure = null;
    notifyListeners();
    try {
      switch (kind) {
        case WalletKind.driver:
          final wallet = await _service.fetchDriverWallet();
          _balance = wallet.balance;
          _entries = wallet.entries;
          // Le portefeuille chauffeur n'expose pas de cumul gagné.
          _totalEarned = null;
        case WalletKind.ambassador:
          final dashboard = await _service.fetchAmbassadorDashboard();
          _balance = dashboard.balance;
          _totalEarned = dashboard.totalEarned;
          _usageCount = dashboard.usageCount;
          _conversionCount = dashboard.conversionCount;
          _entries = dashboard.recentConversions;
      }
    } on ApiException catch (e) {
      _failure = e;
    } on NetworkException catch (e) {
      _failure = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Demande un retrait de [amount], transmis **en chaîne** comme le serveur
  /// l'attend.
  ///
  /// Renvoie `true` si le serveur a accepté la demande — qui reste `pending` :
  /// la confirmation arrive plus tard par le webhook de décaissement. L'UI ne
  /// doit pas annoncer un virement effectué.
  Future<bool> requestWithdrawal(String amount) async {
    _busy = true;
    _failure = null;
    _lastWithdrawal = null;
    notifyListeners();
    try {
      _lastWithdrawal = switch (kind) {
        WalletKind.driver => await _service.requestDriverWithdrawal(amount),
        WalletKind.ambassador => await _service.requestAmbassadorWithdrawal(
          amount,
        ),
      };
      // Le solde a changé côté serveur : on le relit plutôt que de le déduire.
      await refresh();
      return true;
    } on ApiException catch (e) {
      _failure = e;
      return false;
    } on NetworkException catch (e) {
      _failure = e;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void clearFailure() {
    if (_failure == null) return;
    _failure = null;
    notifyListeners();
  }
}
