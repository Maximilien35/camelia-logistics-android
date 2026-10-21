/// Saisie du nom d'une adresse favorite (« Maison », « Travail »…), partagée
/// par l'écran de sélection d'adresses (A4) et « Adresses favorites ».
///
/// **Le dialogue possède son champ.** Libérer le `TextEditingController` juste
/// après `showDialog` casse l'app : le dialogue est encore affiché pendant son
/// animation de fermeture et son `TextField` réutiliserait un contrôleur déjà
/// libéré (« TextEditingController was used after being disposed »). Ici, il
/// n'est libéré qu'avec le dialogue lui-même.
library;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../state/saved_addresses_controller.dart';

/// Ouvre le dialogue ; renvoie le nom saisi, ou `null` si l'utilisateur
/// annule.
Future<String?> showFavoriteLabelDialog(
  BuildContext context, {
  String initial = '',
}) => showDialog<String>(
  context: context,
  builder: (_) => FavoriteLabelDialog(initial: initial),
);

class FavoriteLabelDialog extends StatefulWidget {
  const FavoriteLabelDialog({super.key, this.initial = ''});

  final String initial;

  @override
  State<FavoriteLabelDialog> createState() => _FavoriteLabelDialogState();
}

class _FavoriteLabelDialogState extends State<FavoriteLabelDialog> {
  late final TextEditingController _label = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.addressPickerSaveFavoriteTitle),
      content: TextField(
        controller: _label,
        autofocus: true,
        maxLength: SavedAddressesController.maxLabelLength,
        decoration: InputDecoration(hintText: l10n.addressPickerFavoriteLabel),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _label.text),
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
