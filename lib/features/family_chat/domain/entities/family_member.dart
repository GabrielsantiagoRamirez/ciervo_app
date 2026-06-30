class FamilyMember {
  const FamilyMember({
    required this.userId,
    required this.fullName,
    this.country,
    this.city,
    this.photoUrl,
    this.relationship,
  });

  final String userId;
  final String fullName;
  final String? country;
  final String? city;
  final String? photoUrl;
  final String? relationship;

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    userId: '${json['userId'] ?? json['id'] ?? ''}',
    fullName: _name(json),
    country: _optional(json['country'] ?? json['countryName']),
    city: _optional(json['city']),
    photoUrl: _optional(
      json['photoUrl'] ?? json['profilePhotoUrl'] ?? json['photoMediaId'],
    ),
    relationship: _optional(json['relationship'] ?? json['relationshipType']),
  );

  static String _name(Map<String, dynamic> json) {
    final direct = _optional(json['fullName'] ?? json['name']);
    if (direct != null) return direct;
    final first = _optional(json['firstName']);
    final last = _optional(json['lastName']);
    return [first, last].whereType<String>().join(' ').trim().isEmpty
        ? 'Familiar'
        : [first, last].whereType<String>().join(' ');
  }

  static String? _optional(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
