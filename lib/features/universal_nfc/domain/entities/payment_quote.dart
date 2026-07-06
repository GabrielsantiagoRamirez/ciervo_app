class PaymentQuote {
  const PaymentQuote({
    required this.subtotal,
    required this.fee,
    required this.tax,
    required this.discount,
    required this.cashback,
    required this.total,
    required this.currency,
    required this.type,
    required this.paymentMethod,
    required this.feeApplies,
    this.feePercentage,
    this.availableBalance,
    this.sufficientFunds = true,
  });

  final double subtotal;
  final double fee;
  final double tax;
  final double discount;
  final double cashback;
  final double total;
  final String currency;
  final String type;
  final String paymentMethod;
  final bool feeApplies;
  final double? feePercentage;
  final double? availableBalance;
  final bool sufficientFunds;
}
