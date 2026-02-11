import 'package:camelia_logistics/models/services/admin_service.dart';
import 'package:camelia_logistics/models/services/firebase_service.dart';
import 'package:camelia_logistics/models/services/user_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final AdminService admin = AdminService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF6C63FF).withValues(alpha:0.95),
                  const Color(0xFF8B84FF).withValues(alpha:0.95),
                  Colors.white,
                ],
                stops: const [0.0, 0.3, 0.3],
              ),
            ),
            child: Column(
              children: [
                // Header avec effet de vague
                Container(
                  height: 180,
                  padding: const EdgeInsets.only(top: 50),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha:0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              onPressed: () => context.go('/home'),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha:0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.help_outline_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha:0.2),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.delivery_dining_rounded,
                                color:  Color(0xFF6C63FF),
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Camelia Logistics",
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              "Livraison express à votre service",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha:0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Contenu principal
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.05),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        // Tabs avec design élégant
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 30),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TabBar(
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.grey.shade700,
                            indicator: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6C63FF).withValues(alpha:0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            labelStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            unselectedLabelStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            tabs: const [
                              Tab(text: 'Connexion'),
                              Tab(text: 'Inscription'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Expanded(
                          child: TabBarView(
                            children: [
                              LoginTabContent(),
                              SignupTabContent(),
                            ],
                          ),
                        ),
                      ],
                    ),
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
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _submitLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final user = await AuthService().signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (user != null) {
        final userSer = UserProfileService();
        final userProfile = await userSer.getProfile(user.uid);
        final String? role = userProfile?.role;

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
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    'Identifiants invalides',
                    style: GoogleFonts.poppins(),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 10,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Erreur: ${e.toString()}',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 10,
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
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bon retour !',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Content de vous revoir',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Formulaire
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Email
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha:0.1),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      hintText: 'votre.email@exemple.com',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        child:const Icon(
                          Icons.email_rounded,
                          color:  Color(0xFF6C63FF),
                          size: 22,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'L\'email est requis';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Format d\'email invalide';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Mot de passe
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha:0.1),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    style: GoogleFonts.poppins(),
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'Votre mot de passe',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        child:const Icon(
                          Icons.lock_rounded,
                          color:  Color(0xFF6C63FF),
                          size: 22,
                        ),
                      ),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        child: IconButton(
                          onPressed: () {
                            setState(() => _isPasswordVisible = !_isPasswordVisible);
                          },
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.grey.shade500,
                            size: 22,
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le mot de passe est requis';
                      }
                      if (value.length < 6) {
                        return 'Minimum 6 caractères';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Mot de passe oublié
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go('/reset'),
                    child: Text(
                      'Mot de passe oublié ?',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF6C63FF),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Bouton de connexion
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withValues(alpha:0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: _isLoading ? null : _submitLogin,
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: _isLoading
                              ?const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Se connecter',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Séparateur
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        'Ou continuer avec',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Bouton Google
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha:0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => AuthService().signInWithGoogle(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/log.webp'),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Text(
                              'Continuer avec Google',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Lien d'inscription
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pas encore de compte ? ',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        DefaultTabController.of(context).animateTo(1);
                      },
                      child: Text(
                        'S\'inscrire',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6C63FF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
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
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  void _submitForm() async {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    'Inscription réussie !',
                    style: GoogleFonts.poppins(),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 10,
            ),
          );
          context.go('/home_custom');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Erreur: ${e.toString()}',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 10,
          ),
        );
      }
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
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Créer un compte',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Rejoignez notre communauté',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Formulaire
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Nom
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha:0.1),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      hintText: 'Jean Pierre',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        child:const Icon(
                          Icons.person_outline_rounded,
                          color:  Color(0xFF6C63FF),
                          size: 22,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le nom est requis';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Email
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha:0.1),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      hintText: 'votre.email@exemple.com',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.email_rounded,
                          color:  Color(0xFF6C63FF),
                          size: 22,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'L\'email est requis';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Format d\'email invalide';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Mot de passe
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha:0.1),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    style: GoogleFonts.poppins(),
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'Minimum 6 caractères',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.lock_rounded,
                          color:  Color(0xFF6C63FF),
                          size: 22,
                        ),
                      ),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        child: IconButton(
                          onPressed: () {
                            setState(() => _isPasswordVisible = !_isPasswordVisible);
                          },
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.grey.shade500,
                            size: 22,
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le mot de passe est requis';
                      }
                      if (value.length < 6) {
                        return 'Minimum 6 caractères';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Confirmation mot de passe
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha:0.1),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    style: GoogleFonts.poppins(),
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'Confirmez votre mot de passe',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        child:const Icon(
                          Icons.lock_rounded,
                          color:  Color(0xFF6C63FF),
                          size: 22,
                        ),
                      ),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        child: IconButton(
                          onPressed: () {
                            setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                          },
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.grey.shade500,
                            size: 22,
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez confirmer votre mot de passe';
                      }
                      if (value != _passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Téléphone
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha:0.1),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _phoneController,
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      hintText: '6 XX XX XX XX',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        child:const Icon(
                          Icons.phone_rounded,
                          color:  Color(0xFF6C63FF),
                          size: 22,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le téléphone est requis';
                      }
                      if (value.length < 8) {
                        return 'Numéro invalide';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 30),

                // Bouton d'inscription
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withValues(alpha:0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: _isLoading ? null : _submitForm,
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: _isLoading
                              ?const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Créer mon compte',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // Lien de connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Déjà un compte ? ',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        DefaultTabController.of(context).animateTo(0);
                      },
                      child: Text(
                        'Se connecter',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6C63FF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}