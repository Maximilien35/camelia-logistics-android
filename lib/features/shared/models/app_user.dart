/// Utilisateur authentifié, tel que renvoyé par `GET /v1/me/`.
///
/// Contrat vérifié dans `accounts/serializers.py` (`MeSerializer`) : tous les
/// champs sont en **lecture seule**, et seule la langue est modifiable, par
/// `PATCH /v1/me/ {language}` (`MeUpdateSerializer`).
library;

/// Rôle du compte, renvoyé par le serveur.
///
/// **Le routage vers l'expérience Client ou Chauffeur se fait uniquement à
/// partir de cette valeur** (CLAUDE.md § Architecture) — jamais un choix local,
/// jamais un drapeau stocké sans validation serveur, jamais un interrupteur
/// dans les réglages.
enum UserRole {
  client('client'),
  driver('driver'),

  /// Hors périmètre de l'app mobile : le back-office est une application web.
  /// Un compte `admin` qui se connecte ici n'a pas d'expérience dédiée.
  admin('admin');

  const UserRole(this.wire);

  /// Valeur littérale échangée avec l'API (`accounts.models.User.Role`).
  final String wire;

  /// Lit un rôle du serveur.
  ///
  /// Lève si la valeur est inconnue : un rôle non reconnu ne doit **pas**
  /// retomber silencieusement sur `client`, ce qui donnerait à un compte une
  /// expérience que le serveur ne lui a pas attribuée.
  static UserRole fromWire(String value) {
    for (final role in UserRole.values) {
      if (role.wire == value) return role;
    }
    throw ArgumentError.value(value, 'role', 'Rôle inconnu du serveur');
  }
}

/// Langue de l'interface, persistée côté serveur (`accounts.models.User.Language`).
enum AppLanguage {
  fr('fr'),
  en('en');

  const AppLanguage(this.wire);

  final String wire;

  static AppLanguage fromWire(String value) =>
      AppLanguage.values.firstWhere((l) => l.wire == value, orElse: () => fr);
}

/// Profil de l'utilisateur connecté.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.language,
    required this.emailVerified,
    required this.createdAt,
  });

  final String id;
  final String email;

  /// Numéro au format E.164 (`^\+[1-9]\d{7,14}$` côté serveur).
  ///
  /// C'est une donnée de **profil**, pas un identifiant de connexion : le
  /// backend authentifie par email (voir `docs/design-api-map.md` § 1).
  final String phone;
  final String firstName;
  final String lastName;
  final UserRole role;
  final AppLanguage language;
  final bool emailVerified;
  final DateTime createdAt;

  String get fullName => '$firstName $lastName'.trim();

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'].toString(),
    email: json['email'] as String,
    phone: (json['phone'] as String?) ?? '',
    firstName: (json['first_name'] as String?) ?? '',
    lastName: (json['last_name'] as String?) ?? '',
    role: UserRole.fromWire(json['role'] as String),
    language: AppLanguage.fromWire((json['language'] as String?) ?? 'fr'),
    emailVerified: (json['email_verified'] as bool?) ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  /// Aucun `toJson` complet : `/me/` est en lecture seule. Seule la langue
  /// s'écrit, et c'est le corps exact attendu par `PATCH /v1/me/`.
  static Map<String, dynamic> languageUpdateBody(AppLanguage language) => {
    'language': language.wire,
  };

  @override
  String toString() => 'AppUser($id, role: ${role.wire})';
}
