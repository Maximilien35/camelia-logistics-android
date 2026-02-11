// ignore_for_file: use_build_context_synchronously

import 'package:camelia_logistics/models/services/user_profile_service.dart';
import 'package:camelia_logistics/models/user_profile.dart';
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
    required String password,
    required String email,
    required String phoneNumber,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-created',
          message: "L'utilisateur Firebase n'a pas été créé.",
        );
      }
      final UserProfile profile = UserProfile(
        uid: user.uid,
        name: name,
        phoneNumber: phoneNumber,
        email: email,
        role: 'client',
      );

      await _storeService.saveProfile(profile);
      return user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('SignUp FirebaseAuthException: ${e.code}');

      return null;
    } catch (e) {
      if (kDebugMode) print('SignUp error: $e');
      return null;
    }
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('SignIn FirebaseAuthException: ${e.code}');
      return null;
    } catch (e) {
      if (kDebugMode) print('SignIn error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
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
          }
          else {
            await firebaseUser.delete();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Aucun compte associé. Veuillez vous inscrire d\'abord.'),
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
      ScaffoldMessenger(child :SnackBar(content: Text('Erreur de connexion: ${e.code}')));
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger(child:SnackBar(content: Text('Erreur de connexion: ${e.code}')));
    } catch (e) {
      Navigator.of(context).pop();
      if (kDebugMode) print('Google sign-in error: $e');
      ScaffoldMessenger(child: SnackBar(content: const Text('Erreur inattendue lors de la connexion Google')));
    }
  }
}
