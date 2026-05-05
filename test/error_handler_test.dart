import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Simple transformation handler for testing without Firebase initialization
class TestErrorHandlerService {
  /// Transforme une exception Firebase Auth en message user-friendly
  String handleFirebaseAuthError(FirebaseAuthException e) {
    String userMessage;

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
      case 'too-many-requests':
        userMessage = 'Trop de tentatives. Veuillez patienter avant de réessayer.';
        break;
      case 'invalid-verification-code':
        userMessage = 'Code de vérification invalide. Demandez un nouveau code.';
        break;
      case 'network-request-failed':
        userMessage = 'Problème de connexion réseau. Vérifiez votre connexion internet.';
        break;
      default:
        userMessage = 'Une erreur est survenue. Veuillez réessayer.';
        break;
    }

    return userMessage;
  }
}

void main() {
  group('Error Message Transformations - Unit Tests', () {
    late TestErrorHandlerService errorHandler;

    setUp(() {
      errorHandler = TestErrorHandlerService();
    });

    test('handleFirebaseAuthError returns user-friendly message for user-not-found', () {
      final exception = FirebaseAuthException(
        code: 'user-not-found',
        message: 'There is no user record corresponding to this identifier.',
      );

      final result = errorHandler.handleFirebaseAuthError(exception);

      expect(
        result,
        'Cet email n\'est pas associé à un compte. Créez-vous un compte ou vérifiez l\'adresse email.',
      );
      expect(result, isNotEmpty);
      expect(result, isNot('user-not-found'));
    });

    test('handleFirebaseAuthError returns user-friendly message for wrong-password', () {
      final exception = FirebaseAuthException(
        code: 'wrong-password',
        message: 'The password is invalid or the user does not have a password.',
      );

      final result = errorHandler.handleFirebaseAuthError(exception);

      expect(result, 'Mot de passe incorrect. Vérifiez votre saisie.');
      expect(result, isNotEmpty);
    });

    test('handleFirebaseAuthError returns user-friendly message for email-already-in-use', () {
      final exception = FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'The email address is already in use by another account.',
      );

      final result = errorHandler.handleFirebaseAuthError(exception);

      expect(result, 'Cette adresse email est déjà utilisée.');
    });

    test('handleFirebaseAuthError returns user-friendly message for weak-password', () {
      final exception = FirebaseAuthException(
        code: 'weak-password',
        message: 'The password must be 6 characters long or more.',
      );

      final result = errorHandler.handleFirebaseAuthError(exception);

      expect(result, 'Mot de passe trop faible. Utilisez au moins 6 caractères.');
    });

    test('handleFirebaseAuthError returns user-friendly message for invalid-email', () {
      final exception = FirebaseAuthException(
        code: 'invalid-email',
        message: 'The email address is badly formatted.',
      );

      final result = errorHandler.handleFirebaseAuthError(exception);

      expect(result, 'Adresse email invalide. Vérifiez le format.');
    });

    test('handleFirebaseAuthError returns user-friendly message for too-many-requests', () {
      final exception = FirebaseAuthException(
        code: 'too-many-requests',
        message: 'Too many unsuccessful login attempts.',
      );

      final result = errorHandler.handleFirebaseAuthError(exception);

      expect(result, 'Trop de tentatives. Veuillez patienter avant de réessayer.');
    });

    test('handleFirebaseAuthError returns generic message for unknown error', () {
      final exception = FirebaseAuthException(
        code: 'unknown-code',
        message: 'Unknown error occurred.',
      );

      final result = errorHandler.handleFirebaseAuthError(exception);

      expect(result, 'Une erreur est survenue. Veuillez réessayer.');
    });

    test('All Firebase auth error codes are handled', () {
      final codes = [
        'user-not-found',
        'wrong-password',
        'invalid-email',
        'user-disabled',
        'account-disabled',
        'email-already-in-use',
        'weak-password',
        'invalid-verification-code',
        'too-many-requests',
        'network-request-failed',
      ];

      for (final code in codes) {
        final exception = FirebaseAuthException(
          code: code,
          message: 'Test message for $code',
        );

        final result = errorHandler.handleFirebaseAuthError(exception);

        // Result should not contain the raw code
        expect(result, isNotEmpty);
        expect(result, isNot(code));
        // Result should be a string
        expect(result, isA<String>());
      }
    });

    test('Error messages are user-friendly and in French', () {
      final exception = FirebaseAuthException(
        code: 'wrong-password',
        message: 'Technical message here',
      );

      final result = errorHandler.handleFirebaseAuthError(exception);

      // Should not contain technical details
      expect(result, isNot(contains('Technical message')));
      // Should be user-friendly
      expect(result, isA<String>());
      expect(result.length, greaterThan(10));
    });

    test('Message for invalid-email is in French', () {
      final exception = FirebaseAuthException(
        code: 'invalid-email',
        message: 'Invalid email format',
      );

      final result = errorHandler.handleFirebaseAuthError(exception);

      // Should contain French word "Adresse"
      expect(result, contains('Adresse'));
      expect(result, contains('email'));
    });

    test('Message for network-request-failed is in French', () {
      final exception = FirebaseAuthException(
        code: 'network-request-failed',
        message: 'Network error',
      );

      final result = errorHandler.handleFirebaseAuthError(exception);

      // Should contain French words
      expect(result, contains('Problème'));
      expect(result, contains('connexion'));
    });
  });

}
