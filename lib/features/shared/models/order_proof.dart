/// Preuve de course visible du client — liste `proofs` de
/// `GET /v1/orders/{id}/` (`orders.serializers.OrderProofSerializer`,
/// § 7.3.11, T6.5).
///
/// **Quatre clés**, en ordre chronologique, `[]` tant que rien n'a été
/// capturé. La position GPS de la capture n'en fait pas partie.
///
/// ## Les URL de photo sont signées et expirent
///
/// `photo_url` est recalculée **à chaque lecture** et ne vaut que
/// `ORDER_MEDIA_URL_TTL_SECONDS` (5 minutes par défaut). Conséquences, qui
/// sont des règles et pas des précautions :
/// - on ne conserve jamais une URL au-delà de l'écran qui l'affiche : ni
///   cache disque, ni état persistant, ni partage ;
/// - deux lectures rendent deux URL différentes, donc **la position dans la
///   liste identifie une photo**, jamais la chaîne ;
/// - une image qui ne charge plus se corrige en relisant la commande.
///
/// `photo_url` peut valoir `null` : preuve antérieure à la bascule en privé,
/// ou média purgé à six mois (§ 2.19). La livraison reste constatée — seule
/// l'image a disparu, définitivement.
library;

enum ProofType {
  pickup('pickup'),
  delivery('delivery'),

  /// Type ajouté côté serveur après ce build.
  unknown('');

  const ProofType(this.wire);

  final String wire;

  static ProofType fromWire(String value) => ProofType.values.firstWhere(
    (t) => t.wire == value && t != unknown,
    orElse: () => unknown,
  );
}

class OrderProof {
  const OrderProof({
    required this.type,
    required this.rawType,
    required this.recipientSignatureName,
    this.photoUrl,
    this.capturedAt,
  });

  final ProofType type;

  /// Valeur brute, conservée pour un type que l'app ne connaît pas.
  final String rawType;

  /// URL signée à courte durée de vie — voir l'en-tête de ce fichier.
  /// `null` quand la photo n'est pas (ou plus) servie.
  final String? photoUrl;

  /// Chaîne **vide** si aucun nom n'a été saisi, jamais `null` côté serveur.
  final String recipientSignatureName;

  final DateTime? capturedAt;

  bool get hasPhoto => (photoUrl ?? '').isNotEmpty;
  bool get hasSignatureName => recipientSignatureName.trim().isNotEmpty;

  factory OrderProof.fromJson(Map<String, dynamic> json) {
    final raw = (json['proof_type'] as String?) ?? '';
    final url = (json['photo_url'] as String?)?.trim();
    return OrderProof(
      type: ProofType.fromWire(raw),
      rawType: raw,
      photoUrl: (url == null || url.isEmpty) ? null : url,
      recipientSignatureName:
          (json['recipient_signature_name'] as String?) ?? '',
      capturedAt: json['captured_at'] is String
          ? DateTime.tryParse(json['captured_at'] as String)
          : null,
    );
  }
}
