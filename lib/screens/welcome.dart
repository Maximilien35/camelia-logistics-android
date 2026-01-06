import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CameliaHome extends StatelessWidget {
  const CameliaHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A00E0), // violet profond
              Color(0xFF8E2DE2), // violet clair/rose
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Logo rond avec icône camion
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.local_shipping,
                    size: 40,
                    color: Color(0xFF4A00E0),
                  ),
                ),

                const SizedBox(height: 20),

                // Nom entreprise
                const Text(
                  "Camelia Logistics",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                // Slogan
                const Text(
                  "Livraison rapide et fiable",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),

                const SizedBox(height: 30),

                // Barre de recherche stylisée
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Icon(Icons.location_on, color: Colors.white),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Divider(color: Colors.white54, thickness: 2),
                        ),
                      ),
                      Icon(Icons.inventory, color: Colors.white),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Boutons info
                _InfoCard(
                  icon: Icons.local_shipping,
                  text: "Livraison express au Cameroun",
                ),
                const SizedBox(height: 15),
                _InfoCard(
                  icon: Icons.track_changes,
                  text: "Suivi en temps réel",
                ),
                const SizedBox(height: 15),
                _InfoCard(icon: Icons.lock, text: "Colis sécurisés"),

                const Spacer(),

                // Bouton principal
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      context.go('/signup');
                    },
                    child: const Text(
                      "Commencer",
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF4A00E0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget réutilisable pour les cartes
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16, color: Colors.white)),
        ],
      ),
    );
  }
}
