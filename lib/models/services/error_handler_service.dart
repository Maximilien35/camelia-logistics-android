import 'package:firebase_auth/firebase_auth.dart';
import 'logging_service.dart';

/// Service centralisé pour transformer les erreurs techniques
/// en messages user-friendly en français
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  final LoggingService _loggingService = LoggingService();

  factory ErrorHandlerService() {
    return _instance;
  }

  ErrorHandlerService._internal();

  /// Transforme une exception Firebase Auth en message user-friendly
  /// Log l'erreur technique pour les administrateurs
  String handleFirebaseAuthError(FirebaseAuthException e, {StackTrace? stackTrace}) {
    String userMessage;
    String technicalMessage = '${e.code}: ${e.message}';

    switch (e.code) {
      case 'user-not-found':
        userMessage = 'Cet email n\'est pas associé à un compte. Créez-vous un compte ou vérifiez l\'adresse email.';
        break;
      case 'wrong-password':
        userMessage = 'Mot de passe incorrect. Vérifiez votre saisie.';
        break;
      case 'invalid-email':
        userMessage = 'Adresse email invalide. Vérifiez le format.';
        break;
      case 'user-disabled':
        userMessage = 'Ce compte a été temporairement désactivé. Contactez le support.';
        break;
      case 'account-disabled':
        userMessage = 'Votre compte a été désactivé. Contactez le support pour le réactiver.';
        break;
      case 'email-already-in-use':
        userMessage = 'Cette adresse email est déjà utilisée.';
        break;
      case 'weak-password':
        userMessage = 'Mot de passe trop faible. Utilisez au moins 6 caractères.';
        break;
      case 'operation-not-allowed':
        userMessage = 'Cette méthode d\'authentification n\'est pas disponible.';
        break;
      case 'invalid-verification-code':
        userMessage = 'Code de vérification invalide. Demandez un nouveau code.';
        break;
      case 'invalid-verification-id':
        userMessage = 'Session de vérification expirée. Redémarrez le processus.';
        break;
      case 'too-many-requests':
        userMessage = 'Trop de tentatives. Veuillez patienter avant de réessayer.';
        break;
      case 'network-request-failed':
        userMessage = 'Problème de connexion réseau. Vérifiez votre connexion internet.';
        break;
      case 'invalid-phone-number':
        userMessage = 'Numéro de téléphone invalide. Vérifiez le format.';
        break;
      case 'missing-phone-number':
        userMessage = 'Numéro de téléphone requis.';
        break;
      case 'quota-exceeded':
        userMessage = 'Limite de demandes dépassée. Réessayez plus tard.';
        break;
      case 'captcha-check-failed':
        userMessage = 'Vérification de sécurité échouée. Réessayez.';
        break;
      case 'app-not-authorized':
        userMessage = 'Application non autorisée. Contactez le support.';
        break;
      case 'app-not-verified':
        userMessage = 'Application non vérifiée. Contactez le support.';
        break;
      default:
        userMessage = 'Une erreur est survenue. Veuillez réessayer.';
        break;
    }

    // Log l'erreur technique pour les administrateurs
    _loggingService.logError(
      title: 'Firebase Auth Error',
      technicalMessage: technicalMessage,
      category: 'auth',
      stackTrace: stackTrace,
      additionalContext: {
        'errorCode': e.code,
        'userMessage': userMessage,
      },
    );

    return userMessage;
  }

  /// Transforme une exception Firestore en message user-friendly
  String handleFirestoreError(dynamic e, {StackTrace? stackTrace}) {
    String userMessage;
    String technicalMessage = e.toString();

    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          userMessage = 'Accès non autorisé. Vérifiez vos permissions.';
          break;
        case 'not-found':
          userMessage = 'Données introuvables.';
          break;
        case 'already-exists':
          userMessage = 'Ces données existent déjà.';
          break;
        case 'resource-exhausted':
          userMessage = 'Limite de ressources atteinte. Réessayez plus tard.';
          break;
        case 'failed-precondition':
          userMessage = 'Opération impossible dans l\'état actuel.';
          break;
        case 'aborted':
          userMessage = 'Opération annulée. Réessayez.';
          break;
        case 'out-of-range':
          userMessage = 'Valeur hors limites.';
          break;
        case 'unimplemented':
          userMessage = 'Fonctionnalité non disponible.';
          break;
        case 'internal':
          userMessage = 'Erreur interne. Réessayez plus tard.';
          break;
        case 'unavailable':
          userMessage = 'Service temporairement indisponible. Réessayez.';
          break;
        case 'data-loss':
          userMessage = 'Données corrompues. Contactez le support.';
          break;
        case 'unauthenticated':
          userMessage = 'Authentification requise.';
          break;
        case 'deadline-exceeded':
          userMessage = 'Délai dépassé. Vérifiez votre connexion.';
          break;
        default:
          userMessage = 'Erreur de base de données. Réessayez.';
          break;
      }
    } else {
      userMessage = 'Erreur de base de données. Réessayez.';
    }

    // Log l'erreur technique
    _loggingService.logError(
      title: 'Firestore Error',
      technicalMessage: technicalMessage,
      category: 'firestore',
      stackTrace: stackTrace,
      additionalContext: {
        'errorCode': e is FirebaseException ? e.code : 'unknown',
        'userMessage': userMessage,
      },
    );

    return userMessage;
  }

  /// Transforme une exception Cloud Functions en message user-friendly
  String handleCloudFunctionsError(dynamic e, {StackTrace? stackTrace}) {
    String userMessage;
    String technicalMessage = e.toString();

    if (e is FirebaseException && e.plugin == 'cloud_functions') {
      switch (e.code) {
        case 'cancelled':
          userMessage = 'Opération annulée.';
          break;
        case 'unknown':
          userMessage = 'Erreur inconnue. Réessayez.';
          break;
        case 'invalid-argument':
          userMessage = 'Paramètres invalides.';
          break;
        case 'deadline-exceeded':
          userMessage = 'Délai dépassé. Réessayez.';
          break;
        case 'not-found':
          userMessage = 'Service introuvable.';
          break;
        case 'already-exists':
          userMessage = 'Ressource déjà existante.';
          break;
        case 'permission-denied':
          userMessage = 'Permissions insuffisantes.';
          break;
        case 'resource-exhausted':
          userMessage = 'Limite de ressources atteinte.';
          break;
        case 'failed-precondition':
          userMessage = 'Conditions non remplies.';
          break;
        case 'aborted':
          userMessage = 'Opération interrompue.';
          break;
        case 'out-of-range':
          userMessage = 'Valeur hors limites.';
          break;
        case 'unimplemented':
          userMessage = 'Fonction non implémentée.';
          break;
        case 'internal':
          userMessage = 'Erreur interne. Réessayez plus tard.';
          break;
        case 'unavailable':
          userMessage = 'Service indisponible. Réessayez.';
          break;
        case 'data-loss':
          userMessage = 'Données perdues.';
          break;
        case 'unauthenticated':
          userMessage = 'Authentification requise.';
          break;
        default:
          userMessage = 'Erreur de service. Réessayez.';
          break;
      }
    } else {
      userMessage = 'Erreur de service. Réessayez.';
    }

    // Log l'erreur technique
    _loggingService.logError(
      title: 'Cloud Functions Error',
      technicalMessage: technicalMessage,
      category: 'cloud-functions',
      stackTrace: stackTrace,
      additionalContext: {
        'errorCode': e is FirebaseException && e.plugin == 'cloud_functions' ? e.code : 'unknown',
        'userMessage': userMessage,
      },
    );

    return userMessage;
  }

  /// Transforme une exception réseau en message user-friendly
  String handleNetworkError(dynamic e, {StackTrace? stackTrace}) {
    String userMessage = 'Problème de connexion. Vérifiez votre réseau et réessayez.';
    String technicalMessage = e.toString();

    // Log l'erreur technique
    _loggingService.logError(
      title: 'Network Error',
      technicalMessage: technicalMessage,
      category: 'network',
      stackTrace: stackTrace,
      additionalContext: {
        'userMessage': userMessage,
      },
    );

    return userMessage;
  }

  /// Transforme une exception générique en message user-friendly
  String handleGenericError(dynamic e, {StackTrace? stackTrace, String? context}) {
    String userMessage = 'Une erreur inattendue est survenue. Veuillez réessayer.';
    String technicalMessage = e.toString();

    // Log l'erreur technique
    _loggingService.logError(
      title: 'Generic Error',
      technicalMessage: technicalMessage,
      category: 'generic',
      stackTrace: stackTrace,
      additionalContext: {
        'context': context ?? 'unknown',
        'userMessage': userMessage,
      },
    );

    return userMessage;
  }

  /// Transforme une exception selon son type
  String handleError(dynamic e, {StackTrace? stackTrace, String? context}) {
    if (e is FirebaseAuthException) {
      return handleFirebaseAuthError(e, stackTrace: stackTrace);
    } else if (e is FirebaseException && e.plugin == 'cloud_firestore') {
      return handleFirestoreError(e, stackTrace: stackTrace);
    } else if (e is FirebaseException && e.plugin == 'cloud_functions') {
      return handleCloudFunctionsError(e, stackTrace: stackTrace);
    } else if (e.toString().contains('network') || e.toString().contains('connection')) {
      return handleNetworkError(e, stackTrace: stackTrace);
    } else {
      return handleGenericError(e, stackTrace: stackTrace, context: context);
    }
  }
}