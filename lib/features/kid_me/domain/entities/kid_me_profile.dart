class KidGuardianSummary {
  const KidGuardianSummary({
    required this.displayName,
    required this.username,
    required this.ciervoUserCode,
    this.isPrimary = false,
  });

  final String displayName;
  final String username;
  final String ciervoUserCode;
  final bool isPrimary;
}

class KidMeProfile {
  const KidMeProfile({
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

  String get greetingName {
    if (displayName.isNotEmpty) return displayName.split(' ').first;
    if (firstName.isNotEmpty) return firstName;
    if (nickname.isNotEmpty) return nickname;
    return 'amigo';
  }
}
