import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 1. Masquer la barre de statut IMMÉDIATEMENT
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    //_navigateToNextScreen(context);
  }

  @override
  void dispose() {
    // 2. Rétablit l'affichage de la barre de statut lorsque le widget est détruit.
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Utilisation de const car les valeurs sont fixes
          gradient: LinearGradient(
            colors: [Color(0xFF6B4EE7), Color(0xFF8A62F8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  // Utilisation de const
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  // Assurez-vous que le chemin 'assets/log.jpg' est valide
                  child: Image.asset("assets/log.webp", fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20), // Utilisation de const
              const CircularProgressIndicator(
                // Un indicateur de chargement subtil.
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // void _navigateToNextScreen(BuildContext context) async {
  //   // 3. Délai pour afficher le Splash Screen
  //   await Future.delayed(const Duration(milliseconds: 1500));
  //   context.go('/welcome');
  // }
}
