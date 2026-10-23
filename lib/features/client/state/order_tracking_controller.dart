/// État de l'écran de suivi d'une commande — maquettes « Suivi — Client ».
///
/// **Aucun sondage** (règle non négociable n°5) : la commande se relit à
/// l'ouverture, sur tirage vers le bas, sur le bouton « Actualiser », et plus
/// tard sur notification push. Rien ne tourne en arrière-plan.
///
/// **Paiement** : [pay] n'est appelé que depuis un bouton (règle n°7). Il ne
/// fait qu'obtenir l'invite Mobile Money ; l'issue du paiement arrive au
/// serveur par webhook, et l'écran ne la connaît qu'en relisant la commande.
library;

import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../shared/models/order.dart';
import '../models/order_rating.dart';
import '../models/search_relaunch.dart';
import '../services/order_service.dart';

class OrderTrackingController extends ChangeNotifier {
  OrderTrackingController({
    required OrderService service,
    required this.orderId,
    Order? initial,
    DateTime Function()? clock,
  }) : _service = service,
       _order = initial,
       _clock = clock ?? DateTime.now;

  final OrderService _service;
  final String orderId;
  final DateTime Function() _clock;

  Order? _order;
  bool _loading = false;
  bool _paying = false;
  bool _cancelling = false;
  Object? _failure;
  PaymentInvite? _pendingInvite;
  bool _awaitingValidation = false;
  String? _payerPhone;
  DateTime? _sameNumberRetryAt;
  CancellationResult? _cancellation;
  bool _cancelFeePromptFailed = false;
  OrderRating? _rating;
  bool _ratingBusy = false;
  SearchRelaunchResult? _relaunch;
  bool _relaunching = false;

  Order? get order => _order;
  bool get loading => _loading;
  bool get paying => _paying;
  bool get cancelling => _cancelling;
  bool get busy => _paying || _cancelling;
  Object? get failure => _failure;

  /// Dernière invite de paiement obtenue, tant que la commande n'est pas
  /// relue comme payée (`completed`).
  PaymentInvite? get pendingInvite => _pendingInvite;

  /// Une demande de paiement attend la validation du payeur sur son
  /// téléphone : invite obtenue pendant cette session, ou `409
  /// payment_already_pending` (invite envoyée plus tôt, peut-être depuis un
  /// autre écran). Faux dès que la commande est relue `completed`.
  bool get awaitingValidation => _awaitingValidation;

  /// Numéro auquel la dernière demande a été adressée, s'il est connu.
  String? get payerPhone => _payerPhone;

  /// Heure à partir de laquelle une nouvelle demande vers **le même** numéro
  /// ([payerPhone]) sera acceptée — lue sur `retry_after_seconds` d'un `409
  /// payment_already_pending` (lot 9, § 6.5.1bis). `null` : rien n'empêche de
  /// renvoyer. Un **autre** numéro part toujours immédiatement : c'est ainsi
  /// qu'une faute de frappe se corrige. L'app ne déduit ce délai que de la
  /// réponse du serveur, elle ne le calcule jamais d'avance.
  DateTime? get sameNumberRetryAt {
    final at = _sameNumberRetryAt;
    return at != null && at.isAfter(_clock()) ? at : null;
  }

  CancellationResult? get cancellation => _cancellation;

  /// L'annulation a réussi mais l'invite de paiement des frais n'a pas pu
  /// partir (`502 payment_provider_unavailable` sur `cancel/`, § 7.3.14).
  bool get cancelFeePromptFailed => _cancelFeePromptFailed;

  /// Note déposée pendant cette session, `null` avant.
  OrderRating? get rating => _rating;
  bool get ratingBusy => _ratingBusy;

  /// Résultat de la dernière relance de recherche.
  SearchRelaunchResult? get relaunch => _relaunch;
  bool get relaunching => _relaunching;

  /// Relances encore possibles. `null` tant qu'aucune n'a été tentée : le
  /// plafond est une règle serveur, l'app ne la duplique pas — elle grise le
  /// bouton une fois que le serveur a dit combien il en reste.
  int? get relaunchesRemaining => _relaunch?.relaunchesRemaining;

