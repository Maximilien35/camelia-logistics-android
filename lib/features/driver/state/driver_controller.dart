/// État de l'expérience chauffeur : statut de validation et propositions.
///
/// `ChangeNotifier` + `provider`, comme le reste du projet.
///
/// **Aucun sondage en boucle** (règle non négociable n°5) : [refresh] est
/// déclenché par l'ouverture de l'écran, un geste de l'utilisateur, ou plus tard
/// une notification push. Rien ne tourne en arrière-plan.
library;

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../models/driver_status.dart';
import '../models/order_offer.dart';
import '../services/driver_service.dart';

class DriverController extends ChangeNotifier {
  DriverController({required DriverService service}) : _service = service;

  final DriverService _service;

  DriverStatus? _status;
  List<OrderOffer> _offers = const [];
  bool _loading = false;
  bool _busy = false;
  Object? _failure;

  /// Identifiant de l'offre en cours de traitement, pour n'animer que sa carte.
  String? _pendingOfferId;

  /// Pièce en cours d'envoi, pour n'animer que sa ligne.
  DriverDocumentType? _uploadingDocument;

  DriverStatus? get status => _status;
  List<OrderOffer> get offers => _offers;

  /// Chargement initial ou rafraîchissement complet.
  bool get loading => _loading;

  /// Une action est en cours (bascule en ligne, réponse à une offre).
  bool get busy => _busy;

  Object? get failure => _failure;
  String? get pendingOfferId => _pendingOfferId;
  DriverDocumentType? get uploadingDocument => _uploadingDocument;

  /// `true` avant le premier chargement réussi.
  bool get isEmpty => _status == null;

  /// Propositions encore répondables, les seules à afficher comme actionnables.
  List<OrderOffer> get actionableOffers =>
      _offers.where((o) => o.isActionable).toList(growable: false);

  /// Charge statut **et** propositions.
  ///
  /// Les deux appels partent en parallèle : ils sont indépendants et l'écran les
  /// affiche ensemble.
  Future<void> refresh() async {
    _loading = true;
    _failure = null;
    notifyListeners();
    try {
      // Les deux requêtes partent ensemble puis sont attendues séparément :
      // `Future.wait` sur des types différents rendrait une `List<Object>`
      // qu'il faudrait recaster à l'aveugle.
      final statusFuture = _service.fetchStatus();
      final offersFuture = _service.fetchOffers();
      _status = await statusFuture;
      _offers = (await offersFuture).results;
    } on ApiException catch (e) {
      _failure = e;
    } on NetworkException catch (e) {
      _failure = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Bascule la disponibilité.
  ///
  /// Le statut affiché vient de la **réponse du serveur**, jamais de la valeur
  /// qu'on espérait : un compte non approuvé reçoit `driver_not_approved` et
  /// reste hors ligne.
  Future<bool> toggleOnline(bool isOnline) => _run(() async {
    _status = await _service.setOnline(isOnline: isOnline);
  });

  /// Dépose une pièce (`POST /v1/driver/documents/`), puis relit le statut.
  ///
  /// Le statut du compte et l'état de chaque pièce viennent de la **réponse du
  /// serveur** : c'est lui qui bascule le profil en `pending_review` quand les
  /// trois pièces sont là, l'app ne le déduit pas.
  Future<bool> uploadDocument(DriverDocumentType type, ApiFileField photo) =>
      _run(() async {
        _uploadingDocument = type;
        notifyListeners();
        try {
          await _service.uploadDocument(
            type: type,
            bytes: photo.bytes,
            filename: photo.filename,
            contentType: photo.contentType,
          );
          // La pièce est acquise côté serveur : un échec de relecture ne doit
          // pas la faire passer pour perdue. Le prochain tirage la remontera.
          try {
            _status = await _service.fetchStatus();
          } on Exception {
            // Volontairement ignoré, voir ci-dessus.
          }
        } finally {
          _uploadingDocument = null;
        }
      });

  /// Accepte une proposition, puis recharge la liste.
  ///
  /// Le rechargement n'est pas cosmétique : accepter une course change aussi le
  /// statut des autres propositions côté serveur.
  ///
  /// Renvoie l'offre **telle que renvoyée par le serveur**, seule source du
  /// résumé de course une fois l'offre sortie de `GET /driver/offers/`.
  Future<OrderOffer?> acceptOffer(String offerId) async {
    OrderOffer? accepted;
    final ok = await _run(() async {
      _pendingOfferId = offerId;
      accepted = await _service.acceptOffer(offerId);
      // L'acceptation est acquise côté serveur : un échec du rechargement ne
      // doit pas faire perdre la course. La liste se rafraîchira au prochain
      // tirage.
      try {
        await _reloadOffers();
      } on Exception {
        _offers = _offers.where((o) => o.id != offerId).toList();
      }
    }, offerId: offerId);
    return ok ? accepted : null;
  }

  /// Refuse une proposition, puis recharge la liste.
  Future<bool> declineOffer(String offerId) => _run(() async {
    _pendingOfferId = offerId;
    await _service.declineOffer(offerId);
    await _reloadOffers();
  }, offerId: offerId);

  void clearFailure() {
    if (_failure == null) return;
    _failure = null;
    notifyListeners();
  }

  Future<void> _reloadOffers() async {
    final page = await _service.fetchOffers();
    _offers = page.results;
  }

  Future<bool> _run(Future<void> Function() action, {String? offerId}) async {
    _busy = true;
    _failure = null;
    _pendingOfferId = offerId;
    notifyListeners();
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      _failure = e;
      return false;
    } on NetworkException catch (e) {
      _failure = e;
      return false;
    } finally {
      _busy = false;
      _pendingOfferId = null;
      notifyListeners();
    }
  }
}
