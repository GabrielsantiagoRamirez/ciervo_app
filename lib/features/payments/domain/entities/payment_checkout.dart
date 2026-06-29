class PaymentCheckout {
  const PaymentCheckout({
    required this.placeName,
    required this.planLabel,
    required this.totalAmount,
    required this.subtotal,
    required this.serviceFee,
  });

  final String placeName;
  final String planLabel;
  final double totalAmount;
  final double subtotal;
  final double serviceFee;
}

enum PaymentSplitOption { self, others }

enum PaymentMethod { upliWallet, card, qr }
