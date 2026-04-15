import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '/models/order_state_model.dart';
import '/l10n/app_localizations.dart';

class DeliveryFormWidget extends StatefulWidget {
  final VoidCallback onProceed;

  const DeliveryFormWidget({
    required this.onProceed,
    super.key,
  });

  @override
  State<DeliveryFormWidget> createState() => _DeliveryFormWidgetState();
}

class _DeliveryFormWidgetState extends State<DeliveryFormWidget> {
  final TextEditingController _descriptionController = TextEditingController();

  static const Color _primary = Color(0xFF6C63FF);
  static const Color _secondary = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_updateDescription);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateDescription() {
    final orderState = Provider.of<OrderStateModel>(context, listen: false);
    orderState.setDescription(_descriptionController.text);
  }

  void _pickAndAddPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      final orderState = Provider.of<OrderStateModel>(context, listen: false);
      orderState.addPhoto(imageFile);
    }
  }

  Widget _buildPhotoGrid(List<File> files) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: files.map((file) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(file, fit: BoxFit.cover),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () {
                  final orderState = Provider.of<OrderStateModel>(context, listen: false);
                  orderState.removePhoto(file);
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient header ───────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), _primary, Color(0xFF8B85FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(28, 48, 28, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.packagePhotoTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.delivererDescription,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Consumer<OrderStateModel>(
              builder: (context, orderState, child) {
                final hasPhotos = orderState.selectedFiles.isNotEmpty;
                final hasPackage = orderState.packageNature?.isNotEmpty ?? false;
                final isValid = hasPhotos && hasPackage;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Photos ───────────────────────────────────
                    _buildSectionLabel(l10n.photosRequired, Icons.photo_camera_rounded),
                    const SizedBox(height: 4),
                    Text(
                      l10n.photosRequiredHint,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 12),
                    if (hasPhotos)
                      _buildPhotoGrid(orderState.selectedFiles)
                    else
                      _buildPhotoPlaceholder(onTap: _pickAndAddPhoto),
                    const SizedBox(height: 12),
                    _buildOutlinedPhotoButton(label: l10n.takeOrChoosePhoto, onTap: _pickAndAddPhoto),
                    const SizedBox(height: 24),

                    // ── Package type ─────────────────────────────
                    _buildSectionLabel(l10n.packageType, Icons.category_rounded),
                    const SizedBox(height: 4),
                    Text(
                      l10n.selectPackageTypeHint,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildPackageTypeChip(l10n.goods, Icons.local_shipping_rounded, orderState.packageNature),
                        _buildPackageTypeChip(l10n.electronics, Icons.laptop_mac_rounded, orderState.packageNature),
                        _buildPackageTypeChip(l10n.food, Icons.restaurant_rounded, orderState.packageNature),
                        _buildPackageTypeChip(l10n.fragile, Icons.warning_rounded, orderState.packageNature),
                        _buildPackageTypeChip(l10n.other, Icons.more_horiz_rounded, orderState.packageNature),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Description ──────────────────────────────
                    _buildSectionLabel(l10n.descriptionOptional, Icons.notes_rounded),
                    const SizedBox(height: 4),
                    Text(
                      l10n.describeYourPackageHint,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: l10n.specialInstructionsHint,
                          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade800),
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildCTA(isValid: isValid, label: l10n.continueButton),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageTypeChip(String label, IconData icon, String? currentSelection) {
    final isSelected = currentSelection == label;
    return GestureDetector(
      onTap: () {
        final orderState = Provider.of<OrderStateModel>(context, listen: false);
        final newValue = isSelected ? null : label;
        orderState.setPackageNature(newValue);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [_primary, Color(0xFF8B85FF)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? _primary.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_secondary, _primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _primary.withValues(alpha: 0.07), blurRadius: 18, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPhotoPlaceholder({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 165,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F6FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primary.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _primary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt_rounded, size: 32, color: _primary),
            ),
            const SizedBox(height: 10),
            Text('Ajouter une photo du colis', style: GoogleFonts.poppins(fontSize: 13, color: _primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Obligatoire', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedPhotoButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _primary.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_rounded, color: _primary, size: 20),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.poppins(color: _primary, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildCTA({required bool isValid, required String label}) {
    return GestureDetector(
      onTap: isValid ? widget.onProceed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: isValid
              ? const LinearGradient(colors: [_secondary, _primary], begin: Alignment.centerLeft, end: Alignment.centerRight)
              : null,
          color: isValid ? null : const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isValid
              ? [BoxShadow(color: _primary.withValues(alpha: 0.38), blurRadius: 22, offset: const Offset(0, 8))]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isValid ? Colors.white : Colors.grey.shade400,
                letterSpacing: 0.3,
              ),
            ),
            if (isValid) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}