import 'package:camelia_logistics/models/services/AdminService.dart';
import 'package:camelia_logistics/models/services/order_service.dart';
import 'package:camelia_logistics/models/services/userProfileService.dart';
import 'package:camelia_logistics/models/userProfile.dart';
import 'package:camelia_logistics/screens/change_informations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/services/firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserProfileService _userSer = UserProfileService();
  final OrderService _orderService = OrderService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  void _handleLogout() async {
    try {
      // 1. Appeler la déconnexion Firebase
      await AuthService().signOut();
      if (mounted) {
        // Utilisez context.go pour la déconnexion complète et non traçable
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Échec de la déconnexion. Réessayez.")),
        );
      }
    }
  }

  void promote() async {
    final AdminService admin = AdminService();
    await admin.setRole(
      targetUid: 'JGmPCYyizmSfw38n1l2zypIucDN2',
      role: 'Admin',
      region: 'us-central1',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Center(child: Text('Utilisateur non connecté.'));
    }
    return FutureBuilder<UserProfile?>(
      future: _userSer.getProfile(_currentUserId),
      builder: (context, snapshot) {
        // État de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // État d'erreur ou profil non trouvé
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profil')),
            body: Center(
              child: Text(
                'Erreur de chargement du profil: ${snapshot.error ?? "Données introuvables"}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final UserProfile profile = snapshot.data!;
        // Maintenant, 'profile' est un objet UserProfile valide.

        // SingleChildScrollView permet de faire défiler le contenu si l'écran est trop petit
        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Section du haut (arrière-plan dégradé)
                Container(
                  padding: EdgeInsets.only(
                    top: 50,
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4C4CE7), Color(0xFF6B4EE7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Ligne de la barre de titre
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.accessibility_new_rounded,
                              color: Colors.white,
                            ),
                          ),
                          Spacer(),
                          Text(
                            'Mon profil',
                            style: GoogleFonts.pacifico(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          Spacer(),
                          // L'icône pour les paramètres, si nécessaire
                          Icon(Icons.settings, color: Colors.white),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Image de profil
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 40, color: Colors.blue),
                      ),
                      SizedBox(height: 10),
                      Text(
                        profile.name,
                        style: GoogleFonts.pacifico(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Membre depuis le Cameroun',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Ligne des statistiques (Note, Livraisons, Réussite)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          FutureBuilder(
                            future: _orderService.getOrdersByUserId(
                              _currentUserId,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 50.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final count = snapshot.data?.length ?? '0';
                              return _buildStatColumn(
                                count.toString(),
                                'Livraisons',
                              );
                            },
                          ),
                          FutureBuilder(
                            future: _orderService.getOrdersByUserId(
                              _currentUserId,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 50.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final int count = snapshot.data?.length ?? 0;
                              List<Widget> stars = [];
                              if (count >= 100) {
                                stars = List.generate(
                                  4,
                                  (_) => Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                );
                              } else if (count > 50) {
                                stars = List.generate(
                                  2,
                                  (_) => Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                );
                              } else {
                                stars = List.generate(
                                  1,
                                  (_) => Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                );
                              }
                              return _buildStatColumnWithStars(stars, 'Niveau');
                            },
                          ),
                          _buildStatColumn('98%', 'Réussite'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Section "Informations personnelles"
                _buildInfoCard(
                  title: 'Informations personnelles',
                  items: [
                    _buildInfoRow(
                      icon: Icons.mail_outline_rounded,
                      label: 'Email principal',
                      value: profile.email,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      icon: Icons.phone_sharp,
                      label: 'Téléphone',
                      value: profile.phoneNumber,
                    ),
                  ],
                  buttonLabel: 'Modifier mes informations',
                  buttonIcon: Icons.settings,
                  onButtonPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChangeInformations(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Section "Vos performances"
                _buildInfoCard(
                  title: 'Vos performances',
                  items: [
                    _buildPerformanceRow(
                      label: 'Note moyenne',
                      value: '4.8/5',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 10),
                    _buildPerformanceRow(
                      label: 'Taux de réussite',
                      value: '98%',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 10),
                    _buildPerformanceRow(
                      label: 'Total des livraisons',
                      value: '24',
                      color: Colors.black,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Section "Paramètres"
                _buildInfoCard(
                  title: 'Paramètres',
                  items: [
                    _buildSettingsRow(
                      label: 'Notifications push',
                      icon: Icons.notifications,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _handleLogout,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(30),
                    ),

                    child: Row(
                      children: [
                        Icon(Icons.exit_to_app, color: Colors.red.shade800),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Se deconnecter',
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // Fonction pour construire une colonne de statistiques
  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatColumnWithStars(List<Widget> stars, String label) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: stars.isNotEmpty
              ? stars
              : [
                  Text(
                    'Débutant', // Ou ce que vous voulez afficher par défaut
                    style: GoogleFonts.ubuntu(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // Fonction pour construire les cartes d'information
  Widget _buildInfoCard({
    required String title,
    required List<Widget> items,
    String? buttonLabel,
    IconData? buttonIcon,
    VoidCallback? onButtonPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.ubuntu(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ...items,
          if (buttonLabel != null) ...[
            const SizedBox(height: 15),
            TextButton(
              onPressed: onButtonPressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(buttonIcon, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    buttonLabel,
                    style: GoogleFonts.ubuntu(fontSize: 16, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Fonction pour construire une ligne d'information (email, téléphone)
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.ubuntu(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Fonction pour construire une ligne de performance
  Widget _buildPerformanceRow({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 16)),
        Text(
          value,
          style: GoogleFonts.ubuntu(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Fonction pour construire une ligne de paramètres avec un interrupteur
  Widget _buildSettingsRow({required String label, required IconData icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(width: 15),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
        Switch(
          value: true, // Remplace par la valeur de ton état
          onChanged: (bool value) {
            // Logique de l'interrupteur
          },
          activeThumbColor: Colors.blue,
        ),
      ],
    );
  }
}

Widget _params(IconData icon, String label) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      border: Border(),
    ),
    child: Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.black),
          SizedBox(width: 10),
          Text(label),
        ],
      ),
    ),
  );
}
