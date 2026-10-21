/// Course en cours du chauffeur — maquettes « App chauffeur — Course » 2 à 6.
///
/// Enchaînement réel du backend, et rien d'autre :
///
/// | Étape app | Statut serveur | Geste | Endpoint |
/// |---|---|---|---|
/// | Vers la collecte | `driver_en_route_pickup` | photo du colis | `pickup-proof/` |
/// | Vers la livraison | `in_transit` | photo + **code à 4 chiffres** | `delivery-proof/` |
/// | Livrée | `delivered` | — | *(le client paie)* |
///
/// Les étapes « Je suis arrivé » de la maquette n'ont **pas** de transition
/// serveur (aucun statut « chauffeur sur place ») : elles ouvrent l'écran de
/// preuve, elles n'envoient rien.
///
/// ## Le serveur est la source, l'appareil n'est qu'un repli
///
/// Depuis T5.1, [CourseController.refresh] relit la course auprès de
/// `GET /v1/driver/orders/current/`. Le stockage local sert à afficher quelque
/// chose immédiatement et hors ligne ; il est écrasé dès que le serveur
/// répond. Une commande annulée par le client disparaît donc d'elle-même de la
/// liste des courses actives, sans attendre le prochain geste.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../shared/models/order.dart';
import '../models/driver_earnings.dart';
import '../models/order_offer.dart';
import '../services/driver_service.dart';
import '../services/position_reporter.dart';
import 'current_course_store.dart';

enum CourseStage { toPickup, toDropoff, finished, unknown }

class CourseController extends ChangeNotifier {
  CourseController({
    required DriverService service,
    required CurrentCourseStore store,
    required PositionReporter positions,
    required this.userId,
  }) : _service = service,
       _store = store,
       _positions = positions;

  final DriverService _service;
  final CurrentCourseStore _store;
  final PositionReporter _positions;
  final String userId;

  CurrentCourse? _course;

  /// Dernière réponse **complète** du serveur, gardée en mémoire seulement.
  ///
  /// La copie persistée ([CurrentCourse]) est volontairement amputée de ce
  /// qui périme — numéros de téléphone, URL signées. L'écran lit donc cette
  /// version-ci tant qu'elle existe, et ne retombe sur la copie réduite que
  /// hors ligne, avant la première relecture.
  Order? _liveOrder;
  OrderDriverEarnings? _earnings;
  bool _submitting = false;
  bool _refreshing = false;
  Object? _failure;

  CurrentCourse? get course => _course;
  bool get hasCourse => _course != null;
  bool get submitting => _submitting;
  bool get refreshing => _refreshing;
  Object? get failure => _failure;

  /// Commande telle que le serveur l'a rendue en dernier.
  Order? get order => _liveOrder ?? _course?.order;

  /// Gain de la course — `GET /v1/driver/orders/{id}/earnings/` (§ 7.4.5).
  ///
  /// `null` tant que la relecture n'a pas abouti : on affiche alors le gain
  /// prévisionnel conservé de l'offre, jamais un montant reconstruit.
  OrderDriverEarnings? get earnings => _earnings;

  /// Montant à afficher : le fait comptable s'il est connu, sinon la prévision
  /// de l'offre. **Jamais une addition ni une différence** (règle n°3).
  String? get earningsAmount => _earnings?.amount ?? _course?.earningsEstimate;

  /// `true` quand le montant affiché n'est qu'une prévision.
  bool get earningsAreEstimated => _earnings?.isEstimate ?? true;

  CourseStage get stage => switch (_course?.status) {
    null => CourseStage.unknown,
    OrderStatus.driverAssigned ||
    OrderStatus.driverEnRoutePickup => CourseStage.toPickup,
    OrderStatus.pickedUp || OrderStatus.inTransit => CourseStage.toDropoff,
    OrderStatus.delivered || OrderStatus.completed => CourseStage.finished,
    _ => CourseStage.unknown,
  };

  /// Le serveur a signalé que la course n'est plus celle qu'on croit
  /// (annulée par le client, réassignée) : l'écran propose de la libérer.
  bool get isStale {
    final f = _failure;
    return f is ApiException &&
        (f.code == ApiErrorCode.invalidOrderTransition ||
            f.code == ApiErrorCode.driverNotAssignedToOrder ||
            f.statusCode == 404);
  }

  /// Une annulation client **après collecte** laisse un colis à rendre : le
  /// serveur attend alors `confirm-return/`. On ne le devine pas — c'est
  /// [confirmReturn] qui tranche, et `return_not_required` dit que non.
  bool get mayNeedReturn {
    final f = _failure;
    return f is ApiException && f.code == ApiErrorCode.invalidOrderTransition;
  }

  /// Affiche d'abord ce que l'appareil a gardé, puis relit le serveur.
  Future<void> load() async {
    _course = await _store.read(userId);
    notifyListeners();
    await refresh();
  }

