import 'package:cloud_functions/cloud_functions.dart';
import 'package:camelia/models/services/error_handler_service.dart';

/// Métadonnées d'un partenaire B2B (jamais le hash de clé API ni le secret webhook,
/// exclus côté Cloud Function `listPartners`).
class PartnerModel {
  final String id;
  final String name;
  final String? contactEmail;
  final String status; // 'active' | 'suspended'
  final String apiKeyPrefix;
  final String? webhookUrl;
  final int monthlyOrderCount;
  final DateTime? createdAt;

  PartnerModel({
    required this.id,
    required this.name,
    required this.status,
    required this.apiKeyPrefix,
    required this.monthlyOrderCount,
    this.contactEmail,
    this.webhookUrl,
    this.createdAt,
  });

  bool get isActive => status == 'active';

  factory PartnerModel.fromMap(Map<dynamic, dynamic> map) {
    return PartnerModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      apiKeyPrefix: map['apiKeyPrefix'] as String? ?? '',
      monthlyOrderCount: (map['monthlyOrderCount'] as num?)?.toInt() ?? 0,
      contactEmail: map['contactEmail'] as String?,
      webhookUrl: map['webhookUrl'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
    );
  }
}

/// Gestion des partenaires B2B (API de commandes) — réservé aux admins.
/// Appelle les Cloud Functions `createPartner`, `rotatePartnerApiKey`,
/// `suspendPartner`, `reactivatePartner`, `listPartners` (functions/partnerAdmin.js).
class PartnerService {
  static const String _region = 'us-central1';
  final ErrorHandlerService _errorHandler = ErrorHandlerService();

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: _region);

  Future<List<PartnerModel>> listPartners() async {
    try {
      final result = await _functions.httpsCallable('listPartners').call();
      final partners = (result.data['partners'] as List<dynamic>? ?? [])
          .map((p) => PartnerModel.fromMap(p as Map<dynamic, dynamic>))
          .toList();
      return partners;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(_errorHandler.handleCloudFunctionsError(e));
    } catch (e) {
      throw Exception(_errorHandler.handleError(e));
    }
  }

  /// Retourne la clé API en clair : à afficher UNE SEULE FOIS à l'admin.
  Future<String> createPartner({
    required String name,
    String? contactEmail,
    String? webhookUrl,
  }) async {
    try {
      final result = await _functions.httpsCallable('createPartner').call({
        'name': name,
        'contactEmail': contactEmail,
        'webhookUrl': webhookUrl,
      });
      return result.data['apiKey'] as String;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(_errorHandler.handleCloudFunctionsError(e));
    } catch (e) {
      throw Exception(_errorHandler.handleError(e));
    }
  }

  /// Retourne la nouvelle clé API en clair : à afficher UNE SEULE FOIS à l'admin.
  Future<String> rotateApiKey(String partnerId) async {
    try {
      final result = await _functions
          .httpsCallable('rotatePartnerApiKey')
          .call({'partnerId': partnerId});
      return result.data['apiKey'] as String;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(_errorHandler.handleCloudFunctionsError(e));
    } catch (e) {
      throw Exception(_errorHandler.handleError(e));
    }
  }

  Future<void> setSuspended(String partnerId, bool suspended) async {
    final functionName = suspended ? 'suspendPartner' : 'reactivatePartner';
    try {
      await _functions.httpsCallable(functionName).call({
        'partnerId': partnerId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(_errorHandler.handleCloudFunctionsError(e));
    } catch (e) {
      throw Exception(_errorHandler.handleError(e));
    }
  }
}
