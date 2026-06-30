import '../../domain/entities/user_profile.dart';

class UserProfileDto {
  const UserProfileDto({
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

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    final data = json['value'] ?? json['data'];
    final source = data is Map<String, dynamic> ? data : json;

    return UserProfileDto(
      id: _string(source, const ['id', 'clientId', 'userId']),
      firstName: _string(source, const ['firstName', 'name', 'nombre', 'Name']),
      lastName: _string(source, const [
        'lastName',
        'lastname',
        'Lastname',
        'surname',
        'apellido',
      ]),
      email: _string(source, const ['email', 'mail']),
      phone: _string(source, const ['phone', 'phoneNumber', 'telefono']),
      ciervoUserCode: _optionalString(source, const [
        'ciervoUserCode',
        'CiervoUserCode',
        'ciervoCode',
        'userCode',
        'userPublicCode',
        'userCiervoCode',
      ]),
      identityDocument: _optionalString(source, const [
        'identityDocument',
        'document',
        'documentNumber',
      ]),
      documentType: _optionalString(source, const [
        'documentType',
        'identityDocumentType',
      ]),
      photoUrl: _optionalString(source, const [
        'photoUrl',
        'PhotoUrl',
        'profilePhotoUrl',
        'ProfilePhotoUrl',
        'avatarUrl',
        'photoMediaId',
        'profilePhotoMediaId',
        'avatarMediaId',
        'mediaId',
      ]),
      currentLatitude: _double(source['currentLatitude']),
      currentLongitude: _double(source['currentLongitude']),
      locationUpdatedAt: DateTime.tryParse('${source['locationUpdatedAt'] ?? ''}'),
      city: _optionalString(source, const ['city']),
      countryCode: _optionalString(source, const ['countryCode']),
    );
  }

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

  UserProfile toDomain() {
    return UserProfile(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      ciervoUserCode: ciervoUserCode,
      identityDocument: identityDocument,
      documentType: documentType,
      photoUrl: photoUrl,
      currentLatitude: currentLatitude,
      currentLongitude: currentLongitude,
      locationUpdatedAt: locationUpdatedAt,
      city: city,
      countryCode: countryCode,
    );
  }

  static String _string(Map<String, dynamic> json, List<String> keys) {
    return _optionalString(json, keys) ?? '';
  }

  static String? _optionalString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  static double? _double(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('${value ?? ''}');
}
