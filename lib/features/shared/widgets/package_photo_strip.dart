/// Vignettes des photos du colis, agrandies au toucher.
///
/// Sert là où le chauffeur doit **juger le colis** : sur l'offre, avant
/// d'accepter (§ 7.4.2, ajouté le 18 octobre 2026), pendant la course, et dans
/// l'historique.
///
/// Les URL sont **signées et valables quelques minutes** : elles viennent de
/// la dernière lecture du serveur et ne sont jamais gardées. Une image qui ne
/// charge plus (URL expirée, réseau) affiche un pictogramme à sa place — le
/// prochain rafraîchissement rapporte des URL neuves.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';

class PackagePhotoStrip extends StatelessWidget {
  const PackagePhotoStrip({
    super.key,
    required this.urls,
    this.size = 64,
    this.max = 3,
  });

  final List<String> urls;
  final double size;

  /// Trois photos au plus par commande (§ 7.3.1).
  final int max;

  @override
  Widget build(BuildContext context) {
    final shown = urls.take(max).toList(growable: false);
    if (shown.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.driverOfferPhotos,
      child: Row(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: () => _open(context, shown, i),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(size * .2),
                child: _Photo(url: shown[i], size: size),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static void _open(BuildContext context, List<String> urls, int initial) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, _, _) => _PhotoViewer(urls: urls, initial: initial),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) => Image.network(
    url,
    width: size,
    height: size,
    fit: BoxFit.cover,
    errorBuilder: (_, _, _) => _placeholder(),
    loadingBuilder: (_, child, progress) =>
        progress == null ? child : _placeholder(),
  );

  Widget _placeholder() => Container(
    width: size,
    height: size,
    color: AppColors.surface,
    child: const Icon(AppIcons.package, color: AppColors.inkMuted),
  );
}

/// Plein écran : balayage entre les photos, pincement pour zoomer.
class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.urls, required this.initial});

  final List<String> urls;
  final int initial;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initial,
  );
  late int _index = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pages,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => InteractiveViewer(
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    widget.urls[i],
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      AppIcons.imageBroken,
                      size: 48,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: IconButton(
                tooltip: l10n.commonClose,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(AppIcons.close, color: Colors.white),
              ),
            ),
            if (widget.urls.length > 1)
              Positioned(
                bottom: AppSpacing.lg,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.urls.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _index ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _index ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(3),
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
}
