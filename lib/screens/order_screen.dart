import 'dart:io';
import 'dart:convert';
import 'package:camelia_logistics/models/services/user_profile_service.dart';
import 'package:camelia_logistics/models/user_profile.dart';
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
import 'package:camelia_logistics/l10n/app_localizations.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  void _selectVehicleAndProceed(String vehicleType) {
    final orderState = Provider.of<OrderStateModel>(context, listen: false);
    orderState.setVehicleType(vehicleType);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const PackagePhotoScreen()));
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
            l10n.chooseVehicleTitle,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () => context.go('/home_custom'),
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
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.selectTransportMode,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF6C63FF),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.serviceComingSoon,
                            style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ListView(
                  children: [
                    _buildVehicleCard(
                      icon: Icons.fire_truck_rounded,
                      title: l10n.dumpTruck,
                      subtitle: l10n.fastAndEconomic,
                      color: const Color(0xFF6C63FF),
                      onTap: () => _selectVehicleAndProceed(l10n.dumpTruck),
                    ),
                    const SizedBox(height: 16),
                    _buildVehicleCard(
                      icon: Icons.local_shipping_rounded,
                      title: l10n.van,
                      subtitle: l10n.secureTransport,
                      color: const Color(0xFF4CAF50),
                      onTap: () => _selectVehicleAndProceed(l10n.van),
                    ),
                    const SizedBox(height: 16),
                    _buildVehicleCard(
                      icon: Icons.moped_rounded,
                      title: l10n.tricycle,
                      subtitle: l10n.fastAndEconomic,
                      color: const Color(0xFFFF9800),
                      onTap: () => _selectVehicleAndProceed(l10n.tricycle),
                    ),
                    const SizedBox(height: 16),
                    _buildVehicleCard(
                      icon: Icons.airport_shuttle_rounded,
                      title: l10n.minivan,
                      subtitle: l10n.mediumCapacity,
                      color: const Color(0xFF9C27B0),
                      onTap: () => _selectVehicleAndProceed(l10n.minivan),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFF6C63FF),
                            size: 20,
                          ),
                          label: Text(
                            l10n.trackPackage,
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Color(0xFF9C27B0),
                            size: 20,
                          ),
                          label: Text(
                            l10n.support,
                            style: const TextStyle(
                              color: Color(0xFF9C27B0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color(0xFF9C27B0)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.contactSupportCta,
                    style:  TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
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
                                    const DeliveryPointsScreen(),
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
  const DeliveryPointsScreen({super.key});
  @override
  DeliveryPointsScreenState createState() => DeliveryPointsScreenState();
}

class DeliveryPointsScreenState extends State<DeliveryPointsScreen> {
  final TextEditingController _depart = TextEditingController();
  final TextEditingController _arrive = TextEditingController();

  LatLng? _pickupCoords;
  LatLng? _dropoffCoords;
  double? _estimatedDistance;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _arrive.addListener(_updatePointDelivery);
    _depart.addListener(_updatePointDelivery);
  }

  @override
  void dispose() {
    _depart.dispose();
    _arrive.dispose();
    super.dispose();
  }

  void _updatePointDelivery() {
    final orderState = Provider.of<OrderStateModel>(context, listen: false);
    orderState.setPointDelivery(_depart.text, _arrive.text);
    _calculateDistance();
  }

  Future<void> _useMyLocation() async {
    final l10n = AppLocalizations.of(context)!;
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

      setState(() {
        _arrive.text = address;
        _dropoffCoords = coords;
        _calculateDistance();
        _fetchRoute();
      });
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
                    style:  TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                      hintStyle:  TextStyle(color: Colors.grey.shade400),
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
                      onPressed: _useMyLocation,
                      icon: const Icon(
                        Icons.my_location_rounded,
                        color: Color(0xFF6C63FF),
                        size: 18,
                      ),
                      label: Text(
                        l10n.useMyPosition,
                        style: const TextStyle(
                          color: Color(0xFF6C63FF),
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
                      hintStyle:  TextStyle(color: Colors.grey.shade400),
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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _selectDestinationOnMap,
                      icon: const Icon(
                        Icons.map_rounded,
                        color: Color(0xFF6C63FF),
                        size: 18,
                      ),
                      label: Text(
                        l10n.chooseOnMap,
                        style: const TextStyle(
                          color: Color(0xFF6C63FF),
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.mapAndDistance,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
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
                    onTap: _pickupCoords != null && _dropoffCoords != null
                        ? () {
                            final orderState = Provider.of<OrderStateModel>(
                              context,
                              listen: false,
                            );
                            orderState.setCoordinates(
                              _pickupCoords!,
                              _dropoffCoords!,
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
                            _pickupCoords != null && _dropoffCoords != null
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

    if (orderState.pickupAddress == null || orderState.vehicleType == null) {
      return;
    }
    setState(() => _isLoading = true);

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
        dropoffAddress: orderState.dropoffAddress!,
        packageNature: orderState.packageNature ?? 'Non spécifié',
        photoUrls: photoUrls,
        vehicleType: orderState.vehicleType!,
        status: 'PENDING',
        timestamp: now,
        priceQuote: orderState.priceQuote,
        description: orderState.description,
      );

      final String newOrderId = await OrderService().addOrder(newOrder);
      context.go('/waiting/$newOrderId');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar( // This should be translated, but requires context.
          content: const Text("Erreur lors de l'envoi de la commande."),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
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

  @override
  void initState() {
    super.initState();
    _currentCameraPosition = widget.initialPosition;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAddress(_currentCameraPosition);
    });
  }

  Future<void> _fetchAddress(LatLng position) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isGeocoding = true);
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
        });
      }
    } catch (e) {
      if (mounted) setState(() => _selectedAddress = l10n.unknownLocation);
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedAddress.isEmpty) {
      _selectedAddress = l10n.searchingForAddress;
    }
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
                            ? LinearProgressIndicator(
                                color: const Color(0xFF6C63FF),
                                backgroundColor: const Color(
                                  0xFF6C63FF,
                                ).withValues(alpha: 0.1),
                              )
                            : Text(
                                _selectedAddress,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
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
