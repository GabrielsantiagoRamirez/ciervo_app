class RegisterRequestDto {
  const RegisterRequestDto({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.identityDocument,
    required this.documentType,
    required this.countryCode,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final String identityDocument;
  final String documentType;
  final String countryCode;

  Map<String, dynamic> toJson() {
    return {
      'name': firstName.trim(),
      'lastname': lastName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
      'identityDocument': identityDocument.trim(),
      'documentType': documentType.trim(),
      'countryCode': countryCode.trim().toUpperCase(),
    };
  }
}
