class GeocodeResult {
  const GeocodeResult({
    this.latitude,
    this.longitude,
    this.formattedAddress,
    this.street,
    this.city,
    this.region,
    this.country,
    this.postalCode,
    this.mapsUrl,
    this.provider,
  });

  factory GeocodeResult.fromJson(Map<String, dynamic> json) => GeocodeResult(
        latitude: _double(json['latitude']),
        longitude: _double(json['longitude']),
        formattedAddress: json['formattedAddress']?.toString(),
        street: json['street']?.toString(),
        city: json['city']?.toString(),
        region: json['region']?.toString(),
        country: json['country']?.toString(),
        postalCode: json['postalCode']?.toString(),
        mapsUrl: json['mapsUrl']?.toString(),
        provider: json['provider']?.toString(),
      );

  final double? latitude;
  final double? longitude;
  final String? formattedAddress;
  final String? street;
  final String? city;
  final String? region;
  final String? country;
  final String? postalCode;
  final String? mapsUrl;
  final String? provider;

  String get displayLine =>
      formattedAddress ??
      [street, city, region, country].where((p) => (p ?? '').isNotEmpty).join(', ');
}

double? _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}
