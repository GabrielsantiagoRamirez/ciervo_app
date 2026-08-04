import 'dart:convert';

import 'move_onboarding_enums.dart';

typedef MoveValidationErrors = Map<String, List<String>>;

final _documentTypePattern = RegExp(r'^[A-Za-z0-9_-]+$');
final _termsHashPattern = RegExp(r'^[a-fA-F0-9]{64}$');
final _phonePattern = RegExp(r'^\+?[1-9]\d{7,14}$');
final _last4Pattern = RegExp(r'^\d{4}$');
final _vinPattern = RegExp(r'^[A-HJ-NPR-Za-hj-npr-z0-9]{17}$');
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

void _error(MoveValidationErrors errors, String field, String message) {
  errors.putIfAbsent(field, () => <String>[]).add(message);
}

bool _length(String value, int min, int max) =>
    value.trim().length >= min && value.trim().length <= max;

String _dateOnly(DateTime value) {
  final utc = value.toUtc();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-'
      '${two(utc.day)}';
}

class MoveIdentityOnboardingRequest {
  const MoveIdentityOnboardingRequest({
    required this.firstNames,
    required this.lastNames,
    required this.documentType,
    required this.documentNumber,
    required this.countryCode,
    required this.city,
    required this.email,
    required this.phone,
    required this.birthDate,
    required this.selfieMediaAssetId,
    required this.acceptMoveTerms,
    required this.termsVersion,
    required this.termsContentHash,
  });

  final String firstNames;
  final String lastNames;
  final String documentType;
  final String documentNumber;
  final String countryCode;
  final String city;
  final String? email;
  final String? phone;
  final DateTime birthDate;
  final int selfieMediaAssetId;
  final bool acceptMoveTerms;
  final String termsVersion;
  final String termsContentHash;

  Map<String, dynamic> toJson() => {
    'firstNames': firstNames,
    'lastNames': lastNames,
    'documentType': documentType,
    'documentNumber': documentNumber,
    'countryCode': countryCode,
    'city': city,
    'email': email,
    'phone': phone,
    'birthDate': _dateOnly(birthDate),
    'selfieMediaAssetId': selfieMediaAssetId,
    'acceptMoveTerms': acceptMoveTerms,
    'termsVersion': termsVersion,
    'termsContentHash': termsContentHash,
  };

  MoveValidationErrors validate({DateTime? nowUtc}) {
    final errors = <String, List<String>>{};
    if (!_length(firstNames, 2, 80)) {
      _error(errors, 'firstNames', 'Debe tener entre 2 y 80 caracteres.');
    }
    if (!_length(lastNames, 2, 80)) {
      _error(errors, 'lastNames', 'Debe tener entre 2 y 80 caracteres.');
    }
    if (!_length(documentType, 2, 20) ||
        !_documentTypePattern.hasMatch(documentType)) {
      _error(errors, 'documentType', 'Tipo de documento inválido.');
    }
    if (!_length(documentNumber, 4, 40)) {
      _error(errors, 'documentNumber', 'Debe tener entre 4 y 40 caracteres.');
    }
    if (countryCode != 'CO' && countryCode != 'CL') {
      _error(errors, 'countryCode', 'Solo se admite CO o CL.');
    }
    if (!_length(city, 2, 80)) {
      _error(errors, 'city', 'Debe tener entre 2 y 80 caracteres.');
    }
    final normalizedEmail = email?.trim() ?? '';
    final normalizedPhone = phone?.trim() ?? '';
    if (normalizedEmail.isEmpty && normalizedPhone.isEmpty) {
      _error(errors, 'contact', 'Se requiere email o teléfono.');
    }
    if (normalizedEmail.isNotEmpty &&
        (normalizedEmail.length > 254 ||
            !_emailPattern.hasMatch(normalizedEmail))) {
      _error(errors, 'email', 'Email inválido.');
    }
    if (normalizedPhone.length > 30) {
      _error(errors, 'phone', 'El teléfono supera 30 caracteres.');
    }
    final today = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    var age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    if (age < 18) _error(errors, 'birthDate', 'Debe ser mayor de edad.');
    if (selfieMediaAssetId <= 0) {
      _error(errors, 'selfieMediaAssetId', 'Asset inválido.');
    }
    if (!acceptMoveTerms) {
      _error(errors, 'acceptMoveTerms', 'Debe aceptar los términos.');
    }
    if (!_length(termsVersion, 1, 40)) {
      _error(errors, 'termsVersion', 'Versión de términos inválida.');
    }
    if (!_termsHashPattern.hasMatch(termsContentHash)) {
      _error(errors, 'termsContentHash', 'Hash SHA-256 inválido.');
    }
    return errors;
  }
}

