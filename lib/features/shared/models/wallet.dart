/// Modèles du domaine `payments` : livre comptable, solde, retraits.
///
/// Contrat vérifié dans `payments/serializers.py` (`LedgerEntrySerializer`,
/// `WalletBalanceSerializer`, `WithdrawalRequestSerializer`).
///
/// **Les montants restent des chaînes.** DRF sérialise ses `DecimalField` en
/// chaîne, et c'est la valeur de référence : l'app la transporte et l'affiche
/// sans jamais faire d'arithmétique métier dessus (règles non négociables n°3 et
/// n°4). `asDouble` n'existe que pour le **formatage** à l'écran, jamais pour
/// recalculer un solde ou un total.
library;

/// Nature d'une écriture comptable (`LedgerEntry.EntryType`).
enum LedgerEntryType {
  paymentIn('payment_in'),
  commission('commission'),
  driverCredit('driver_credit'),
  withdrawal('withdrawal'),
  refund('refund'),
  bonusReferral('bonus_referral'),
  ambassadorCommission('ambassador_commission');

  const LedgerEntryType(this.wire);

  final String wire;

  /// Un type inconnu ne doit pas faire échouer l'affichage de tout l'historique :
  /// le backend peut en ajouter un sans que l'app le connaisse encore. On le
  /// signale par `null` et la ligne s'affiche avec son libellé brut.
  static LedgerEntryType? tryFromWire(String value) {
    for (final t in LedgerEntryType.values) {
      if (t.wire == value) return t;
    }
    return null;
  }
}

/// Une ligne du livre comptable.
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.rawType,
    required this.amount,
    required this.currency,
    this.type,
    this.externalReference,
    this.createdAt,
  });

  final String id;

  /// Valeur littérale du serveur, conservée même si [type] est `null`.
  final String rawType;

  final LedgerEntryType? type;

  /// Montant **signé**, en chaîne : négatif pour un retrait.
  final String amount;

  /// `XAF` en pratique.
  final String currency;

  final String? externalReference;
  final DateTime? createdAt;

  /// Conversion **d'affichage uniquement**. Voir l'avertissement du fichier.
  double? get asDouble => double.tryParse(amount);

  bool get isDebit => amount.startsWith('-');

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    final rawType = json['entry_type'] as String;
    return LedgerEntry(
      id: json['id'].toString(),
      rawType: rawType,
      type: LedgerEntryType.tryFromWire(rawType),
      amount: json['amount'].toString(),
      currency: (json['currency'] as String?) ?? 'XAF',
      externalReference: json['external_reference'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Contenu de `GET /v1/driver/wallet/`.
///
/// Le serveur ajoute `balance` **dans l'enveloppe de pagination**, à côté de
/// `results` — pas dans les lignes. D'où un modèle qui porte les deux.
class DriverWallet {
  const DriverWallet({
    required this.balance,
    required this.entries,
    required this.totalCount,
    this.hasMore = false,
  });

  /// Solde net disponible, en chaîne, calculé par le serveur.
  final String balance;

  final List<LedgerEntry> entries;
  final int totalCount;
  final bool hasMore;

  double? get balanceAsDouble => double.tryParse(balance);
}

/// Contenu de `GET /v1/me/ambassador-code/` (`WalletBalanceSerializer`).
class AmbassadorDashboard {
  const AmbassadorDashboard({
    required this.balance,
    required this.totalEarned,
    required this.usageCount,
    required this.conversionCount,
    required this.recentConversions,
  });

  /// Solde **net** disponible au retrait : diminue après un retrait confirmé.
  final String balance;

  /// Cumul historique des seules commissions : **ne baisse jamais**. Ce n'est
  /// pas un alias de [balance] — les confondre à l'affichage serait une erreur
  /// que le backend signale explicitement.
  final String totalEarned;

  /// Nombre d'utilisations du ou des codes possédés.
  final int usageCount;

  /// Nombre d'utilisations ayant effectivement rapporté une commission.
  final int conversionCount;

  final List<LedgerEntry> recentConversions;

  double? get balanceAsDouble => double.tryParse(balance);
  double? get totalEarnedAsDouble => double.tryParse(totalEarned);

  factory AmbassadorDashboard.fromJson(Map<String, dynamic> json) =>
      AmbassadorDashboard(
        balance: json['balance'].toString(),
        totalEarned: json['total_earned'].toString(),
        usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
        conversionCount: (json['conversion_count'] as num?)?.toInt() ?? 0,
        recentConversions:
            (json['recent_conversions'] as List<dynamic>? ?? const [])
                .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
                .toList(growable: false),
      );
}

/// État d'une demande de retrait (`WithdrawalRequest.Status`).
enum WithdrawalStatus {
  pending('pending'),
  confirmed('confirmed'),
  failed('failed');

  const WithdrawalStatus(this.wire);

  final String wire;

  static WithdrawalStatus fromWire(String value) =>
      WithdrawalStatus.values.firstWhere(
        (s) => s.wire == value,
        orElse: () => throw ArgumentError.value(
          value,
          'status',
          'Statut de retrait inconnu',
        ),
      );
}

/// Réponse d'une demande de retrait.
///
/// Toujours `pending` à ce stade : la confirmation arrive **de façon asynchrone**
/// par le webhook de décaissement côté serveur. L'UI ne doit pas annoncer un
/// virement effectué.
class WithdrawalRequest {
  const WithdrawalRequest({
    required this.id,
    required this.amount,
    required this.status,
    this.recipientPhone,
    this.createdAt,
  });

  final String id;
  final String amount;
  final WithdrawalStatus status;
  final String? recipientPhone;
  final DateTime? createdAt;

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) =>
      WithdrawalRequest(
        id: json['id'].toString(),
        amount: json['amount'].toString(),
        status: WithdrawalStatus.fromWire(json['status'] as String),
        recipientPhone: json['recipient_phone'] as String?,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
      );
}
