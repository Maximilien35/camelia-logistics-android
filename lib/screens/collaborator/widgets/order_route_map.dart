import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderRouteMap extends StatelessWidget {
  final String pickupAddress;
  final double? pickupLat;
  final double? pickupLng;
  final String dropoffAddress;
  final double? dropoffLat;
  final double? dropoffLng;
  final String serviceType;

  const OrderRouteMap({
    super.key,
    required this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    required this.dropoffAddress,
    this.dropoffLat,
    this.dropoffLng,
    required this.serviceType,
  });
  Future<void> _launchUrl(BuildContext context, String url) async {
    Uri? primaryUri;

    if (pickupLat != null && pickupLng != null && dropoffLat != null && dropoffLng != null) {
      primaryUri = Uri.parse(
          'comgooglemaps://?saddr=$pickupLat,$pickupLng&daddr=$dropoffLat,$dropoffLng&directionsmode=driving');
    } else if (pickupLat != null && pickupLng != null) {
      primaryUri = Uri.parse('comgooglemaps://?q=$pickupLat,$pickupLng');
    }

    if (primaryUri != null && await canLaunchUrl(primaryUri)) {
      await launchUrl(primaryUri, mode: LaunchMode.externalApplication);
      return;
    }

    Uri? appleUri;
    if (pickupLat != null && pickupLng != null && dropoffLat != null && dropoffLng != null) {
      appleUri = Uri.parse('maps://?saddr=$pickupLat,$pickupLng&daddr=$dropoffLat,$dropoffLng');
    } else if (pickupLat != null && pickupLng != null) {
      appleUri = Uri.parse('maps://?q=$pickupLat,$pickupLng');
    }

    if (appleUri != null && await canLaunchUrl(appleUri)) {
      await launchUrl(appleUri, mode: LaunchMode.externalApplication);
      return;
    }

    final webUri = Uri.parse(url);
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return;
    }

    final fallbackUri = Uri.parse(_getGoogleMapsUrl());
    if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri, mode: LaunchMode.platformDefault);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir l\'application de navigation.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getGoogleMapsUrl() {
    // Format: https://www.google.com/maps/dir/origin/destination
    if (pickupLat != null && pickupLng != null && dropoffLat != null && dropoffLng != null) {
      return 'https://www.google.com/maps/dir/$pickupLat,$pickupLng/$dropoffLat,$dropoffLng';
    } else if (pickupLat != null && pickupLng != null) {
      return 'https://www.google.com/maps/search/?api=1&query=$pickupLat,$pickupLng';
    } else {
      // Fallback to address search with better encoding
      final encodedPickup = Uri.encodeComponent(pickupAddress);
      final encodedDropoff = Uri.encodeComponent(dropoffAddress);
      return 'https://www.google.com/maps/dir/?api=1&origin=$encodedPickup&destination=$encodedDropoff';
    }
  }

  String _getAppleMapsUrl() {
    // Format: https://maps.apple.com/?daddr=destination&saddr=origin
    if (pickupLat != null && pickupLng != null && dropoffLat != null && dropoffLng != null) {
      return 'https://maps.apple.com/?saddr=$pickupLat,$pickupLng&daddr=$dropoffLat,$dropoffLng';
    } else if (pickupLat != null && pickupLng != null) {
      return 'https://maps.apple.com/?q=$pickupLat,$pickupLng';
    } else {
      final encodedPickup = Uri.encodeComponent(pickupAddress);
      final encodedDropoff = Uri.encodeComponent(dropoffAddress);
      return 'https://maps.apple.com/?saddr=$encodedPickup&daddr=$encodedDropoff';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with service type
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getServiceTypeColor().withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getServiceTypeIcon(),
                color: _getServiceTypeColor(),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Itinéraire - $serviceType',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Navigation et suivi en temps réel',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Map container (static representation)
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Stack(
            children: [
              // Base map representation
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Carte statique de l\'itinéraire',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Route visualization
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    // Start point
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 160,
                      color: Colors.blue.shade300,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    // End point
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Action button overlay
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      // Handle map app selection
                      if (value == 'google') {
                        _launchUrl(context, _getGoogleMapsUrl());
                      } else if (value == 'apple') {
                        _launchUrl(context, _getAppleMapsUrl());
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'google',
                        child: Row(
                          children: [
                            Icon(Icons.map, size: 18, color: Colors.blue),
                            SizedBox(width: 12),
                            Text('Google Maps'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'apple',
                        child: Row(
                          children: [
                            Icon(Icons.map, size: 18, color: Colors.grey),
                            SizedBox(width: 12),
                            Text('Apple Maps'),
                          ],
                        ),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.directions,
                        color: Colors.blue.shade600,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Route details with enhanced information
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pickup point
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Point de départ',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                            ),
                            if (pickupLat != null && pickupLng != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.green.shade600,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pickupAddress,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (pickupLat != null && pickupLng != null)
                          Text(
                            '${pickupLat!.toStringAsFixed(6)}, ${pickupLng!.toStringAsFixed(6)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // Route line
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 2,
                color: Colors.blue.shade300,
              ),

              // Dropoff point
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Destination',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                            ),
                            if (dropoffLat != null && dropoffLng != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.red.shade600,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dropoffAddress,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (dropoffLat != null && dropoffLng != null)
                          Text(
                            '${dropoffLat!.toStringAsFixed(6)}, ${dropoffLng!.toStringAsFixed(6)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Enhanced info section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            border: Border.all(color: Colors.amber.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Conseils de navigation',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• Utilisez Google Maps ou Apple Maps pour une navigation précise\n• L\'itinéraire affiché est statique et peut varier selon le trafic\n• Vérifiez les conditions météo avant le départ\n• Respectez les limitations de vitesse et les règles de circulation',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade700,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getServiceTypeColor() {
    switch (serviceType.toUpperCase()) {
      case 'LIVRAISON':
        return Colors.blue;
      case 'COURSE':
        return Colors.green;
      case 'MESSAGERIE':
        return Colors.orange;
      case 'TRANSPORT':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getServiceTypeIcon() {
    switch (serviceType.toUpperCase()) {
      case 'LIVRAISON':
        return Icons.local_shipping;
      case 'COURSE':
        return Icons.directions_car;
      case 'MESSAGERIE':
        return Icons.mail;
      case 'TRANSPORT':
        return Icons.inventory;
      default:
        return Icons.map;
    }
  }
}
