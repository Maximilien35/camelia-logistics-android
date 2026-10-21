/// Libellés et couleurs d'une commande, communs au client et au chauffeur.
///
/// Toujours localisés sur la **valeur** du serveur (`status`, `service_type`),
/// jamais sur un libellé rédigé par le serveur — sauf en repli pour une valeur
/// que ce build ne connaît pas.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../models/order.dart';

String serviceLabel(AppLocalizations l10n, ServiceType type) => switch (type) {
  ServiceType.delivery => l10n.serviceDelivery,
  ServiceType.moving => l10n.serviceMoving,
  ServiceType.shipping => l10n.serviceShipping,
  ServiceType.storage => l10n.serviceStorage,
};

/// Pictogramme d'un type de service, le même dans toutes les listes.
IconData serviceIcon(ServiceType type) => switch (type) {
  ServiceType.delivery => AppIcons.package,
  ServiceType.moving => AppIcons.truck,
  ServiceType.shipping => AppIcons.globe,
  ServiceType.storage => AppIcons.warehouse,
};

String statusLabel(AppLocalizations l10n, Order order) => statusLabelFor(
  l10n,
  order.status,
  fallback: order.statusLabel ?? order.rawStatus,
);

/// Libellé d'un statut seul — pour une ligne d'historique, qui n'a pas d'objet
/// [Order] complet.
///
/// [fallback] est le `status_label` du serveur : c'est lui qu'on affiche pour
/// un statut ajouté côté serveur après ce build, plutôt qu'une chaîne vide ou
/// un code brut.
String statusLabelFor(
  AppLocalizations l10n,
  OrderStatus status, {
  String fallback = '',
}) => switch (status) {
  OrderStatus.draft => l10n.orderStatusDraft,
  OrderStatus.searchingDriver => l10n.orderStatusSearchingDriver,
  OrderStatus.driverAssigned => l10n.orderStatusDriverAssigned,
  OrderStatus.driverEnRoutePickup => l10n.orderStatusEnRoutePickup,
  OrderStatus.pickedUp => l10n.orderStatusPickedUp,
  OrderStatus.inTransit => l10n.orderStatusInTransit,
  OrderStatus.delivered => l10n.orderStatusDelivered,
  OrderStatus.completed => l10n.orderStatusCompleted,
  OrderStatus.cancelledByClient => l10n.orderStatusCancelledByClient,
  OrderStatus.cancelledBySystem => l10n.orderStatusCancelledBySystem,
  OrderStatus.disputed => l10n.orderStatusDisputed,
  OrderStatus.unknown => fallback,
};

/// Couleur de la puce de statut, alignée sur le ruban.
Color statusColor(OrderStatus status) => switch (status) {
  OrderStatus.draft => AppColors.inkMuted,
  OrderStatus.searchingDriver => AppColors.error,
  OrderStatus.driverAssigned ||
  OrderStatus.driverEnRoutePickup => AppColors.accentMagenta,
  OrderStatus.pickedUp => AppColors.warning,
  OrderStatus.inTransit => AppColors.accentCyan,
  OrderStatus.delivered || OrderStatus.completed => AppColors.success,
  OrderStatus.cancelledByClient ||
  OrderStatus.cancelledBySystem ||
  OrderStatus.disputed => AppColors.error,
  OrderStatus.unknown => AppColors.inkMuted,
};

/// Première partie d'une adresse (« Bonanjo » dans « Bonanjo, Rue Joss »),
/// pour les résumés « Départ → Arrivée ».
String shortAddress(String address) {
  final first = address.split(',').first.trim();
  return first.isEmpty ? address : first;
}
