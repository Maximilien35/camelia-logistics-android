import 'package:camelia_logistics/screens/admin_panel.dart';
import 'package:camelia_logistics/screens/home_custumer_screen.dart';
import 'package:camelia_logistics/screens/home_screen.dart';
import 'package:camelia_logistics/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final User? user = authSnapshot.data;

        // Si l'utilisateur n'est PAS connecté, afficher la page de connexion
        if (user == null) {
          return const HomeScreen();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            // Si le document  et contient des données
            if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
              final userData = roleSnapshot.data!.data();
              final String role = userData?['role'] ?? 'client';

              // 3. LOGIQUE DE REDIRECTION BASÉE SUR LE RÔLE

              if (role == 'admin') {
                return const AdminPage();
              } else {
                return const HomeCustumerScreen();
              }
            }
            return const HomeScreen();
          },
        );
      },
    );
  }
}
