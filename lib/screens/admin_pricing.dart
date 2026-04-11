// import 'package:flutter/material.dart';
// import '../models/pricing_model.dart';
// import '../models/services/pricing_service.dart';

// class AdminPricingScreen extends StatefulWidget {
//   const AdminPricingScreen({super.key});

//   @override
//   State<AdminPricingScreen> createState() => _AdminPricingScreenState();
// }

// class _AdminPricingScreenState extends State<AdminPricingScreen> {
//   final PricingService _pricingService = PricingService();
//   PricingModel? _pricingModel;
//   bool _isLoading = true;
//   bool _isSaving = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadPricing();
//   }

//   Future<void> _loadPricing() async {
//     try {
//       final pricing = await _pricingService.getPricingModel();
//       setState(() {
//         _pricingModel = pricing;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Erreur lors du chargement des tarifs: $e')),
//         );
//       }
//     }
//   }

//   Future<void> _savePricing() async {
//     if (_pricingModel == null) return;

//     setState(() => _isSaving = true);
//     try {
//       await _pricingService.setPricingModel(_pricingModel!);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Tarifs sauvegardés avec succès')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
//         );
//       }
//     } finally {
//       setState(() => _isSaving = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {

//     if (_isLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_pricingModel == null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Gestion des Tarifs')),
//         body: const Center(child: Text('Erreur de chargement')),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Gestion des Tarifs'),
//         actions: [
//           if (_isSaving)
//             const Padding(
//               padding: EdgeInsets.all(16),
//               child: SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               ),
//             )
//           else
//             IconButton(
//               onPressed: _savePricing,
//               icon: const Icon(Icons.save),
//             ),
//         ],
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: _pricingModel!.vehiclePricings.entries.map((entry) {
//           final vehicleType = entry.key;
//           final pricing = entry.value;

//           return Card(
//             margin: const EdgeInsets.only(bottom: 16),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     vehicleType,
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   if (pricing.isQuoteOnly)
//                     const Text(
//                       'Mode Devis Uniquement',
//                       style: TextStyle(
//                         color: Colors.orange,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     )
//                   else ...[
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextFormField(
//                             initialValue: pricing.basePrice.toString(),
//                             decoration: const InputDecoration(
//                               labelText: 'Prix de Base (FCFA)',
//                               border: OutlineInputBorder(),
//                             ),
//                             keyboardType: TextInputType.number,
//                             onChanged: (value) {
//                               final newPrice = double.tryParse(value) ?? pricing.basePrice;
//                               setState(() {
//                                 _pricingModel!.vehiclePricings[vehicleType] =
//                                     VehiclePricing(
//                                   basePrice: newPrice,
//                                   pricePerKm: pricing.pricePerKm,
//                                   isQuoteOnly: pricing.isQuoteOnly,
//                                 );
//                               });
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: TextFormField(
//                             initialValue: pricing.pricePerKm.toString(),
//                             decoration: const InputDecoration(
//                               labelText: 'Prix par KM (FCFA)',
//                               border: OutlineInputBorder(),
//                             ),
//                             keyboardType: TextInputType.number,
//                             onChanged: (value) {
//                               final newPrice = double.tryParse(value) ?? pricing.pricePerKm;
//                               setState(() {
//                                 _pricingModel!.vehiclePricings[vehicleType] =
//                                     VehiclePricing(
//                                   basePrice: pricing.basePrice,
//                                   pricePerKm: newPrice,
//                                   isQuoteOnly: pricing.isQuoteOnly,
//                                 );
//                               });
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
// }