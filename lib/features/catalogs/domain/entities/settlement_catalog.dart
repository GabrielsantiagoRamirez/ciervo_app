class SettlementCountry {
  const SettlementCountry({
    required this.code,
    required this.name,
    this.currency,
  });

  final String code;
  final String name;
  final String? currency;

  factory SettlementCountry.fromJson(Map<String, dynamic> json) =>
      SettlementCountry(
        code: '${json['code'] ?? json['countryCode'] ?? ''}',
        name: '${json['name'] ?? json['displayName'] ?? json['code'] ?? ''}',
        currency: _optional(json['currency']),
      );

  static String? _optional(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class SettlementMethodOption {
  const SettlementMethodOption({
    required this.code,
    required this.name,
    this.description,
    this.requiredFields = const [],
  });

  final String code;
  final String name;
  final String? description;
  final List<String> requiredFields;

  bool requires(String field) =>
      requiredFields.any((f) => f.toLowerCase() == field.toLowerCase());

  factory SettlementMethodOption.fromJson(Map<String, dynamic> json) {
    final fieldsRaw = json['requiredFields'];
    final fields = fieldsRaw is List
        ? fieldsRaw.map((f) => f.toString()).where((f) => f.isNotEmpty).toList()
        : const <String>[];

    return SettlementMethodOption(
      code: '${json['code'] ?? json['settlementMethod'] ?? ''}',
      name: '${json['name'] ?? json['displayName'] ?? json['label'] ?? ''}',
      description: json['description']?.toString(),
      requiredFields: fields,
    );
  }
}

class BankOption {
  const BankOption({required this.id, required this.name});

  final String id;
  final String name;

  factory BankOption.fromJson(Map<String, dynamic> json) => BankOption(
    id: '${json['id'] ?? json['bankId'] ?? json['code'] ?? json['bankCode'] ?? ''}',
    name: '${json['name'] ?? json['displayName'] ?? json['label'] ?? ''}',
  );
}
