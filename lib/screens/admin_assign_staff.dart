import 'package:camelia/models/order_model.dart';
import 'package:camelia/models/services/order_service.dart';
import 'package:camelia/models/services/user_profile_service.dart';
import 'package:camelia/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminAssignStaffScreen extends StatefulWidget {
  final String orderId;

  const AdminAssignStaffScreen({super.key, required this.orderId});

  @override
  State<AdminAssignStaffScreen> createState() => _AdminAssignStaffScreenState();
}

class _AdminAssignStaffScreenState extends State<AdminAssignStaffScreen> {
  final UserProfileService _userProfileService = UserProfileService();
  final OrderService _orderService = OrderService();

  late Future<Order?> _orderFuture;
  late TextEditingController _quotePriceController;
  bool _isUpdatingQuote = false;

  String _selectedGroup = 'all';
  String? _selectedZone;
  String _searchQuery = '';
  bool _assigning =
      false; 

  Future<List<UserProfile>>? _staffFuture;

  @override
  void initState() {
    super.initState();
    _loadStaff();
    _loadZones();
    _orderFuture = _orderService.getOrder(widget.orderId);
    _quotePriceController = TextEditingController();
    _orderFuture.then((order) {
      if (order != null && order.priceQuote != null) {
        _quotePriceController.text = order.priceQuote!.toStringAsFixed(0);
      }
    });
  }

  void _loadStaff() {
    _staffFuture = _userProfileService.getStaff(
      group: _selectedGroup,
      zone: _selectedGroup == 'collaborator' ? _selectedZone : null,
    );
    if (mounted) setState(() {});
  }

  List<String> _zones = [];
  bool _loadingZones = true;
  String? _zonesError;

  Future<void> _loadZones() async {
    try {
      final zones = await _userProfileService.getServiceZones();
      if (!mounted) return;
      setState(() {
        _zones = zones;
        _loadingZones = false;
        _zonesError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingZones = false;
        _zonesError = 'Erreur de chargement des zones';
      });
    }
  }

  void _onGroupChanged(String? value) {
    setState(() {
      _selectedGroup = value ?? 'all';
      _selectedZone = null; // On réinitialise la zone quand on change de groupe
    });
    _loadStaff();
  }

  void _onZoneChanged(String? value) {
    setState(() {
      _selectedZone = value;
    });
    _loadStaff();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();
    });
  }

  Future<void> _assignStaff(UserProfile user) async {
    setState(() => _assigning = true);
    try {
      await _orderService.assignDeliverer(
        orderId: widget.orderId,
        delivererUid: user.uid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Assignation effectuée avec succès',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 10,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Échec de l\'assignation: ${e.toString()}',
                  style: GoogleFonts.poppins(),
                ),
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
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF6C63FF),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Assigner un prestataire',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Filtres par rôle
              Row(
                children: [
                  _buildRoleChip('all', 'Tous'),
                  const SizedBox(width: 8),
                  _buildRoleChip('deliverer', 'Chauffeurs'),
                  const SizedBox(width: 8),
                  _buildRoleChip('collaborator', 'Collaborateurs'),
                ],
              ),
              const SizedBox(height: 16),
              _buildZoneFilter(),
              const SizedBox(height: 16),
              _buildSearchField(),
              const SizedBox(height: 16),
              FutureBuilder<Order?>(
                future: _orderFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const SizedBox.shrink();
                  }
                  final order = snapshot.data!;
                  if (!order.isQuote) return const SizedBox.shrink();

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _quotePriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Prix devis',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _isUpdatingQuote
                                ? null
                                : () async {
                                    setState(() => _isUpdatingQuote = true);
                                    try {
                                      final value = double.tryParse(
                                        _quotePriceController.text,
                                      );
                                      if (value == null || value <= 0) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Prix invalide'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      } else {
                                        await _orderService.updateFinalPrice(
                                          order.id!,
                                          value,
                                        );
                                        await _orderService.updateOrderStatus(
                                          orderId: order.id!,
                                          newStatus: 'ACCEPTED',
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Devis enregistré'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Erreur: $e'),
                                          backgroundColor: Colors.red.shade600,
                                        ),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(
                                          () => _isUpdatingQuote = false,
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isUpdatingQuote
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Valider'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<UserProfile>>(
                  future: _staffFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erreur: ${snapshot.error}',
                          style: GoogleFonts.poppins(
                            color: Colors.red.shade600,
                          ),
                        ),
                      );
                    }
                    final staff = snapshot.data ?? [];
                    final filtered = staff.where((u) {
                      final text =
                          '${u.name} ${u.email} ${u.serviceZone ?? ''} ${u.role}'
                              .toLowerCase();
                      return text.contains(_searchQuery);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucun résultat.',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = filtered[index];
                        return _buildStaffCard(user);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(String value, String label) {
    final selected = _selectedGroup == value;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: selected ? Colors.white : Colors.grey.shade700,
        ),
      ),
      selected: selected,
      onSelected: (_) => _onGroupChanged(value),
      selectedColor: const Color(0xFF6C63FF),
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: Colors.grey.shade200, width: 0),
      ),
    );
  }

  Widget _buildZoneFilter() {
    if (_selectedGroup != 'collaborator') return const SizedBox.shrink();

    if (_loadingZones) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_zonesError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _zonesError!,
                style: GoogleFonts.poppins(
                  color: Colors.red.shade600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final items = ['Toutes les zones', ..._zones];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedZone,
        decoration: InputDecoration(
          labelText: 'Zone collaborative',
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
          prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        items: items.map((zone) {
          return DropdownMenuItem(
            value: zone == 'Toutes les zones' ? null : zone,
            child: Text(
              zone,
              style: GoogleFonts.poppins(color: const Color(0xFF6C63FF)),
            ),
          );
        }).toList(),
        onChanged: _onZoneChanged,
        icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.grey.shade600),
        dropdownColor: Colors.white,
        isExpanded: true,
        style: GoogleFonts.poppins(),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
          hintText: 'Rechercher un nom, zone...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: GoogleFonts.poppins(),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildStaffCard(UserProfile user) {
    final roleLabel = user.role == 'collaborator'
        ? 'Collaborateur'
        : 'Chauffeur';
    final zoneText = user.serviceZone != null
        ? 'zone: ${user.serviceZone}'
        : 'zone non définie';

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icône de profil
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Color(0xFF6C63FF),
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$roleLabel • $zoneText',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Bouton assigner
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: _assigning ? null : () => _assignStaff(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  elevation: 0,
                ),
                child: _assigning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Assigner',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
