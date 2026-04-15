import 'package:camelia/models/services/admin_service.dart';
import 'package:camelia/models/services/firebase_service.dart';
import 'package:camelia/models/services/firebase_service.dart'
    hide CacheEntry;
import 'package:camelia/screens/reset_password.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camelia/screens/help_center.dart';
import 'package:camelia/models/services/launch_url.dart';
import 'package:camelia/models/services/user_profile_service.dart';
import 'package:camelia/screens/change_informations.dart';
class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});
  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  final AdminService _adminService = AdminService();
  final UserProfileService _profileService = UserProfileService();
  final TextEditingController _uidController = TextEditingController();
  final uid = FirebaseAuth.instance.currentUser?.uid;

  void _showPromoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool inProgress = false;
        String selectedSearchType = 'uid';
        String selectedRole = 'admin';
        final GlobalKey<FormState> promoFormKey = GlobalKey<FormState>();
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(28),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Promouvoir un utilisateur',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    Form(
                      key: promoFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rechercher par Email, Téléphone ou UID',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: selectedSearchType,
                            onChanged: (value) {
                              if (value != null) {
                                setStateDialog(() {
                                  selectedSearchType = value;
                                });
                              }
                            },
                            items: const [
                              DropdownMenuItem(value: 'uid', child: Text('UID')),
                              DropdownMenuItem(value: 'email', child: Text('Email')),
                              DropdownMenuItem(value: 'phone', child: Text('Téléphone')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Type d\'identifiant',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _uidController,
                            decoration: InputDecoration(
                              hintText:
                                  selectedSearchType == 'email'
                                      ? 'exemple@domaine.com'
                                      : selectedSearchType == 'phone'
                                          ? '+237612345678'
                                          : 'UID utilisateur',
                              prefixIcon: const Icon(Icons.search_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 20,
                              ),
                              counterText: '',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ce champ est requis';
                              }
                              return null;
                            },
                            style: GoogleFonts.poppins(fontSize: 15),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: selectedRole,
                            onChanged: (value) {
                              if (value != null) {
                                setStateDialog(() {
                                  selectedRole = value;
                                });
                              }
                            },
                            items: const [
                              DropdownMenuItem(value: 'admin', child: Text('Admin')),
                              DropdownMenuItem(value: 'collaborator', child: Text('Collaborateur')),
                              DropdownMenuItem(value: 'deliverer', child: Text('Livreur')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Rôle à attribuer',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                    
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: const BorderSide(
                              color: Color(0xFF6C63FF),
                            ),
                          ),
                          child: Text(
                            'Annuler',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF6C63FF),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withValues(alpha:0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Material(
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: inProgress
                                  ? null
                                  : () async {
                                      if (!promoFormKey.currentState!.validate()) {
                                        return;
                                      }

                                      setStateDialog(() => inProgress = true);
                                      try {
                                        final inputValue = _uidController.text.trim();
                                        String targetUid = inputValue;

                                        if (selectedSearchType == 'email') {
                                          final profile = await _profileService.getProfileByEmail(inputValue);
                                          if (profile == null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Utilisateur introuvable pour cet email.'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            setStateDialog(() => inProgress = false);
                                            return;
                                          }
                                          targetUid = profile.uid;
                                        } else if (selectedSearchType == 'phone') {
                                          String normalized = inputValue;
                                          if (!normalized.startsWith('+')) {
                                            normalized = '+$normalized';
                                          }
                                          final profile = await _profileService.getProfileByPhone(normalized);
                                          if (profile == null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Utilisateur introuvable pour ce numéro.'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            setStateDialog(() => inProgress = false);
                                            return;
                                          }
                                          targetUid = profile.uid;
                                        } else if (targetUid.length < 20) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('UID invalide.'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          setStateDialog(() => inProgress = false);
                                          return;
                                        }

                                        await _adminService.setRole(
                                          context: context,
                                          targetUid: targetUid,
                                          role: selectedRole,
                                          region: 'us-central1',
                                        );

                                        setStateDialog(() => inProgress = false);
                                        CacheManager.instance.invalidate(
                                          'userRole_$targetUid',
                                        );
                                        Navigator.of(context).pop();
                                      } on Exception catch (_) {
                                        setStateDialog(() => inProgress = false);
                                      }
                                    },
                              borderRadius: BorderRadius.circular(14),
                              child: Ink(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: inProgress
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.verified_rounded,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Promouvoir',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleLogout() async {
    try {
      await AuthService().signOut();
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  'Échec de la déconnexion,Verifier votre connexion internet',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 10,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Header avec gradient
          SliverAppBar(
            expandedHeight: 250,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6C63FF).withValues(alpha:0.95),
                      const Color(0xFF8B84FF).withValues(alpha:0.95),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    top: 70,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha:0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Stack(
                              children: [
                                Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),                              
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Paramètres',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 36,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gérez vos préférences et paramètres administrateur',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha:0.9),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Section Compte
          _buildSection(
            title: 'Compte',
            icon: Icons.account_circle_rounded,
            items: [
              _buildSettingItem(
                icon: Icons.person_outline_rounded,
                title: 'Profil Utilisateur',
                subtitle: 'Modifier vos informations personnelles',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangeInformations()),
                ),

              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.lock_outline_rounded,
                title: 'Changer le mot de passe',
                subtitle: 'Mettre à jour vos identifiants',
                onTap: () { 
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ResetPassword()),
                  );
                },
              ),
            ],
          ),
          
          // Section Administration
          _buildSection(
            title: 'Administration',
            icon: Icons.admin_panel_settings_rounded,
            items: [
              _buildSettingItem(
                icon: Icons.person_add_alt_1_rounded,
                title: 'Ajouter un administrateur',
                subtitle: 'Promouvoir un utilisateur',
                onTap: () => _showPromoteDialog(context),
                showChevron: true,
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Politique et Confidentialité',
                subtitle: 'Consulter nos conditions',
                onTap: () =>launchURL("https://camelia-website.onrender.com/legal.html#mentions-legales", context),
                showChevron: true,
              ),
             
            ],
          ),
          
          // Section Support
          _buildSection(
            title: 'Support',
            icon: Icons.support_agent_rounded,
            items: [
              _buildSettingItem(
                icon: Icons.help_outline_rounded,
                title: 'Centre d\'aide',
                subtitle: 'FAQ et guides',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpCenterPage()),
                  );
                },
                showChevron: true,
              ),
              // _buildDivider(),
              // _buildSettingItem(
              //   icon: Icons.feedback_outlined,
              //   title: 'Donner votre avis',
              //   subtitle: 'Partagez vos suggestions',
              //   onTap: () {},
              //   showChevron: true,
              // ),
            ],
          ),
          
          // Bouton de déconnexion
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Material(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
                elevation: 0,
                child: InkWell(
                  onTap: _handleLogout,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade100, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha:0.05),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            color: Colors.red.shade700,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Se déconnecter',
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red.shade800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Déconnectez-vous de votre compte',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey.shade400,
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Espace en bas
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF6C63FF),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade100, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha:0.05),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: items,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showChevron = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(0),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(0),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF6C63FF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 26,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Divider(
        height: 0,
        thickness: 1,
        color: Colors.grey.shade100,
      ),
    );
  }
}