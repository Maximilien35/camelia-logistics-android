/// Onglet **Accueil** client — maquette « Commande — Client / 1. Accueil »,
/// revue par la refonte UI d'octobre 2026.
///
/// Construit ce que le backend peut réellement alimenter :
/// - la salutation et le prénom viennent de `GET /v1/me/` ;
/// - les raccourcis « Livrer vers » sont les adresses favorites du serveur
///   (`GET /v1/me/addresses/`, § 7.3.7) — jamais une adresse gardée en local ;
/// - la grille de services porte les **quatre** `service_type` du serveur.
///
/// **Refonte UI** (au-delà du handoff) :
/// - en-tête en dégradé de marque, salutation selon l'heure et grande barre
///   « Où livrer votre colis ? » qui ouvre directement l'écran A4 ;
/// - grille « bento » de tuiles photo (photos Camelia de `assets/`) au lieu de
///   quatre tuiles blanches identiques, avec la mention « Prix immédiat » ou
///   « Sur devis » tirée de [ServiceType.isManualQuote] ;
/// - bandeau « Comment ça marche » en trois étapes reliées par un tracé.
///
/// **Écarts assumés**, tous faute de backend — voir `docs/design-api-map.md` :
/// - la maquette affiche cinq tuiles (Colis, Déménag., National, Stockage,
///   Internat.) pour quatre `service_type` réels : `National` et `Internat.`
///   relèvent tous deux d'`shipping`, qui part en devis manuel par WhatsApp. La
///   grille en compte donc quatre, sans perdre de fonction ;
/// - le bloc « Portefeuille Camelia » avec solde rechargeable n'a **aucun
///   endpoint** : il n'existe pas de portefeuille client côté serveur. Bloc non
///   affiché ;
/// - la carte « Commande en cours » est alimentée par `GET /v1/orders/`
///   (§ 7.3.4, T5.5), filtré sur les statuts actifs, et relue au retour du
///   suivi ;
/// - le bandeau promotionnel « −25 % ce mois » est un contenu éditorial sans
///   source de données : il n'est pas codé en dur ici.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_error_messages.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/models/order.dart';
import '../../shared/state/auth_controller.dart';
import '../../shared/state/push_controller.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/expand_to_screen.dart';
import '../../shared/widgets/order_labels.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/route_decoration.dart';
import '../models/saved_address.dart';
import '../services/address_service.dart';
import '../state/active_orders_controller.dart';
import '../state/saved_addresses_controller.dart';
import '../widgets/order_card.dart';
import 'account/saved_addresses_screen.dart';
import 'order/order_addresses_screen.dart';
import 'order/order_tracking_screen.dart';

class ClientHomeTab extends StatefulWidget {
  const ClientHomeTab({super.key});

  @override
  State<ClientHomeTab> createState() => _ClientHomeTabState();
}

class _ClientHomeTabState extends State<ClientHomeTab> {
  late final PushController _push;
  late final SavedAddressesController _favorites;

