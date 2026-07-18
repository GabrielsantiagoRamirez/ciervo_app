class WalletRechargeSession {
  const WalletRechargeSession({
    required this.intentId,
    required this.preferenceId,
    required this.checkoutUrl,
    required this.currency,
    required this.countryCode,
    required this.idempotencyKey,
    required this.amount,
    required this.cardId,
  });

  factory WalletRechargeSession.fromJson(Map<String, dynamic> json) {
    return WalletRechargeSession(
      intentId: '${json['intentId'] ?? ''}',
      preferenceId: '${json['preferenceId'] ?? ''}',
      checkoutUrl: '${json['checkoutUrl'] ?? ''}',
      currency: '${json['currency'] ?? ''}',
      countryCode: '${json['countryCode'] ?? ''}',
      idempotencyKey: '${json['idempotencyKey'] ?? ''}',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      cardId: '${json['cardId'] ?? ''}',
    );
  }

  final String intentId;
  final String preferenceId;
  final String checkoutUrl;
  final String currency;
  final String countryCode;
  final String idempotencyKey;
  final double amount;
  final String cardId;

  Map<String, dynamic> toJson() => {
    'intentId': intentId,
    'preferenceId': preferenceId,
    'checkoutUrl': checkoutUrl,
    'currency': currency,
    'countryCode': countryCode,
    'idempotencyKey': idempotencyKey,
    'amount': amount,
    'cardId': cardId,
  };

  bool isCompatibleWith({
    required String currency,
    required String countryCode,
    required double amount,
    required String cardId,
  }) {
    return this.currency == currency.trim().toUpperCase() &&
        this.countryCode == countryCode.trim().toUpperCase() &&
        this.amount == amount &&
        this.cardId == cardId;
  }
}
