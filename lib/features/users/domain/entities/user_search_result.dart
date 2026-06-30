class UserSearchResult {
  const UserSearchResult({
    required this.userId,
    required this.fullName,
    this.ciervoUserCode,
    this.country,
    this.city,
    this.photoUrl,
    this.distanceKm,
    this.canStartConversation = true,
  });

  final String userId;
  final String fullName;
  final String? ciervoUserCode;
  final String? country;
  final String? city;
  final String? photoUrl;
  final double? distanceKm;
  final bool canStartConversation;

  String? get distanceLabel {
    if (distanceKm == null) return null;
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).round()} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  factory UserSearchResult.fromJson(Map<String, dynamic> json) =>
      UserSearchResult(
        userId: '${json['userId'] ?? json['id'] ?? ''}',
        fullName: _name(json),
        ciervoUserCode: _optional(
          json['ciervoUserCode'] ?? json['ciervoId'] ?? json['userCode'],
        ),
        country: _optional(json['country'] ?? json['countryName']),
        city: _optional(json['city']),
        photoUrl: _optional(
          json['photoUrl'] ?? json['profilePhotoUrl'] ?? json['photoMediaId'],
        ),
        distanceKm: _distance(json['distanceKm'] ?? json['DistanceKm']),
        canStartConversation: json['canStartConversation'] != false,
      );

  static String _name(Map<String, dynamic> json) {
    final direct = _optional(json['displayName'] ?? json['fullName'] ?? json['name']);
    if (direct != null) return direct;
    final first = _optional(json['firstName']);
    final last = _optional(json['lastName']);
    return [first, last].whereType<String>().join(' ').trim().isEmpty
        ? 'Usuario'
        : [first, last].whereType<String>().join(' ');
  }

  static double? _distance(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  static String? _optional(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
