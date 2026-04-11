import 'package:camelia/models/services/admin_service.dart';
import 'package:camelia/models/services/firebase_service.dart';
import 'package:camelia/models/services/user_profile_service.dart';
import 'package:camelia/models/services/phone_auth_service.dart';
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

  // Gestion des onglets
  late TabController _tabController;
  int _previousTabIndex = 0;
  bool _isProgrammaticChange = false;

  // État OTP partagé
  bool _otpInProgress = false;

  // Clés pour accéder aux états des onglets
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
      // Tentative de changement alors qu'un processus OTP est actif
      _tabController.animateTo(_previousTabIndex); // on annule le changement
      _showConfirmationDialog(); // on demande confirmation
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
  final PhoneAuthService _phoneAuthService = PhoneAuthService();

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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l10n.error}: $message'), backgroundColor: Colors.red),
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
                SnackBar(content: Text('Erreur auto-vérification: $e'), backgroundColor: Colors.red),
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
        SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: Colors.red),
      );
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
        SnackBar(content: Text('${l10n.error}: ${e.toString()}'), backgroundColor: Colors.red),
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
    if (_otpSent) {
      await _verifyOtp();
    } else {
      await _sendOtp();
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    _loadingTimeoutTimer?.cancel();
    if (!_otpProcessEnded && (_otpSent || _verificationId != null)) {
      widget.onOtpEnded();
    }
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
            const SizedBox(height: 30),

            // Numéro de téléphone
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
                              _otpSent ? 'Vérifier OTP' : 'Envoyer OTP',
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
                  onTap: () => DefaultTabController.of(context).animateTo(1),
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

  const SignupTabContent({
    super.key,
    required this.onAuthInProgressChanged,
    required this.onOtpStarted,
    required this.onOtpEnded,
  });

  @override
  State<SignupTabContent> createState() => _SignupTabContentState();
}

class _SignupTabContentState extends State<SignupTabContent> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

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
        SnackBar(content: Text('${l10n.error}: ${e.toString()}'), backgroundColor: Colors.red),
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
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.error}: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  void _submitForm() async {
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
                    '${l10n.error}: ${e.toString().replaceAll('Exception: ', '')}',
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
    _timer?.cancel();
    _loadingTimeoutTimer?.cancel();
    if (!_otpProcessEnded && (!_isPhoneVerified && _verificationId != null)) {
      widget.onOtpEnded();
    }
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
            const SizedBox(height: 30),

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
                validator: (value) => value == null || value.isEmpty ? l10n.nameRequired : null,
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
                  if (value == null || value.number.isEmpty) return l10n.phoneRequired;
                  if (value.number.length < 8) return l10n.invalidPhone;
                  return null;
                },
              ),
            ),
            const SizedBox(height: 10),

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
                              l10n.createMyAccount,
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
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
                Text(l10n.alreadyHaveAccount, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
                GestureDetector(
                  onTap: () => DefaultTabController.of(context).animateTo(0),
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