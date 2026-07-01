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
    this.imageUrl,
    this.thumbnailUrl,
    this.storagePath,
    this.photoUpdatedAt,
    this.currentLatitude,
    this.currentLongitude,
    this.locationUpdatedAt,
    this.city,
    this.countryCode,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.authProvider,
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
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? storagePath;
  final DateTime? photoUpdatedAt;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? locationUpdatedAt;
  final String? city;
  final String? countryCode;
  final bool emailVerified;
  final bool phoneVerified;
  final String? authProvider;

  UserProfile copyWith({
    String? photoUrl,
    String? imageUrl,
    String? thumbnailUrl,
    String? storagePath,
    DateTime? photoUpdatedAt,
    bool? emailVerified,
    bool? phoneVerified,
    String? countryCode,
    String? ciervoUserCode,
  }) =>
      UserProfile(
        id: id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        ciervoUserCode: ciervoUserCode ?? this.ciervoUserCode,
        identityDocument: identityDocument,
        documentType: documentType,
        photoUrl: photoUrl ?? this.photoUrl,
        imageUrl: imageUrl ?? this.imageUrl,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        storagePath: storagePath ?? this.storagePath,
        photoUpdatedAt: photoUpdatedAt ?? this.photoUpdatedAt,
        currentLatitude: currentLatitude,
        currentLongitude: currentLongitude,
        locationUpdatedAt: locationUpdatedAt,
        city: city,
        countryCode: countryCode ?? this.countryCode,
        emailVerified: emailVerified ?? this.emailVerified,
        phoneVerified: phoneVerified ?? this.phoneVerified,
        authProvider: authProvider,
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
    final ref = displayImageUrl?.trim();
    return ref != null && ref.isNotEmpty;
  }

  String? get displayImageUrl {
    for (final candidate in [imageUrl, photoUrl, thumbnailUrl]) {
      final text = candidate?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  bool get isFirebaseAuth =>
      (authProvider ?? '').toLowerCase().contains('firebase');
}
