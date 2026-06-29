import '../../domain/entities/child_profile.dart';

class ChildProfileDto {
  const ChildProfileDto({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.relationshipType,
    required this.isActive,
    this.birthDate,
    this.age,
    this.documentType,
    this.documentNumber,
    this.medicalNotes,
    this.allowedBusinessesCount = 0,
    this.allowedCategoriesCount = 0,
  });

  factory ChildProfileDto.fromJson(Map<String, dynamic> json) {
    return ChildProfileDto(
      id: _string(json, const ['id', 'childId', 'childProfileId']),
      firstName: _string(json, const ['firstName', 'name']),
      lastName: _string(json, const ['lastName', 'lastname']),
      birthDate: DateTime.tryParse(_string(json, const ['birthDate'])),
      age: _int(json, const ['age']),
      documentType: _optionalString(json, const ['documentType']),
      documentNumber: _optionalString(json, const ['documentNumber']),
      medicalNotes: _optionalString(json, const ['medicalNotes']),
      relationshipType: _string(json, const ['relationshipType']),
      isActive: _bool(json, const ['isActive', 'active']),
      allowedBusinessesCount: _int(json, const ['allowedBusinessesCount']) ?? 0,
      allowedCategoriesCount: _int(json, const ['allowedCategoriesCount']) ?? 0,
    );
  }

  final String id;
  final String firstName;
  final String lastName;
  final String relationshipType;
  final bool isActive;
  final DateTime? birthDate;
  final int? age;
  final String? documentType;
  final String? documentNumber;
  final String? medicalNotes;
  final int allowedBusinessesCount;
  final int allowedCategoriesCount;

  ChildProfile toDomain() => ChildProfile(
    id: id,
    firstName: firstName,
    lastName: lastName,
    relationshipType: relationshipType,
    isActive: isActive,
    birthDate: birthDate,
    age: age,
    documentType: documentType,
    documentNumber: documentNumber,
    medicalNotes: medicalNotes,
    allowedBusinessesCount: allowedBusinessesCount,
    allowedCategoriesCount: allowedCategoriesCount,
  );

  static List<ChildProfileDto> listFrom(dynamic value) {
    final source = value is Map<String, dynamic>
        ? value['value'] ?? value['data'] ?? value
        : value;
    final items = source is List
        ? source
        : source is Map<String, dynamic> && source['items'] is List
        ? source['items'] as List
        : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ChildProfileDto.fromJson)
        .toList();
  }

  static String _string(Map<String, dynamic> json, List<String> keys) =>
      _optionalString(json, keys) ?? '';

  static String? _optionalString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
    return null;
  }

  static int? _int(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  static bool _bool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value != null) return value.toString().toLowerCase() == 'true';
    }
    return true;
  }
}
