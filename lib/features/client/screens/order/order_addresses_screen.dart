/// Étape 2 · **Adresses** du parcours de commande.
///
/// Décision produit du 13 septembre 2026, livrée par T5.3 : plus de saisie
/// libre. Départ et arrivée sont **placés sur la carte** de l'écran A4
/// ([AddressPickerScreen]), qui renvoie pour chacun un libellé et des
/// coordonnées exactes. Les quatre coordonnées sont obligatoires à la création
/// (§ 7.3.1) et servent aussi au devis : le serveur calcule seul la distance
/// et le prix, avec le même cache dans les deux cas.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../shared/models/geo_point.dart';
import '../../../shared/models/order.dart';
import '../../services/catalogue_service.dart';
import '../../services/order_service.dart';
import '../../state/address_picker_controller.dart';
import '../../state/order_draft.dart';
import 'address_picker_screen.dart';
import 'order_details_screen.dart';

/// Ouvre le parcours de commande pour [service].
///
/// [dropoff] pré-remplit l'arrivée — raccourci « Livrer vers » de l'accueil,
/// alimenté par une adresse favorite du serveur. Le client reste libre de la
/// changer sur la carte ; rien n'est envoyé avant sa validation.
Future<void> startOrderFlow(
  BuildContext context,
  ServiceType service, {
  PlacedAddress? dropoff,
}) {
  final draft = OrderDraft(
    service: context.read<OrderService>(),
    catalogue: context.read<CatalogueService>(),
    serviceType: service,
  )..dropoff = dropoff;
  return Navigator.of(context)
      .push(
        MaterialPageRoute<void>(
          builder: (_) => OrderAddressesStep(draft: draft),
        ),
      )
      .whenComplete(draft.dispose);
}

class OrderAddressesStep extends StatelessWidget {
  const OrderAddressesStep({super.key, required this.draft});

  final OrderDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AddressPickerScreen(
      mode: PickerMode.route,
      title: l10n.orderAddressesTitle,
      pickup: draft.pickup,
      dropoff: draft.dropoff,
      onConfirm: (picked) {
        draft.setRoute(pickup: picked.pickup, dropoff: picked.dropoff!);
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OrderDetailsScreen(draft: draft),
          ),
        );
      },
    );
  }
}
