class AdminCity {
  const AdminCity({required this.code, required this.name});

  factory AdminCity.fromJson(Map<String, dynamic> json) =>
      AdminCity(code: '${json['code'] ?? ''}', name: '${json['name'] ?? ''}');

  final String code;
  final String name;
}

class ColombiaDepartment {
  const ColombiaDepartment({
    required this.code,
    required this.name,
    required this.cities,
  });

  factory ColombiaDepartment.fromJson(Map<String, dynamic> json) =>
      ColombiaDepartment(
        code: '${json['code'] ?? ''}',
        name: '${json['name'] ?? ''}',
        cities: (json['cities'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => AdminCity.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
      );

  final String code;
  final String name;
  final List<AdminCity> cities;
}

class ChileProvince {
  const ChileProvince({
    required this.code,
    required this.name,
    required this.communes,
  });

  factory ChileProvince.fromJson(Map<String, dynamic> json) => ChileProvince(
    code: '${json['code'] ?? ''}',
    name: '${json['name'] ?? ''}',
    communes: (json['communes'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => AdminCity.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
  );

  final String code;
  final String name;
  final List<AdminCity> communes;
}

class ChileRegion {
  const ChileRegion({
    required this.code,
    required this.name,
    required this.provinces,
  });

  factory ChileRegion.fromJson(Map<String, dynamic> json) => ChileRegion(
    code: '${json['code'] ?? ''}',
    name: '${json['name'] ?? ''}',
    provinces: (json['provinces'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => ChileProvince.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
  );

  final String code;
  final String name;
  final List<ChileProvince> provinces;
}

/// Selección administrativa lista para enviar al backend.
class AdminDivisionSelection {
  const AdminDivisionSelection({
    required this.countryCode,
    required this.cityName,
    this.departmentName,
    this.regionName,
    this.provinceName,
    this.cityCode,
  });

  final String countryCode;
  final String cityName;
  final String? departmentName;
  final String? regionName;
  final String? provinceName;
  final String? cityCode;

  String get displayLabel {
    if (countryCode == 'CL') {
      return [
        regionName,
        provinceName,
        cityName,
      ].where((part) => part != null && part.isNotEmpty).join(' · ');
    }
    return [
      departmentName,
      cityName,
    ].where((part) => part != null && part.isNotEmpty).join(' · ');
  }
}
