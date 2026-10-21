/// Onglet **Compte** du client — maquettes « Compte — Client » 3 (Profil),
/// 5 (Adresses favorites), 6 (Parrainage) et 8 (Paramètres), revues par la
/// refonte UI d'octobre 2026.
///
/// Chaque entrée ouvre son écran :
/// - **Informations personnelles** : prénom, nom, téléphone vérifié (C3) ;
/// - **Adresses favorites** : carnet placé sur la carte (C4) ;
/// - **Parrainage** : tableau ambassadeur, anciennement onglet Portefeuille.
///
/// **Refonte UI** : carte de membre sombre (même surface que l'en-tête de
/// l'accueil, motif trajet), trois chiffres lus sur le serveur
/// ([AccountStatsController]), menus groupés par section avec pictogrammes
/// teintés, parrainage mis en avant, langue en pastille glissante.
///
/// **Écarts assumés** : « Vérification d'identité », « Sécurité », « Moyens de
/// paiement enregistrés » et « Centre d'aide » n'ont ni endpoint ni décision
/// produit ; ils ne sont pas affichés.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_error_messages.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/screens/profile/edit_profile_screen.dart';
import '../../../shared/state/auth_controller.dart';
import '../../../shared/widgets/account_widgets.dart';
import '../../../shared/widgets/entrance.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../../shared/widgets/pressable.dart';
import '../../services/address_service.dart';
import '../../services/order_service.dart';
import '../../state/account_stats_controller.dart';
import 'referral_screen.dart';
import 'saved_addresses_screen.dart';

class ClientAccountTab extends StatefulWidget {
  const ClientAccountTab({super.key, this.active = false});

  /// Vrai quand l'onglet est à l'écran : les chiffres se relisent à chaque
  /// retour sur l'onglet (une commande a pu être passée entre-temps).
  final bool active;

  @override
  State<ClientAccountTab> createState() => _ClientAccountTabState();
}

class _ClientAccountTabState extends State<ClientAccountTab> {
  late final AccountStatsController _stats;

  @override
  void initState() {
    super.initState();
    _stats = AccountStatsController(
      orders: context.read<OrderService>(),
      addresses: context.read<AddressService>(),
    );
    if (widget.active) _stats.refresh();
  }

  @override
  void didUpdateWidget(ClientAccountTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _stats.refresh();
  }

  @override
  void dispose() {
    _stats.dispose();
    super.dispose();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    // Le carnet ou le profil a pu changer.
    await _stats.refresh();
  }

  /// Fait entrer chaque bloc de l'écran à son tour ; les espacements restent
  /// fixes et ne comptent pas dans la cascade.
  static List<Widget> _cascade(List<Widget> blocks) {
    var rank = 0;
    return [
      for (final block in blocks)
        block is SizedBox ? block : Entrance(index: rank++, child: block),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final user = auth.user;

    return RefreshIndicator(
      onRefresh: _stats.refresh,
      color: AppColors.brand,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.screenPadding,
          AppSpacing.xl,
          AppDimens.screenPadding,
          AppSpacing.xxxl,
        ),
        children: _cascade([
          Text(
            l10n.accountTitle,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w800,
              fontSize: AppFontSize.display,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (user != null)
            MemberCard(
              user: user,
              editLabel: l10n.accountEditProfile,
              onEdit: () => _open(const EditProfileScreen()),
            ),
          const SizedBox(height: AppSpacing.md),
          ListenableBuilder(
            listenable: _stats,
            builder: (context, _) => Row(
              children: [
                Expanded(
                  child: StatTile(
                    icon: AppIcons.package,
                    value: _stats.ordersTotal?.toString(),
                    label: l10n.accountStatOrders,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatTile(
                    icon: AppIcons.checkCircle,
                    value: _stats.completed?.toString(),
                    label: l10n.accountStatCompleted,
                    accent: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatTile(
                    icon: AppIcons.pin,
                    value: _stats.addressCount?.toString(),
                    label: l10n.accountStatAddresses,
                    accent: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),

          AccountSectionLabel(l10n.accountSectionProfile),
          MenuCard(
            children: [
              MenuTile(
                icon: AppIcons.user,
                label: l10n.accountPersonalInfo,
                detail: user?.phone,
                onTap: () => _open(const EditProfileScreen()),
              ),
              ListenableBuilder(
                listenable: _stats,
                builder: (context, _) => MenuTile(
                  icon: AppIcons.bookmark,
                  label: l10n.accountSavedAddresses,
                  detail: _stats.addressCount == null
                      ? null
                      : l10n.accountSavedAddressesCount(_stats.addressCount!),
                  onTap: () => _open(const SavedAddressesScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ReferralBanner(
            title: l10n.accountReferral,
            hint: l10n.accountReferralHint,
            onTap: () => _open(const ReferralScreen()),
          ),

          AccountSectionLabel(l10n.accountSectionPreferences),
          const LanguagePreferenceCard(),

          if (auth.failure != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ErrorNotice(message: messageForFailure(l10n, auth.failure!)),
          ],
          const SizedBox(height: AppSpacing.xxl),

          MenuCard(
            children: [
              MenuTile(
                icon: AppIcons.logout,
                label: l10n.authSignOutAction,
                tint: AppColors.error,
                busy: auth.busy,
                showChevron: false,
                onTap: auth.busy
                    ? null
                    : () => context.read<AuthController>().logout(),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}

/// Parrainage mis en avant : bloc teinté plutôt qu'une ligne de menu de plus.
/// Teinte violette **très claire** — pas d'aplat saturé.
class _ReferralBanner extends StatelessWidget {
  const _ReferralBanner({
    required this.title,
    required this.hint,
    required this.onTap,
  });

  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.brandTint,
        borderRadius: BorderRadius.circular(AppRadii.sheet),
        border: Border.all(color: AppColors.brand.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(AppIcons.gift, size: 24, color: AppColors.brand),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: AppFontSize.bodyLarge,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  hint,
                  style: const TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.brand,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.forwardBold,
              size: 14,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    ),
  );
}