  /// `GET /v1/driver/orders/current/` — la course telle que le serveur la voit.
  ///
  /// Aucune course active côté serveur : on libère l'appareil. C'est ce qui
  /// remplace le pis-aller d'avant T5.1, où une annulation client n'était
  /// découverte qu'au geste suivant.
  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    notifyListeners();
    try {
      final page = await _service.fetchCurrentOrders();
      final known = _course?.orderId;
      final match = page.results.where((o) => o.id == known).firstOrNull;
      final active = match ?? page.results.firstOrNull;
      if (active == null) {
        // Plus rien à faire : course terminée côté serveur, ou annulée.
        await release();
        return;
      }
      final base =
          _course ??
          CurrentCourse(
            orderJson: active.toJson(),
            acceptedAt: active.createdAt,
          );
      final updated = base.withOrder(active);
      _course = updated;
      _liveOrder = active;
      _failure = null;
      await _store.save(userId, updated);
      unawaited(_loadEarnings(active.id));
    } on ApiException catch (e) {
      _failure = e;
    } on NetworkException catch (e) {
      // Hors ligne : on garde ce que l'appareil sait, sans rien inventer.
      _failure = e;
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  /// Démarre la course à partir de l'offre **renvoyée par le serveur** à
  /// l'acceptation, puis relit immédiatement : le résumé d'offre ne porte ni
  /// destinataire, ni ruban, ni numéro du client.
  Future<void> startFrom(OrderOffer accepted) async {
    final course = CurrentCourse.accepted(accepted);
    _course = course;
    _liveOrder = null;
    _earnings = null;
    _failure = null;
    await _store.save(userId, course);
    notifyListeners();
    // Position à jour pour la future preuve de collecte ; sans attente.
    unawaited(_positions.reportOnce());
    await refresh();
  }

  Future<bool> confirmPickup(ApiFileField photo) => _submit(() async {
    await _positions.reportOnce();
    return _service.submitPickupProof(orderId: _course!.orderId, photo: photo);
  });

  /// [deliveryCode] est dicté par le destinataire, qui le lit sur l'écran de
  /// suivi du client — l'app chauffeur ne le connaît jamais à l'avance.
  Future<bool> confirmDelivery(
    ApiFileField photo, {
    required String deliveryCode,
    String? recipientSignatureName,
  }) => _submit(() async {
    await _positions.reportOnce();
    return _service.submitDeliveryProof(
      orderId: _course!.orderId,
      photo: photo,
      deliveryCode: deliveryCode,
      recipientSignatureName: recipientSignatureName,
    );
  });

  /// `POST /v1/orders/{id}/confirm-return/` — colis rendu au point de collecte
  /// après une annulation post-collecte.
  Future<bool> confirmReturn(ApiFileField photo) => _submit(
    () => _service.confirmReturn(orderId: _course!.orderId, photo: photo),
  );

  /// `POST /v1/orders/{id}/delivery-code-unavailable/` — le destinataire n'a
  /// pas le code.
  ///
  /// Ouvre une alerte au support et **rien d'autre** : aucune transition,
  /// aucun code révélé. La course reste `in_transit`.
  Future<bool> reportDeliveryCodeUnavailable() async {
    final current = _course;
    if (current == null || _submitting) return false;
    _submitting = true;
    _failure = null;
    notifyListeners();
    try {
      await _service.reportDeliveryCodeUnavailable(current.orderId);
      return true;
    } on ApiException catch (e) {
      _failure = e;
      return false;
    } on NetworkException catch (e) {
      _failure = e;
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  /// Libère la course côté appareil. N'appelle aucun endpoint : la course
  /// n'existe plus côté serveur, ou n'est plus la nôtre.
  Future<void> release() async {
    _course = null;
    _liveOrder = null;
    _earnings = null;
    _failure = null;
    await _store.clear(userId);
    notifyListeners();
  }

  void clearFailure() {
    if (_failure == null) return;
    _failure = null;
    notifyListeners();
  }

  Future<void> _loadEarnings(String orderId) async {
    try {
      final value = await _service.fetchOrderEarnings(orderId);
      _earnings = value;
      notifyListeners();
    } on ApiException {
      // Le gain n'est qu'un affichage : son absence ne casse pas la course.
    } on NetworkException {
      // Idem.
    }
  }

  Future<bool> _submit(Future<Order> Function() send) async {
    if (_course == null || _submitting) return false;
    _submitting = true;
    _failure = null;
    notifyListeners();
    try {
      final order = await send();
      final updated = _course!.withOrder(order);
      _course = updated;
      _liveOrder = order;
      await _store.save(userId, updated);
      unawaited(_loadEarnings(order.id));
      return true;
    } on ApiException catch (e) {
      _failure = e;
      return false;
    } on NetworkException catch (e) {
      _failure = e;
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
