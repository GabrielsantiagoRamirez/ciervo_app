class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.relationshipType,
    required this.isActive,
    this.birthDate,
    this.age,
    this.documentType,
    this.documentNumber,
    this.medicalNotes,
    this.allowedBusinessesCount = 0,
    this.allowedCategoriesCount = 0,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String relationshipType;
  final bool isActive;
  final DateTime? birthDate;
  final int? age;
  final String? documentType;
  final String? documentNumber;
  final String? medicalNotes;
  final int allowedBusinessesCount;
  final int allowedCategoriesCount;

  String get fullName => '$firstName $lastName'.trim();
}
