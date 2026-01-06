import 'package:camelia_logistics/models/services/AdminService.dart';
import 'package:camelia_logistics/models/services/firebase_service.dart';
import 'package:camelia_logistics/models/services/userProfileService.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AdminService admin = AdminService();
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        admin.handlePopInvoked(didPop, context);
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              "Camelia Logistics",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            leading: IconButton(
              onPressed: () {
                context.go('/home');
              },
              icon: Icon(Icons.arrow_back),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(kToolbarHeight),
              child: TabBar(
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue.shade800,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: [
                  Tab(text: 'Connexion'),
                  Tab(text: 'Inscription'),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: TabBarView(
                  children: [LoginTabContent(), SignupTabContent()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginTabContent extends StatefulWidget {
  const LoginTabContent({super.key});
  @override
  State<LoginTabContent> createState() => _LoginTabContentState();
}

class _LoginTabContentState extends State<LoginTabContent> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Variable pour gérer l'état du chargement (à des fins d'UI)
  bool _isLoading = false;
  bool fill = true;

  // CONNEXION ---
  void _submitLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true); // Afficher le chargement

    try {
      // APPEL DU SERVICE D'AUTHENTIFICATION
      final user = await AuthService().signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (user != null) {
        final UserProfileService userSer = UserProfileService();
        final userProfile = await userSer.getProfile(user.uid);
        String? role = userProfile?.role;

        if (mounted) {
          if (role == 'admin') {
            context.go('/admin');
          } else {
            context.go('/home_custom');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur de connexion : Identifiants invalides.'),
            ),
          );
        }
      }
    } catch (e) {
      // Gérer toute erreur inattendue (ex: problème réseau)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oupss Une erreur est survenue: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Pour éviter le débordement
      child: Container(
        margin: const EdgeInsets.all(24),
        child: Form(
          // On utilise le widget Form
          key: _formKey, // On attache la clé ici
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _header(context),
              const SizedBox(height: 40),
              _inputField(context),
              _forgotPassword(context),
              _signup(context),
            ],
          ),
        ),
      ),
    );
  }

  // Helper pour l'en-tête (inchangé)
  Column _header(context) {
    return const Column(
      children: [
        Text(
          "Bienvenue",
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
        Text("Entrer vos identifiants de connexion"),
      ],
    );
  }

  // Helper pour les champs de saisie (maintenant des TextFormField avec validateurs)
  Column _inputField(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Champ Email
        TextFormField(
          controller: _emailController, // LIAISON
          decoration: InputDecoration(
            hintText: "Email",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.blue.withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'L\'email est requis.';
            if (!value.contains('@') || !value.contains('.')) {
              return 'Format invalide.'; // Validation minimale
            }
            return null;
          },
        ),
        const SizedBox(height: 10),

        // Champ Mot de passe
        TextFormField(
          controller: _passwordController, // LIAISON
          decoration: InputDecoration(
            hintText: "Password",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.blue.withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.password),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  fill = !fill;
                });
              },
              icon: Icon(Icons.remove_red_eye_rounded),
            ),
          ),
          obscureText: fill,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Le mot de passe est requis.';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Bouton de connexion
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : _submitLogin, // Désactiver pendant le chargement
          style: ElevatedButton.styleFrom(
            shape: StadiumBorder(),
            padding: EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue,
          ),
          child: _isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Text(
                  "Connexion",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
        ),
        const Center(child: Text("Ou")),

        Container(
          height: 45,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.blue),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 1,
                offset: const Offset(0, 1), // changes position of shadow
              ),
            ],
          ),
          child: TextButton(
            onPressed: () {
              AuthService().signInWithGoogle(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 30.0,
                  width: 30.0,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/log.webp'),
                      fit: BoxFit.cover,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 18),

                const Text(
                  "Connexion avec Google",
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper pour "Mot de passe oublié" (inchangé)
  TextButton _forgotPassword(BuildContext context) {
    return TextButton(
      onPressed: () {
        context.go('/reset');
      },
      child: const Text(
        "Mot de passe oublie?",
        style: TextStyle(color: Colors.blue),
      ),
    );
  }

  // Helper pour "Inscription" (Navigation vers l'onglet Inscription)
  Row _signup(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("vous n'avez pas de Compte? "),
        TextButton(
          onPressed: () {
            DefaultTabController.of(context).animateTo(1);
          },
          child: const Text(
            "Inscription",
            style: TextStyle(color: Colors.blue),
          ),
        ),
      ],
    );
  }
}