class MoveLicenseOnboardingRequest {
  const MoveLicenseOnboardingRequest({
    required this.number,
    required this.licenseClass,
    required this.expiresAt,
    required this.frontMediaAssetId,
    this.backMediaAssetId,
    this.experienceYears,
  });

  final String number;
  final String licenseClass;
  final DateTime expiresAt;
  final int frontMediaAssetId;
  final int? backMediaAssetId;
  final int? experienceYears;

  Map<String, dynamic> toJson() => {
    'number': number,
    'class': licenseClass,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'frontMediaAssetId': frontMediaAssetId,
    'backMediaAssetId': backMediaAssetId,
    'experienceYears': experienceYears,
  };

  MoveValidationErrors validate({
    required String countryCode,
    DateTime? nowUtc,
  }) {
    final errors = <String, List<String>>{};
    if (!_length(number, 4, 40)) {
      _error(errors, 'number', 'Debe tener entre 4 y 40 caracteres.');
    }
    if (!_length(licenseClass, 1, 20)) {
      _error(errors, 'class', 'Debe tener entre 1 y 20 caracteres.');
    }
    if (!expiresAt.isAfter(nowUtc ?? DateTime.now().toUtc())) {
      _error(errors, 'expiresAt', 'La licencia debe estar vigente.');
    }
    if (frontMediaAssetId <= 0) {
      _error(errors, 'frontMediaAssetId', 'Asset inválido.');
    }
    if (countryCode == 'CO' && (backMediaAssetId ?? 0) <= 0) {
      _error(errors, 'backMediaAssetId', 'CO exige reverso de licencia.');
    }
    if (backMediaAssetId != null && backMediaAssetId! <= 0) {
      _error(errors, 'backMediaAssetId', 'Asset inválido.');
    }
    if (experienceYears != null &&
        (experienceYears! < 0 || experienceYears! > 80)) {
      _error(errors, 'experienceYears', 'Debe estar entre 0 y 80.');
    }
    return errors;
  }
}

class MoveVehicleDocumentInputV2 {
  const MoveVehicleDocumentInputV2({
    required this.type,
    required this.mediaAssetId,
    this.expiresAt,
  });

  final MoveVehicleDocumentType type;
  final int mediaAssetId;
  final DateTime? expiresAt;

  Map<String, dynamic> toJson() => {
    'type': type.value,
    'mediaAssetId': mediaAssetId,
    'expiresAt': expiresAt?.toUtc().toIso8601String(),
  };
}

class MoveVehiclePhotoInput {
  const MoveVehiclePhotoInput({required this.type, required this.mediaAssetId});

  final MoveVehiclePhotoType type;
  final int mediaAssetId;

  Map<String, dynamic> toJson() => {
    'type': type.value,
    'mediaAssetId': mediaAssetId,
  };
}

class MoveVehicleOnboardingRequest {
  const MoveVehicleOnboardingRequest({
    required this.physicalType,
    required this.serviceCategory,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.plate,
    required this.passengerCapacity,
    required this.vin,
    required this.documents,
    required this.photos,
    required this.confirmsFrontShowsReadablePlate,
  });

  final MovePhysicalVehicleType physicalType;
  final MoveVehicleCategory serviceCategory;
  final String brand;
  final String model;
  final int year;
  final String color;
  final String plate;
  final int passengerCapacity;
  final String? vin;
  final List<MoveVehicleDocumentInputV2> documents;
  final List<MoveVehiclePhotoInput> photos;
  /// Obligatorio: foto Front (type=1) muestra frente + placa legible.
  final bool confirmsFrontShowsReadablePlate;

  Map<String, dynamic> toJson() => {
    'physicalType': physicalType.value,
    'serviceCategory': serviceCategory.value,
    'brand': brand,
    'model': model,
    'year': year,
    'color': color,
    'plate': plate,
    'passengerCapacity': passengerCapacity,
    'vin': vin,
    'documents': documents.map((item) => item.toJson()).toList(),
    'photos': photos.map((item) => item.toJson()).toList(),
    'confirmsFrontShowsReadablePlate': confirmsFrontShowsReadablePlate,
  };

