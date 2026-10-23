/// Enregistrement de l'appareil auprès du backend pour les notifications
/// push — § 7.7, T5.2.
///
/// ## Pourquoi c'est structurant
///
/// La règle non négociable n°5 interdit toute connexion persistante : l'app ne
/// sonde rien et ne garde aucun canal ouvert. Elle est **réveillée** par une
/// notification, puis relit la ressource par un `GET`. Sans cet
/// enregistrement, un chauffeur n'apprend pas qu'une course l'attend et un
/// client n'apprend pas qu'il doit payer — sauf à tirer l'écran vers le bas.
///
/// ## Ce que le serveur envoie, et ce qu'on en fait
///
/// Chaque message porte un **titre et un corps fixes**, génériques et traduits
/// côté serveur, plus un type d'événement et un identifiant. Jamais de prix,
/// d'adresse ni de nom (§ 2.17). On ne construit donc aucun affichage à partir
/// de la charge utile : elle sert uniquement à savoir **quoi relire**.
///
/// ## Contrat de cette couche
///
/// [PushRegistrar] est une abstraction volontaire : le mode simulé et les
/// tests n'ont pas à embarquer Firebase, et aucun écran ne connaît jamais
/// `firebase_messaging`. L'implémentation réelle vit dans
/// `firebase_push_registrar.dart`.
library;

/// Plateformes acceptées par `POST /v1/me/devices/`.
///
/// Redéclaré ici plutôt qu'importé du service : cette couche ne connaît que la
/// notion d'appareil, pas la forme de l'API.
enum PushPlatform { ios, android }

/// Ce qu'une notification apprend à l'app : **quoi relire**, rien de plus.
class PushHint {
  const PushHint({required this.event, this.orderId, this.offerId});

  /// Type d'événement, tel que le serveur le nomme. L'app ne s'en sert que
  /// pour décider quelle ressource relire.
  final String event;

  final String? orderId;
  final String? offerId;

  /// Campagne ou push de test du back-office (§ 7.7.3, lot 10) : un toucher
  /// ouvre simplement l'app, rien n'est à relire. Une campagne part par lots
  /// de 500 : relire sur chacune ferait arriver des centaines d'appels en même
  /// temps, pour rien.
  bool get isInformational =>
      const {'campaign', 'campaign.test', 'admin.test'}.contains(event);

  /// Clés relevées dans `notifications/services.py` côté backend : `event`
  /// toujours, `order_id` sur un changement de statut, `offer_id` sur une
  /// offre chauffeur.
  factory PushHint.fromData(Map<String, dynamic> data) => PushHint(
    event: (data['event'] ?? '').toString(),
    orderId: data['order_id']?.toString(),
    offerId: data['offer_id']?.toString(),
  );
}

/// Source de jetons d'appareil et de notifications reçues.
abstract interface class PushRegistrar {
  /// Demande l'autorisation si besoin et rend le jeton de cet appareil.
  ///
  /// `null` si l'utilisateur a refusé, ou si la plateforme n'en fournit pas :
  /// **ce n'est jamais un blocage**, l'app reste utilisable avec le
  /// rafraîchissement manuel.
  Future<String?> token();

  /// Plateforme courante, pour le champ `platform` du serveur.
  PushPlatform get platform;

  /// Jeton renouvelé par le système : il faut le réenregistrer, sinon les
  /// notifications cessent d'arriver sans que rien ne le signale.
  Stream<String> tokenRefreshes();

  /// Notifications reçues, application au premier plan ou ouverte depuis une
  /// notification.
  Stream<PushHint> messages();
}

/// Implémentation inerte : aucun jeton, aucun message.
///
/// Sert au mode simulé et aux tests. L'app se comporte alors exactement comme
/// sur un appareil dont l'utilisateur a refusé les notifications — cas réel
/// qu'il faut de toute façon savoir traiter.
class NoPushRegistrar implements PushRegistrar {
  const NoPushRegistrar({this.platform = PushPlatform.android});

  @override
  final PushPlatform platform;

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> tokenRefreshes() => const Stream<String>.empty();

  @override
  Stream<PushHint> messages() => const Stream<PushHint>.empty();
}
