import '../../domain/entities/kid_me_profile.dart';

class KidMeProfileDto {
  const KidMeProfileDto({
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.nickname,
    required this.username,
    required this.ciervoUserCode,
    required this.role,
    required this.roleLabel,
    required this.photoUrl,
    required this.familyName,
    required this.countryCode,
    required this.childProfileId,
    required this.guardians,
  });

  factory KidMeProfileDto.fromHomeMap(Map<String, dynamic> json) {
    final wallet = json['wallet'];
    final walletMap = wallet is Map
        ? Map<String, dynamic>.from(wallet)
        : const <String, dynamic>{};
    final names = _resolveNames(json);
    return KidMeProfileDto(
      firstName: names.$1,
      lastName: names.$2,
      displayName: _string(json, const ['displayName', 'nickname', 'name']),
      nickname: _string(json, const ['nickname', 'displayName', 'name']),
      username: _string(json, const ['username', 'kidUsername']),
      ciervoUserCode: _string(json, const [
        'ciervoUserCode',
        'kidsPublicId',
        'publicCode',
      ]),
      role: _string(json, const ['role'], fallback: 'Kid'),
      roleLabel: _string(json, const ['roleLabel'], fallback: 'Menor'),
      photoUrl: _string(json, const ['photoUrl', 'avatarUrl', 'imageUrl']),
      familyName: _string(json, const ['familyName']),
      countryCode: _string(
        json,
        const ['countryCode', 'country'],
        fallback: _string(walletMap, const ['countryCode', 'currencyCountry']),
      ),
      childProfileId: _string(json, const ['childProfileId', 'kidId', 'id']),
      guardians: _guardians(json),
    );
  }

  factory KidMeProfileDto.fromJson(Map<String, dynamic> json) {
    final names = _resolveNames(json);
    return KidMeProfileDto(
      firstName: names.$1,
      lastName: names.$2,
      displayName: _string(json, const ['displayName', 'nickname']),
      nickname: _string(json, const ['nickname', 'displayName']),
      username: _string(json, const ['username', 'kidUsername']),
      ciervoUserCode: _string(json, const [
        'ciervoUserCode',
        'kidsPublicId',
        'publicCode',
      ]),
      role: _string(json, const ['role'], fallback: 'Kid'),
      roleLabel: _string(json, const ['roleLabel'], fallback: 'Menor'),
      photoUrl: _string(json, const ['photoUrl', 'avatarUrl', 'imageUrl']),
      familyName: _string(json, const ['familyName']),
      countryCode: _string(json, const [
        'countryCode',
        'country',
      ], fallback: 'CO'),
      childProfileId: _string(json, const ['childProfileId', 'kidId', 'id']),
      guardians: _guardians(json),
    );
  }

  final String firstName;
  final String lastName;
  final String displayName;
  final String nickname;
  final String username;
  final String ciervoUserCode;
  final String role;
  final String roleLabel;
  final String photoUrl;
  final String familyName;
  final String countryCode;
  final String childProfileId;
  final List<KidGuardianSummary> guardians;

  KidMeProfile toDomain() => KidMeProfile(
    firstName: firstName,
    lastName: lastName,
    displayName: displayName,
    nickname: nickname,
    username: username,
    ciervoUserCode: ciervoUserCode,
    role: role,
    roleLabel: roleLabel,
    photoUrl: photoUrl,
    familyName: familyName,
    countryCode: countryCode,
    childProfileId: childProfileId,
    guardians: guardians,
  );

  static (String, String) _resolveNames(Map<String, dynamic> json) {
    var firstName = _string(json, const ['firstName']);
    var lastName = _string(json, const ['lastName', 'lastname']);
    if (firstName.isEmpty && lastName.isEmpty) {
      final fullName = _string(json, const ['name']);
      if (fullName.isNotEmpty) {
        final parts = fullName.split(RegExp(r'\s+'));
        firstName = parts.first;
        if (parts.length > 1) {
          lastName = parts.sublist(1).join(' ');
        }
      }
    }
    return (firstName, lastName);
  }

  static List<KidGuardianSummary> _guardians(Map<String, dynamic> json) {
    for (final key in const ['guardians', 'tutors', 'familyTutors']) {
      final raw = json[key];
      if (raw is! List) continue;
      return raw.whereType<Map>().map((item) {
        final map = Map<String, dynamic>.from(item);
        return KidGuardianSummary(
          displayName: _string(map, const ['displayName', 'fullName', 'name']),
          username: _string(map, const ['username', 'userName']),
          ciervoUserCode: _string(map, const [
            'ciervoUserCode',
            'publicCode',
            'userId',
          ]),
          isPrimary:
              map['isPrimaryGuardian'] == true || map['isPrimary'] == true,
        );
      }).toList();
    }
    return const [];
  }

  static String _string(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return fallback;
  }
}