  MoveValidationErrors validate({
    required String countryCode,
    Iterable<MoveServiceType> services = const [],
    DateTime? nowUtc,
  }) {
    final errors = <String, List<String>>{};
    final now = nowUtc ?? DateTime.now().toUtc();
    if (physicalType == MovePhysicalVehicleType.unknown) {
      _error(errors, 'physicalType', 'Tipo físico inválido.');
    }
    if (serviceCategory == MoveVehicleCategory.unknown) {
      _error(errors, 'serviceCategory', 'Categoría inválida.');
    }
    if (!_length(brand, 1, 60)) _error(errors, 'brand', 'Marca inválida.');
    if (!_length(model, 1, 60)) _error(errors, 'model', 'Modelo inválido.');
    if (year < 1950 || year > 2100 || year > now.year + 1) {
      _error(errors, 'year', 'Año inválido.');
    }
    if (!_length(color, 1, 40)) _error(errors, 'color', 'Color inválido.');
    if (!_length(plate, 1, 16)) _error(errors, 'plate', 'Placa inválida.');
    if (passengerCapacity < 1 || passengerCapacity > 20) {
      _error(errors, 'passengerCapacity', 'Debe estar entre 1 y 20.');
    }
    if (vin != null && !_vinPattern.hasMatch(vin!)) {
      _error(errors, 'vin', 'VIN inválido.');
    }
    if (!confirmsFrontShowsReadablePlate) {
      _error(
        errors,
        'confirmsFrontShowsReadablePlate',
        'Confirmá que la foto frontal muestra la placa legible.',
      );
    }
    if (documents.length < 2 || documents.length > 4) {
      _error(errors, 'documents', 'Se requieren entre 2 y 4 documentos.');
    }
    final documentTypes = documents.map((item) => item.type).toSet();
    if (documentTypes.length != documents.length ||
        documents.any(
          (item) =>
              item.type == MoveVehicleDocumentType.unknown ||
              item.mediaAssetId <= 0,
        )) {
      _error(errors, 'documents', 'Documentos duplicados o inválidos.');
    }
    for (final required in requiredDocumentTypes(
      countryCode: countryCode,
      vehicleYear: year,
      services: services,
      nowUtc: now,
    )) {
      if (!documentTypes.contains(required)) {
        _error(errors, 'documents', 'Falta ${required.name}.');
      }
    }
    for (final document in documents) {
      final requiresExpiry =
          document.type != MoveVehicleDocumentType.registration;
      if (requiresExpiry &&
          (document.expiresAt == null || !document.expiresAt!.isAfter(now))) {
        _error(
          errors,
          'documents',
          '${document.type.name} debe estar vigente.',
        );
      }
    }
    final photoTypes = photos.map((item) => item.type).toSet();
    final photoAssets = photos.map((item) => item.mediaAssetId).toSet();
    if (photos.length != 5 ||
        photoTypes.length != 5 ||
        photoAssets.length != 5 ||
        photos.any(
          (item) =>
              item.type == MoveVehiclePhotoType.unknown ||
              item.mediaAssetId <= 0,
        )) {
      _error(
        errors,
        'photos',
        'Se requieren cinco tipos y cinco assets diferentes.',
      );
    }
    if (!photos.any((item) => item.type == MoveVehiclePhotoType.front)) {
      _error(
        errors,
        'photos',
        'La foto frontal (frente + placa legible) es obligatoria.',
      );
    }
    return errors;
  }
}

Set<MoveVehicleDocumentType> requiredDocumentTypes({
  required String countryCode,
  required int vehicleYear,
  Iterable<MoveServiceType> services = const [],
  DateTime? nowUtc,
}) {
  final now = nowUtc ?? DateTime.now().toUtc();
  final age = now.year - vehicleYear;
  final result = <MoveVehicleDocumentType>{
    MoveVehicleDocumentType.registration,
    MoveVehicleDocumentType.insurance,
  };
  if ((countryCode == 'CO' && age >= 6) || (countryCode == 'CL' && age >= 1)) {
    result.add(MoveVehicleDocumentType.technicalInspection);
  }
  if (services.contains(MoveServiceType.taxi)) {
    result.add(MoveVehicleDocumentType.taxiAuthorization);
  }
  return result;
}

class MoveOperationsOnboardingRequest {
  const MoveOperationsOnboardingRequest({
    this.payoutMethod = MovePayoutMethod.wallet,
    this.externalProviderToken,
    this.bank,
    this.accountType,
    this.accountLast4,
    required this.emergencyName,
    required this.emergencyPhone,
    required this.emergencyRelationship,
    required this.languages,
    required this.accessible,
    required this.pets,
    required this.airConditioning,
    required this.luggage,
    required this.isAvailableNow,
    this.scheduleJson,
    this.radiusKm,
    this.maxDistanceKm,
    required this.services,
  });

  final MovePayoutMethod payoutMethod;
  final String? externalProviderToken;
  final String? bank;
  final String? accountType;
  final String? accountLast4;
  final String emergencyName;
  final String emergencyPhone;
  final String emergencyRelationship;
  final List<String> languages;
  final bool accessible;
  final bool pets;
  final bool airConditioning;
  final bool luggage;
  final bool isAvailableNow;
  final String? scheduleJson;
  final double? radiusKm;
  final double? maxDistanceKm;
  final List<MoveServiceType> services;

