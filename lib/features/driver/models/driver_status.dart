/// Statut du compte chauffeur, tel que renvoyé par `GET /v1/driver/status/`.
///
/// Contrat vérifié dans `accounts/serializers.py` (`DriverStatusSerializer`) :
/// tous les champs sont en lecture seule. Le **solde n'y figure pas** — il est
/// dérivé du livre comptable et exposé par `GET /v1/driver/wallet/`.
library;

/// Étapes de validation d'un compte chauffeur (`DriverProfile.Status`).
enum DriverApproval {
  pendingDocuments('pending_documents'),
  pendingReview('pending_review'),
  approved('approved'),
  rejected('rejected'),
  suspended('suspended'),

  /// Valeur que l'app ne connaît pas encore.
  ///
  /// Le backend peut ajouter un statut sans que l'app soit redéployée : lever
  /// ici ferait planter tout l'onglet Courses. On retombe donc sur ce cas, qui
  /// **n'autorise pas** à passer en ligne — c'est le sens sûr de l'erreur : on
  /// ne relâche jamais une garde parce qu'une valeur est inconnue.
  unknown('');

  const DriverApproval(this.wire);

  final String wire;

  static DriverApproval fromWire(String value) {
    for (final s in DriverApproval.values) {
      if (s.wire == value && s != DriverApproval.unknown) return s;
    }
    return DriverApproval.unknown;
  }

  /// Seul un compte approuvé peut passer en ligne et recevoir des courses
  /// (`driver_not_approved` sinon).
  bool get canGoOnline => this == DriverApproval.approved;
}

/// Pièces d'identité obligatoires (`DriverDocument.DocumentType`).
enum DriverDocumentType {
  idCard('id_card'),
  drivingLicence('driving_licence'),
  vehicleRegistration('vehicle_registration');

  const DriverDocumentType(this.wire);

  final String wire;

  static DriverDocumentType fromWire(String value) =>
      DriverDocumentType.values.firstWhere(
        (t) => t.wire == value,
        orElse: () =>
            throw ArgumentError.value(value, 'document_type', 'Type inconnu'),
      );
}

/// État de revue d'une pièce (`DriverDocument.Status`).
enum DriverDocumentState {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const DriverDocumentState(this.wire);

  final String wire;

  static DriverDocumentState fromWire(String value) =>
      DriverDocumentState.values.firstWhere(
        (s) => s.wire == value,
        orElse: () => throw ArgumentError.value(
          value,
          'status',
          'Statut de document inconnu',
        ),
      );
}

/// Une pièce justificative.
///
/// **Aucune URL de fichier n'est exposée** par le serveur (règle backend n°7) :
/// l'accès au document passe par une URL signée générée pour l'administrateur.
/// Le chauffeur ne reçoit que le statut et l'éventuel motif de rejet, de quoi
/// guider une re-soumission.
class DriverDocument {
  const DriverDocument({
    required this.id,
    required this.type,
    required this.state,
    this.rejectionReason,
    this.reviewedAt,
  });

  final String id;
  final DriverDocumentType type;
  final DriverDocumentState state;
  final String? rejectionReason;
  final DateTime? reviewedAt;

  bool get isRejected => state == DriverDocumentState.rejected;

  factory DriverDocument.fromJson(Map<String, dynamic> json) => DriverDocument(
    id: json['id'].toString(),
    type: DriverDocumentType.fromWire(json['document_type'] as String),
    state: DriverDocumentState.fromWire(json['status'] as String),
    rejectionReason: json['rejection_reason'] as String?,
    reviewedAt: json['reviewed_at'] == null
        ? null
        : DateTime.parse(json['reviewed_at'] as String),
  );
}

class DriverStatus {
  const DriverStatus({
    required this.approval,
    required this.rawApproval,
    required this.isOnline,
    required this.documents,
    this.vehicleCode,
    this.vehiclePlate,
    this.ratingAverage,
    this.ratingCount = 0,
    this.lastPositionAt,
  });

  final DriverApproval approval;

  /// Valeur littérale du serveur, conservée même quand [approval] vaut
  /// `unknown` : de quoi afficher quelque chose d'exact et diagnostiquer.
  final String rawApproval;

  /// Le chauffeur se déclare disponible. Piloté par `POST /v1/driver/online/`.
  final bool isOnline;

  final List<DriverDocument> documents;

  /// `vehicle_type` est sérialisé **par son code**, jamais par son id.
  final String? vehicleCode;

  final String? vehiclePlate;

  /// Note moyenne, en chaîne côté serveur (`DecimalField`). Conservée telle
  /// quelle : l'app l'affiche, elle ne calcule rien dessus.
  final String? ratingAverage;

  final int ratingCount;
  final DateTime? lastPositionAt;

  /// Pièces encore à fournir ou à refaire, dans l'ordre attendu.
  List<DriverDocument> get documentsNeedingAction => documents
      .where((d) => d.state != DriverDocumentState.approved)
      .toList(growable: false);

  bool get canGoOnline => approval.canGoOnline;

  factory DriverStatus.fromJson(Map<String, dynamic> json) => DriverStatus(
    rawApproval: json['status'] as String,
    approval: DriverApproval.fromWire(json['status'] as String),
    isOnline: (json['is_online'] as bool?) ?? false,
    vehicleCode: json['vehicle_type'] as String?,
    vehiclePlate: json['vehicle_plate'] as String?,
    ratingAverage: json['rating_average']?.toString(),
    ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
    lastPositionAt: json['last_position_at'] == null
        ? null
        : DateTime.parse(json['last_position_at'] as String),
    documents: (json['documents'] as List<dynamic>? ?? const [])
        .map((e) => DriverDocument.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
}
