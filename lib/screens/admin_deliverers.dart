import 'package:camelia/models/order_model.dart';
import 'package:camelia/models/services/order_service.dart';
import 'package:camelia/models/services/user_profile_service.dart';
import 'package:camelia/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminDeliverersScreen extends StatefulWidget {
  const AdminDeliverersScreen({super.key});

  @override
  State<AdminDeliverersScreen> createState() => _DeliverersScreenState();
}

class _DeliverersScreenState extends State<AdminDeliverersScreen> {
  final UserProfileService _delivererService = UserProfileService();
  final OrderService _orderService = OrderService();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    _nameController.dispose();
    _vehicleController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveDeliverer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _delivererService.createDeliverer(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        vehicle: _vehicleController.text.trim().isEmpty
            ? null
            : _vehicleController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop(); // ferme le dialogue
        _clearAddForm(); // réinitialise les champs
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chauffeur créé avec succès'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur création chauffeur : $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearAddForm() {
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _vehicleController.clear();
    _locationController.clear();
  }

  void addDeliverDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                return Container(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En‑tête
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
                              Icons.person_add_alt_1_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Ajouter un chauffeur',
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
                      // Formulaire
                      Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _nameController,
                                label: 'Nom complet',
                                hint: 'Jean Dupont',
                                icon: Icons.person_outline_rounded,
                                validator: (value) =>
                                    value?.trim().isEmpty ?? true
                                    ? 'Le nom est requis'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _phoneController,
                                label: 'Téléphone',
                                hint: '+2376XXXXXXXX',
                                icon: Icons.phone_rounded,
                                keyboardType: TextInputType.phone,
                                validator: (value) =>
                                    value?.trim().isEmpty ?? true
                                    ? 'Le téléphone est requis'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email',
                                hint: 'jean@example.com',
                                icon: Icons.email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value?.trim().isEmpty ?? true) {
                                    return 'L\'email est requis';
                                  }
                                  final emailRegex = RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+',
                                  );
                                  if (!emailRegex.hasMatch(value!)) {
                                    return 'Email invalide';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _vehicleController,
                                label: 'Véhicule',
                                hint: 'Toyota Hilux',
                                icon: Icons.directions_car_rounded,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _locationController,
                                label: 'Localisation',
                                hint: 'Akwa, Douala',
                                icon: Icons.location_on_rounded,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _clearAddForm(); // réinitialise les champs à la fermeture
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: const BorderSide(color: Color(0xFF6C63FF)),
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
                                  color: const Color(
                                    0xFF6C63FF,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Material(
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: _isLoading ? null : _saveDeliverer,
                                borderRadius: BorderRadius.circular(14),
                                child: Ink(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6C63FF),
                                        Color(0xFF8B84FF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: _isLoading
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
                                              Icons.save_rounded,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Enregistrer',
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
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    ).then((_) => _clearAddForm()); // au cas où le dialog est fermé autrement
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: Colors.grey.shade500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Chauffeurs',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.grey.shade900,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom, téléphone ou localisation...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF6C63FF),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Order>>(
              stream: _orderService.streamActiveOrdersForDrivers(),
              builder: (context, orderSnapshot) {
                final Set<String> busyDriverIds = {};
                if (orderSnapshot.hasData) {
                  for (var order in orderSnapshot.data!) {
                    if (order.delivererId != null) {
                      busyDriverIds.add(order.delivererId!);
                    }
                  }
                }

                return StreamBuilder<List<UserProfile>>(
                  stream: _delivererService.getDeliverersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF),
                          strokeWidth: 2,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Erreur : ${snapshot.error}',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final allDeliverers = snapshot.data ?? [];
                    final filteredDeliverers = allDeliverers.where((d) {
                      final name = d.name.toLowerCase();
                      final phone = d.phoneNumber.toLowerCase();
                      final location = d.location?.toLowerCase() ?? '';
                      return name.contains(_searchQuery) ||
                          phone.contains(_searchQuery) ||
                          location.contains(_searchQuery);
                    }).toList();

                    if (filteredDeliverers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_outline_rounded,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun chauffeur trouvé',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Essayez de modifier votre recherche',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: filteredDeliverers.length,
                      itemBuilder: (context, index) {
                        final deliverer = filteredDeliverers[index];
                        final isBusy = busyDriverIds.contains(deliverer.uid);
                        return DelivererCard(
                          deliverer: deliverer,
                          isBusy: isBusy,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_deliverer',
        onPressed: () => addDeliverDialog(context),
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class DelivererCard extends StatelessWidget {
  final UserProfile deliverer;
  final bool isBusy;

  const DelivererCard({
    super.key,
    required this.deliverer,
    required this.isBusy,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      debugPrint('Erreur d\'appel: $e');
    }
  }

  Future<void> _sendSms(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'sms', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      debugPrint('Erreur SMS: $e');
    }
  }

  Future<void> _openLocation(String location) async {
    final Uri googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}',
    );
    try {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Erreur d\'ouverture de la carte: $e');
    }
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DelivererDetailsSheet(deliverer: deliverer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = isBusy ? 'EN COURSE' : 'DISPONIBLE';
    final isAvailable = status == 'DISPONIBLE';
    final statusColor = isAvailable
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF9800);

    final initials = deliverer.name.isNotEmpty
        ? deliverer.name
              .split(' ')
              .where((s) => s.isNotEmpty)
              .map((s) => s[0])
              .take(2)
              .join()
              .toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne avatar + infos principales
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isAvailable
                          ? [
                              const Color(0xFF6C63FF).withValues(alpha: 0.2),
                              const Color(0xFF6C63FF).withValues(alpha: 0.4),
                            ]
                          : [Colors.grey.shade200, Colors.grey.shade300],
                    ),
                    border: Border.all(
                      color: isAvailable
                          ? const Color(0xFF6C63FF)
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.poppins(
                        color: isAvailable
                            ? const Color(0xFF6C63FF)
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deliverer.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.grey.shade900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF6C63FF,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              deliverer.vehicle ?? 'Véhicule non spécifié',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF6C63FF),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ID: ${deliverer.uid.substring(0, 6)}...',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Badge statut
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              deliverer.isActive ? 'Actif' : 'Inactif',
                              style: GoogleFonts.poppins(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
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
            const SizedBox(height: 20),

            // Bloc d'infos secondaires
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.phone_rounded,
                    iconColor: const Color(0xFF6C63FF),
                    label: 'Téléphone',
                    value: deliverer.phoneNumber,
                    onTap: () => _makePhoneCall(deliverer.phoneNumber),
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFF4CAF50),
                    label: 'Localisation',
                    value: deliverer.location ?? 'Non spécifiée',
                    onTap: () => _openLocation(deliverer.location ?? ''),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Barre d'actions
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.phone_rounded,
                    label: 'Appeler',
                    color: const Color(0xFF6C63FF),
                    onPressed: () => _makePhoneCall(deliverer.phoneNumber),
                  ),
                  _buildVerticalDivider(),
                  _buildActionButton(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Message',
                    color: const Color(0xFF4CAF50),
                    onPressed: () => _sendSms(deliverer.phoneNumber),
                  ),
                  _buildVerticalDivider(),
                  _buildActionButton(
                    icon: Icons.location_on_rounded,
                    label: 'Localiser',
                    color: const Color(0xFFFF9800),
                    onPressed: () => _openLocation(deliverer.location ?? ''),
                  ),
                  _buildVerticalDivider(),
                  _buildActionButton(
                    icon: Icons.info_outline_rounded,
                    label: 'Détails',
                    color: Colors.grey.shade600,
                    onPressed: () => _showDetails(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(width: 1, height: 30, color: Colors.grey.shade200);
  }
}

class _DelivererDetailsSheet extends StatelessWidget {
  final UserProfile deliverer;

  const _DelivererDetailsSheet({required this.deliverer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Détails du chauffeur',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailCard(
                        title: 'Informations personnelles',
                        children: [
                          _buildDetailItem('Nom complet', deliverer.name),
                          _buildDetailItem('Téléphone', deliverer.phoneNumber),
                          _buildDetailItem('Email', deliverer.email),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailCard(
                        title: 'Informations professionnelles',
                        children: [
                          _buildDetailItem(
                            'Type de véhicule',
                            deliverer.vehicle ?? 'Non spécifié',
                          ),
                          _buildDetailItem(
                            'Localisation',
                            deliverer.location ?? 'Non spécifiée',
                          ),
                          _buildDetailItem(
                            'Statut',
                            deliverer.isActive ? 'Actif' : 'Inactif',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
