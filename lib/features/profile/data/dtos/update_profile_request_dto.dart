class UpdateProfileRequestDto {
  const UpdateProfileRequestDto({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  Map<String, dynamic> toJson() {
    return {
      'name': firstName.trim(),
      'lastname': lastName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
    };
  }
}
