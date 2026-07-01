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
    this.photoUrl,
    this.kidsPublicId,
    this.hasKidAccount = false,
    this.kidUsername,
    this.countryCode,
    this.isPrimaryGuardian = false,
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
  final String? photoUrl;
  final String? kidsPublicId;
  final bool hasKidAccount;
  final String? kidUsername;
  final String? countryCode;
  final bool isPrimaryGuardian;

  String get fullName => '$firstName $lastName'.trim();

  bool get hasPhoto {
    final ref = photoUrl?.trim();
    return ref != null && ref.isNotEmpty;
  }

  ChildProfile copyWith({String? photoUrl}) => ChildProfile(
        id: id,
        firstName: firstName,
        lastName: lastName,
        relationshipType: relationshipType,
        isActive: isActive,
        birthDate: birthDate,
        age: age,
        documentType: documentType,
        documentNumber: documentNumber,
        medicalNotes: medicalNotes,
        allowedBusinessesCount: allowedBusinessesCount,
        allowedCategoriesCount: allowedCategoriesCount,
        photoUrl: photoUrl ?? this.photoUrl,
        kidsPublicId: kidsPublicId,
        hasKidAccount: hasKidAccount,
        kidUsername: kidUsername,
        countryCode: countryCode,
        isPrimaryGuardian: isPrimaryGuardian,
      );
}
