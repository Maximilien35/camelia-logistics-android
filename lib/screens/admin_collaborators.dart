import 'package:camelia/models/services/collaborator_service.dart';
import 'package:camelia/models/user_profile.dart';
import 'package:camelia/screens/admin/widgets/location_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminCollaboratorsScreen extends StatefulWidget {
  const AdminCollaboratorsScreen({super.key});

  @override
  State<AdminCollaboratorsScreen> createState() =>
      _AdminCollaboratorsScreenState();
}

class _AdminCollaboratorsScreenState extends State<AdminCollaboratorsScreen> {
  final CollaboratorService _collaboratorService = CollaboratorService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 30,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Collaborateurs',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    FloatingActionButton(
                      heroTag: 'add_collaborator',
                      onPressed: () => _showCollaboratorDialog(context),
                      backgroundColor: Colors.white,
                      child: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.05),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un collaborateur...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey.shade400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Liste des collaborateurs
          Expanded(
            child: StreamBuilder<List<UserProfile>>(
              stream: _collaboratorService.getCollaboratorsStream(),
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
                    child: Text(
                      'Erreur de chargement',
                      style: GoogleFonts.poppins(color: Colors.grey.shade600),
                    ),
                  );
                }

                List<UserProfile> collaborators = snapshot.data ?? [];

                if (_searchQuery.isNotEmpty) {
                  collaborators = collaborators
                      .where(
                        (c) =>
                            c.name.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            c.email.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            c.phoneNumber.contains(_searchQuery),
                      )
                      .toList();
                }

                if (collaborators.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun collaborateur',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: collaborators.length,
                  itemBuilder: (context, index) {
                    final collaborator = collaborators[index];
                    return CollaboratorCard(
                      collaborator: collaborator,
                      onEdit: () =>
                          _showCollaboratorDialog(context, collaborator),
                      onDelete: () =>
                          _showDeleteConfirmation(context, collaborator),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCollaboratorDialog(
    BuildContext context, [
    UserProfile? collaborator,
  ]) {
    showDialog(
      context: context,
      builder: (ctx) {
        return CollaboratorFormDialog(
          collaborator: collaborator,
          onSave: () {
            if (mounted) setState(() {});
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, UserProfile collaborator) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.shade600,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Supprimer le collaborateur ?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  collaborator.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Material(
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () async {
                            await _collaboratorService.deleteCollaborator(
                              collaborator.uid,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            // Pas besoin de setState, le StreamBuilder se rafraîchit
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                'Supprimer',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CollaboratorCard extends StatelessWidget {
  final UserProfile collaborator;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CollaboratorCard({
    super.key,
    required this.collaborator,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.05),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
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
                child: Center(
                  child: Text(
                    collaborator.name.isNotEmpty ? collaborator.name[0] : '?',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
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
                      collaborator.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      collaborator.email,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      collaborator.phoneNumber,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: collaborator.isActive
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      collaborator.isActive ? 'Actif' : 'Inactif',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: collaborator.isActive
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_rounded,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Supprimer',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CollaboratorFormDialog extends StatefulWidget {
  final UserProfile? collaborator;
  final VoidCallback onSave;

  const CollaboratorFormDialog({
    super.key,
    this.collaborator,
    required this.onSave,
  });

  @override
  State<CollaboratorFormDialog> createState() => _CollaboratorFormDialogState();
}

class _CollaboratorFormDialogState extends State<CollaboratorFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _serviceZoneController;
  late TextEditingController _vehicleController;



  final CollaboratorService _collaboratorService = CollaboratorService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final collab = widget.collaborator;

    _nameController = TextEditingController(text: collab?.name ?? '');
    _emailController = TextEditingController(text: collab?.email ?? '');
    _phoneController = TextEditingController(text: collab?.phoneNumber ?? '');
    _serviceZoneController = TextEditingController(
      text: collab?.serviceZone ?? '',
    );
    _vehicleController = TextEditingController(text: collab?.vehicle ?? '');

    // Initialize location data
    _selectedLatitude = collab?.latitude;
    _selectedLongitude = collab?.longitude;
    _selectedAddress = collab?.serviceZone; // Use service zone as address hint
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _serviceZoneController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.collaborator != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    child: Icon(
                      isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      isEditing
                          ? 'Modifier le collaborateur'
                          : 'Nouveau collaborateur',
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
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Informations de base
                    _buildSectionTitle('Informations générales'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nom complet',
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Nom requis' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Email requis';
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegex.hasMatch(value!)) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Téléphone',
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Téléphone requis' : null,
                    ),
                    
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _serviceZoneController,
                      label: 'Zone de service',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _vehicleController,
                      label: 'Véhicule',
                    ),

                    // Localisation
                    const SizedBox(height: 24),
                    _buildSectionTitle('Localisation'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Position géographique',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedAddress ?? 'Aucune position sélectionnée',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (_selectedLatitude != null &&
                              _selectedLongitude != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${_selectedLatitude!.toStringAsFixed(6)}, ${_selectedLongitude!.toStringAsFixed(6)}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                // fontFamily: 'monospace',
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _openLocationPicker,
                              icon: const Icon(Icons.map_rounded, size: 18),
                              label: Text(
                                'Sélectionner sur la carte',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF6C63FF),
                                ),
                                foregroundColor: const Color(0xFF6C63FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tarifs
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
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
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _isLoading ? null : _submitForm,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEditing ? 'Modifier' : 'Créer',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 15),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade800,
      ),
    );
  }

  void _openLocationPicker() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => LocationPickerDialog(
        initialLat: _selectedLatitude,
        initialLng: _selectedLongitude,
        initialAddress: _selectedAddress,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLatitude = result['latitude'];
        _selectedLongitude = result['longitude'];
        _selectedAddress = result['address'];
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final double? latitude = _selectedLatitude;
      final double? longitude = _selectedLongitude;

      if (widget.collaborator != null) {
        // Modification
        final updated = UserProfile(
          uid: widget.collaborator!.uid,
          name: _nameController.text,
          phoneNumber: _phoneController.text,
          email: _emailController.text,
          role: 'collaborator',
          isCollaborator: true,

          serviceZone: _serviceZoneController.text.isEmpty
              ? null
              : _serviceZoneController.text,
          vehicle: _vehicleController.text.isEmpty
              ? null
              : _vehicleController.text,
          isActive: widget.collaborator!.isActive,
          latitude: latitude,
          longitude: longitude,
        );
        await _collaboratorService.updateCollaborator(updated);
      } else {
        // Création d'un collaborateur séparé (pas modification de l'admin connecté)

        await _collaboratorService.createCollaborator(
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          serviceZone: _serviceZoneController.text.isEmpty
              ? null
              : _serviceZoneController.text.trim(),
          vehicle: _vehicleController.text.isEmpty
              ? null
              : _vehicleController.text.trim(),
          latitude: latitude,
          longitude: longitude,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
