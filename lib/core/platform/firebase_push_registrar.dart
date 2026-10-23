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
///
/// ## Affichage au premier plan
///
/// App en arrière-plan ou fermée, c'est le système qui affiche la
/// notification. App **ouverte**, ni Android ni iOS ne l'affichent d'eux-mêmes :
/// - iOS : les options de présentation FCM suffisent ;
/// - Android : la notification est redessinée localement, sur
///   [pushChannelId] — le même canal que FCM utilise en arrière-plan
///   (`default_notification_channel_id` dans `AndroidManifest.xml`).
///
/// Le titre et le corps sont ceux du serveur, déjà traduits ; seuls le nom et
/// la description du canal, visibles dans les réglages Android, viennent de
/// l'app.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'push_registrar.dart';

/// Canal Android des notifications Camelia. **Doit rester identique** à la
/// valeur `com.google.firebase.messaging.default_notification_channel_id` de
/// `AndroidManifest.xml`.
const pushChannelId = 'camelia_updates';

/// Libellés du canal Android, résolus dans la langue courante.
typedef PushChannelLabels = ({String name, String description});

class FirebasePushRegistrar implements PushRegistrar {
  FirebasePushRegistrar({
    required PushChannelLabels Function() channelLabels,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _channelLabels = channelLabels,
       _injected = messaging,
       _local = localNotifications ?? FlutterLocalNotificationsPlugin();

  final PushChannelLabels Function() _channelLabels;
  final FirebaseMessaging? _injected;
  final FlutterLocalNotificationsPlugin _local;

  /// `true` une fois le canal Android créé : sans lui, rien n'est redessiné.
  bool _localReady = false;

  /// Touchers sur une notification redessinée au premier plan (Android).
  final _taps = StreamController<PushHint>.broadcast();

  /// Résolu **à la demande**, jamais à la construction : lire
  /// `FirebaseMessaging.instance` sans application Firebase initialisée lève
  /// une exception (initialisation absente ou échouée dans `main_v2.dart`).
  /// Construire ce registre au démarrage ne doit jamais pouvoir faire planter
  /// l'app.
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
      await _prepareForegroundDisplay(messaging);
      return await messaging.getToken();
    } on Object {
      // Firebase absent ou mal configuré sur cet appareil : pas de jeton, pas
      // de notification. Rien d'autre ne doit en souffrir.
      return null;
    }
  }

  /// Rend les notifications visibles app ouverte.
  ///
  /// Un échec ici ne coûte que l'affichage au premier plan : le jeton est
  /// quand même enregistré, et l'écran ouvert se relit quand même.
  Future<void> _prepareForegroundDisplay(FirebaseMessaging messaging) async {
    try {
      if (Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        return;
      }
      if (!Platform.isAndroid) return;

      if (!_localReady) {
        await _local.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          ),
          onDidReceiveNotificationResponse: (response) {
            final payload = response.payload;
            if (payload == null) return;
            final data = jsonDecode(payload);
            if (data is Map<String, dynamic>) {
              _taps.add(PushHint.fromData(data));
            }
          },
        );
      }
      // Rejoué à chaque session : Android met à jour le nom et la description
      // d'un canal existant, ce qui suit un changement de langue.
      final labels = _channelLabels();
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            AndroidNotificationChannel(
              pushChannelId,
              labels.name,
              description: labels.description,
              importance: Importance.high,
            ),
          );
      _localReady = true;
    } on Object {
      // Pas d'affichage au premier plan, rien d'autre de perdu.
    }
  }

  /// Redessine une notification reçue app ouverte (Android seulement).
  Future<void> _showInForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (!Platform.isAndroid || !_localReady || notification == null) return;
    final labels = _channelLabels();
    try {
      await _local.show(
        id: (message.messageId ?? message.sentTime.toString()).hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            pushChannelId,
            labels.name,
            channelDescription: labels.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } on Object {
      // L'écran ouvert se relit quand même via `messages()`.
    }
  }

  @override
  Stream<String> tokenRefreshes() =>
      _messaging?.onTokenRefresh ?? const Stream<String>.empty();

  /// Messages reçus au premier plan, ouverture de l'app depuis une
  /// notification, et toucher d'une notification redessinée au premier plan.
  ///
  /// On ne lit que `data` : le titre et le corps sont affichés tels quels et
  /// ne portent, par contrat, ni prix ni adresse (§ 2.17).
  @override
  Stream<PushHint> messages() {
    if (_messaging == null) return const Stream<PushHint>.empty();
    final controller = StreamController<PushHint>.broadcast();
    final subscriptions = <StreamSubscription<Object>>[
      FirebaseMessaging.onMessage.listen((m) {
        _showInForeground(m);
        controller.add(PushHint.fromData(m.data));
      }),
      FirebaseMessaging.onMessageOpenedApp.listen(
        (m) => controller.add(PushHint.fromData(m.data)),
      ),
      _taps.stream.listen(controller.add),
    ];
    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };
    return controller.stream;
  }
}
