class GuardianVerifyResult {
  const GuardianVerifyResult({
    required this.guardianUserId,
    required this.guardianCiervoCode,
    required this.name,
    required this.countryCode,
    required this.guardianEmail,
  });

  factory GuardianVerifyResult.fromJson(Map<String, dynamic> json) {
    return GuardianVerifyResult(
      guardianUserId: _int(json['guardianUserId']) ?? 0,
      guardianCiervoCode: _string(json, const [
        'guardianCiervoCode',
        'ciervoUserCode',
      ]),
      name: _string(json, const ['name', 'guardianName']),
      countryCode: _string(json, const ['countryCode']),
      guardianEmail: _string(json, const ['guardianEmail', 'email']),
    );
  }

  final int guardianUserId;
  final String guardianCiervoCode;
  final String name;
  final String countryCode;
  final String guardianEmail;

  static String _string(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse('${value ?? ''}');
  }
}

class KidSelfRegisterRequest {
  const KidSelfRegisterRequest({
    required this.guardianUserId,
    required this.guardianEmail,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.documentType,
    required this.documentNumber,
    required this.username,
    required this.pin,
  });

  final int guardianUserId;
  final String guardianEmail;
  final String firstName;
  final String lastName;
  final String birthDate;
  final String documentType;
  final String documentNumber;
  final String username;
  final String pin;

  Map<String, dynamic> toJson() => {
        'guardianUserId': guardianUserId,
        'guardianEmail': guardianEmail.trim(),
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'birthDate': birthDate,
        'documentType': documentType,
        'documentNumber': documentNumber.trim(),
        'username': username.trim(),
        'pin': pin.trim(),
      };
}

class KidVerifyGuardianRequest {
  const KidVerifyGuardianRequest({
    required this.guardianEmail,
    this.guardianCiervoCode,
    this.guardianUserId,
  });

  final String guardianEmail;
  final String? guardianCiervoCode;
  final int? guardianUserId;

  Map<String, dynamic> toJson() => {
        'guardianEmail': guardianEmail.trim(),
        if (guardianCiervoCode != null && guardianCiervoCode!.isNotEmpty)
          'guardianCiervoCode': guardianCiervoCode!.trim(),
        if (guardianUserId != null) 'guardianUserId': guardianUserId,
      };
}
