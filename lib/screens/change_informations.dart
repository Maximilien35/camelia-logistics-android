import 'package:camelia_logistics/models/services/userProfileService.dart';
import 'package:camelia_logistics/models/userProfile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Color kPrimaryColor = Color(0xFF1E3A8A); // Bleu foncé de votre maquette
const Color kAccentColor = Color(0xFF10B981);

class ChangeInformations extends StatefulWidget {
  const ChangeInformations({super.key});

  @override
  State<ChangeInformations> createState() => _ChangeInformationsState();
}

class _ChangeInformationsState extends State<ChangeInformations> {
  final idUser = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = false;
  final UserProfileService _service = UserProfileService();
  Future info() async {
    final UserProfile? profile = await _service.getProfile(idUser!);
    return profile?.name;
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController(
    text: FirebaseAuth.instance.currentUser?.email,
  );
  final TextEditingController _nameController = TextEditingController(
    text: FirebaseAuth.instance.currentUser?.displayName,
  );
  final TextEditingController _telController = TextEditingController(
    text: FirebaseAuth.instance.currentUser?.phoneNumber,
  );

  void _changeInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 1. Début du chargement
    setState(() {
      _isLoading = true;
    });

    try {
      await _service.updateProfile(
        email: _emailController.text,
        phone: _telController.text,
        name: _nameController.text,
        uid: idUser!,
      );
      // Succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [Icon(Icons.check), Text("mis a jour")]),
            backgroundColor: kAccentColor,
          ),
        );
        context.go('/profil');
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('informationd personnelles'),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      // 4. Utilisation du SingleChildScrollView pour éviter le dépassement de l'écran lors du clavier
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: StreamBuilder<UserProfile?>(
          stream: UserProfileService().streamProfile(idUser!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data == null) {
              return Text('Erreur de chargement du profil.,${snapshot.error}');
            }
            final profile = snapshot.data;
            return Center(
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
                        'Modifier vos informations',
                        style: TextStyle(
                          fontSize: 24,
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _nameController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: 'nom',
                          hintText: 'jean Pierre',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          prefixIcon: const Icon(
                            Icons.nest_cam_wired_stand_outlined,
                            color: kPrimaryColor,
                          ),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Veuillez entrer votre nom';
                          } else {
                            return null;
                          }
                        },
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _telController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'telephone',
                          hintText: '6 xx xx xx xx',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: kPrimaryColor,
                          ),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Veuillez entrer votre numero de telephone';
                          }
                          if (value.length < 10) {
                            return 'Veuillez entrer un numero de telephone valide';
                          }

                          return null;
                        },
                      ),
                      SizedBox(height: 8),
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
                          if (value!.isEmpty) {
                            return 'L\'email est obligatoire.';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Format d\'email invalide.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _changeInfo,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: kAccentColor,
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
            );
          },
        ),
      ),
    );
  }
}
