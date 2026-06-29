class PaymentConfig {
  const PaymentConfig({
    required this.provider,
    required this.enabled,
    required this.isSandbox,
    required this.publicKey,
    required this.currency,
    this.successUrl,
    this.failureUrl,
    this.pendingUrl,
  });

  final String provider;
  final bool enabled;
  final bool isSandbox;
  final String publicKey;
  final String currency;
  final String? successUrl;
  final String? failureUrl;
  final String? pendingUrl;
}
