import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '/models/order_state_model.dart';
import '/l10n/app_localizations.dart';

class StorageFormWidget extends StatefulWidget {
  final VoidCallback onProceed;

  const StorageFormWidget({
    required this.onProceed,
    super.key,
  });

  @override
  State<StorageFormWidget> createState() => _StorageFormWidgetState();
}

class _StorageFormWidgetState extends State<StorageFormWidget> {
  final TextEditingController _spaceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _startDate;
  int _estimatedDuration = 1;

  static const Color _primary = Color(0xFF6C63FF);
  static const Color _secondary = Color(0xFF1565C0);

  @override
  void dispose() {
    _spaceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateAdditionalDetails() {
    final orderState = Provider.of<OrderStateModel>(context, listen: false);
    orderState.setAdditionalDetails({
      'startDate': _startDate?.toIso8601String(),
      'estimatedDurationMonths': _estimatedDuration,
      'spaceRequired': _spaceController.text,
    });
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

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate && mounted) {
      setState(() {
        _startDate = picked;
        _updateAdditionalDetails();
      });
    }
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
                colors: [_secondary, _primary, Color(0xFF8B85FF)],
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
                  child: const Icon(Icons.warehouse_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.storageDetails,
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
                  l10n.provideStorageInfo,
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
                final isValid = _startDate != null && _estimatedDuration > 0 && _spaceController.text.isNotEmpty;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Date ─────────────────────────────────────
                    _buildSectionLabel(l10n.startDate, Icons.event_rounded),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _selectStartDate(context),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: _startDate != null ? const Color(0xFFF0EFFE) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _startDate != null ? _primary.withValues(alpha: 0.5) : Colors.grey.shade200,
                            width: _startDate != null ? 2 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _startDate != null ? _primary.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: _startDate != null
                                    ? const LinearGradient(colors: [_secondary, _primary], begin: Alignment.topLeft, end: Alignment.bottomRight)
                                    : null,
                                color: _startDate == null ? Colors.grey.shade100 : null,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.calendar_today_rounded,
                                color: _startDate != null ? Colors.white : Colors.grey.shade400,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _startDate != null
                                    ? l10n.dateSelected(_startDate!.day, _startDate!.month, _startDate!.year)
                                    : l10n.selectADate,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: _startDate != null ? _primary : Colors.grey.shade400,
                                  fontWeight: _startDate != null ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: _startDate != null ? _primary : Colors.grey.shade300, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Duration ─────────────────────────────────
                    _buildSectionLabel(l10n.estimatedDuration, Icons.timelapse_rounded),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Durée',
                                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_estimatedDuration mois',
                                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: _primary),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _estimatedDuration > 1
                                    ? () => setState(() {
                                          _estimatedDuration--;
                                          _updateAdditionalDetails();
                                        })
                                    : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _estimatedDuration > 1 ? const Color(0xFFF5F4FF) : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _estimatedDuration > 1 ? _primary.withValues(alpha: 0.3) : Colors.grey.shade200),
                                  ),
                                  child: Icon(Icons.remove_rounded, color: _estimatedDuration > 1 ? _primary : Colors.grey.shade300, size: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => setState(() {
                                  _estimatedDuration++;
                                  _updateAdditionalDetails();
                                }),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [_secondary, _primary],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                                  ),
                                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Space ────────────────────────────────────
                    _buildSectionLabel('Espace requis', Icons.square_foot_rounded),
                    const SizedBox(height: 12),
                    _buildCard(child: _buildFormField(
                      label: l10n.spaceRequired,
                      hint: l10n.spaceInSquareMetersHint,
                      icon: Icons.square_foot_rounded,
                      controller: _spaceController,
                      onChanged: (_) => _updateAdditionalDetails(),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      suffix: 'm²',
                      required: true,
                    )),
                    const SizedBox(height: 22),

                    // ── Photos ───────────────────────────────────
                    _buildSectionLabel(l10n.photosOptional, Icons.photo_library_rounded),
                    const SizedBox(height: 4),
                    Text(l10n.photosHelpsStorage, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 12),
                    if (orderState.selectedFiles.isNotEmpty)
                      _buildPhotoGrid(orderState.selectedFiles)
                    else
                      _buildPhotoPlaceholder(onTap: _pickAndAddPhoto),
                    const SizedBox(height: 12),
                    _buildOutlinedPhotoButton(label: l10n.addPhoto, onTap: _pickAndAddPhoto),
                    const SizedBox(height: 22),

                    // ── Notes ────────────────────────────────────
                    _buildSectionLabel(l10n.additionalNotes, Icons.notes_rounded),
                    const SizedBox(height: 4),
                    Text(l10n.addAnySpecialInstructions, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: TextFormField(
                        controller: _descriptionController,
                        onChanged: (_) => _updateAdditionalDetails(),
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

  Widget _buildFormField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required void Function(String) onChanged,
    TextInputType? keyboardType,
    String? suffix,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5),
            ),
            if (required) ...[
              const SizedBox(width: 3),
              const Text('*', style: TextStyle(color: _primary, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade300, fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Icon(icon, color: _primary.withValues(alpha: 0.55), size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 48),
            suffixText: suffix,
            suffixStyle: GoogleFonts.poppins(color: _primary, fontWeight: FontWeight.w600, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF5F4FF),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
        ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F6FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primary.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _primary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.add_photo_alternate_rounded, size: 30, color: _primary),
            ),
            const SizedBox(height: 10),
            Text('Ajouter une photo', style: GoogleFonts.poppins(fontSize: 13, color: _primary, fontWeight: FontWeight.w600)),
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
            const Icon(Icons.add_a_photo_rounded, color: _primary, size: 18),
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