/// Cycle de vie de l'enregistrement push, calé sur la session — § 7.7, T5.2.
///
/// | Moment | Geste |
/// |---|---|
/// | Session ouverte | jeton obtenu, puis `POST /v1/me/devices/` |
/// | Jeton renouvelé par le système | réenregistrement du nouveau jeton |
/// | Déconnexion | `DELETE /v1/me/devices/{token}/` |
///
/// `POST /v1/me/devices/` est un **upsert par jeton** (`201` à la création,
/// `200` à la mise à jour) : rejouer l'enregistrement à chaque ouverture de
/// session est donc sans risque, et c'est ce qu'on fait.
///
/// Le désenregistrement à la déconnexion n'est pas une politesse : sans lui,
/// le compte suivant sur le même téléphone recevrait les notifications du
/// précédent.
///
/// **Rien de tout cela ne peut bloquer l'app.** Un refus de permission, une
/// panne de Firebase, un `404` sur le désenregistrement : on continue, avec le
/// rafraîchissement manuel partout. C'est un cas réel qu'il faut savoir
/// traiter, pas une erreur à afficher.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/platform/push_registrar.dart';
import '../services/device_service.dart';

class PushController extends ChangeNotifier {
  PushController({
    required PushRegistrar registrar,
    required DeviceService service,
  }) : _registrar = registrar,
       _service = service;

  final PushRegistrar _registrar;
  final DeviceService _service;

  String? _token;
  StreamSubscription<String>? _refreshes;
  StreamSubscription<PushHint>? _messages;

  /// Dernière notification reçue, pour que l'écran ouvert décide s'il doit se
  /// relire. L'app ne se sert **que** de l'identifiant : le contenu affiché
  /// vient toujours d'un `GET`.
  PushHint? _lastHint;
  PushHint? get lastHint => _lastHint;

  /// `true` quand cet appareil est enregistré auprès du serveur.
  bool get isRegistered => _token != null;

  /// À appeler dès qu'une session est ouverte.
  Future<void> attach() async {
    if (_token != null) return;
    final token = await _registrar.token();
    if (token == null) return; // Permission refusée : rien de plus à faire.
    await _register(token);

    _refreshes ??= _registrar.tokenRefreshes().listen((next) async {
      // Un jeton renouvelé et non réenregistré coupe les notifications sans
      // rien signaler : c'est le cas qu'on protège ici.
      if (next == _token) return;
      await _unregister();
      await _register(next);
    });

    _messages ??= _registrar.messages().listen((hint) {
      if (hint.isInformational) return;
      _lastHint = hint;
      notifyListeners();
    });
  }

  /// À appeler à la déconnexion, **avant** que les jetons d'accès soient
  /// effacés — sans quoi l'appel partirait sans autorisation.
  Future<void> detach() async {
    await _unregister();
    await _refreshes?.cancel();
    await _messages?.cancel();
    _refreshes = null;
    _messages = null;
    _lastHint = null;
  }

  Future<void> _register(String token) async {
    try {
      await _service.register(
        token: token,
        platform: switch (_registrar.platform) {
          PushPlatform.ios => DevicePlatform.ios,
          PushPlatform.android => DevicePlatform.android,
        },
      );
      _token = token;
      notifyListeners();
    } on Object {
      // Échec d'enregistrement : pas de notification, mais l'app fonctionne.
      _token = null;
    }
  }

  Future<void> _unregister() async {
    final token = _token;
    if (token == null) return;
    _token = null;
    try {
      await _service.unregister(token);
    } on Object {
      // `404` sur un jeton qui n'est pas le nôtre : déjà le résultat voulu.
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshes?.cancel();
    _messages?.cancel();
    super.dispose();
  }
}
