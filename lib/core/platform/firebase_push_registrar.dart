/// [PushRegistrar] appuyé sur Firebase Cloud Messaging — le canal que le
/// backend branche côté serveur (§ 7.7, T5.2).
///
/// C'est le **seul** fichier de l'app qui connaît `firebase_messaging` : les
/// écrans et les services ne voient que l'abstraction. Une panne de Firebase
/// se traduit donc par « pas de jeton », cas déjà prévu — jamais par un écran
/// cassé.
///
/// **Aucune permission demandée au lancement à froid** : `requestPermission`
/// n'est appelé qu'une fois la session ouverte, au moment où l'app a une
/// raison de notifier (une commande, une course). Même principe que la
/// géolocalisation de l'écran A4.
library;

import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_registrar.dart';

class FirebasePushRegistrar implements PushRegistrar {
  FirebasePushRegistrar({FirebaseMessaging? messaging}) : _injected = messaging;

  final FirebaseMessaging? _injected;

  /// Résolu **à la demande**, jamais à la construction : `main_v2.dart`
  /// n'initialise pas Firebase, et lire `FirebaseMessaging.instance` sans
  /// application Firebase initialisée lève une exception. Construire ce
  /// registre au démarrage ne doit jamais pouvoir faire planter l'app.
  FirebaseMessaging? get _messaging {
    if (_injected != null) return _injected;
    try {
      return FirebaseMessaging.instance;
    } on Object {
      return null;
    }
  }

  @override
  PushPlatform get platform =>
      Platform.isIOS ? PushPlatform.ios : PushPlatform.android;

  @override
  Future<String?> token() async {
    final messaging = _messaging;
    if (messaging == null) return null;
    try {
      final settings = await messaging.requestPermission();
      // Refus de l'utilisateur : l'app reste entièrement utilisable, avec le
      // rafraîchissement manuel. On ne réinsiste pas.
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }
      return await messaging.getToken();
    } on Object {
      // Firebase absent ou mal configuré sur cet appareil : pas de jeton, pas
      // de notification. Rien d'autre ne doit en souffrir.
      return null;
    }
  }

  @override
  Stream<String> tokenRefreshes() =>
      _messaging?.onTokenRefresh ?? const Stream<String>.empty();

  /// Messages reçus au premier plan **et** ouverture de l'app depuis une
  /// notification.
  ///
  /// On ne lit que `data` : le titre et le corps sont affichés par le système
  /// et ne portent, par contrat, ni prix ni adresse (§ 2.17).
  @override
  Stream<PushHint> messages() {
    if (_messaging == null) return const Stream<PushHint>.empty();
    final controller = StreamController<PushHint>.broadcast();
    final subscriptions = <StreamSubscription<RemoteMessage>>[
      FirebaseMessaging.onMessage.listen(
        (m) => controller.add(PushHint.fromData(m.data)),
      ),
      FirebaseMessaging.onMessageOpenedApp.listen(
        (m) => controller.add(PushHint.fromData(m.data)),
      ),
    ];
    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };
    return controller.stream;
  }
}
