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
  }) : _service = service,
       _order = initial;

  final OrderService _service;
  final String orderId;

  Order? _order;
  bool _loading = false;
  bool _paying = false;
  bool _cancelling = false;
  Object? _failure;
  PaymentInvite? _pendingInvite;
  CancellationResult? _cancellation;
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

  CancellationResult? get cancellation => _cancellation;

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
      if (order.status == OrderStatus.completed) _pendingInvite = null;
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
  Future<PaymentInvite?> pay() async {
    if (busy) return null;
    _paying = true;
    _failure = null;
    notifyListeners();
    try {
      final invite = await _service.confirmDelivery(orderId);
      _pendingInvite = invite;
      return invite;
    } on ApiException catch (e) {
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

  Future<CancellationResult?> cancel() async {
    if (busy) return null;
    _cancelling = true;
    _failure = null;
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
