import 'package:camelia_logistics/models/services/order_service.dart';
import 'package:camelia_logistics/models/services/user_profile_service.dart';
import 'package:camelia_logistics/models/user_profile.dart';
import 'package:camelia_logistics/screens/change_informations.dart';
import 'package:camelia_logistics/models/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserProfileService _userSer = UserProfileService();
  final OrderService _orderService = OrderService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<List<dynamic>> _loadData() {
    if (_currentUserId == null) {
      return Future.value([null, []]);
    }
    return Future.wait(
        [_userSer.getProfile(_currentUserId), _orderService.getOrdersByUserId(_currentUserId)]);
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
                  'Échec de la déconnexion',
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
    if (_currentUserId == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Text(
            'Utilisateur non connecté',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade700,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/home_custom');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: FutureBuilder<List<dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null || snapshot.data![0] == null) {
              return Scaffold(
                backgroundColor: Colors.grey.shade50,
                body: Center(
                  child: Text(
                    'Erreur de chargement du profil',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }

            final UserProfile profile = snapshot.data![0];
            final List<dynamic> orders = snapshot.data![1];
            
            return CustomScrollView(
              slivers: [
                // Header avec gradient
                SliverAppBar(
                  expandedHeight: 400,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4C4CE7).withValues(alpha:0.95),
                            const Color(0xFF6B4EE7).withValues(alpha:0.95),
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
                                  onTap: () {
                                    if (Navigator.of(context).canPop()) {
                                      Navigator.of(context).pop();
                                    } else {
                                      context.go('/home_custom');
                                    }
                                  },
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
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha:0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.settings_outlined,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            
                            // Photo de profil et nom
                            Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    profile.name,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 24,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Membre depuis le Cameroun',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withValues(alpha:0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Statistiques
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatColumn(
                                  orders.length.toString(),
                                  'Livraisons',
                                ),
                                Builder(builder: (context) {
                                  final int count = orders.length;
                                  List<Widget> stars = [];
                                  if (count >= 100) {
                                    stars = List.generate(
                                      4,
                                      (_) => const Icon(Icons.star, color: Colors.amber, size: 20),
                                    );
                                  } else if (count > 50) {
                                    stars = List.generate(
                                      2,
                                      (_) => const Icon(Icons.star, color: Colors.amber, size: 20),
                                    );
                                  } else if (count > 0) {
                                    stars = List.generate(
                                      1,
                                      (_) => const Icon(Icons.star, color: Colors.amber, size: 20),
                                    );
                                  }
                                  return _buildStatColumnWithStars(stars, 'Niveau');
                                }),
                                _buildStatColumn('98%', 'Réussite'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Section Informations personnelles
                _buildSection(
                  title: 'Informations personnelles',
                  icon: Icons.person_outline_rounded,
                  items: [
                    _buildInfoItem(
                      icon: Icons.mail_outline_rounded,
                      title: 'Email principal',
                      subtitle: profile.email,
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildInfoItem(
                      icon: Icons.phone_rounded,
                      title: 'Téléphone',
                      subtitle: profile.phoneNumber,
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildActionItem(
                      icon: Icons.edit_rounded,
                      title: 'Modifier mes informations',
                      subtitle: 'Mettre à jour votre profil',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ChangeInformations(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                // Section Performances
                _buildSection(
                  title: 'Vos performances',
                  icon: Icons.analytics_rounded,
                  items: [
                    _buildPerformanceItem(
                      title: 'Note moyenne',
                      value: '4.8/5',
                      color: Colors.blue.shade700,
                    ),
                    _buildDivider(),
                    _buildPerformanceItem(
                      title: 'Taux de réussite',
                      value: '98%',
                      color: Colors.green.shade700,
                    ),
                    _buildDivider(),
                    _buildPerformanceItem(
                      title: 'Total des livraisons',
                      value: orders.length.toString(),
                      color: Colors.grey.shade800,
                    ),
                  ],
                ),
                
                // Section Paramètres
                _buildSection(
                  title: 'Paramètres',
                  icon: Icons.settings_rounded,
                  items: [
                    _buildSettingItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications push',
                      subtitle: 'Activer/Désactiver les notifications',
                      value: true,
                      onChanged: (value) {},
                    ),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha:0.9),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumnWithStars(List<Widget> stars, String label) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: stars.isNotEmpty
              ? stars
              : [
                  Text(
                    'Débutant',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha:0.9),
            fontSize: 13,
          ),
        ),
      ],
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

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(0),
        child: Container(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: Colors.blue.shade700,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(0),
        child: Container(
          padding: const EdgeInsets.all(22),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
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

  Widget _buildPerformanceItem({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: Colors.grey.shade700,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 4),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF6C63FF),
          ),
        ],
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