class ActionConfirmation {
  const ActionConfirmation({
    required this.title,
    required this.confirmationCode,
    this.userCiervoCode,
    this.businessName,
    this.amount,
    this.currency,
    this.status,
    this.date,
    this.time,
    this.publicReceiptUrl,
    this.shareTitle,
    this.shareDescription,
  });

  factory ActionConfirmation.fromJson(
    Map<String, dynamic> json, {
    required String fallbackTitle,
    String? fallbackCode,
  }) {
    return ActionConfirmation(
      title: _string(json, const ['shareTitle', 'title']).isEmpty
          ? fallbackTitle
          : _string(json, const ['shareTitle', 'title']),
      confirmationCode: _string(json, const [
        'confirmationCode',
        'reference',
        'publicCode',
        'code',
        'id',
      ]).isEmpty
          ? fallbackCode ?? ''
          : _string(json, const [
              'confirmationCode',
              'reference',
              'publicCode',
              'code',
              'id',
            ]),
      userCiervoCode: _stringOrNull(json, const [
        'userCiervoCode',
        'userPublicCode',
        'ciervoUserCode',
      ]),
      businessName: _stringOrNull(json, const ['businessName']),
      amount: _num(json['amount'] ?? json['total'] ?? json['totalAmount']),
      currency: _stringOrNull(json, const ['currency', 'currencyCode']),
      status: _stringOrNull(json, const ['status']),
      date: _stringOrNull(json, const ['date', 'bookingDate', 'createdAt']),
      time: _stringOrNull(json, const ['time']),
      publicReceiptUrl: _stringOrNull(json, const ['publicReceiptUrl']),
      shareTitle: _stringOrNull(json, const ['shareTitle']),
      shareDescription: _stringOrNull(json, const ['shareDescription']),
    );
  }

  final String title;
  final String confirmationCode;
  final String? userCiervoCode;
  final String? businessName;
  final num? amount;
  final String? currency;
  final String? status;
  final String? date;
  final String? time;
  final String? publicReceiptUrl;
  final String? shareTitle;
  final String? shareDescription;
}

String _string(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }
  return '';
}

String? _stringOrNull(Map<String, dynamic> json, List<String> keys) {
  final value = _string(json, keys);
  return value.isEmpty ? null : value;
}

num? _num(dynamic value) => value is num ? value : num.tryParse('$value');
