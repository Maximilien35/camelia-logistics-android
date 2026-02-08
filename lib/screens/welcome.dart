import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class CameliaHome extends StatelessWidget {
  const CameliaHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF4A00E0),
              const Color(0xFF8E2DE2),
              Colors.purple.shade300,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: CustomScrollView(
              slivers: [
                // Header avec logo animé
                const SliverToBoxAdapter(child: AnimatedLogoSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),

                // Titre avec animation
                SliverToBoxAdapter(
                  child: Hero(
                  tag: 'logo',
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        Text(
                          "Camelia",
                          style: GoogleFonts.poppins(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha:0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "LOGISTICS",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha:0.9),
                            letterSpacing: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // Slogan avec effet
                SliverToBoxAdapter(
                  child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha:0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "Livraison express au Cameroun",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha:0.9),
                    ),
                  ),
                ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),

                // Section de présentation
                SliverList(
                  delegate: SliverChildListDelegate([
                    _buildAnimatedCard(
                        icon: Icons.rocket_launch_rounded,
                        title: "Livraison ultra-rapide",
                        description: "Votre colis livré en moins de 24h",
                        color: Colors.orange.shade400,
                        delay: 100,
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedCard(
                        icon: Icons.location_on_rounded,
                        title: "Couverture nationale",
                        description: "Service disponible dans toutes les villes",
                        color: Colors.blue.shade400,
                        delay: 200,
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedCard(
                        icon: Icons.shield_rounded,
                        title: "Sécurité garantie",
                        description: "Vos colis assurés jusqu'à destination",
                        color: Colors.green.shade400,
                        delay: 300,
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedCard(
                        icon: Icons.phone_in_talk_rounded,
                        title: "Support 24/7",
                        description: "Notre équipe à votre écoute",
                        color: Colors.purple.shade400,
                        delay: 400,
                      ),
                  ]),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),

                // Bouton principal avec effet
                SliverToBoxAdapter(
                  child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha:0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: const Color(0xFF4A00E0).withValues(alpha:0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Material(
                    borderRadius: BorderRadius.circular(25),
                    child: InkWell(
                      onTap: () => context.go('/signup'),
                      borderRadius: BorderRadius.circular(25),
                      child: Ink(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 30,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFF0F0F0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withValues(alpha:0.5),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Color(0xFF4A00E0),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Commencer",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF4A00E0),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Bouton secondaire
                SliverToBoxAdapter(
                  child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    "J'ai déjà un compte",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha:0.9),
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white.withValues(alpha:0.5),
                    ),
                  ),
                ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha:0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.1),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha:0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha:0.5),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedLogoSection extends StatefulWidget {
  const AnimatedLogoSection({super.key});

  @override
  State<AnimatedLogoSection> createState() => _AnimatedLogoSectionState();
}

class _AnimatedLogoSectionState extends State<AnimatedLogoSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha:0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: Colors.purple.shade300.withValues(alpha:0.3),
                    blurRadius: 40,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Cercle intérieur
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.shade800.withValues(alpha:0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Effet de particules
                  ...List.generate(
                    8,
                    (index) => Positioned(
                      left: 50 + 35 * _scaleAnimation.value * cos(index * 45 * pi / 180),
                      top: 50 + 35 * _scaleAnimation.value * sin(index * 45 * pi / 180),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}