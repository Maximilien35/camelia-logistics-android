/// **Adresses favorites** — maquette « Compte — Client / 5 ».
///
/// Ajouter ou déplacer une adresse ouvre l'écran de sélection d'adresses (A4)
/// en mode point unique : c'est le **même** écran que pour une commande, donc
/// la carte n'apparaît toujours qu'à un seul endroit (règle n°11).
///
/// `GET`/`POST /v1/me/addresses/` et `PATCH`/`DELETE /v1/me/addresses/{id}/`
/// (§ 7.3.7, livrés par T5.8 et T6.12). Les coordonnées viennent de la carte ;
/// le serveur ne géocode rien ici.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_error_messages.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/models/geo_point.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../models/saved_address.dart';
import '../../services/address_service.dart';
import '../../state/address_picker_controller.dart';
import '../../state/saved_addresses_controller.dart';
import '../../widgets/favorite_label_dialog.dart';
import '../order/address_picker_screen.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../shared/widgets/skeleton.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  late final SavedAddressesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SavedAddressesController(
      service: context.read<AddressService>(),
    )..refresh();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<PlacedAddress?> _pickPoint({PlacedAddress? initial}) {
    final l10n = AppLocalizations.of(context)!;
    return Navigator.of(context).push<PlacedAddress>(
      MaterialPageRoute(
        builder: (context) => AddressPickerScreen(
          mode: PickerMode.singlePoint,
          title: l10n.addressPickerSingleTitle,
          pickup: initial,
          onConfirm: (picked) => Navigator.of(context).pop(picked.pickup),
        ),
      ),
    );
  }

  Future<String?> _askLabel({String initial = ''}) =>
      showFavoriteLabelDialog(context, initial: initial);

  Future<void> _add() async {
    final place = await _pickPoint();
    if (place == null || !mounted) return;
    final label = await _askLabel();
    if (label == null || !mounted) return;
    await _controller.add(label: label, place: place);
  }

  Future<void> _rename(SavedAddress address) async {
    final label = await _askLabel(initial: address.label);
    if (label == null || !mounted) return;
    await _controller.rename(address, label);
  }

  Future<void> _move(SavedAddress address) async {
    final place = await _pickPoint(initial: address.placed);
    if (place == null || !mounted) return;
    await _controller.move(address, place);
  }

  Future<void> _delete(SavedAddress address) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addressesDeleteConfirm(address.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) await _controller.remove(address);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final failure = _controller.failure;
        return FlowScaffold(
          bottom: PrimaryButton(
            label: l10n.addressesAdd,
            busy: _controller.busy,
            onPressed: _add,
          ),
          child: RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              children: [
                FlowHeader(title: l10n.addressesTitle, large: true),
                if (failure != null) ...[
                  ErrorNotice(
                    message: messageForFailure(l10n, failure),
                    action: TextButton(
                      onPressed: _controller.refresh,
                      child: Text(l10n.commonRetry),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (_controller.loading && !_controller.loaded)
                  const SkeletonCardList()
                else if (_controller.loaded && _controller.items.isEmpty)
                  InfoNotice(
                    icon: AppIcons.bookmark,
                    message: l10n.addressesEmpty,
                  )
                else
                  for (final address in _controller.items) ...[
                    _AddressTile(
                      address: address,
                      onRename: () => _rename(address),
                      onMove: () => _move(address),
                      onDelete: () => _delete(address),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _TileAction { rename, move, delete }

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.onRename,
    required this.onMove,
    required this.onDelete,
  });

  final SavedAddress address;
  final VoidCallback onRename;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FlowCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.brandTint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(AppIcons.pin, color: AppColors.brand, size: 19),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.label,
                  style: const TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  address.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppFontSize.caption,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<_TileAction>(
            tooltip: l10n.commonEdit,
            onSelected: (action) => switch (action) {
              _TileAction.rename => onRename(),
              _TileAction.move => onMove(),
              _TileAction.delete => onDelete(),
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _TileAction.rename,
                child: Text(l10n.addressesRename),
              ),
              PopupMenuItem(
                value: _TileAction.move,
                child: Text(l10n.addressesMovePoint),
              ),
              PopupMenuItem(
                value: _TileAction.delete,
                child: Text(
                  l10n.commonDelete,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
