class UserSearchResult {
  const UserSearchResult({
    required this.userId,
    required this.fullName,
    this.country,
    this.city,
    this.photoUrl,
    this.canStartConversation = true,
  });

  final String userId;
  final String fullName;
  final String? country;
  final String? city;
  final String? photoUrl;
  final bool canStartConversation;

  factory UserSearchResult.fromJson(Map<String, dynamic> json) =>
      UserSearchResult(
        userId: '${json['userId'] ?? json['id'] ?? ''}',
        fullName: _name(json),
        country: _optional(json['country'] ?? json['countryName']),
        city: _optional(json['city']),
        photoUrl: _optional(
          json['photoUrl'] ?? json['profilePhotoUrl'] ?? json['photoMediaId'],
        ),
        canStartConversation: json['canStartConversation'] != false,
      );

  static String _name(Map<String, dynamic> json) {
    final direct = _optional(json['fullName'] ?? json['name']);
    if (direct != null) return direct;
    final first = _optional(json['firstName']);
    final last = _optional(json['lastName']);
    return [first, last].whereType<String>().join(' ').trim().isEmpty
        ? 'Usuario'
        : [first, last].whereType<String>().join(' ');
  }

  static String? _optional(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
