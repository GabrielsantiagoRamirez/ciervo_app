class UserProfile {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.ciervoUserCode,
    this.identityDocument,
    this.documentType,
    this.photoUrl,
    this.currentLatitude,
    this.currentLongitude,
    this.locationUpdatedAt,
    this.city,
    this.countryCode,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? ciervoUserCode;
  final String? identityDocument;
  final String? documentType;
  final String? photoUrl;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? locationUpdatedAt;
  final String? city;
  final String? countryCode;

  UserProfile copyWith({String? photoUrl}) => UserProfile(
    id: id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    phone: phone,
    ciervoUserCode: ciervoUserCode,
    identityDocument: identityDocument,
    documentType: documentType,
    photoUrl: photoUrl ?? this.photoUrl,
    currentLatitude: currentLatitude,
    currentLongitude: currentLongitude,
    locationUpdatedAt: locationUpdatedAt,
    city: city,
    countryCode: countryCode,
  );

  String get fullName {
    final value = '$firstName $lastName'.trim();
    return value.isEmpty ? email : value;
  }

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    final value = '$first$last'.toUpperCase();
    return value.isEmpty ? 'C' : value;
  }

  bool get hasPhoto {
    final ref = photoUrl?.trim();
    return ref != null && ref.isNotEmpty;
  }
}
