// ignore_for_file: use_build_context_synchronously

import 'package:camelia/models/services/user_profile_service.dart';
import 'package:camelia/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// ignore: depend_on_referenced_packages
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

class CacheEntry {
  final dynamic value;
  final DateTime expiry;
  CacheEntry(this.value, this.expiry);
}

class CacheManager {
  CacheManager._private();
  static final CacheManager instance = CacheManager._private();

  final Map<String, CacheEntry> _cache = {};
  Duration defaultTTL = const Duration(minutes: 5);

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      return null;
    }
    return entry.value as T;
  }

  void set(String key, dynamic value, [Duration? ttl]) {
    final expiry = DateTime.now().add(ttl ?? defaultTTL);
    _cache[key] = CacheEntry(value, expiry);
  }

  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetcher, [
    Duration? ttl,
  ]) async {
    final existing = get<T>(key);
    if (existing != null) return existing;
    final fetched = await fetcher();
    set(key, fetched, ttl);
    return fetched;
  }

  void invalidate(String key) => _cache.remove(key);
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserProfileService _storeService = UserProfileService();
  Future<void> ensureInitialized() async {
    return GoogleSignInPlatform.instance.init(InitParameters());
  }

  Future<User?> signUp({
    required String name,
    required String phoneNumber,
    required String email,
  }) async {
    try {
      // Vérifier unicité du numéro de téléphone
      final existingPhoneProfile = await _storeService.getProfileByPhone(
        phoneNumber.trim(),
      );
      final existingEmailProfile = await _storeService.getProfileByEmail(
        email.trim(),
      );
      if (existingPhoneProfile != null) {
        if (!existingPhoneProfile.isActive) {
          throw FirebaseAuthException(
            code: 'phone-account-disabled',
            message:
                'Ce numéro de téléphone est associé à un compte désactivé. Veuillez contacter le support.',
          );
        }
        throw FirebaseAuthException(
          code: 'phone-already-in-use',
          message:
              'Un compte existe déjà avec ce numéro de téléphone. Connectez-vous ou utilisez un autre numéro.',
        );
      }

      if (existingEmailProfile != null) {
        if (!existingEmailProfile.isActive) {
          throw FirebaseAuthException(
            code: 'email-account-disabled',
            message:
                'Cette adresse e-mail est associée à un compte désactivé. Veuillez contacter le support.',
          );
        }
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message:
              'Un compte existe déjà avec cette adresse e-mail. Connectez-vous ou utilisez une autre adresse.',
        );
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw FirebaseAuthException(
          code: 'user-not-authenticated',
          message:
              'L’utilisateur n’est pas authentifié. Complétez la vérification OTP d’abord.',
        );
      }

      final profile = UserProfile(
        uid: currentUser.uid,
        name: name,
        phoneNumber: phoneNumber,
        email: email.trim(),
        role: 'client',
        isActive: true,
      );

      await _storeService.saveProfile(profile);
      return currentUser;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('SignUp FirebaseAuthException: ${e.code} - ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) print('SignUp error: $e');
      throw Exception('Erreur lors de l\'inscription : $e');
    }
  }

  Future<User?> signIn({
    required String phoneNumber,
  }) async {
    try {
      
      final userProfile = await _storeService.getProfileByPhone(phoneNumber.trim());
      if (userProfile == null) {
        throw FirebaseAuthException(
          code: 'profile-not-found',
          message:
              'Profil utilisateur introuvable. Veuillez vous inscrire.',
        );
      }
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw FirebaseAuthException(
          code: 'user-not-authenticated',
          message:
              'L’utilisateur n’est pas authentifié. Complétez la vérification OTP d’abord.',
        );
      }


      if (!userProfile.isActive) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'account-disabled',
          message:
              'Votre compte a été désactivé. Contactez le support pour le réactiver.',
        );
      }

      return currentUser;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('SignIn FirebaseAuthException: ${e.code} - ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) print('SignIn error: $e');
      throw Exception('Erreur lors de la connexion: $e');
    }
  }

  Future<void> signOut() async {
    await _storeService.clearMemoryCache();
    await _auth.signOut();
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Succès
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'Aucun utilisateur trouvé pour cette adresse e-mail.';
      }
      return "Erreur lors de l'envoi de l'e-mail: ${e.message}";
    } catch (e) {
      return "Une erreur inattendue s'est produite.";
    }
  }

  /// Connexion avec email et mot de passe
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Utilisateur introuvable.',
        );
      }

      // Vérifier si l'email est vérifié
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Veuillez vérifier votre email avant de vous connecter. Un nouvel email de vérification a été envoyé.',
        );
      }

      // Récupérer le profil utilisateur
      final userProfile = await _storeService.getProfileByEmail(email.trim());
      if (userProfile == null) {
        throw FirebaseAuthException(
          code: 'profile-not-found',
          message: 'Profil utilisateur introuvable. Veuillez contacter le support.',
        );
      }

      if (!userProfile.isActive) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'account-disabled',
          message: 'Votre compte a été désactivé. Contactez le support pour le réactiver.',
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('SignInWithEmail FirebaseAuthException: ${e.code} - ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) print('SignInWithEmail error: $e');
      throw Exception('Erreur lors de la connexion: $e');
    }
  }

  /// Inscription avec email et mot de passe
  Future<User?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      // Vérifier unicité de l'email et du téléphone
      final existingEmailProfile = await _storeService.getProfileByEmail(email.trim());
      final existingPhoneProfile = await _storeService.getProfileByPhone(phoneNumber.trim());

      if (existingEmailProfile != null) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Cette adresse e-mail est déjà utilisée.',
        );
      }

      if (existingPhoneProfile != null) {
        throw FirebaseAuthException(
          code: 'phone-already-in-use',
          message: 'Ce numéro de téléphone est déjà utilisé.',
        );
      }

      // Créer l'utilisateur dans Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'Échec de la création du compte.',
        );
      }

      // Envoyer l'email de vérification
      await user.sendEmailVerification();

      // Créer le profil utilisateur
      final profile = UserProfile(
        uid: user.uid,
        name: name,
        phoneNumber: phoneNumber,
        email: email.trim(),
        role: 'client',
        isActive: true,
      );

      await _storeService.saveProfile(profile);

      // Déconnecter immédiatement l'utilisateur non vérifié
      await _auth.signOut();

      return user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('SignUpWithEmail FirebaseAuthException: ${e.code} - ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) print('SignUpWithEmail error: $e');
      throw Exception('Erreur lors de l\'inscription : $e');
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );
      await ensureInitialized();
      final AuthenticationResults results = await GoogleSignInPlatform.instance
          .authenticate(AuthenticateParameters());
      final String? idToken = results.authenticationTokens.idToken;
      if (idToken != null) {
        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: idToken,
        );
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithCredential(credential);
        final firebaseUser = userCredential.user;
        if (firebaseUser != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .get();
          Navigator.of(context).pop();
          if (userDoc.exists) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Connexion avec Google ${firebaseUser.displayName}',
                ),
              ),
            );
            context.go('/welcome');
          } else {
            await firebaseUser.delete();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Aucun compte associé. Veuillez vous inscrire d\'abord.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger(
          child: SnackBar(
            content: Text('Erreur de connexion: idToken est null'),
          ),
        );
      }
    } on GoogleSignInException catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger(
        child: SnackBar(content: Text('Erreur de connexion: ${e.code}')),
      );
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger(
        child: SnackBar(content: Text('Erreur de connexion: ${e.code}')),
      );
    } catch (e) {
      Navigator.of(context).pop();
      if (kDebugMode) print('Google sign-in error: $e');
      ScaffoldMessenger(
        child: SnackBar(
          content: const Text('Erreur inattendue lors de la connexion Google'),
        ),
      );
    }
  }
}
