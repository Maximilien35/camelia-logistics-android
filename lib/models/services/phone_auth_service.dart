import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:camelia/models/services/user_profile_service.dart';
import 'package:camelia/models/user_profile.dart';

typedef VerificationIdCallback = void Function(String verificationId);
typedef AuthErrorCallback = void Function(String message);

enum PhoneAuthStage { sendingCode, codeSent, verifyingCode, verified, failed }

class PhoneAuthState {
  final PhoneAuthStage stage;
  final String? message;
  final bool isLoading;

  PhoneAuthState({
    required this.stage,
    this.message,
    this.isLoading = false,
  });
}

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserProfileService _profileService = UserProfileService();

  Future<void> sendCode({
    required String phoneNumber,
    required VerificationIdCallback onCodeSent,
    required AuthErrorCallback onVerificationFailed,
    required VoidCallback onAutoRetrievalTimeout,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 40),
        verificationCompleted: (PhoneAuthCredential credential) async {
          onAutoVerified(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onVerificationFailed(e.message ?? e.code);
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          onAutoRetrievalTimeout();
        },
      );
    } catch (e) {
      onVerificationFailed(e.toString());
    }
  }

  Future<UserCredential?> verifyCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    try {
      final credentialResult = await _auth.signInWithCredential(credential);
      return credentialResult;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Erreur de vérification du code OTP');
    }
  }

  Future<UserCredential> signInWithCredential(PhoneAuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }

  /// Vérifie si un numéro de téléphone existe déjà dans la base de données
  /// Retourne le profil utilisateur si existant, null sinon
  Future<UserProfile?> checkPhoneNumberExists(String phoneNumber) async {
    return await _profileService.getProfileByPhone(phoneNumber);
  }

  /// Authentifie un utilisateur existant avec numéro de téléphone
  /// Cette méthode lie le téléphone à un compte existant ou crée un nouveau compte Firebase
  Future<UserCredential> authenticateWithPhone({
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    try {
      // Vérifier si le numéro existe déjà dans notre base
      final existingProfile = await checkPhoneNumberExists(phoneNumber);

      if (existingProfile != null) {
        // Numéro existant - connecter l'utilisateur
        if (!existingProfile.isActive) {
          throw Exception('Ce compte a été désactivé. Contactez le support.');
        }

        // Se connecter avec le téléphone (Firebase va créer un compte anonyme ou lier)
        final userCredential = await _auth.signInWithCredential(credential);

        // Mettre à jour le profil avec le nouvel UID si nécessaire
        if (userCredential.user?.uid != existingProfile.uid) {
          // Le téléphone est lié à un compte différent - fusionner ou gérer le conflit
          if (kDebugMode) {
            print('Phone linked to different account - handling merge');
          }
        }

        return userCredential;
      } else {
        // Nouveau numéro - créer un compte temporaire pour l'inscription
        final userCredential = await _auth.signInWithCredential(credential);
        return userCredential;
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Erreur d\'authentification téléphone');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
