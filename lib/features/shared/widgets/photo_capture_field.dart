/// Champ photo : photo du colis (client) et preuves de course (chauffeur).
///
/// Produit un [ApiFileField] prêt à partir en multipart. Le type MIME est posé
/// explicitement : le backend revalide `content_type` et n'accepte que JPEG,
/// PNG ou WebP (`ALLOWED_PACKAGE_PHOTO_CONTENT_TYPES`).
///
/// La taille maximale reste appliquée par le serveur ; la compression ici
/// (1600 px, qualité 80) sert seulement à ne pas envoyer 8 Mo sur un réseau
/// mobile.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_icons.dart';

class PhotoCaptureField extends StatelessWidget {
  const PhotoCaptureField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.emptyLabel,
    this.errorText,
    this.allowGallery = true,
    this.height = 130,
  });

  final ApiFileField? value;
  final ValueChanged<ApiFileField?> onChanged;
  final String emptyLabel;
  final String? errorText;

  /// Une preuve de course se prend sur place : galerie désactivée côté
  /// chauffeur.
  final bool allowGallery;

  final double height;

  static const int _maxDimension = 1600;
  static const int _quality = 80;

  Future<void> _pick(BuildContext context) async {
    final photo = await pick(context, allowGallery: allowGallery);
    if (photo != null) onChanged(photo);
  }

  /// Ouvre l'appareil photo (ou propose la galerie) et renvoie la photo prête
  /// à l'envoi, ou `null` si l'utilisateur renonce.
  static Future<ApiFileField?> pick(
    BuildContext context, {
    bool allowGallery = true,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    var source = ImageSource.camera;
    if (allowGallery) {
      final chosen = await showModalBottomSheet<ImageSource>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(AppIcons.camera),
                title: Text(l10n.photoTake),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(AppIcons.gallery),
                title: Text(l10n.photoChooseGallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (chosen == null) return null;
      source = chosen;
    }

    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: _maxDimension.toDouble(),
        maxHeight: _maxDimension.toDouble(),
        imageQuality: _quality,
      );
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      // Renommé par le service au nom de champ attendu (`photo`,
      // `package_photos`).
      return ApiFileField(
        field: 'photo',
        filename: file.name,
        bytes: bytes,
        contentType: contentTypeFor(file.name, file.mimeType),
      );
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.photoFailed)));
      return null;
    }
  }

  /// Type MIME accepté par le serveur, déduit du nom quand le système ne le
  /// fournit pas. `image_picker` réencode en JPEG lorsqu'il compresse.
  static String contentTypeFor(String filename, String? reported) {
    const allowed = {'image/jpeg', 'image/png', 'image/webp'};
    if (reported != null && allowed.contains(reported)) return reported;
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasError = errorText != null;
    final photo = value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _pick(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: height,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: photo == null ? AppColors.white : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: photo == null
                    ? Border.all(
                        color: hasError
                            ? AppColors.error
                            : AppColors.borderStrong,
                        width: 1.8,
                      )
                    : null,
              ),
              child: photo == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            AppIcons.camera,
                            size: 20,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          emptyLabel,
                          style: const TextStyle(
                            fontSize: AppFontSize.caption,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          Uint8List.fromList(photo.bytes),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xB30E0E10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.photoRetake,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: AppFontSize.micro,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: AppFontSize.caption,
              ),
            ),
          ),
      ],
    );
  }
}
