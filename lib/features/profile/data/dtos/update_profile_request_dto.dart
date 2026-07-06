class UpdateProfileRequestDto {
  const UpdateProfileRequestDto({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.username,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? username;

  Map<String, dynamic> toJson() {
    final normalizedUsername = username?.trim().replaceAll('@', '');
    return {
      'name': firstName.trim(),
      'lastname': lastName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      if (normalizedUsername != null && normalizedUsername.isNotEmpty)
        'username': normalizedUsername,
    };
  }
}
