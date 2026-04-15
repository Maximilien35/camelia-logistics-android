import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:go_router/go_router.dart';
import 'package:camelia/models/services/firebase_service.dart';
import 'package:camelia/models/services/user_profile_service.dart';

class CollaboratorAuthScreen extends StatefulWidget {
  const CollaboratorAuthScreen({super.key});

  @override
  State<CollaboratorAuthScreen> createState() => _CollaboratorAuthScreenState();
}

class _CollaboratorAuthScreenState extends State<CollaboratorAuthScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final bool _otpSent = false;
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = await AuthService().signIn(
        phoneNumber: _phoneController.text.trim(),
      );

      if (user != null) {
        final userSer = UserProfileService();
        final userProfile = await userSer.getProfileFresh(user.uid);
        final role = userProfile?.role;

        if (mounted) {
          if (role == 'admin') {
            context.go('/admin');
          } else if (role == 'collaborator') {
            context.go('/collaborator/home');
          } else {
            context.go('/home_custom');
          }
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('Identifiants invalides');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 10,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF6C63FF);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Espace Collaborateur',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gérez vos courses en toute simplicité',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 48),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Téléphone
                    TextFormField(
                      controller: _phoneController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Numéro de téléphone',
                        hintText: '+237 6xxxxxxx',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir votre numéro de téléphone';
                        }
                        return null;
                      },
                      style: GoogleFonts.poppins(),
                    ),
                    const SizedBox(height: 20),

                    // OTP
                    if (_otpSent)
                      Column(
                        children: [
                          Pinput(
                            controller: _otpController,
                            length: 6,
                            onCompleted: (_) => _submitLogin(),
                          ),
                          const SizedBox(height: 8),
                          Text('Entrez le code envoyé par SMS', style: GoogleFonts.poppins(fontSize: 12)),
                        ],
                      ),
                    const SizedBox(height: 32),

                    // Bouton de connexion
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Se connecter',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Info box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha:0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: primaryColor.withValues(alpha:0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '✓ Gérez toutes vos commandes\n'
                      '✓ Acceptez ou refusez rapidement\n'
                      '✓ Suivez vos revenus en temps réel\n'
                      '✓ Interface optimisée pour une connexion lente',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}