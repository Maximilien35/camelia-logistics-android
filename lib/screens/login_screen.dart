import 'package:camelia/models/services/admin_service.dart';
import 'package:camelia/models/services/firebase_service.dart';
import 'package:camelia/models/services/user_profile_service.dart';
import 'package:camelia/models/services/phone_auth_service.dart';
import 'package:camelia/models/services/error_handler_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camelia/l10n/app_localizations.dart';
import 'package:camelia/models/services/launch_url.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final AdminService admin = AdminService();
  bool _isAuthInProgress = false;

  late TabController _tabController;
  int _previousTabIndex = 0;
  bool _isProgrammaticChange = false;

  bool _otpInProgress = false;

  final GlobalKey<_LoginTabContentState> _loginTabKey = GlobalKey<_LoginTabContentState>();
  final GlobalKey<_SignupTabContentState> _signupTabKey = GlobalKey<_SignupTabContentState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_isProgrammaticChange && _otpInProgress && _tabController.index != _previousTabIndex) {
      _tabController.animateTo(_previousTabIndex); 
      _showConfirmationDialog(); 
    } else {
      _previousTabIndex = _tabController.index;
    }
    _isProgrammaticChange = false;
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Changement d\'onglet',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Un code de vérification est en cours. Êtes-vous sûr de vouloir changer d\'onglet ?\nLe code ne sera plus valide.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              _cancelOtpInCurrentTab();
              // Changer l'onglet programmatiquement
              _isProgrammaticChange = true;
              final newIndex = _previousTabIndex == 0 ? 1 : 0;
              _tabController.animateTo(newIndex);
              _previousTabIndex = newIndex;
            },
            child: Text('Confirmer', style: GoogleFonts.poppins(color: const Color(0xFF6C63FF))),
          ),
        ],
      ),
    );
  }

  void _cancelOtpInCurrentTab() {
    final currentIndex = _tabController.index;
    if (currentIndex == 0) {
      _loginTabKey.currentState?.cancelOtpProcess();
    } else {
      _signupTabKey.currentState?.cancelOtpProcess();
    }
  }

  void _onOtpStarted() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _otpInProgress = true);
    });
  }

  void _onOtpEnded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _otpInProgress = false);
    });
  }

  void _setAuthInProgress(bool value) {
    if (mounted) setState(() => _isAuthInProgress = value);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Stack(
        children: [
          IgnorePointer(
            ignoring: _isAuthInProgress,
            child: Container(
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
                  // Header (inchangé)
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
                              GestureDetector(
                                onTap: () {
                                  launchURL(
                                    'https://camelia-website.onrender.com/legal.html#about',
                                    context,
                                  );
                                },
                                child: Container(
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
                                  color: Color(0xFF6C63FF),
                                  size: 36,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                l10n.appName,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                l10n.expressDeliveryService,
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
                              controller: _tabController,
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
                              tabs: [
                                Tab(text: l10n.loginTab),
                                Tab(text: l10n.signupTab),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              physics: _otpInProgress ? const NeverScrollableScrollPhysics() : null,
                              children: [
                                LoginTabContent(
                                  key: _loginTabKey,
                                  onAuthInProgressChanged: _setAuthInProgress,
                                  onOtpStarted: _onOtpStarted,
                                  onOtpEnded: _onOtpEnded,
                                ),
                                SignupTabContent(
                                  key: _signupTabKey,
                                  onAuthInProgressChanged: _setAuthInProgress,
                                  onOtpStarted: _onOtpStarted,
                                  onOtpEnded: _onOtpEnded,
                                  onTabChanged: (tabIndex) {
                                    _isProgrammaticChange = true;
                                    _tabController.animateTo(tabIndex);
                                  },
                                ),
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
          if (_isAuthInProgress)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LoginTabContent extends StatefulWidget {
  final ValueChanged<bool> onAuthInProgressChanged;
  final VoidCallback onOtpStarted;
  final VoidCallback onOtpEnded;

  const LoginTabContent({
    super.key,
    required this.onAuthInProgressChanged,
    required this.onOtpStarted,
    required this.onOtpEnded,
  });

  @override
  State<LoginTabContent> createState() => _LoginTabContentState();
}

class _LoginTabContentState extends State<LoginTabContent> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final PhoneAuthService _phoneAuthService = PhoneAuthService();
  final ErrorHandlerService _errorHandler = ErrorHandlerService();
  final AuthService _authService = AuthService();

  bool _useEmail = false;
  bool _obscurePassword = true;
  String _loginPhoneNumber = '';
  bool _isLoading = false;
  bool _otpSent = false;
  String? _verificationId;
  int _countdown = 0;
  Timer? _timer;
  Timer? _loadingTimeoutTimer;

  // Pour éviter d'appeler plusieurs fois onOtpEnded
  bool _otpProcessEnded = false;

  void _setAuthInProgress(bool value) {
    if (mounted) {
      setState(() => _isLoading = value);
      widget.onAuthInProgressChanged(value);
    }
  }

  void _toggleAuthMethod(bool useEmail) {
    if (_useEmail == useEmail) return;
    if (!_useEmail && (_otpSent || _verificationId != null)) {
      cancelOtpProcess();
    }
    if (mounted) setState(() => _useEmail = useEmail);
  }

  void _startCountdown() {
    setState(() => _countdown = 40);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void cancelOtpProcess() {
    if (!_otpSent && _verificationId == null) return; // pas de processus actif
    _timer?.cancel();
    _loadingTimeoutTimer?.cancel();
    if (mounted) {
      setState(() {
        _otpSent = false;
        _verificationId = null;
        _countdown = 0;
        _isLoading = false;
      });
      // Notifier le parent que le processus est terminé
      if (!_otpProcessEnded) {
        _otpProcessEnded = true;
        widget.onOtpEnded();
      }
    }
  }

  Future<void> _sendOtp() async {
    final l10n = AppLocalizations.of(context)!;

    // Validation du formulaire
    if (!_formKey.currentState!.validate()) return;

    if (_loginPhoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.phoneRequired),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    String phoneNumber = _loginPhoneNumber.trim();
    if (!phoneNumber.startsWith('+')) phoneNumber = '+$phoneNumber';

    // Vérifier l'existence du compte
    final existingProfile = await UserProfileService().getProfileByPhone(phoneNumber);
    if (existingProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun compte trouvé pour ce numéro. Veuillez vous inscrire.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _otpProcessEnded = false;
    _setAuthInProgress(true);
    widget.onOtpStarted(); // Notifier le parent

    try {
      await _phoneAuthService.sendCode(
        phoneNumber: phoneNumber,
        onCodeSent: (String verificationId) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _otpSent = true;
              _isLoading = false;
            });
            widget.onAuthInProgressChanged(false);
            _startCountdown();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Code envoyé'), backgroundColor: Colors.green),
            );
          }
        },
        onVerificationFailed: (String message) {
          if (mounted) {
            setState(() => _isLoading = false);
            widget.onAuthInProgressChanged(false);
            if (!_otpProcessEnded) {
              _otpProcessEnded = true;
              widget.onOtpEnded();
            }
            final errorMessage = _errorHandler.handleError(Exception(message));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
            );
          }
        },
        onAutoRetrievalTimeout: () {
          if (mounted) setState(() => _isLoading = false);
        },
        onAutoVerified: (PhoneAuthCredential credential) async {
          try {
            final userCredential = await _phoneAuthService.signInWithCredential(credential);
            await _onLoggedIn(userCredential);
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              if (!_otpProcessEnded) {
                _otpProcessEnded = true;
                widget.onOtpEnded();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_errorHandler.handleError(e)), backgroundColor: Colors.red),
              );
            }
          }
        },
      );

      // Timeout de sécurité
      _loadingTimeoutTimer?.cancel();
      _loadingTimeoutTimer = Timer(const Duration(minutes: 6), () {
        if (mounted && _isLoading) {
          setState(() => _isLoading = false);
          if (!_otpProcessEnded) {
            _otpProcessEnded = true;
            widget.onOtpEnded();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Timeout de vérification dépassé. Veuillez réessayer.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    } catch (e) {
      _setAuthInProgress(false);
      if (!_otpProcessEnded) {
        _otpProcessEnded = true;
        widget.onOtpEnded();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorHandler.handleError(e)), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    _setAuthInProgress(true);
    try {
      final user = await _authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (user != null && mounted) {
        final userProfile = await UserProfileService().getProfileFresh(user.uid);
        if (userProfile != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connexion réussie !'), backgroundColor: Colors.green),
          );
          if (userProfile.role == 'admin') {
            context.go('/admin');
          } else if (userProfile.role == 'collaborator') {
            context.go('/collaborator/home');
          } else {
            context.go('/home_custom');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorHandler.handleError(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) _setAuthInProgress(false);
    }
  }

  Future<void> _verifyOtp() async {
    final l10n = AppLocalizations.of(context)!;
    if (_verificationId == null || _otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidOtp), backgroundColor: Colors.red),
      );
      return;
    }

    _setAuthInProgress(true);
    try {
      final userCredential = await _phoneAuthService.verifyCode(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      if (userCredential == null) throw Exception('Échec de l’authentification.');
      await _onLoggedIn(userCredential);
    } catch (e) {
      _setAuthInProgress(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorHandler.handleError(e)), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _onLoggedIn(UserCredential userCredential) async {
    final user = userCredential.user;
    if (user == null) throw Exception('Utilisateur introuvable après authentification.');
    final userProfile = await UserProfileService().getProfileFresh(user.uid);
    if (userProfile == null) throw Exception('Profil utilisateur introuvable.');
    if (!userProfile.isActive) throw Exception('Compte désactivé.');

    if (mounted) {
      _setAuthInProgress(false);
      if (!_otpProcessEnded) {
        _otpProcessEnded = true;
        widget.onOtpEnded();
      }
      if (userProfile.role == 'admin') {
        context.go('/admin');
      } else if (userProfile.role == 'collaborator') {
        context.go('/collaborator/home');
      } else {
        context.go('/home_custom');
      }
    }
  }

  void _submitLogin() async {
    if (_useEmail) {
      await _loginWithEmail();
    } else if (_otpSent) {
      await _verifyOtp();
    } else {
      await _sendOtp();
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _timer?.cancel();
    _loadingTimeoutTimer?.cancel();
    if (!_otpProcessEnded && (_otpSent || _verificationId != null)) {
      widget.onOtpEnded();
    }
    super.dispose();
  }

  Widget _buildAuthToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _toggleAuthMethod(false),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: _useEmail ? Colors.grey.shade100 : const Color(0xFF6C63FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF6C63FF)),
              ),
              child: Center(
                child: Text(
                  'OTP',
                  style: GoogleFonts.poppins(
                    color: _useEmail ? Colors.grey.shade700 : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _toggleAuthMethod(true),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: _useEmail ? const Color(0xFF6C63FF) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF6C63FF)),
              ),
              child: Center(
                child: Text(
                  'Email',
                  style: GoogleFonts.poppins(
                    color: _useEmail ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.welcomeBack,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  l10n.gladToSeeYou,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildAuthToggle(),
            const SizedBox(height: 25),

            if (_useEmail) ...[
              // Email
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
                ),
                child: TextFormField(
                  controller: _emailController,
                  style: GoogleFonts.poppins(),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: l10n.emailHint,
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      child: const Icon(Icons.email_rounded, color: Color(0xFF6C63FF), size: 22),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email requis';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Email invalide';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
                ),
                child: TextFormField(
                  controller: _passwordController,
                  style: GoogleFonts.poppins(),
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Mot de passe',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      child: const Icon(Icons.lock_rounded, color: Color(0xFF6C63FF), size: 22),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade400,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Mot de passe requis';
                    if (value.length < 6) return 'Minimum 6 caractères';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    if (_emailController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez entrer votre email d\'abord'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    try {
                      await _authService.resetPassword(_emailController.text.trim());
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email de réinitialisation envoyé'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_errorHandler.handleError(e)),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    'Mot de passe oublié ?',
                    style: GoogleFonts.poppins(color: const Color(0xFF6C63FF), fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ] else ...[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
                ),
                child: IntlPhoneField(
                  initialCountryCode: 'CM',
                  enabled: !_isLoading && !_otpSent,
                  onChanged: (phone) => _loginPhoneNumber = phone.completeNumber,
                  validator: (value) {
                    if (value == null || value.number.isEmpty) return l10n.phoneRequired;
                    if (value.number.length < 8 || value.number.length > 15) return l10n.invalidPhone;
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: l10n.phoneHint,
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      child: const Icon(Icons.phone_rounded, color: Color(0xFF6C63FF), size: 22),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_otpSent)
                Column(
                  children: [
                    Text('Entrez le code OTP ($_countdown s)', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
                    const SizedBox(height: 10),
                    Pinput(
                      controller: _otpController,
                      length: 6,
                      onCompleted: (_) => _verifyOtp(),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _countdown == 0 ? _sendOtp : null,
                      child: Text(
                        _countdown == 0 ? 'Renvoyer le code' : 'Renvoyer dans $_countdown s',
                        style: GoogleFonts.poppins(color: const Color(0xFF6C63FF)),
                      ),
                    ),
                  ],
                ),
            ],

            const SizedBox(height: 10),

            // Bouton principal
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
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              _useEmail ? 'Se connecter' : (_otpSent ? 'Vérifier OTP' : 'Envoyer OTP'),
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
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
                Text(l10n.noAccount, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
                GestureDetector(
                  onTap: () {
                    if (context.findAncestorStateOfType<LoginPageState>() != null) {
                      context.findAncestorStateOfType<LoginPageState>()?._tabController.animateTo(1);
                    }
                  },
                  child: Text(
                    l10n.signUp,
                    style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6C63FF), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class SignupTabContent extends StatefulWidget {
  final ValueChanged<bool> onAuthInProgressChanged;
  final VoidCallback onOtpStarted;
  final VoidCallback onOtpEnded;
  final ValueChanged<int> onTabChanged;

  const SignupTabContent({
    super.key,
    required this.onAuthInProgressChanged,
    required this.onOtpStarted,
    required this.onOtpEnded,
    required this.onTabChanged,
  });

  @override
  State<SignupTabContent> createState() => _SignupTabContentState();
}

class _SignupTabContentState extends State<SignupTabContent> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final ErrorHandlerService _errorHandler = ErrorHandlerService();
  final AuthService _authService = AuthService();

  bool _useEmail = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isPhoneVerified = false;
  bool _isVerifyingPhone = false;
  String? _verificationId;
  String _completePhoneNumber = '';
  int _countdown = 0;
  Timer? _timer;
  Timer? _loadingTimeoutTimer;
  bool _otpProcessEnded = false;

  void _setAuthInProgress(bool value) {
    if (mounted) {
      setState(() => _isLoading = value);
      widget.onAuthInProgressChanged(value);
    }
  }

  void _toggleAuthMethod(bool useEmail) {
    if (_useEmail == useEmail) return;
    if (!_useEmail && (_verificationId != null || _isVerifyingPhone)) {
      cancelOtpProcess();
    }
    if (mounted) setState(() => _useEmail = useEmail);
  }

  void _startCountdown() {
    setState(() => _countdown = 40);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  // Annulation du processus OTP
  void cancelOtpProcess() {
    if (_isPhoneVerified) return; // déjà vérifié
    _timer?.cancel();
    _loadingTimeoutTimer?.cancel();
    if (mounted) {
      setState(() {
        _isVerifyingPhone = false;
        _verificationId = null;
        _countdown = 0;
      });
      if (!_otpProcessEnded) {
        _otpProcessEnded = true;
        widget.onOtpEnded();
      }
    }
  }

  void _sendSmsCode() async {
    final l10n = AppLocalizations.of(context)!;

    // Validation du formulaire pour le téléphone
    if (!_formKey.currentState!.validate()) return;

    if (_completePhoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.phoneRequired), backgroundColor: Colors.red),
      );
      return;
    }
    final existingProfile = await UserProfileService().getProfileByPhone(_completePhoneNumber);
    if (existingProfile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Un compte existe déjà pour ce numéro. Veuillez vous connecter.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _otpProcessEnded = false;
    setState(() => _isVerifyingPhone = true);
    widget.onOtpStarted();

    try {
      final phoneAuthService = PhoneAuthService();
      await phoneAuthService.sendCode(
        phoneNumber: _completePhoneNumber,
        onCodeSent: (verificationId) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _isVerifyingPhone = false;
            });
            _startCountdown();
          }
        },
        onVerificationFailed: (error) {
          if (mounted) {
            setState(() => _isVerifyingPhone = false);
            if (!_otpProcessEnded) {
              _otpProcessEnded = true;
              widget.onOtpEnded();
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l10n.error}: $error'), backgroundColor: Colors.red),
            );
          }
        },
        onAutoRetrievalTimeout: () {
          if (mounted) setState(() => _isVerifyingPhone = false);
        },
        onAutoVerified: (credential) async {
          if (mounted) {
            setState(() {
              _isPhoneVerified = true;
              _isVerifyingPhone = false;
            });
            if (!_otpProcessEnded) {
              _otpProcessEnded = true;
              widget.onOtpEnded();
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.phoneVerified), backgroundColor: Colors.green),
            );
          }
        },
      );

      _loadingTimeoutTimer?.cancel();
      _loadingTimeoutTimer = Timer(const Duration(minutes: 6), () {
        if (mounted && _isVerifyingPhone) {
          setState(() => _isVerifyingPhone = false);
          if (!_otpProcessEnded) {
            _otpProcessEnded = true;
            widget.onOtpEnded();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Timeout de vérification dépassé. Veuillez réessayer.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    } catch (e) {
      setState(() => _isVerifyingPhone = false);
      if (!_otpProcessEnded) {
        _otpProcessEnded = true;
        widget.onOtpEnded();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorHandler.handleError(e)), backgroundColor: Colors.red),
      );
    }
  }

  void _verifyOtp() async {
    final l10n = AppLocalizations.of(context)!;
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidOtp), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final phoneAuthService = PhoneAuthService();
      await phoneAuthService.verifyCode(
        verificationId: _verificationId!,
        smsCode: _otpController.text,
      );
      if (mounted) {
        setState(() {
          _isPhoneVerified = true;
          _isLoading = false;
        });
        if (!_otpProcessEnded) {
          _otpProcessEnded = true;
          widget.onOtpEnded();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.phoneVerified), backgroundColor: Colors.green),
        );
        _submitForm();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorHandler.handleError(e)), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _signupWithEmail() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_completePhoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.phoneRequired), backgroundColor: Colors.red),
      );
      return;
    }

    _setAuthInProgress(true);
    try {
      final fullName = '${_firstNameController.text.trim()} ${_nameController.text.trim()}'.trim();
      final user = await _authService.signUpWithEmail(
        name: fullName,
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phoneNumber: _completePhoneNumber,
      );

      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscription réussie ! Vérifiez votre email pour confirmer votre compte.\nN\'oubliez pas de vérifier vos spams.'), backgroundColor: Colors.green),
        );
        widget.onTabChanged(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorHandler.handleError(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) _setAuthInProgress(false);
    }
  }

  void _submitForm() async {
    if (_useEmail) {
      await _signupWithEmail();
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (!_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.verifyPhoneFirst), backgroundColor: Colors.red),
      );
      return;
    }

    _setAuthInProgress(true);
    try {
      final userService = AuthService();
      final user = await userService.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _completePhoneNumber,
      );

      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text(l10n.registrationSuccess, style: GoogleFonts.poppins()),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 10,
          ),
        );
        context.go('/home_custom');
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
                    _errorHandler.handleError(e),
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 10,
          ),
        );
      }
    } finally {
      if (mounted) _setAuthInProgress(false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    _loadingTimeoutTimer?.cancel();
    if (!_otpProcessEnded && (!_isPhoneVerified && _verificationId != null)) {
      widget.onOtpEnded();
    }
    super.dispose();
  }

  Widget _buildAuthToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _toggleAuthMethod(false),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: _useEmail ? Colors.grey.shade100 : const Color(0xFF6C63FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF6C63FF)),
              ),
              child: Center(
                child: Text(
                  'OTP',
                  style: GoogleFonts.poppins(
                    color: _useEmail ? Colors.grey.shade700 : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _toggleAuthMethod(true),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: _useEmail ? const Color(0xFF6C63FF) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF6C63FF)),
              ),
              child: Center(
                child: Text(
                  'Email',
                  style: GoogleFonts.poppins(
                    color: _useEmail ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.createAccount,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  l10n.joinCommunity,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildAuthToggle(),
            const SizedBox(height: 25),

            if (_useEmail) ...[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
                ),
                child: TextFormField(
                  controller: _firstNameController,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    hintText: 'Prénom',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      child: const Icon(Icons.person_outline_rounded, color: Color(0xFF6C63FF), size: 22),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Prénom requis' : null,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
                ),
                child: TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    hintText: 'Nom de famille',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      child: const Icon(Icons.person_outline_rounded, color: Color(0xFF6C63FF), size: 22),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Nom requis' : null,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
                ),
                child: TextFormField(
                  controller: _emailController,
                  style: GoogleFonts.poppins(),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: l10n.emailHint,
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      child: const Icon(Icons.email_rounded, color: Color(0xFF6C63FF), size: 22),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email requis';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Email invalide';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
                ),
                child: IntlPhoneField(
                  controller: _phoneController,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    hintText: l10n.phoneHint,
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  ),
                  initialCountryCode: 'CM',
                  onChanged: (phone) => _completePhoneNumber = phone.completeNumber,
                  validator: (value) {
                    if (value == null || value.number.isEmpty) return 'Téléphone requis';
                    if (value.number.length < 8) return 'Numéro invalide';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
                ),
                child: TextFormField(
                  controller: _passwordController,
                  style: GoogleFonts.poppins(),
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Mot de passe',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      child: const Icon(Icons.lock_rounded, color: Color(0xFF6C63FF), size: 22),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade400,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Mot de passe requis';
                    if (value.length < 6) return 'Minimum 6 caractères';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
                ),
                child: TextFormField(
                  controller: _confirmPasswordController,
                  style: GoogleFonts.poppins(),
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Confirmer le mot de passe',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      child: const Icon(Icons.lock_rounded, color: Color(0xFF6C63FF), size: 22),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade400,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Confirmation requise';
                    if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),
              ),
            ] else ...[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
                ),
                child: TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    hintText: l10n.nameHint,
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      child: const Icon(Icons.person_outline_rounded, color: Color(0xFF6C63FF), size: 22),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  ),
                  validator: (value) => value == null || value.isEmpty ? l10n.nameRequired : null,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
                ),
                child: TextFormField(
                  controller: _emailController,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    hintText: l10n.emailHint,
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      child: const Icon(Icons.email_rounded, color: Color(0xFF6C63FF), size: 22),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return l10n.emailRequired;
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return l10n.invalidEmail;
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
                ),
                child: IntlPhoneField(
                  controller: _phoneController,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    hintText: l10n.phoneHint,
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  ),
                  initialCountryCode: 'CM',
                  onChanged: (phone) => _completePhoneNumber = phone.completeNumber,
                  validator: (value) {
                    if (value == null || value.number.isEmpty) return l10n.phoneRequired;
                    if (value.number.length < 8) return l10n.invalidPhone;
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (!_isPhoneVerified && _verificationId == null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isVerifyingPhone ? null : _sendSmsCode,
                    child: Text(
                      _isVerifyingPhone ? l10n.sendingCode : l10n.verifyPhone,
                      style: GoogleFonts.poppins(color: const Color(0xFF6C63FF), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              if (_verificationId != null && !_isPhoneVerified)
                Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      l10n.enterOtp,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 10),
                    Pinput(
                      controller: _otpController,
                      length: 6,
                      defaultPinTheme: PinTheme(
                        width: 50,
                        height: 50,
                        textStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF6C63FF)),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                      ),
                      focusedPinTheme: PinTheme(
                        width: 50,
                        height: 50,
                        textStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF6C63FF)),
                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFF6C63FF)), borderRadius: BorderRadius.circular(12)),
                      ),
                      onCompleted: (pin) => _verifyOtp(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _countdown > 0 ? '${l10n.resendIn} $_countdown s' : l10n.resendCode,
                          style: GoogleFonts.poppins(color: Colors.grey.shade600),
                        ),
                        if (_countdown == 0)
                          TextButton(
                            onPressed: _sendSmsCode,
                            child: Text(l10n.resend, style: GoogleFonts.poppins(color: const Color(0xFF6C63FF), fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ],
                ),
              if (_isPhoneVerified)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        l10n.phoneVerified,
                        style: GoogleFonts.poppins(color: Colors.green.shade700, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 30),
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
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              _useEmail ? 'S\'inscrire' : l10n.createMyAccount,
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Lien vers connexion
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.alreadyHaveAccount, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
                GestureDetector(
                  onTap: () {
                    if (context.findAncestorStateOfType<_EmailTabContentState>() != null) {
                      context.findAncestorStateOfType<_EmailTabContentState>()?._emailTabController.animateTo(0);
                    }
                  },
                  child: Text(
                    l10n.login,
                    style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6C63FF), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class EmailTabContent extends StatefulWidget {
  final ValueChanged<bool> onAuthInProgressChanged;

  const EmailTabContent({
    super.key,
    required this.onAuthInProgressChanged,
  });

  @override
  State<EmailTabContent> createState() => _EmailTabContentState();
}

class _EmailTabContentState extends State<EmailTabContent> with SingleTickerProviderStateMixin {
  late TabController _emailTabController;
  final GlobalKey<_EmailLoginContentState> _loginKey = GlobalKey<_EmailLoginContentState>();
  final GlobalKey<_EmailSignupContentState> _signupKey = GlobalKey<_EmailSignupContentState>();

  @override
  void initState() {
    super.initState();
    _emailTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _emailTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        // Sous-onglets pour Email
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _emailTabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade700,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: l10n.loginTab),
              Tab(text: l10n.signupTab),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: TabBarView(
            controller: _emailTabController,
            children: [
              EmailLoginContent(
                key: _loginKey,
                onAuthInProgressChanged: widget.onAuthInProgressChanged,
              ),
              EmailSignupContent(
                key: _signupKey,
                onAuthInProgressChanged: widget.onAuthInProgressChanged,
                onTabChanged: (tabIndex) {
                  _emailTabController.animateTo(tabIndex);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EmailLoginContent extends StatefulWidget {
  final ValueChanged<bool> onAuthInProgressChanged;

  const EmailLoginContent({
    super.key,
    required this.onAuthInProgressChanged,
  });

  @override
  State<EmailLoginContent> createState() => _EmailLoginContentState();
}

class _EmailLoginContentState extends State<EmailLoginContent> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final ErrorHandlerService _errorHandler = ErrorHandlerService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  void _setAuthInProgress(bool value) {
    if (mounted) {
      setState(() => _isLoading = value);
      widget.onAuthInProgressChanged(value);
    }
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    _setAuthInProgress(true);
    try {
      final user = await _authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (user != null && mounted) {
        final userProfile = await UserProfileService().getProfileFresh(user.uid);
        if (userProfile != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connexion réussie !'),
              backgroundColor: Colors.green,
            ),
          );

          if (userProfile.role == 'admin') {
            context.go('/admin');
          } else if (userProfile.role == 'collaborator') {
            context.go('/collaborator/home');
          } else {
            context.go('/home_custom');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorHandler.handleError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) _setAuthInProgress(false);
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
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connexion par Email',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Utilisez votre email et mot de passe',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Email
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
              ),
              child: TextFormField(
                controller: _emailController,
                style: GoogleFonts.poppins(),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: l10n.emailHint,
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    child: const Icon(Icons.email_rounded, color: Color(0xFF6C63FF), size: 22),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email requis';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Email invalide';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),

            // Mot de passe
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
              ),
              child: TextFormField(
                controller: _passwordController,
                style: GoogleFonts.poppins(),
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Mot de passe',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    child: const Icon(Icons.lock_rounded, color: Color(0xFF6C63FF), size: 22),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade400,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Mot de passe requis';
                  if (value.length < 6) return 'Minimum 6 caractères';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 10),

            // Lien mot de passe oublié
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  if (_emailController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez entrer votre email d\'abord'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  try {
                    await _authService.resetPassword(_emailController.text.trim());
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email de réinitialisation envoyé'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_errorHandler.handleError(e)),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  'Mot de passe oublié ?',
                  style: GoogleFonts.poppins(color: const Color(0xFF6C63FF), fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Bouton connexion
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
                  onTap: _isLoading ? null : _loginWithEmail,
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
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              'Se connecter',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Lien vers inscription
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Pas de compte ? ', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
                GestureDetector(
                  onTap: () {
                    if (context.findAncestorStateOfType<LoginPageState>() != null) {
                      context.findAncestorStateOfType<LoginPageState>()?._tabController.animateTo(1);
                    }
                  },
                  child: Text(
                    'S\'inscrire',
                    style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6C63FF), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class EmailSignupContent extends StatefulWidget {
  final ValueChanged<bool> onAuthInProgressChanged;
  final ValueChanged<int> onTabChanged;

  const EmailSignupContent({
    super.key,
    required this.onAuthInProgressChanged,
    required this.onTabChanged,
  });

  @override
  State<EmailSignupContent> createState() => _EmailSignupContentState();
}

class _EmailSignupContentState extends State<EmailSignupContent> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final ErrorHandlerService _errorHandler = ErrorHandlerService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _completePhoneNumber = '';

  void _setAuthInProgress(bool value) {
    if (mounted) {
      setState(() => _isLoading = value);
      widget.onAuthInProgressChanged(value);
    }
  }

  Future<void> _signupWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _setAuthInProgress(true);
    try {
      final fullName = '${_firstNameController.text.trim()} ${_nameController.text.trim()}'.trim();
      final user = await _authService.signUpWithEmail(
        name: fullName,
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phoneNumber: _completePhoneNumber,
      );

      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie ! Vérifiez votre email pour confirmer votre compte.\nN\'oubliez pas de vérifier vos spams.'),
            backgroundColor: Colors.green,
          ),
        );
        // Rediriger vers la page de connexion email
        widget.onTabChanged(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorHandler.handleError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) _setAuthInProgress(false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inscription par Email',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Créez votre compte avec email et mot de passe',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Prénom
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
              ),
              child: TextFormField(
                controller: _firstNameController,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  hintText: 'Prénom',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    child: const Icon(Icons.person_outline_rounded, color: Color(0xFF6C63FF), size: 22),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Prénom requis' : null,
              ),
            ),
            const SizedBox(height: 20),

            // Nom
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
              ),
              child: TextFormField(
                controller: _nameController,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  hintText: l10n.nameHint,
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    child: const Icon(Icons.person_outline_rounded, color: Color(0xFF6C63FF), size: 22),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Nom requis' : null,
              ),
            ),
            const SizedBox(height: 20),

            // Email
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
              ),
              child: TextFormField(
                controller: _emailController,
                style: GoogleFonts.poppins(),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: l10n.emailHint,
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    child: const Icon(Icons.email_rounded, color: Color(0xFF6C63FF), size: 22),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email requis';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Email invalide';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),

            // Téléphone
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
              ),
              child: IntlPhoneField(
                controller: _phoneController,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  hintText: l10n.phoneHint,
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                ),
                initialCountryCode: 'CM',
                onChanged: (phone) => _completePhoneNumber = phone.completeNumber,
                validator: (value) {
                  if (value == null || value.number.isEmpty) return 'Téléphone requis';
                  if (value.number.length < 8) return 'Numéro invalide';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),

            // Mot de passe
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
              ),
              child: TextFormField(
                controller: _passwordController,
                style: GoogleFonts.poppins(),
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Mot de passe',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    child: const Icon(Icons.lock_rounded, color: Color(0xFF6C63FF), size: 22),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade400,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Mot de passe requis';
                  if (value.length < 6) return 'Minimum 6 caractères';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),

            // Confirmation mot de passe
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 15, spreadRadius: 2)],
              ),
              child: TextFormField(
                controller: _confirmPasswordController,
                style: GoogleFonts.poppins(),
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: 'Confirmer le mot de passe',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    child: const Icon(Icons.lock_rounded, color: Color(0xFF6C63FF), size: 22),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade400,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Confirmation requise';
                  if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 30),

            // Bouton inscription
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
                  onTap: _isLoading ? null : _signupWithEmail,
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
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              'S\'inscrire',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Lien vers connexion
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Déjà un compte ? ', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
                GestureDetector(
                  onTap: () => widget.onTabChanged(0),
                  child: Text(
                    'Se connecter',
                    style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6C63FF), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}