  Future<void> refresh() async {
    _loading = true;
    _failure = null;
    notifyListeners();
    try {
      final order = await _service.fetchOrder(orderId);
      _order = order;
      if (order.status != OrderStatus.delivered) {
        // Payée, ou passée en litige (relance par le support, § 6.5.8) : plus
        // aucune demande à suivre depuis l'app.
        _pendingInvite = null;
        _awaitingValidation = false;
        _sameNumberRetryAt = null;
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

  /// `confirm-delivery` — **uniquement sur appui explicite** (règle n°7).
  ///
  /// [payerPhone] : numéro Mobile Money choisi par le client (E.164), ou
  /// `null` pour le téléphone du compte. Chaque appui est une nouvelle
  /// **tentative** côté serveur (lot 9) : vers un autre numéro elle part
  /// immédiatement ; vers le même numéro, le serveur peut répondre `409
  /// payment_already_pending` avec le délai à attendre.
  Future<PaymentInvite?> pay({String? payerPhone}) async {
    if (busy) return null;
    _paying = true;
    _failure = null;
    notifyListeners();
    try {
      final invite = await _service.confirmDelivery(
        orderId,
        payerPhone: payerPhone,
      );
      _pendingInvite = invite;
      _awaitingValidation = true;
      _payerPhone = payerPhone;
      _sameNumberRetryAt = null;
      return invite;
    } on ApiException catch (e) {
      // Pas un échec : une invite vers ce numéro attend toujours.
      if (e.code == ApiErrorCode.paymentAlreadyPending) {
        _awaitingValidation = true;
        _payerPhone = payerPhone ?? _payerPhone;
        final seconds = _retryAfterSeconds(e.details['retry_after_seconds']);
        _sameNumberRetryAt = seconds > 0
            ? _clock().add(Duration(seconds: seconds))
            : null;
      }
      _failure = e;
      return null;
    } on NetworkException catch (e) {
      _failure = e;
      return null;
    } finally {
      _paying = false;
      notifyListeners();
    }
  }

  /// Entier attendu ; toléré en chaîne, au cas où un intermédiaire le
  /// convertirait. `0` : une nouvelle demande peut partir tout de suite.
  static int _retryAfterSeconds(Object? raw) => switch (raw) {
    final int s => s,
    final num s => s.ceil(),
    final String s => int.tryParse(s) ?? 0,
    _ => 0,
  };

  /// `POST /v1/orders/{id}/rate/` — **sur appui explicite** d'un bouton.
  ///
  /// Le serveur est seul juge de l'éligibilité : `order_not_ratable`,
  /// `order_already_rated` et `order_has_no_driver_to_rate` sont trois
  /// conflits distincts, que l'écran ne présente pas de la même façon.
  Future<OrderRating?> rate({required int stars, String comment = ''}) async {
    if (_ratingBusy) return null;
    _ratingBusy = true;
    _failure = null;
    notifyListeners();
    try {
      final result = await _service.rateOrder(
        orderId: orderId,
        rating: stars,
        comment: comment,
      );
      _rating = result;
      return result;
    } on ApiException catch (e) {
      _failure = e;
      return null;
    } on NetworkException catch (e) {
      _failure = e;
      return null;
    } finally {
      _ratingBusy = false;
      notifyListeners();
    }
  }

  /// `POST /v1/orders/{id}/relaunch-search/` — corps vide (§ 7.3.13).
  ///
  /// Le prix est recalculé au tarif en vigueur : `price_changed` dit s'il a
  /// bougé, et c'est [order] qui porte le nouveau total. L'app ne compare
  /// aucun montant elle-même (règle n°3).
  Future<SearchRelaunchResult?> relaunchSearch() async {
    if (_relaunching) return null;
    _relaunching = true;
    _failure = null;
    notifyListeners();
    try {
      final result = await _service.relaunchSearch(orderId);
      _relaunch = result;
      _order = result.order;
      // La réponse de relance n'a pas de ruban : on relit le suivi complet.
      try {
        _order = await _service.fetchOrder(orderId);
      } on Exception {
        // Sans gravité : la commande relancée est déjà affichable.
      }
      return result;
    } on ApiException catch (e) {
      _failure = e;
      return null;
    } on NetworkException catch (e) {
      _failure = e;
      return null;
    } finally {
      _relaunching = false;
      notifyListeners();
    }
  }

  /// `cancel/` sans `payer_phone` : des frais éventuels sont demandés au
  /// téléphone du compte. L'app ne sait pas d'avance s'il y en aura — c'est le
  /// serveur qui le décide (§ 6.10bis) — et ne demande donc pas de numéro.
  Future<CancellationResult?> cancel() async {
    if (busy) return null;
    _cancelling = true;
    _failure = null;
    _cancelFeePromptFailed = false;
    notifyListeners();
    try {
      final result = await _service.cancelOrder(orderId);
      _cancellation = result;
      _order = result.order;
      // La réponse d'annulation n'a pas de ruban : on relit le suivi complet
      // pour ne pas afficher un écran à moitié vide.
      try {
        _order = await _service.fetchOrder(orderId);
      } on Exception {
        // Sans gravité : la commande annulée est déjà affichable.
      }
      return result;
    } on ApiException catch (e) {
      // § 7.3.14 : l'annulation est acquise, seule l'invite des frais n'est
      // pas partie. On relit la commande pour afficher son vrai statut, et
      // l'écran le dit en clair plutôt qu'en erreur générique.
      if (e.code == ApiErrorCode.paymentProviderUnavailable) {
        _cancelFeePromptFailed = true;
        try {
          _order = await _service.fetchOrder(orderId);
        } on Exception {
          // L'avertissement suffit ; le tirage vers le bas relira.
        }
        return null;
      }
      _failure = e;
      return null;
    } on NetworkException catch (e) {
      _failure = e;
      return null;
    } finally {
      _cancelling = false;
      notifyListeners();
    }
  }
}
