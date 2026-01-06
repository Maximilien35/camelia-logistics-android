import 'package:camelia_logistics/models/services/AdminService.dart';
import 'package:camelia_logistics/models/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});
  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  final AdminService _adminService = AdminService();
  final TextEditingController mail = TextEditingController();
  final uid = FirebaseAuth.instance.currentUser?.uid;
  void addAdminDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(children: [Icon(Icons.add), Text('ajouter un admin')]),
          content: TextFormField(
            controller: mail,
            validator: (value) {
              if (value!.isEmpty) return 'L\'ID est obligatoire.';
              if (value.length < 20) {
                return 'Id  invalide.';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Entrer l\'email a promouvoir',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Retour'),
            ),
            ElevatedButton(
              onPressed: () {
                _adminService.setRole(
                  targetUid: mail.text,
                  role: 'Admin',
                  region: 'us-central1',
                ); // Statut payé/terminé
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text(
                'Confirmer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4C4CE7), Color(0xFF6B4EE7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Text(
                    'Parametres',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  Icon(Icons.notifications, size: 40, color: Colors.white),
                ],
              ),
            ),
            SizedBox(height: 16),
            _buildInfoCard(
              title: 'Compte',
              items: [
                _buildInfoRow(
                  icons: Icons.account_box,
                  value: 'Profil Utilisateur',
                  color: Colors.blue,
                ),
                SizedBox(height: 12),
                _buildInfoRow(
                  icons: Icons.check_box,
                  value: 'changer de mot de passe',
                  color: Colors.blue,
                ),
              ],
            ),
            SizedBox(height: 15),
            _buildInfoCard(
              title: 'Parametres',
              items: [
                _buildInfoRow(
                  icons: Icons.add,
                  value: 'Ajouter un Admin',
                  color: Colors.purpleAccent,
                  onPressed: () {
                    addAdminDialog(context);
                  },
                ),
                SizedBox(height: 12),
                _buildInfoRow(
                  icons: Icons.local_police_outlined,
                  value: 'Politique et Confidentialite',
                  color: Colors.purpleAccent,
                ),
              ],
            ),
            SizedBox(height: 15),
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
          ],
        ),
      ),
    );
  }
}

Widget _buildInfoRow({
  required IconData icons,
  required Color color,
  required String value,
  VoidCallback? onPressed,
}) {
  return GestureDetector(
    onTap: onPressed,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icons, color: color, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
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
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
