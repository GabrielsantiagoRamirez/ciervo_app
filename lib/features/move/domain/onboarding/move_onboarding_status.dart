import 'move_onboarding_enums.dart';

class MoveOnboardingStage {
  const MoveOnboardingStage({
    required this.stage,
    required this.name,
    required this.complete,
    required this.percentage,
    required this.missing,
    required this.reasons,
  });

  factory MoveOnboardingStage.fromJson(Map<String, dynamic> json) {
    return MoveOnboardingStage(
      stage: MoveOnboardingStageType.fromValue(json['stage']),
      name: json['name']?.toString() ?? '',
      complete: json['complete'] == true,
      percentage: _int(json['percentage']),
      missing: _strings(json['missing']),
      reasons: _strings(json['reasons']),
    );
  }

  final MoveOnboardingStageType stage;
  final String name;
  final bool complete;
  final int percentage;
  final List<String> missing;
  final List<String> reasons;
}

class MoveReviewItem {
  const MoveReviewItem({
    required this.id,
    required this.type,
    required this.status,
    this.expiresAt,
    this.rowVersion,
  });

  factory MoveReviewItem.fromJson(Map<String, dynamic> json) {
    return MoveReviewItem(
      id: _int(json['id']),
      type: MoveVehicleDocumentType.fromValue(json['type']),
      status: MoveDocumentStatus.fromValue(json['status']),
      expiresAt: _date(json['expiresAt']),
      rowVersion: _nullableString(json['rowVersion']),
    );
  }

  final int id;
  final MoveVehicleDocumentType type;
  final MoveDocumentStatus status;
  final DateTime? expiresAt;
  final String? rowVersion;
}

class MoveDriverOnboardingStatus {
  const MoveDriverOnboardingStatus({
    required this.driverId,
    required this.status,
    required this.percentage,
    required this.canSubmit,
    required this.canGoOnline,
    this.maskedDocument,
    this.maskedLicense,
    this.maskedPlate,
    this.vinLast4,
    this.payoutLast4,
    this.currentLicenseId,
    this.vehicleId,
    this.profileRowVersion,
    this.identityRowVersion,
    this.licenseRowVersion,
    this.vehicleRowVersion,
    required this.vehicleDocuments,
    required this.stages,
    required this.missing,
    required this.reasons,
  });

  factory MoveDriverOnboardingStatus.fromJson(Map<String, dynamic> json) {
    return MoveDriverOnboardingStatus(
      driverId: _int(json['driverId']),
      status: MoveDriverStatus.fromValue(json['status']),
      percentage: _int(json['percentage']),
      canSubmit: json['canSubmit'] == true,
      canGoOnline: json['canGoOnline'] == true,
      maskedDocument: _nullableString(json['maskedDocument']),
      maskedLicense: _nullableString(json['maskedLicense']),
      maskedPlate: _nullableString(json['maskedPlate']),
      vinLast4: _nullableString(json['vinLast4']),
      payoutLast4: _nullableString(json['payoutLast4']),
      currentLicenseId: _nullableInt(json['currentLicenseId']),
      vehicleId: _nullableInt(json['vehicleId']),
      profileRowVersion: _nullableString(json['profileRowVersion']),
      identityRowVersion: _nullableString(json['identityRowVersion']),
      licenseRowVersion: _nullableString(json['licenseRowVersion']),
      vehicleRowVersion: _nullableString(json['vehicleRowVersion']),
      vehicleDocuments: _maps(
        json['vehicleDocuments'],
      ).map(MoveReviewItem.fromJson).toList(growable: false),
      stages: _maps(
        json['stages'],
      ).map(MoveOnboardingStage.fromJson).toList(growable: false),
      missing: _strings(json['missing']),
      reasons: _strings(json['reasons']),
    );
  }

  final int driverId;
  final MoveDriverStatus status;
  final int percentage;
  final bool canSubmit;
  final bool canGoOnline;
  final String? maskedDocument;
  final String? maskedLicense;
  final String? maskedPlate;
  final String? vinLast4;
  final String? payoutLast4;
  final int? currentLicenseId;
  final int? vehicleId;
  final String? profileRowVersion;
  final String? identityRowVersion;
  final String? licenseRowVersion;
  final String? vehicleRowVersion;
  final List<MoveReviewItem> vehicleDocuments;
  final List<MoveOnboardingStage> stages;
  final List<String> missing;
  final List<String> reasons;
}

int _int(Object? value) => _nullableInt(value) ?? 0;

int? _nullableInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _date(Object? value) => DateTime.tryParse(value?.toString() ?? '');

List<String> _strings(Object? value) => value is List
    ? List<String>.unmodifiable(value.map((item) => item.toString()))
    : const [];

List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false)
    : const [];
