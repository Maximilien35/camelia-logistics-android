import 'dart:io';
import 'dart:convert';
import 'package:camelia/models/services/user_profile_service.dart';
import 'package:camelia/models/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/order_model.dart';
import '../models/services/order_service.dart';
import '../models/order_state_model.dart';
import '../models/services/storage_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:camelia/l10n/app_localizations.dart';
import 'widgets/service_type_selector.dart';
import 'widgets/delivery_form_widget.dart';
import 'widgets/moving_form_widget.dart';
import 'widgets/shipment_form_widget.dart';
import 'widgets/storage_form_widget.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  @override
  void initState() {
    super.initState();
    // Réinitialiser l'état de commande au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderStateModel>(context, listen: false).reset();
    });
  }

  void _onServiceTypeSelected(String serviceType) {
    final orderState = Provider.of<OrderStateModel>(context, listen: false);
    orderState.setServiceType(serviceType);
    _proceedToTunnel(serviceType);
  }

  void _proceedToTunnel(String serviceType) {
        Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ServiceTunnelScreen(
          serviceType: serviceType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/home_custom');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.newOrderTitle,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () => context.push('/home_custom'),
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => context.push('/history'),
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.history_rounded,
                  size: 20,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            IconButton(
              onPressed: () => context.go('/profil'),
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 20,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        body: ServiceTypeSelector(
          onServiceTypeSelected: _onServiceTypeSelected,
        ),
      ),
    );
  }
}

class ServiceTunnelScreen extends StatefulWidget {
  final String serviceType;

  const ServiceTunnelScreen({
    required this.serviceType,
    super.key,
  });

  @override
  State<ServiceTunnelScreen> createState() => _ServiceTunnelScreenState();
}

class _ServiceTunnelScreenState extends State<ServiceTunnelScreen> {
  late String _currentServiceType;

  @override
  void initState() {
    super.initState();
    _currentServiceType = widget.serviceType;
  }

  void _proceedToDeliveryPoints() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeliveryPointsScreen(
          serviceType: _currentServiceType,
        ),
      ),
    );
  }

  void _submitQuoteRequest() {
    final l10n = AppLocalizations.of(context)!;
    final orderState = Provider.of<OrderStateModel>(context, listen: false);
    
    orderState.setIsQuote(true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.quoteRequestSubmitted),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DeliveryPointsScreen(
              serviceType: _currentServiceType,
            ),
          ),
        );
      }
    });
  }

  Color _getColorForServiceType() {
    switch (_currentServiceType) {
      case 'LIVRAISON':
        return const Color(0xFF4CAF50);
      case 'DÉMÉNAGEMENT ET TRANSPORT':
        return const Color(0xFF2196F3);
      case 'EXPÉDITION':
        return const Color(0xFFFF9800);
      case 'STOCKAGE':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF6C63FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    _getColorForServiceType();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentServiceType,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildFormWidget(
          key: ValueKey(_currentServiceType),
        ),
      ),
    );
  }

  Widget _buildFormWidget({required Key key}) {
    switch (_currentServiceType) {
      case 'LIVRAISON':
        return DeliveryFormWidget(
          key: key,
          onProceed: _proceedToDeliveryPoints,
        );
      case 'DÉMÉNAGEMENT ET TRANSPORT':
        return MovingFormWidget(
          key: key,
          onProceed: _submitQuoteRequest,
        );
      case 'EXPÉDITION':
        return ShipmentFormWidget(
          key: key,
          onProceed: _submitQuoteRequest,
        );
      case 'STOCKAGE ET LIVRAISON':
        return StorageFormWidget(
          key: key,
          onProceed: _submitQuoteRequest,
        );
      case 'TRANSPORT INTERNATIONAL':
        return ShipmentFormWidget(
          key: key,
          onProceed: _submitQuoteRequest,
        );
      default:
        return Center(
          child: Text('Service type not found: $_currentServiceType'),
        );
    }
  }
}

class PackagePhotoScreen extends StatefulWidget {
  const PackagePhotoScreen({super.key});

  @override
  State<PackagePhotoScreen> createState() => _PackagePhotoScreenState();
}

