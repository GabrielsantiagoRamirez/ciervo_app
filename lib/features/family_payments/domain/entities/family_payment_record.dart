class FamilyPaymentRecord {
  const FamilyPaymentRecord({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.merchantName,
    required this.createdAt,
    this.kidId,
    this.kidName,
    this.fundingSource,
    this.cardAlias,
    this.cardLastFour,
    this.city,
  });

  final String id;
  final double amount;
  final String currency;
  final String status;
  final String merchantName;
  final DateTime? createdAt;
  final String? kidId;
  final String? kidName;
  final String? fundingSource;
  final String? cardAlias;
  final String? cardLastFour;
  final String? city;
}

class FamilyPaymentDetail extends FamilyPaymentRecord {
  const FamilyPaymentDetail({
    required super.id,
    required super.amount,
    required super.currency,
    required super.status,
    required super.merchantName,
    required super.createdAt,
    super.kidId,
    super.kidName,
    super.fundingSource,
    super.cardAlias,
    super.cardLastFour,
    super.city,
    this.usedParentCard = false,
    this.requiresParentApproval = false,
    this.publicReceiptUrl,
  });

  final bool usedParentCard;
  final bool requiresParentApproval;
  final String? publicReceiptUrl;
}