  Map<String, dynamic> toJson() => {
    'payoutMethod': payoutMethod.value,
    'externalProviderToken': externalProviderToken,
    'bank': bank,
    'accountType': accountType,
    'accountLast4': accountLast4,
    'emergencyName': emergencyName,
    'emergencyPhone': emergencyPhone,
    'emergencyRelationship': emergencyRelationship,
    'languages': languages,
    'accessible': accessible,
    'pets': pets,
    'airConditioning': airConditioning,
    'luggage': luggage,
    'isAvailableNow': isAvailableNow,
    'scheduleJson': scheduleJson,
    'radiusKm': radiusKm,
    'maxDistanceKm': maxDistanceKm,
    'services': services.map((item) => item.value).toList(),
  };

  MoveValidationErrors validate() {
    final errors = <String, List<String>>{};
    if (payoutMethod != MovePayoutMethod.wallet &&
        payoutMethod != MovePayoutMethod.externalPayout) {
      _error(errors, 'payoutMethod', 'Método de pago inválido.');
    }
    if ((externalProviderToken?.length ?? 0) > 1000) {
      _error(errors, 'externalProviderToken', 'Token demasiado largo.');
    }
    if (payoutMethod == MovePayoutMethod.externalPayout) {
      if (!_length(externalProviderToken ?? '', 1, 1000)) {
        _error(errors, 'externalProviderToken', 'Token requerido.');
      }
      if (!_length(bank ?? '', 2, 80)) {
        _error(errors, 'bank', 'Banco inválido.');
      }
      if (!_length(accountType ?? '', 2, 40)) {
        _error(errors, 'accountType', 'Tipo de cuenta inválido.');
      }
      if (!_last4Pattern.hasMatch(accountLast4 ?? '')) {
        _error(errors, 'accountLast4', 'Se requieren cuatro dígitos.');
      }
    }
    if (!_length(emergencyName, 2, 120)) {
      _error(errors, 'emergencyName', 'Nombre inválido.');
    }
    if (!_phonePattern.hasMatch(emergencyPhone)) {
      _error(errors, 'emergencyPhone', 'Teléfono inválido.');
    }
    if (!_length(emergencyRelationship, 2, 60)) {
      _error(errors, 'emergencyRelationship', 'Relación inválida.');
    }
    if (languages.length > 10 ||
        languages.any((item) => !_length(item, 1, 30) || item.contains(','))) {
      _error(errors, 'languages', 'Idiomas inválidos.');
    }
    if (scheduleJson != null) {
      if (scheduleJson!.length > 2000) {
        _error(errors, 'scheduleJson', 'Horario demasiado largo.');
      } else {
        try {
          final decoded = jsonDecode(scheduleJson!);
          if (decoded is! Map || _jsonDepth(decoded) > 8) {
            _error(
              errors,
              'scheduleJson',
              'Debe ser un objeto de profundidad 8.',
            );
          }
        } on FormatException {
          _error(errors, 'scheduleJson', 'JSON inválido.');
        }
      }
    }
    if (radiusKm != null && (radiusKm! < 0.1 || radiusKm! > 200)) {
      _error(errors, 'radiusKm', 'Debe estar entre 0.1 y 200.');
    }
    if (maxDistanceKm != null &&
        (maxDistanceKm! < 0.1 || maxDistanceKm! > 1000)) {
      _error(errors, 'maxDistanceKm', 'Debe estar entre 0.1 y 1000.');
    }
    if (radiusKm != null &&
        maxDistanceKm != null &&
        radiusKm! > maxDistanceKm!) {
      _error(errors, 'radiusKm', 'No puede superar la distancia máxima.');
    }
    final validServices = services
        .where((item) => item != MoveServiceType.unknown)
        .toSet();
    if (services.isEmpty ||
        services.length > 11 ||
        validServices.isEmpty ||
        validServices.length != services.length) {
      _error(errors, 'services', 'Servicios inválidos o duplicados.');
    }
    return errors;
  }
}

int _jsonDepth(Object? value) {
  if (value is Map) {
    if (value.isEmpty) return 1;
    return 1 +
        value.values
            .map(_jsonDepth)
            .reduce((left, right) => left > right ? left : right);
  }
  if (value is List) {
    if (value.isEmpty) return 1;
    return 1 +
        value
            .map(_jsonDepth)
            .reduce((left, right) => left > right ? left : right);
  }
  return 0;
}