class _PackagePhotoScreenState extends State<PackagePhotoScreen> {
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_updateDescription);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateDescription() {
    final orderState = Provider.of<OrderStateModel>(context, listen: false);
    orderState.setDescription(_descriptionController.text);
  }

  void _pickAndAddPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      final orderState = Provider.of<OrderStateModel>(context, listen: false);
      orderState.addPhoto(imageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.newOrderTitle,
          style:  TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.grey.shade700,
            ),
          ),
          onPressed: () => {
            if (Navigator.of(context).canPop())
              {Navigator.of(context).pop()}
            else
              {context.go('/home_custom')},
          },
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.step2of4,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.packagePhotoTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.packagePhotoSubtitle,
                    style:  TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Consumer<OrderStateModel>(
                builder: (context, orderState, child) {
                  final hasPhotos = orderState.selectedFiles.isNotEmpty;
                  return Column(
                    children: [
                      if (hasPhotos)
                        _buildPhotoGrid(orderState.selectedFiles)
                      else
                        GestureDetector(
                          onTap: _pickAndAddPhoto,
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_rounded,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.addAPhoto,
                                  style:  TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.touchToChoosePhoto,
                                  style:  TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _pickAndAddPhoto,
                          icon: const Icon(
                            Icons.add_a_photo_rounded,
                            color: Color(0xFF6C63FF),
                            size: 20,
                          ),
                          label: Text(
                            l10n.takeOrChoosePhoto,
                            style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color(0xFF6C63FF)),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.packageType,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<OrderStateModel>(
                    builder: (context, orderState, child) {
                      final currentSelection = orderState.packageNature;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildPackageTypeChip(
                            l10n.goods,
                            Icons.local_shipping_rounded,
                            currentSelection,
                          ),
                          _buildPackageTypeChip(
                            l10n.electronics,
                            Icons.laptop_mac_rounded,
                            currentSelection,
                          ),
                          _buildPackageTypeChip(
                            l10n.furniture,
                            Icons.chair_rounded,
                            currentSelection,
                          ),
                          _buildPackageTypeChip(
                            l10n.food,
                            Icons.restaurant_rounded,
                            currentSelection,
                          ),
                          _buildPackageTypeChip(
                            l10n.fragile,
                            Icons.warning_rounded,
                            currentSelection,
                          ),
                          _buildPackageTypeChip(
                            l10n.other,
                            Icons.more_horiz_rounded,
                            currentSelection,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.descriptionOptional,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: l10n.describeYourPackageHint,
                      hintStyle:  TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF6C63FF),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Consumer<OrderStateModel>(
                builder: (context, orderState, child) {
                  final hasPhotos = orderState.selectedFiles.isNotEmpty;
                  final hasPackage =
                      orderState.packageNature?.isNotEmpty ?? false;
                  return SizedBox(
                    width: double.infinity,
                    child: Material(
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          if (hasPhotos && hasPackage) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    DeliveryPointsScreen(
                                      serviceType: orderState.serviceType ?? '',
                                    ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.pleaseCompleteSelection,
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.red.shade600,
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              l10n.continueButton,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(List<File> files) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: files.map((file) {
        return Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  file,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: GestureDetector(
                onTap: () {
                  final orderState = Provider.of<OrderStateModel>(
                    context,
                    listen: false,
                  );
                  orderState.removePhoto(file);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPackageTypeChip(
    String label,
    IconData icon,
    String? currentSelection,
  ) {
    final isSelected = currentSelection == label;
    return GestureDetector(
      onTap: () {
        final orderState = Provider.of<OrderStateModel>(context, listen: false);
        final newValue = isSelected ? null : label;
        orderState.setPackageNature(newValue);
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class DeliveryPointsScreen extends StatefulWidget {
  final String serviceType;

  const DeliveryPointsScreen({super.key, required this.serviceType});

  @override
  DeliveryPointsScreenState createState() => DeliveryPointsScreenState();
}

class DeliveryPointsScreenState extends State<DeliveryPointsScreen> {
  bool get _mapActionsEnabled {
    const disallowed = [
      'STOCKAGE ET LIVRAISON',
      'EXPÉDITION',
      'TRANSPORT INTERNATIONAL',
    ];
    return !disallowed.contains(widget.serviceType);
  }
  final TextEditingController _depart = TextEditingController();
  final TextEditingController _arrive = TextEditingController();

  LatLng? _pickupCoords;
  LatLng? _dropoffCoords;
  double? _estimatedDistance;
  List<LatLng> _routePoints = [];

  // Debouncer pour la recherche d'adresse
  Timer? _debounceTimerDepart;
  Timer? _debounceTimerArrive;

  @override
  void initState() {
    super.initState();
    _arrive.addListener(_onDestinationChanged);
    _depart.addListener(_onDepartureChanged); // Ajout du listener pour le départ manuel
  }

  @override
  void dispose() {
    _debounceTimerDepart?.cancel();
    _debounceTimerArrive?.cancel();
    _depart.dispose();
    _arrive.dispose();
    super.dispose();
  }

  // Nouvelle méthode pour gérer la saisie manuelle du départ
  void _onDepartureChanged() {
    if (mounted) setState(() {});
    final orderState = Provider.of<OrderStateModel>(context, listen: false);
    orderState.setPointDelivery(_depart.text, _arrive.text);
    
    // Si le champ est vide, réinitialiser les coordonnées
    if (_depart.text.isEmpty) {
      setState(() {
        _pickupCoords = null;
        _calculateDistance();
        _fetchRoute();
      });
      return;
    }

    _debounceTimerDepart?.cancel();
    _debounceTimerDepart = Timer(const Duration(milliseconds: 800), () {
      _geocodeAddress(_depart.text, isPickup: true);
    });
  }

  void _onDestinationChanged() {
    if (mounted) setState(() {});
    final orderState = Provider.of<OrderStateModel>(context, listen: false);
    orderState.setPointDelivery(_depart.text, _arrive.text);

    if (_arrive.text.isEmpty) {
      setState(() {
        _dropoffCoords = null;
        _calculateDistance();
        _fetchRoute();
      });
      return;
    }

    _debounceTimerArrive?.cancel();
    _debounceTimerArrive = Timer(const Duration(milliseconds: 800), () {
      _geocodeAddress(_arrive.text, isPickup: false);
    });
  }

  Future<void> _geocodeAddress(String address, {required bool isPickup}) async {
    if (address.isEmpty) return;

    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final coords = LatLng(location.latitude, location.longitude);

        if (mounted) {
          setState(() {
            if (isPickup) {
              _pickupCoords = coords;
            } else {
              _dropoffCoords = coords;
            }
            _calculateDistance();
            _fetchRoute();
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur de géocodage: $e");
    }
  }

  Future<void> _useMyLocation() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_mapActionsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carte / position indisponible pour ce type de service.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.locationPermissionDenied),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final LatLng coords = LatLng(position.latitude, position.longitude);

      final placemarks = await placemarkFromCoordinates(
        coords.latitude,
        coords.longitude,
      );

      if (placemarks.isNotEmpty) {
        final address = placemarks.first;
        final fullAddress = "${address.street}, ${address.locality}";

        if (mounted) {
          setState(() {
            _depart.text = fullAddress;
            _pickupCoords = coords;
            _calculateDistance();
            _fetchRoute();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.locationError(e.toString())),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _selectDestinationOnMap() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapSelectorScreen(
          initialPosition: _dropoffCoords ?? const LatLng(4.0450, 9.7041),
        ),
      ),
    );

    if (!mounted) return;

    if (result != null && result is Map<String, dynamic>) {
      final LatLng coords = result['coords'];
      final String address = result['address'];

      if (mounted) {
        setState(() {
          _arrive.text = address;
          _dropoffCoords = coords;
          _calculateDistance();
          _fetchRoute();
        });
      }
    }
  }

  void _calculateDistance() {
    if (_pickupCoords != null && _dropoffCoords != null) {
      final distanceInMeters = Geolocator.distanceBetween(
        _pickupCoords!.latitude,
        _pickupCoords!.longitude,
        _dropoffCoords!.latitude,
        _dropoffCoords!.longitude,
      );

      setState(() {
        _estimatedDistance = distanceInMeters / 1000;
      });
    } else {
      setState(() {
        _estimatedDistance = null;
      });
    }
  }

  Future<void> _fetchRoute() async {
    if (_pickupCoords == null || _dropoffCoords == null) return;

    final start = _pickupCoords!;
    final end = _dropoffCoords!;

    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry = data['routes'][0]['geometry']['coordinates'] as List;
        if (mounted) {
          setState(() {
            _routePoints = geometry
                .map((p) => LatLng(p[1].toDouble(), p[0].toDouble()))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur OSRM: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.deliveryPointsTitle,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.grey.shade700,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.step3of4,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.deliveryPointsTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.setDepartureAndDestination,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.startingPoint,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _depart,
                    decoration: InputDecoration(
                      hintText: l10n.departureAddressHint,
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF6C63FF),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF6C63FF),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _mapActionsEnabled ? _useMyLocation : null,
                      icon:  Icon(
                        Icons.my_location_rounded,
                        color:_mapActionsEnabled ? const Color(0xFF6C63FF) : Colors.grey.shade400,
                        size: 18,
                      ),
                      label: Text(
                        l10n.useMyPosition,
                        style:  TextStyle(
                          color:_mapActionsEnabled ? const Color(0xFF6C63FF) : Colors.grey.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFF6C63FF)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.destinationPoint,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _arrive,
                    decoration: InputDecoration(
                      hintText: l10n.deliveryAddressHint,
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(
                        Icons.flag_rounded,
                        color: Color(0xFF4CAF50),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF4CAF50),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _mapActionsEnabled ? _selectDestinationOnMap : null,
                          icon:  Icon(
                            Icons.map_rounded,
                            color:_mapActionsEnabled ? const Color(0xFF6C63FF) : Colors.grey.shade400,
                            size: 18,
                          ),
                          label: Text(
                            l10n.chooseOnMap,
                            style:  TextStyle(
                              color:_mapActionsEnabled ? const Color(0xFF6C63FF) : Colors.grey.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color(0xFF6C63FF)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                    l10n.mapAndDistance,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                   const SizedBox(width: 10),
                                  Text(
                                    _estimatedDistance != null
                                        ? '${_estimatedDistance!.toStringAsFixed(1)} km'
                                        : l10n.selectAddresses,
                                    style:  const TextStyle(
                                      color: Color.fromARGB(255, 18, 59, 207),
                                      fontSize: 13,
                                    ),
                                  ),
                    ]),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _pickupCoords == null && _dropoffCoords == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.map_rounded,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n.interactiveMap,
                                    style:  TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _estimatedDistance != null
                                        ? '${_estimatedDistance!.toStringAsFixed(1)} km'
                                        : l10n.selectAddresses,
                                    style:  TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : FlutterMap(
                              options: MapOptions(
                                initialCenter:
                                    _pickupCoords ??
                                    const LatLng(4.0450, 9.7041),
                                initialZoom: 13.0,
                                initialCameraFit:
                                    _pickupCoords != null &&
                                        _dropoffCoords != null
                                    ? CameraFit.bounds(
                                        bounds: LatLngBounds(
                                          _pickupCoords!,
                                          _dropoffCoords!,
                                        ),
                                        padding: const EdgeInsets.all(40),
                                      )
                                    : null,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.camelia.logistics',
                                ),
                                if (_routePoints.isNotEmpty)
                                  PolylineLayer(
                                    polylines: [
                                      Polyline(
                                        points: _routePoints,
                                        strokeWidth: 4.0,
                                        color: const Color(0xFF6C63FF),
                                      ),
                                    ],
                                  ),
                                MarkerLayer(
                                  markers: [
                                    if (_pickupCoords != null)
                                      Marker(
                                        point: _pickupCoords!,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withValues(
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.location_on_rounded,
                                            color: Color(0xFF6C63FF),
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    if (_dropoffCoords != null)
                                      Marker(
                                        point: _dropoffCoords!,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withValues(
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.flag_rounded,
                                            color: Color(0xFF4CAF50),
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: Material(
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _depart.text.isNotEmpty && _arrive.text.isNotEmpty
                        ? () {
                            final orderState = Provider.of<OrderStateModel>(
                              context,
                              listen: false,
                            );
                            orderState.setCoordinates(
                              _pickupCoords ?? const LatLng(0, 0),
                              _dropoffCoords ?? const LatLng(0, 0),
                              _estimatedDistance ?? 0.0,
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const FinalisationOrder(),
                              ),
                            );
                          }
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient:
                            _depart.text.isNotEmpty && _arrive.text.isNotEmpty
                            ? const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.grey.shade400,
                                  Colors.grey.shade400,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          l10n.continueButton,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class FinalisationOrder extends StatefulWidget {
  const FinalisationOrder({super.key});

  @override
  State<FinalisationOrder> createState() => _FinalisationOrderState();
}

class _FinalisationOrderState extends State<FinalisationOrder> {
  final UserProfileService _userServices = UserProfileService();
  final id = FirebaseAuth.instance.currentUser?.uid;
  late Future<UserProfile?> _profileFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = (id != null)
        ? _userServices.getProfile(id!)
        : Future.value(null);
  }

  void createOrder() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final OrderStateModel orderState = Provider.of<OrderStateModel>(
      context,
      listen: false,
    );
    final DateTime now = DateTime.now();

    if (orderState.pickupAddress == null || orderState.serviceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez définir l’adresse et le type de service.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (mounted) setState(() => _isLoading = true);

    try {
      List<Future<String>> uploadTasks = orderState.selectedFiles.map((file) {
        String fileName = file.path.split('/').last;
        String path =
            'orders/${currentUser.uid}/${now.millisecondsSinceEpoch}/$fileName';
        return StorageService().uploadImage(file, path);
      }).toList();

      List<String> photoUrls = await Future.wait(uploadTasks);
      final newOrder = Order(
        userId: currentUser.uid,
        pickupAddress: orderState.pickupAddress!,
        dropoffAddress: orderState.dropoffAddress ?? 'Non spécifié',
        packageNature: orderState.packageNature ?? 'Non spécifié',
        photoUrls: photoUrls,
        vehicleType: orderState.vehicleType ?? orderState.serviceType ?? 'Non spécifié',
        status: 'PENDING',
        timestamp: now,
        priceQuote: orderState.priceQuote,
        description: orderState.description,
        serviceType: orderState.serviceType ?? 'Transport',
        isQuote: orderState.isQuote,
        additionalDetails: orderState.additionalDetails,
      );

      double? clientLat = orderState.pickupCoords?.latitude;
      double? clientLon = orderState.pickupCoords?.longitude;

      // Créer la commande avec assignation automatique du collaborateur le plus proche
      final String newOrderId = await OrderService().addOrderWithAutoAssignment(
        newOrder,
        clientLat: clientLat,
        clientLon: clientLon,
      );

      if (mounted) {
        context.go('/waiting/$newOrderId');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Erreur lors de l'envoi de la commande: Verifier votre connexion internet et réessayer. Détails: "),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.orderSummaryTitle,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.grey.shade700,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<UserProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child:  CircularProgressIndicator(
                color: Color(0xFF6C63FF),
                strokeWidth: 2,
              ),
            );
          }
          final profile = snapshot.data!;
          final orderState = Provider.of<OrderStateModel>(context);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.step4of4,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.orderSummaryTitle,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.reviewDetailsBeforeConfirming,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100, width: 1),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          label: l10n.transport,
                          value: orderState.vehicleType ?? l10n.notSpecified,
                          icon: Icons.local_shipping_rounded,
                          color: const Color(0xFF6C63FF),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          label: l10n.phone,
                          value: profile.phoneNumber,
                          icon: Icons.phone_rounded,
                          color: const Color(0xFF4CAF50),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          label: l10n.departure,
                          value: _truncateAddress(orderState.pickupAddress),
                          icon: Icons.location_on_rounded,
                          color: const Color(0xFFFF9800),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          label: l10n.packageType,
                          value: orderState.packageNature ?? l10n.notSpecified,
                          icon: Icons.inventory_2_rounded,
                          color: const Color(0xFF9C27B0),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          label: l10n.destination,
                          value: _truncateAddress(orderState.dropoffAddress),
                          icon: Icons.flag_rounded,
                          color: const Color(0xFF2196F3),
                        ),
                        //   _buildSummaryRow(
                        //   label: l10n.estimatedPrice,
                        //   value: orderState.priceQuote != null
                        //       ? '${orderState.priceQuote!.toStringAsFixed(0)} FCFA'
                        //       : l10n.notSpecified,
                        //   icon: Icons.attach_money_rounded,
                        //   color: const Color.fromARGB(255, 19, 65, 232),
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: Material(
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _isLoading ? null : createOrder,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    l10n.confirmOrder,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  String _truncateAddress(String? address) {
    final l10n = AppLocalizations.of(context)!;
    if (address == null) return l10n.notSpecified;
    return address.length > 30 ? '${address.substring(0, 30)}...' : address;
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MapSelectorScreen extends StatefulWidget {
  final LatLng initialPosition;

  const MapSelectorScreen({super.key, required this.initialPosition});

  @override
  State<MapSelectorScreen> createState() => _MapSelectorScreenState();
}

class _MapSelectorScreenState extends State<MapSelectorScreen> {
  late LatLng _currentCameraPosition;
  String _selectedAddress = "";
  bool _isGeocoding = false;
  final MapController _mapController = MapController();
  
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _currentCameraPosition = widget.initialPosition;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAddress(_currentCameraPosition);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAddress(LatLng position) async {
    final l10n = AppLocalizations.of(context)!;
    if (mounted) setState(() => _isGeocoding = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _selectedAddress = "${place.street ?? ''}, ${place.locality ?? ''}";
          _searchController.text = _selectedAddress;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _selectedAddress = l10n.unknownLocation);
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isSearching = true);
    
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1',
      );
      
      final response = await http.get(
        url,
        headers: {'User-Agent': 'CameliaLogistics/1.0'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _searchResults = data;
            _isSearching = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur de recherche: $e");
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchAddress(query);
    });
  }

  void _selectLocation(Map<String, dynamic> location) {
    final lat = double.parse(location['lat']);
    final lon = double.parse(location['lon']);
    final position = LatLng(lat, lon);
    final displayName = location['display_name'] as String;

    setState(() {
      _currentCameraPosition = position;
      _selectedAddress = displayName;
      _searchController.text = displayName;
      _searchResults = [];
    });

    _mapController.move(position, 16);
    _fetchAddress(position);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.chooseDestinationTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.grey.shade700,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Carte
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialPosition,
              initialZoom: 16,
              onPositionChanged: (position, hasGesture) {
                if (position.center != null) {
                  _currentCameraPosition = position.center!;
                  if (hasGesture) _fetchAddress(_currentCameraPosition);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.camelia.logistics',
              ),
            ],
          ),
          
          // Marqueur central
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35),
              child: Icon(
                Icons.location_on_rounded,
                size: 50,
                color: Colors.green.shade700,
              ),
            ),
          ),
          
          // Barre de recherche
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: l10n.searchAddressHint,
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF6C63FF),
                      ),
                      suffixIcon: _isSearching
                          ? Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.all(12),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF6C63FF),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchResults = []);
                                  },
                                )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                
                // Résultats de recherche
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFF6C63FF),
                          ),
                          title: Text(
                            result['display_name'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () => _selectLocation(result),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          
          // Panneau de confirmation
          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.map_rounded,
                        color: Colors.grey.shade400,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isGeocoding
                            ? const LinearProgressIndicator(
                                color: Color(0xFF6C63FF),
                              )
                            : Text(
                                _selectedAddress,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _isGeocoding
                            ? null
                            : () {
                                Navigator.pop(context, {
                                  'coords': _currentCameraPosition,
                                  'address': _selectedAddress,
                                });
                              },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              l10n.confirmThisPoint,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
