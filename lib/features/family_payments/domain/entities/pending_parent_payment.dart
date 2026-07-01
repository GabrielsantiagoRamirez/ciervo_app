import 'family_payment_card.dart';

class PendingParentPayment {
  const PendingParentPayment({
    required this.paymentId,
    required this.kidId,
    required this.kidName,
    required this.merchantName,
    required this.amount,
    required this.currency,
    this.kidPhotoUrl,
    this.city,
    this.requestedAt,
    this.fundingSource,
  });

  final String paymentId;
  final String kidId;
  final String kidName;
  final String? kidPhotoUrl;
  final String merchantName;
  final String? city;
  final double amount;
  final String currency;
  final DateTime? requestedAt;
  final String? fundingSource;
}

class AddFamilyCardResult {
  const AddFamilyCardResult({
    required this.card,
    this.requires3ds = false,
    this.verificationUrl,
  });

  final FamilyPaymentCard card;
  final bool requires3ds;
  final String? verificationUrl;
}
