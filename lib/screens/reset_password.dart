import 'package:camelia_logistics/models/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPassword> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  void _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String emailToReset = _emailController.text.trim();
      final AggregateQuerySnapshot querySnapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .where('email', isEqualTo: emailToReset)
          .limit(1)
          .count()
          .get();

      if (querySnapshot.count == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text('$emailToReset n\'est pas inscrit'),
                ],
              ),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      await _authService.resetPassword(emailToReset);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lien de réinitialisation envoyé ! Vérifiez votre e-mail',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Erreur: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
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
      appBar: AppBar(
        title: Text(
          'Réinitialisation',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.grey.shade700,
            ),
          ),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6C63FF),
                strokeWidth: 2,
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withValues(alpha:0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            size: 40,
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                        const SizedBox(height: 20),
                         Text(
                          'Réinitialiser votre mot de passe',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Entrez votre adresse email pour recevoir un lien de réinitialisation',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            'Adresse email',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'votre.email@exemple.com',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              prefixIcon: Icon(
                                Icons.email_rounded,
                                color: Colors.grey.shade500,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6C63FF),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'L\'adresse email est requise';
                              }
                              if (!RegExp(
                                      r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(value)) {
                                return 'Veuillez entrer une adresse email valide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Un lien vous sera envoyé pour créer un nouveau mot de passe',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Material(
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: _isLoading ? null : _resetPassword,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6C63FF),
                                      Color(0xFF8B84FF)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      :  Text(
                                          'Envoyer le lien de réinitialisation',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Vous vous souvenez de votre mot de passe ?',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: const Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6C63FF),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Color(0xFF6C63FF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withValues(alpha:0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6C63FF).withValues(alpha:0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF6C63FF),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Le lien de réinitialisation sera valide pendant 1 heure',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32),
                ),
              ],
            ),
    );
  }
}