  @override
  void initState() {
    super.initState();
    _favorites = SavedAddressesController(
      service: context.read<AddressService>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ActiveOrdersController>().refresh();
      _favorites.refresh();
    });
    _push = context.read<PushController>()..addListener(_onPush);
  }

  /// Une commande a changé côté serveur : la carte « Commande en cours » se
  /// relit. Rien n'est tiré du contenu de la notification (§ 2.17).
  void _onPush() {
    if (mounted && _push.lastHint?.orderId != null) {
      context.read<ActiveOrdersController>().refresh();
    }
  }

  @override
  void dispose() {
    _push.removeListener(_onPush);
    _favorites.dispose();
    super.dispose();
  }

  Future<void> _refresh() => Future.wait([
    context.read<ActiveOrdersController>().refresh(),
    _favorites.refresh(),
  ]);

  Future<void> _pickService(ServiceType service, {SavedAddress? to}) async {
    final active = context.read<ActiveOrdersController>();
    await startOrderFlow(context, service, dropoff: to?.placed);
    // Retour du parcours : une commande a peut-être été créée.
    await active.refresh();
  }

  Future<void> _openSavedAddresses() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SavedAddressesScreen()),
    );
    await _favorites.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthController>().user;
    final active = context.watch<ActiveOrdersController>();

    // En-tête sombre : icônes de la barre d'état en clair.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.brand,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
          children: [
            _Hero(
              greeting: _greetingFor(l10n, DateTime.now()),
              name: user?.firstName ?? '',
              question: l10n.homeHeroQuestion,
              searchHint: l10n.homeSearchPlaceholder,
              onSearch: () => _pickService(ServiceType.delivery),
            ),

            Entrance(
              index: 1,
              child: ListenableBuilder(
                listenable: _favorites,
                builder: (context, _) => _Shortcuts(
                  title: l10n.homeShortcutsTitle,
                  addLabel: l10n.homeShortcutAdd,
                  favorites: _favorites.items,
                  // Le bouton « Enregistrer » n'apparaît qu'une fois la liste
                  // connue vide — pas pendant le chargement.
                  showAdd: _favorites.loaded && _favorites.items.isEmpty,
                  onPick: (a) => _pickService(ServiceType.delivery, to: a),
                  onAdd: _openSavedAddresses,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (active.orders.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    Entrance(
                      index: 2,
                      child: _SectionTitle(
                        title: l10n.homeActiveOrdersSection,
                        count: active.orders.length,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final (i, order) in active.orders.indexed) ...[
                      Entrance(
                        index: 3 + i,
                        // La carte grandit jusqu'à devenir l'écran de suivi.
                        child: ExpandToScreen(
                          closedColor: AppColors.ink,
                          radius: OrderCard.radius,
                          shadows: OrderCard.shadows,
                          onClosed: active.refresh,
                          openBuilder: (_) => OrderTrackingScreen(
                            orderId: order.id,
                            initial: order,
                          ),
                          closedBuilder: (context, open) => OrderCard(
                            eyebrow: l10n.homeActiveOrderTitle,
                            reference: order.reference,
                            pickupAddress: order.pickupAddress,
                            dropoffAddress: order.dropoffAddress,
                            serviceLabel: serviceLabel(l10n, order.serviceType),
                            status: order.status,
                            statusText: statusLabel(l10n, order),
                            ribbon: order.statusRibbon,
                            onTap: open,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                  if (active.failure != null && active.orders.isEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _InlineError(
                      message:
                          '${l10n.homeActiveOrdersError} '
                          '${messageForFailure(l10n, active.failure!)}',
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xxl),
                  Entrance(
                    index: 3,
                    child: _SectionTitle(title: l10n.homeServicesTitle),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ServicesBento(
                    l10n: l10n,
                    onPick: (service) => _pickService(service),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                  _SectionTitle(title: l10n.homeHowTitle),
                  const SizedBox(height: AppSpacing.md),
                  Entrance(
                    index: 8,
                    child: _HowItWorks(
                      steps: [
                        (AppIcons.route, l10n.homeHowStepRoute),
                        (AppIcons.priceChanged, l10n.homeHowStepPrice),
                        (AppIcons.truck, l10n.homeHowStepTrack),
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

  static String _greetingFor(AppLocalizations l10n, DateTime now) =>
      switch (now.hour) {
        >= 5 && < 12 => l10n.homeGreetingMorning,
        >= 12 && < 18 => l10n.homeGreetingAfternoon,
        _ => l10n.homeGreetingEvening,
      };
}

// ---------------------------------------------------------------------------
// En-tête
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero({
    required this.greeting,
    required this.name,
    required this.question,
    required this.searchHint,
    required this.onSearch,
  });

  final String greeting;
  final String name;
  final String question;
  final String searchHint;
  final VoidCallback onSearch;

  /// Hauteur de la barre de recherche ; la moitié déborde sous le dégradé.
  static const double _searchHeight = 64;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        // L'en-tête s'arrête à mi-hauteur de la barre de recherche : la
        // barre « flotte » à cheval sur l'en-tête et la page.
        //
        // Fond encre neutre, pas de violet en aplat (un premier dégradé
        // violet → bleu fatiguait les yeux) : la couleur de marque n'est plus
        // qu'un accent — l'épingle d'arrivée, l'avatar.
        Padding(
          padding: const EdgeInsets.only(bottom: _searchHeight / 2),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: AppGradients.inkPanel,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: RouteDecorationPainter()),
                  ),
                  // Grand camion en filigrane, coin bas droit.
                  Positioned(
                    right: -18,
                    bottom: 6,
                    child: Icon(
                      AppIcons.truck,
                      size: 132,
                      color: AppColors.white.withValues(alpha: .06),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppDimens.screenPadding,
                      top + AppSpacing.xl,
                      AppDimens.screenPadding,
                      _searchHeight / 2 + AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    greeting,
                                    style: TextStyle(
                                      fontSize: AppFontSize.body,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.white.withValues(
                                        alpha: .72,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: AppFonts.display,
                                      fontWeight: FontWeight.w800,
                                      fontSize: AppFontSize.hero,
                                      height: 1.1,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _Avatar(name: name),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          question,
                          style: TextStyle(
                            fontSize: AppFontSize.bodyLarge,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white.withValues(alpha: .9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: AppDimens.screenPadding,
          right: AppDimens.screenPadding,
          bottom: 0,
          height: _searchHeight,
          child: _SearchBar(hint: searchHint, onTap: onSearch),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.brand,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white.withValues(alpha: .18),
          width: 3,
        ),
      ),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: const TextStyle(
          fontFamily: AppFonts.display,
          fontWeight: FontWeight.w700,
          fontSize: AppFontSize.title,
          color: AppColors.white,
        ),
      ),
    );
  }
}

/// Fausse barre de recherche : un seul appui ouvre l'écran A4, où la vraie
/// recherche a lieu (bouton explicite, jamais en direct — § Cartographie).
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: hint,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.floating,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.brandTint,
                borderRadius: BorderRadius.circular(AppRadii.small),
              ),
              child: const Icon(
                AppIcons.pinFilled,
                size: 22,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppFontSize.body,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.forwardBold,
                size: 18,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Raccourcis « Livrer vers »
// ---------------------------------------------------------------------------

class _Shortcuts extends StatelessWidget {
  const _Shortcuts({
    required this.title,
    required this.addLabel,
    required this.favorites,
    required this.showAdd,
    required this.onPick,
    required this.onAdd,
  });

  final String title;
  final String addLabel;
  final List<SavedAddress> favorites;
  final bool showAdd;
  final ValueChanged<SavedAddress> onPick;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty && !showAdd) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.screenPadding,
          ),
          children: [
            Center(
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: AppFontSize.micro,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                  color: AppColors.inkDisabled,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            for (final address in favorites) ...[
              _Chip(
                icon: AppIcons.pin,
                label: address.label,
                onTap: () => onPick(address),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (showAdd)
              _Chip(
                icon: AppIcons.bookmark,
                label: addLabel,
                onTap: onAdd,
                outlined: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: .94,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: outlined ? AppColors.borderStrong : AppColors.border,
          ),
          boxShadow: outlined ? null : AppShadows.card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.brand),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: AppFontSize.label,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.count});

  final String title;

  /// Pastille de compte à côté du titre (commandes en cours).
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w700,
            fontSize: AppFontSize.title,
            color: AppColors.ink,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: AppFontSize.micro,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(AppIcons.offline, size: 18, color: AppColors.inkMuted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: AppFontSize.caption,
              color: AppColors.inkMuted,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Services : grille « bento » de tuiles photo
// ---------------------------------------------------------------------------

class _ServicesBento extends StatelessWidget {
  const _ServicesBento({required this.l10n, required this.onPick});

  final AppLocalizations l10n;
  final ValueChanged<ServiceType> onPick;

  _ServiceTile _tile(
    ServiceType service, {
    required double height,
    bool featured = false,
  }) {
    final (label, hint, icon, image) = switch (service) {
      ServiceType.delivery => (
        l10n.serviceDelivery,
        l10n.serviceDeliveryHint,
        AppIcons.serviceDelivery,
        'assets/livraison-carousel.webp',
      ),
      ServiceType.moving => (
        l10n.serviceMoving,
        l10n.serviceMovingHint,
        AppIcons.serviceMoving,
        'assets/demenagement-carousel.webp',
      ),
      ServiceType.shipping => (
        l10n.serviceShipping,
        l10n.serviceShippingHint,
        AppIcons.serviceShipping,
        'assets/internationale.webp',
      ),
      ServiceType.storage => (
        l10n.serviceStorage,
        l10n.serviceStorageHint,
        AppIcons.serviceStorage,
        'assets/stockage-carousel.webp',
      ),
    };
    return _ServiceTile(
      label: label,
      hint: hint,
      icon: icon,
      image: image,
      // La photo de livraison porte une bande blanche sur son bord droit.
      imageZoom: service == ServiceType.delivery ? 1.12 : 1,
      badge: service.isManualQuote
          ? l10n.homeServiceOnQuote
          : l10n.homeServiceInstant,
      instant: !service.isManualQuote,
      height: height,
      featured: featured,
      onTap: () => onPick(service),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Entrance(
          index: 4,
          child: _tile(ServiceType.delivery, height: 196, featured: true),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Entrance(
                index: 5,
                child: _tile(ServiceType.moving, height: 176),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Entrance(
                index: 6,
                child: _tile(ServiceType.shipping, height: 176),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Entrance(index: 7, child: _tile(ServiceType.storage, height: 160)),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.label,
    required this.hint,
    required this.icon,
    required this.image,
    this.imageZoom = 1,
    required this.badge,
    required this.instant,
    required this.height,
    required this.onTap,
    this.featured = false,
  });

  final String label;
  final String hint;
  final IconData icon;
  final String image;

  /// Agrandissement ancré à gauche, pour rogner le bord droit d'une photo.
  final double imageZoom;
  final String badge;

  /// Prix calculé par le serveur sur-le-champ (pastille verte) ou devis
  /// manuel (pastille ambre).
  final bool instant;
  final double height;
  final bool featured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Les photos source font jusqu'à 1 536 px de large : on les décode à la
    // taille d'affichage pour ne pas garder des mégaoctets en mémoire.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final width = MediaQuery.sizeOf(context).width;

    return Pressable(
      onTap: onTap,
      semanticLabel: '$label. $hint',
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.sheet),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: imageZoom,
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  cacheWidth: (width * dpr).round(),
                  // Pas de photo (asset manquant, décodage raté) : la tuile
                  // garde un fond de marque plutôt qu'un trou.
                  errorBuilder: (_, _, _) => const DecoratedBox(
                    decoration: BoxDecoration(gradient: AppGradients.inkPanel),
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.photoScrim),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md + 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GlassIcon(icon: icon, large: featured),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Au-dessus du titre plutôt qu'en coin : la
                              // pastille dispose de toute la largeur de la
                              // tuile, même en demi-largeur sur un 360 px.
                              _Badge(text: badge, instant: instant),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppFonts.display,
                                  fontWeight: FontWeight.w800,
                                  fontSize: featured
                                      ? AppFontSize.headline
                                      : AppFontSize.title,
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                hint,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: AppFontSize.caption,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white.withValues(alpha: .8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (featured) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              AppIcons.forwardBold,
                              size: 18,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ],
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
}

/// Pictogramme sur verre dépoli — fond blanc translucide, sans flou réel
/// (un `BackdropFilter` par tuile coûterait cher au défilement).
class _GlassIcon extends StatelessWidget {
  const _GlassIcon({required this.icon, this.large = false});

  final IconData icon;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 46.0 : 38.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(AppRadii.small),
        border: Border.all(color: AppColors.white.withValues(alpha: .35)),
      ),
      child: Icon(icon, size: large ? 24 : 20, color: AppColors.white),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.instant});

  final String text;
  final bool instant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.badge + 4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: instant ? AppColors.success : AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs + 1),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppFontSize.micro,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comment ça marche
// ---------------------------------------------------------------------------

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.steps});

  final List<(IconData, String)> steps;

  static const double _iconSize = 48;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.sheet),
        boxShadow: AppShadows.card,
      ),
      child: Stack(
        children: [
          // Tracé en pointillés qui relie les étapes, au niveau du centre des
          // pastilles — la même grammaire que l'en-tête.
          Positioned(
            top: _iconSize / 2 - 1,
            left: 0,
            right: 0,
            child: LayoutBuilder(
              builder: (context, c) {
                final slot = c.maxWidth / steps.length;
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: slot / 2 + _iconSize / 2 + AppSpacing.xs,
                  ),
                  child: const CustomPaint(
                    size: Size.fromHeight(2),
                    painter: DashedLinePainter(color: AppColors.borderStrong),
                  ),
                );
              },
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++)
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: _iconSize,
                        height: _iconSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == steps.length - 1
                              ? AppColors.brand
                              : AppColors.brandTint,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          steps[i].$1,
                          size: 22,
                          color: i == steps.length - 1
                              ? AppColors.white
                              : AppColors.brand,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: AppFontSize.caption,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkDisabled,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        steps[i].$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: AppFontSize.label,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
