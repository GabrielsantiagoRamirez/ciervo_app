class GeoAutocompleteItem {
  const GeoAutocompleteItem({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
    this.latitude,
    this.longitude,
  });

  factory GeoAutocompleteItem.fromJson(Map<String, dynamic> json) {
    double? d(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v');
    }

    String? s(dynamic v) {
      final t = v?.toString().trim();
      if (t == null || t.isEmpty || t.toLowerCase() == 'null') return null;
      return t;
    }

    return GeoAutocompleteItem(
      placeId: s(json['placeId'] ?? json['PlaceId'] ?? json['id']) ?? '',
      description:
          s(json['description'] ?? json['formattedAddress'] ?? json['label']) ??
          '',
      mainText: s(json['mainText'] ?? json['name'] ?? json['title']),
      secondaryText: s(json['secondaryText'] ?? json['subtitle']),
      latitude: d(json['latitude'] ?? json['lat']),
      longitude: d(json['longitude'] ?? json['lng'] ?? json['lon']),
    );
  }

  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;
  final double? latitude;
  final double? longitude;

  String get primaryLabel =>
      (mainText != null && mainText!.isNotEmpty) ? mainText! : description;

  String get secondaryLabel => secondaryText ?? '';

  bool get hasCoordinates => latitude != null && longitude != null;
}

class GeoPlaceDetails {
  const GeoPlaceDetails({
    required this.latitude,
    required this.longitude,
    this.formattedAddress,
    this.name,
    this.placeId,
    this.city,
    this.country,
    this.provider,
    this.mapsUrl,
  });

  factory GeoPlaceDetails.fromJson(Map<String, dynamic> json) {
    double? d(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v');
    }

    String? s(dynamic v) {
      final t = v?.toString().trim();
      if (t == null || t.isEmpty || t.toLowerCase() == 'null') return null;
      return t;
    }

    return GeoPlaceDetails(
      latitude: d(json['latitude'] ?? json['lat']) ?? 0,
      longitude: d(json['longitude'] ?? json['lng'] ?? json['lon']) ?? 0,
      formattedAddress: s(
        json['formattedAddress'] ?? json['description'] ?? json['address'],
      ),
      name: s(json['name'] ?? json['title']),
      placeId: s(json['placeId'] ?? json['PlaceId']),
      city: s(json['city']),
      country: s(json['country']),
      provider: s(json['provider']),
      mapsUrl: s(json['mapsUrl']),
    );
  }

  final double latitude;
  final double longitude;
  final String? formattedAddress;
  final String? name;
  final String? placeId;
  final String? city;
  final String? country;
  final String? provider;
  final String? mapsUrl;

  String get displayAddress =>
      formattedAddress ?? name ?? '$latitude, $longitude';
}
