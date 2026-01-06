import 'package:camelia_logistics/models/services/userProfileService.dart';
import 'package:camelia_logistics/models/userProfile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

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
    //final String? fmcToken,
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

      await _storeService.saveProfile(
        profile,
        // uid: user.uid,
        // email: email,
        // fullName: name,
        // phoneNumber: phoneNumber,
      );
      return user;
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger(child: Text('erreur d\'inscription : ${e.code}'));
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
      ScaffoldMessenger(child: Text('Erreur de connexion: ${e.code}'));
      return null;
    }
  }

  Future<void> signOut() async {
    // L'appel est simple et ne nécessite pas de try/catch dans un MVP,
    // car l'échec est souvent géré par le fait que l'utilisateur est déjà déconnecté.
    await _auth.signOut();
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Succès
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "Aucun utilisateur trouvé pour cette adresse e-mail. Veuillez vérifier l'e-mail saisi.";
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
        }
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de connexion: idToken est null'),
          ),
        );
      }
    } on GoogleSignInException catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de connexion: ${e.code}')));
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de connexion: ${e.code}')));
    }
  }
}
