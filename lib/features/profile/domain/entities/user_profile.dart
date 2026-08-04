class UserProfile {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.ciervoUserCode,
    this.username,
    this.operationalSessionId,
    this.operationalBand,
    this.nightOperationalId,
    this.identityDocument,
    this.documentType,
    this.birthDate,
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
  final String? username;

  /// ID operativo canónico (DIA / NOCHE / 24H) desde `/users/me`.
  final String? operationalSessionId;

  /// Franja: `day` | `night` | `24h`.
  final String? operationalBand;

  /// Compatibilidad: suele igualar [operationalSessionId].
  final String? nightOperationalId;
  final String? identityDocument;
  final String? documentType;
  final DateTime? birthDate;
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

  /// Preferir session canónica; fallback a nightOperationalId.
  String? get displayOperationalSessionId {
    final session = operationalSessionId?.trim();
    if (session != null && session.isNotEmpty) return session;
    final legacy = nightOperationalId?.trim();
    if (legacy != null && legacy.isNotEmpty) return legacy;
    return null;
  }

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
    String? username,
    String? operationalSessionId,
    String? operationalBand,
    String? nightOperationalId,
  }) => UserProfile(
    id: id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    phone: phone,
    ciervoUserCode: ciervoUserCode ?? this.ciervoUserCode,
    username: username ?? this.username,
    operationalSessionId: operationalSessionId ?? this.operationalSessionId,
    operationalBand: operationalBand ?? this.operationalBand,
    nightOperationalId: nightOperationalId ?? this.nightOperationalId,
    identityDocument: identityDocument,
    documentType: documentType,
    birthDate: birthDate,
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
