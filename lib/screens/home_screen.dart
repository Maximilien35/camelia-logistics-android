import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:camelia_logistics/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

 late List<Map<String, dynamic>> _cards; 

  @override
  void initState() {
    super.initState();
    // Animation automatique du carrousel
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_currentPage < _cards.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.jumpToPage(0);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _cards = [
      {
        'title': l10n.pointAtoB,
        'subtitle': l10n.simplifiedDelivery,
        'description': l10n.pointAtoBDesc,
        'icon': Icons.location_on_rounded,
        'color': const Color(0xFF6C63FF),
        'illustration': Icons.map_rounded,
      },
      {
        'title': l10n.chooseVehicle,
        'subtitle': l10n.adaptedToNeeds,
        'description': l10n.chooseVehicleDesc,
        'icon': Icons.local_shipping_rounded,
        'color': const Color(0xFFFF9800),
        'illustration': Icons.directions_car_filled_rounded,
      },
      {
        'title': l10n.describePackage,
        'subtitle': l10n.preciseInfo,
        'description': l10n.describePackageDesc,
        'icon': Icons.inventory_rounded,
        'color': const Color(0xFF4CAF50),
        'illustration': Icons.widgets_rounded,
      },
      {
        'title': l10n.driverOnWay,
        'subtitle': l10n.fastService,
        'description': l10n.driverOnWayDesc,
        'icon': Icons.person_pin_circle_rounded,
        'color': const Color(0xFF2196F3),
        'illustration': Icons.emoji_people_rounded,
      },
    ];
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF6C63FF).withValues(alpha: 0.95),
              const Color(0xFF8B84FF).withValues(alpha: 0.95),
              const Color(0xFF6C63FF),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Éléments décoratifs en fond
            Positioned(
              top: -screenWidth * 0.15,
              left: -screenWidth * 0.15,
              child: Container(
                width: screenWidth * 0.4,
                height: screenWidth * 0.4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: screenHeight * 0.3,
              right: -screenWidth * 0.1,
              child: Container(
                width: screenWidth * 0.3,
                height: screenWidth * 0.3,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Contenu principal
            SafeArea(
              child: Column(
                children: [
                  // Header (logo + titre)
                  Padding(
                    padding: EdgeInsets.only(
                      top: screenHeight * 0.05,
                      left: 24,
                      right: 24,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: isSmallScreen ? 80 : 100,
                          height: isSmallScreen ? 80 : 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              "assets/log.webp",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                         l10n.appName,
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 26 : 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          l10n.transportSimply,
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 14 : 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha:0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Carrousel principal
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Indicateurs de page
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_cards.length, (index) {
                            return Container(
                              width: _currentPage == index ? 20 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: _currentPage == index 
                                    ? Colors.white 
                                    : Colors.white.withValues(alpha:0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                        
                        SizedBox(height: screenHeight * 0.02),
                        
                        // PageView pour le carrousel
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPage = index;
                              });
                            },
                            itemCount: _cards.length,
                            itemBuilder: (context, index) {
                              final card = _cards[index];
                              return _buildCarouselCard(
                                context: context,
                                title: card['title'],
                                subtitle: card['subtitle'],
                                description: card['description'],
                                icon: card['icon'],
                                color: card['color'],
                                illustration: card['illustration'],
                                isSmallScreen: isSmallScreen,
                              );
                            },
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                  
                  // Bouton Commencer (toujours visible)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: screenHeight * 0.05,
                      left: 24,
                      right: 24,
                    ),
                    child: Column(
                      children: [
                        // Statistiques
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha:0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                value: '1000+',
                                label: l10n.deliveries,
                                isSmallScreen: isSmallScreen,
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.white.withValues(alpha:0.3),
                              ),
                              _buildStatItem(
                                value: '50+',
                                label: l10n.activeDrivers,
                                isSmallScreen: isSmallScreen,
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.white.withValues(alpha:0.3),
                              ),
                              _buildStatItem(
                                value: '24/7',
                                label: l10n.service,
                                isSmallScreen: isSmallScreen,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Bouton principal
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.3),
                                blurRadius: 25,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Material(
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              onTap: () {
                                context.go('/login');
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Ink(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 18 : 20,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Colors.white.withValues(alpha:0.95),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        l10n.startNow,
                                        style: GoogleFonts.poppins(
                                          fontSize: isSmallScreen ? 16 : 18,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF6C63FF),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: const Color(0xFF6C63FF),
                                        size: isSmallScreen ? 20 : 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required IconData illustration,
    required bool isSmallScreen,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 22 : 26),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha:0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.15),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône principale
              Container(
                width: isSmallScreen ? 70 : 80,
                height: isSmallScreen ? 70 : 80,
                decoration: BoxDecoration(
                  color: color.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha:0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isSmallScreen ? 36 : 40,
                ),
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),
              
              // Titre et sous-titre
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 22 : 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              
              // Description
              Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 14 : 15,
                  color: Colors.white.withValues(alpha:0.85),
                  height: 1.5,
                ),
              ),
              SizedBox(height: isSmallScreen ? 24 : 28),
              
              // Illustration décorative
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.circle,
                    size: 12,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      illustration,
                      color: color,
                      size: isSmallScreen ? 28 : 32,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.circle,
                    size: 12,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required bool isSmallScreen,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 10 : 11,
            color: Colors.white.withValues(alpha:0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}