class SignupTabContent extends StatefulWidget {
  const SignupTabContent({super.key});
  @override
  State<SignupTabContent> createState() => _SignupTabContentState();
}

class _SignupTabContentState extends State<SignupTabContent> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = true;
  bool _isConfirmPasswordVisible = true;
  void _submitForm() async {
    // 1. Validation du formulaire
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userService = AuthService();
      final user = await userService.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
      );
      if (user != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('success')));
      }
      // Si la connexion réussit :
      if (mounted) {
        context.go('/home_custom');
      }
    } catch (e) {
      // Gérer l'erreur (Snack bar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'inscription: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Form(
          // 2. On attache la clé GlobalKey<FormState> ici !
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ... Header (Sign up) ...
              const SizedBox(height: 60.0),
              const Text(
                "Inscription",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // ...

              // 3. CHAMPS AVEC CONTROLEURS ET VALIDATEURS
              _buildInputField(
                controller: _nameController,
                hintText: "Nom complet",
                icon: Icons.person,
                validator: (value) =>
                    value!.isEmpty ? 'Veuillez entrer votre nom.' : null,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                controller: _emailController,
                hintText: "Email",
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.isEmpty) return 'L\'email est obligatoire.';
                  // Règle minimale : vérifie la structure de l'email
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Format d\'email invalide.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildInputField(
                controller: _passwordController,
                hintText: "Mot de passe",
                icon: Icons.lock,
                isPassword: true,
                validator: (value) => value!.length < 6
                    ? 'Le mot de passe doit avoir au moins 6 caractères.'
                    : null,
                onTap: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                visible: _isPasswordVisible,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                controller: _confirmPasswordController,
                hintText: "Confirmer Mot de passe",
                icon: Icons.lock,
                isPassword: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Les mots de passe ne correspondent pas.';
                  }
                  return null;
                },
                onTap: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
                visible: _isConfirmPasswordVisible,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                controller: _phoneController,
                hintText: "Entrer un numero pour vous joindre ",
                keyboardType: TextInputType.number,
                icon: Icons.phone,
                isPassword: false,
                validator: (value) =>
                    value!.length < 8 ? 'Entrer un numero valide' : null,
              ),
              const SizedBox(height: 20),

              // Bouton d'inscription
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : _submitForm, // Désactiver pendant le chargement
                style: ElevatedButton.styleFrom(
                  shape: StadiumBorder(),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        "Inscription",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
              ),

              // ... Or, Google Sign In, Login Button ...
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("Deja un Compte?"),
                  TextButton(
                    onPressed: () => DefaultTabController.of(
                      context,
                    ).animateTo(0), // Navigation vers l'onglet Connexion
                    child: const Text(
                      "Connexion",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Fonction pour construire un champ de saisie réutilisable
Widget _buildInputField({
  required TextEditingController controller,
  required String hintText,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  bool isPassword = false,
  bool visible = false,
  String? Function(String?)? validator,
  Function()? onTap,
}) {
  return TextFormField(
    controller: controller, // L'élément clé pour lier le champ au contrôleur
    decoration: InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      fillColor: Colors.blue.withOpacity(0.1),
      filled: true,
      prefixIcon: Icon(icon),
      suffixIcon: isPassword
          ? IconButton(
              onPressed: () {
                onTap?.call();
              },
              icon: Icon(Icons.remove_red_eye_rounded),
            )
          : null,
    ),
    keyboardType: keyboardType,
    obscureText: visible,
    validator: validator, // Le validateur
  );
}
