import 'package:camelia_logistics/models/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Color kPrimaryColor = Color(0xFF1E3A8A); // Bleu foncé de votre maquette
const Color kAccentColor = Color(0xFF10B981); // Vert accent de votre maquette

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPassword> {
  // 1. Clé pour valider le formulaire
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();

  // 2. Variable d'état pour le chargement et la gestion UX
  bool _isLoading = false;

  void _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 1. Début du chargement
    setState(() {
      _isLoading = true;
    });

    try {
      final String emailToReset = _emailController.text.trim();

      // 2. Vérification de l'existence de l'utilisateur dans Firestore
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: emailToReset)
          .limit(
            1,
          ) // Optimisation : on a besoin de vérifier l'existence, une seule suffit
          .get();

      if (querySnapshot.docs.isEmpty) {
        // 3. Cas non inscrit : Afficher une SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$emailToReset n\'est pas inscrit.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return; // Sortir de la fonction
      }

      await _authService.resetPassword(emailToReset);

      // Succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Lien de réinitialisation envoyé ! Vérifiez votre e-mail.",
            ),
            backgroundColor: kAccentColor,
          ),
        );
        // Optionnel : Retourner à l'écran de connexion
        context.go('/login');
      }
    } catch (e) {
      // 5. Gérer les erreurs de Firebase Auth (mauvais format d'email, etc.)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 6. Fin du chargement, toujours exécuté
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 4. Utilisation du SingleChildScrollView pour éviter le dépassement de l'écran lors du clavier
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          // Centrage vertical du contenu
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Form(
              key: _formKey, // 5. Associer la clé au formulaire
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.stretch, // Étire les éléments
                children: [
                  const Text(
                    'Réinitialiser votre mot de passe',
                    style: TextStyle(
                      fontSize: 24,
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Adresse e-mail',
                      hintText: 'votre.email@exemple.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: kPrimaryColor,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "L'adresse e-mail est requise.";
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Veuillez entrer une adresse e-mail valide.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor:
                          kAccentColor, // Utilisation de la couleur accent pour l'action
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0, // Design épuré sans ombre
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'Confirmer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
