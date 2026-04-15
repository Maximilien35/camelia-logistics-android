// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../pricing_model.dart';

// class PricingService {
//   final CollectionReference _pricingRef = FirebaseFirestore.instance.collection('pricing');

//   Future<PricingModel> getPricingModel() async {
//     try {
//       final doc = await _pricingRef.doc('current').get();
//       if (doc.exists) {
//         return PricingModel.fromJson(doc.data() as Map<String, dynamic>);
//       } else {
//         // Si pas de données, utiliser les valeurs par défaut
//         final defaultPricing = PricingModel.defaultPricing();
//         await setPricingModel(defaultPricing);
//         return defaultPricing;
//       }
//     } catch (e) {
//       // En cas d'erreur, retourner les valeurs par défaut
//       return PricingModel.defaultPricing();
//     }
//   }

//   Future<void> setPricingModel(PricingModel pricing) async {
//     try {
//       await _pricingRef.doc('current').set(pricing.toJson());
//     } catch (e) {
//       throw Exception("Impossible de sauvegarder les tarifs.");
//     }
//   }

//   Future<double> calculatePrice(String vehicleType, double distanceKm, {double urgencyFee = 0}) async {
//     final pricing = await getPricingModel();
//     return pricing.calculatePrice(vehicleType, distanceKm, urgencyFee: urgencyFee);
//   }
// }