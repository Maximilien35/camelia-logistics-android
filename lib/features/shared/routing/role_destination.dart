/// Aiguillage Client / Chauffeur après authentification.
///
/// CLAUDE.md § Architecture, règle non négociable de ce projet :
///
/// > Le routage vers l'expérience Client ou Chauffeur se fait **uniquement** à
/// > partir de la valeur `role` renvoyée par le serveur à la connexion — jamais
/// > un choix local, un drapeau stocké sans validation serveur, ni un simple
/// > interrupteur dans les réglages.
///
/// Une seule app, un seul `applicationId`, un seul build : c'est ce fichier qui
/// décide quelle expérience s'ouvre. La décision est **dérivée**, jamais
/// mémorisée : elle se recalcule depuis le [AppUser] renvoyé par
/// `GET /v1/me/`, à chaque démarrage de session.
///
/// Point resté ouvert côté backend (`10-points-en-attente.md`, point 11) : un
/// même numéro peut-il être à la fois client et chauffeur ? Non tranché. D'ici
/// là **un compte a un seul rôle actif**, et aucune bascule « changer de mode »
/// n'existe dans l'app — d'où l'absence de tout setter ici.
library;

import '../models/app_user.dart';

/// Expérience à ouvrir pour un compte donné.
enum RoleDestination {
  /// Parcours client : commande, suivi, compte.
  client,

  /// Parcours chauffeur : statut, offres, courses, gains.
  driver,

  /// Compte `admin` : aucune expérience mobile.
  ///
  /// Le back-office est une application web distincte. L'app doit l'annoncer
  /// clairement plutôt que d'ouvrir un parcours client à moitié vide ou de
  /// laisser un écran blanc.
  unsupported,
}

/// Traduit le rôle serveur en expérience à ouvrir.
///
/// Pure fonction, sans état : testable, et impossible à contourner par un
/// réglage local.
RoleDestination destinationForRole(UserRole role) => switch (role) {
  UserRole.client => RoleDestination.client,
  UserRole.driver => RoleDestination.driver,
  UserRole.admin => RoleDestination.unsupported,
};

/// Expérience à ouvrir pour l'utilisateur connecté.
///
/// [user] est `null` quand aucune session n'est ouverte — l'appelant envoie
/// alors vers l'authentification, qui ne dépend d'aucun rôle.
RoleDestination? destinationForUser(AppUser? user) =>
    user == null ? null : destinationForRole(user.role);
