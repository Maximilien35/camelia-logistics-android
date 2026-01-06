import 'package:camelia_logistics/screens/login_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Fonction utilitaire pour construire les cartes de manière réutilisable.
  Widget _buildCard(String text, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ), // Espacement réduit
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ), // Taille de police réduite
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- Le fond avec le dégradé et les cercles (Inchangé) ---
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6B4EE7), Color(0xFF8A62F8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            right: -50,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            right: 350,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blueAccent.shade200.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 350,
            right: -150,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.shade200.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // --- Le contenu principal (Non défilable) ---
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,

              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 30), // Espacement réduit
                    // LOGO
                    Container(
                      width: 80, // Taille du logo réduite
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          "assets/log.webp",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: 15), // Espacement réduit

                    Text(
                      'Camelia Logistics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24, // Taille de police réduite
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Transportez vos marchandises en toute simplicité',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ), // Taille de police réduite
                    ),
                  ],
                ),

                Column(
                  children: [
                    // CARTE POINTS DE DÉPART/ARRIVÉE
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      padding: const EdgeInsets.all(15), // Padding réduit
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on, color: Colors.white),
                          SizedBox(width: 10),
                          Expanded(
                            child: Divider(color: Colors.white, thickness: 2),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.unarchive, color: Colors.white),
                        ],
                      ),
                    ),

                    // Cartes de description
                    _buildCard(
                      'Choisissez le véhicule adapté (tricycle, camionnette, camion-benne, etc.)',
                      Icons.local_shipping,
                    ),
                    const SizedBox(height: 8), // Espacement réduit
                    _buildCard(
                      'Indiquez votre lieu de départ, d\'arrivée et la nature du colis',
                      Icons.location_on,
                    ),
                    const SizedBox(height: 8), // Espacement réduit
                    _buildCard(
                      'Un chauffeur disponible est dépêché rapidement pour assurer votre transport',
                      Icons.person_pin,
                    ),
                  ],
                ),

                // BAS SECTION : Le bouton "Commencer"
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical:
                        30, // Marge verticale augmentée pour pousser vers le bas
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                      ;
                    },
                    child: const Text(
                      'Commencer',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
