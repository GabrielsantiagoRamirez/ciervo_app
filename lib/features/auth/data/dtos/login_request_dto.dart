class LoginRequestDto {
  const LoginRequestDto({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() {
    final trimmed = email.trim();
    return {'user': trimmed, 'email': trimmed, 'password': password};
  }
}
