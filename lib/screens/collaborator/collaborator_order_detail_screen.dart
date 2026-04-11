import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../models/collaborator_state_model.dart';
import '../../models/services/local_notification_service.dart';

class CollaboratorOrderDetailScreen extends StatefulWidget {
  const CollaboratorOrderDetailScreen({super.key});

  @override
  State<CollaboratorOrderDetailScreen> createState() =>
      _CollaboratorOrderDetailScreenState();
}

class _CollaboratorOrderDetailScreenState
    extends State<CollaboratorOrderDetailScreen> {
  final _notesController = TextEditingController();
  bool _isUpdating = false;

  LatLng? _pickupCoords;
  LatLng? _dropoffCoords;
  List<LatLng> _routePoints = [];
  bool _isLoadingMap = false;
  String? _mapError;
  String? _activeOrderId;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange.shade600;
      case 'ASSIGNED':
        return Colors.blue.shade600;
      case 'ACCEPTED':
        return Colors.blue.shade700;
      case 'IN_PROGRESS':
        return Colors.purple.shade600;
      case 'COMPLETED':
        return Colors.green.shade600;
      case 'CANCELLED':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'En attente';
      case 'ASSIGNED':
        return 'Assignée';
      case 'ACCEPTED':
        return 'Acceptée';
      case 'IN_PROGRESS':
        return 'En cours';
      case 'COMPLETED':
        return 'Terminée';
      case 'CANCELLED':
        return 'Annulée';
      default:
        return status;
    }
  }

  Future<void> _loadRouteFromOrder(Map<String, dynamic> order) async {
    final orderId = order['id']?.toString();
    if (orderId == null) return;

    setState(() {
      _isLoadingMap = true;
      _mapError = null;
      _routePoints = [];
      _pickupCoords = null;
      _dropoffCoords = null;
    });

    try {
      final pickupLat = (order['pickupLat'] as num?)?.toDouble();
      final pickupLng = (order['pickupLng'] as num?)?.toDouble();
      final dropoffLat = (order['dropoffLat'] as num?)?.toDouble();
      final dropoffLng = (order['dropoffLng'] as num?)?.toDouble();
      final pickupAddress = (order['pickupAddress'] as String?) ?? '';
      final dropoffAddress = (order['dropoffAddress'] as String?) ?? '';

      LatLng? pickupPoint;
      LatLng? dropoffPoint;

      if (pickupLat != null && pickupLng != null) {
        pickupPoint = LatLng(pickupLat, pickupLng);
      } else if (pickupAddress.isNotEmpty) {
        final locationResults = await locationFromAddress(
          pickupAddress,
        ).catchError((_) => <Location>[]);
        if (locationResults.isNotEmpty) {
          pickupPoint = LatLng(
            locationResults.first.latitude,
            locationResults.first.longitude,
          );
        }
      }

      if (dropoffLat != null && dropoffLng != null) {
        dropoffPoint = LatLng(dropoffLat, dropoffLng);
      } else if (dropoffAddress.isNotEmpty) {
        final locationResults = await locationFromAddress(
          dropoffAddress,
        ).catchError((_) => <Location>[]);
        if (locationResults.isNotEmpty) {
          dropoffPoint = LatLng(
            locationResults.first.latitude,
            locationResults.first.longitude,
          );
        }
      }

      if (pickupPoint == null || dropoffPoint == null) {
        setState(() {
          _mapError = 'Coordonnées GPS introuvables pour l\'itinéraire.';
          _isLoadingMap = false;
        });
        return;
      }

      _pickupCoords = pickupPoint;
      _dropoffCoords = dropoffPoint;

      final osrmUrl = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${pickupPoint.longitude},${pickupPoint.latitude};${dropoffPoint.longitude},${dropoffPoint.latitude}?overview=full&geometries=geojson',
      );
      final response = await http
          .get(osrmUrl)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => http.Response('timeout', 408),
          );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coords =
            (data['routes']?[0]?['geometry']?['coordinates'] ?? []) as List;
        final points = coords.map<LatLng>((item) {
          final p = item as List;
          return LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble());
        }).toList();

        setState(() {
          _routePoints = points;
          _isLoadingMap = false;
          _mapError = null;
        });
      } else {
        setState(() {
          _mapError = 'Erreur OSRM (${response.statusCode})';
          _isLoadingMap = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mapError = 'Échec chargement itinéraire';
        _isLoadingMap = false;
      });
    } finally {
      if (mounted) _activeOrderId = orderId;
    }
  }

  Widget _buildMapArea() {
    if (_isLoadingMap) return const Center(child: CircularProgressIndicator());
    if (_mapError != null) {
      return Center(
        child: Text(_mapError!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_routePoints.isEmpty ||
        _pickupCoords == null ||
        _dropoffCoords == null) {
      return const Center(child: Text('Itinéraire non disponible'));
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: _pickupCoords!,
        initialZoom: 13,
        minZoom: 3,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.camelia.logistics',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: _routePoints,
              color: Colors.blue.shade700,
              strokeWidth: 4,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _pickupCoords!,
              width: 32,
              height: 32,
              child: const Icon(
                Icons.location_on,
                color: Colors.green,
                size: 32,
              ),
            ),
            Marker(
              point: _dropoffCoords!,
              width: 32,
              height: 32,
              child: const Icon(Icons.location_on, color: Colors.red, size: 32),
            ),
          ],
        ),
      ],
    );
  }

  void _ensureMapLoaded(Map<String, dynamic> order) {
    final orderId = order['id']?.toString();
    if (orderId == null) return;
    if (_activeOrderId != orderId) {
      _loadRouteFromOrder(order);
    }
  }

  @override
  Widget build(BuildContext context) {
    final collaboratorState = context.watch<CollaboratorStateModel>();
    final order = collaboratorState.selectedOrder;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails commande')),
        body: const Center(child: Text('Commande introuvable')),
      );
    }

    _ensureMapLoaded(order);

    final status = (order['status'] as String?)?.toUpperCase() ?? 'PENDING';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final serviceType = (order['serviceType'] as String?) ?? 'LIVRAISON';
    final pickupAddress =
        (order['pickupAddress'] as String?) ?? 'Adresse inconnue';
    final dropoffAddress =
        (order['dropoffAddress'] as String?) ?? 'Adresse inconnue';
    final priceQuote = (order['priceQuote'] as num?)?.toDouble() ?? 0.0;
    final additionalDetails =
        (order['additionalDetails'] as Map<String, dynamic>?) ?? {};
    final photoUrls =
        (order['photoUrls'] as List?)?.cast<String>() ??
        (order['photos'] as List?)?.cast<String>() ??
        [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Détails commande collaborateur'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${order['id']?.toString().substring(0, 8).toUpperCase() ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    serviceType,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prix: ${priceQuote.toStringAsFixed(2)} FCFA',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildMapArea(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Départ : $pickupAddress',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              'Arrivée : $dropoffAddress',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 20),

            if (additionalDetails.isNotEmpty) ...[
              Text(
                'Détails additionnels',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              ...additionalDetails.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          textAlign: TextAlign.right,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (photoUrls.isNotEmpty) ...[
              Text(
                'Photos',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: photoUrls.length,
                itemBuilder: (context, index) {
                  final url = photoUrls[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],

            if (status == 'IN_PROGRESS' || status == 'COMPLETED') ...[
              Text(
                'Notes',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Ajoutez vos notes',
                ),
              ),
              const SizedBox(height: 20),
            ],

            _buildActionButtons(order),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> order) {
    final status = (order['status'] as String?)?.toUpperCase() ?? 'PENDING';
    final provider = context.read<CollaboratorStateModel>();

    if (status == 'PENDING' || status == 'ASSIGNED') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isUpdating
                  ? null
                  : () => _handleRefuse(order, provider),
              child: const Text('Refuser'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: _isUpdating
                  ? null
                  : () => _handleAccept(order, provider),
              child: const Text('Accepter'),
            ),
          ),
        ],
      );
    }

    if (status == 'ACCEPTED') {
      return _buildBigButton(
        'Commencer la livraison',
        Colors.purple.shade600,
        () => _changeStatus(order, provider, 'IN_PROGRESS'),
      );
    }

    if (status == 'IN_PROGRESS') {
      return _buildBigButton(
        'Terminer la livraison',
        Colors.green.shade600,
        () => _changeStatus(order, provider, 'COMPLETED'),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBigButton(String label, Color color, VoidCallback callback) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isUpdating ? null : callback,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isUpdating
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _handleAccept(
    Map<String, dynamic> order,
    CollaboratorStateModel provider,
  ) async {
    final orderPrice = (order['priceQuote'] as num?)?.toDouble() ?? 0.0;
    if (orderPrice <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Prix non valide.')));
      return;
    }
    setState(() => _isUpdating = true);
    final success = await provider.acceptOrder(order['id']);
    setState(() => _isUpdating = false);
    _showScaffoldMsg(
      success ? 'Commande acceptée' : 'Échec acceptation',
      success ? Colors.green : Colors.red,
    );
  }

  void _handleRefuse(
    Map<String, dynamic> order,
    CollaboratorStateModel provider,
  ) async {
    setState(() => _isUpdating = true);
    final success = await provider.refuseOrder(
      order['id'],
      reason: 'Refus collaborateur',
    );
    setState(() => _isUpdating = false);
    _showScaffoldMsg(
      success ? 'Commande refusée' : 'Échec refus',
      success ? Colors.orange : Colors.red,
    );
  }

  void _changeStatus(
    Map<String, dynamic> order,
    CollaboratorStateModel provider,
    String newStatus,
  ) async {
    setState(() => _isUpdating = true);
    final success = await provider.updateOrderStatus(
      order['id'],
      newStatus,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );
    setState(() => _isUpdating = false);

    if (success) {
      // Rappels locaux (synchronisés sur le flux de statut)
      if (newStatus == 'IN_PROGRESS') {
        final deadline = DateTime.now().add(const Duration(minutes: 15));
        await LocalNotificationService.showReminder(
          id: 123456 + order['id'].hashCode,
          title: 'Suivi de livraison',
          body:
              'Votre livraison est en cours. Bientôt arrivée dans 15 minutes.',
          scheduledTime: deadline,
        );
      } else if (newStatus == 'COMPLETED') {
        await LocalNotificationService.cancel(123456 + order['id'].hashCode);
      }
    }

    _showScaffoldMsg(
      success ? 'Statut mis à jour' : 'Échec statut',
      success ? Colors.green : Colors.red,
    );
  }

  void _showScaffoldMsg(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
  }
}
