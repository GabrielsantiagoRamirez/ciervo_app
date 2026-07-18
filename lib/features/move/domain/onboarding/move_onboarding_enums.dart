enum MoveIdentityVerificationStatus {
  unknown(-1),
  pending(1),
  verified(2),
  rejected(3);

  const MoveIdentityVerificationStatus(this.value);
  final int value;
  static MoveIdentityVerificationStatus fromValue(Object? value) =>
      values.where((item) => item.value == value).firstOrNull ?? unknown;
}

enum MoveLicenseStatus {
  unknown(-1),
  pending(1),
  approved(2),
  rejected(3),
  expired(4);

  const MoveLicenseStatus(this.value);
  final int value;
  static MoveLicenseStatus fromValue(Object? value) =>
      values.where((item) => item.value == value).firstOrNull ?? unknown;
}

enum MoveOnboardingStageType {
  unknown(-1),
  identity(1),
  license(2),
  vehicleAndOperations(3);

  const MoveOnboardingStageType(this.value);
  final int value;
  static MoveOnboardingStageType fromValue(Object? value) =>
      values.where((item) => item.value == value).firstOrNull ?? unknown;
}

enum MovePayoutMethod {
  unknown(-1),
  wallet(1),
  externalPayout(2);

  const MovePayoutMethod(this.value);
  final int value;
  static MovePayoutMethod fromValue(Object? value) =>
      values.where((item) => item.value == value).firstOrNull ?? unknown;
}

enum MovePhysicalVehicleType {
  unknown(-1),
  car(1),
  motorcycle(2),
  suv(3),
  van(4),
  pickup(5);

  const MovePhysicalVehicleType(this.value);
  final int value;
  static MovePhysicalVehicleType fromValue(Object? value) =>
      values.where((item) => item.value == value).firstOrNull ?? unknown;
}

enum MoveVehicleCategory {
  unknown(-1),
  economy(1),
  standard(2),
  premium(3),
  corporate(4);

  const MoveVehicleCategory(this.value);
  final int value;
  static MoveVehicleCategory fromValue(Object? value) =>
      values.where((item) => item.value == value).firstOrNull ?? unknown;
}

enum MoveVehiclePhotoType {
  unknown(-1),
  front(1),
  rear(2),
  left(3),
  right(4),
  interior(5);

  const MoveVehiclePhotoType(this.value);
  final int value;
  static MoveVehiclePhotoType fromValue(Object? value) =>
      values.where((item) => item.value == value).firstOrNull ?? unknown;
}

enum MoveServiceType {
  unknown(-1),
  economy(1),
  taxi(2),
  executive(3),
  suv(4),
  van(5),
  tourism(6),
  airport(7),
  corporate(8),
  courier(9),
  delivery(10),
  errands(11);

  const MoveServiceType(this.value);
  final int value;
  static MoveServiceType fromValue(Object? value) =>
      values.where((item) => item.value == value).firstOrNull ?? unknown;
}

enum MoveVehicleDocumentType {
  unknown(-1),
  registration(1),
  insurance(2),
  technicalInspection(3),
  taxiAuthorization(4);

  const MoveVehicleDocumentType(this.value);
  final int value;
  static MoveVehicleDocumentType fromValue(Object? value) =>
      values.where((item) => item.value == value).firstOrNull ?? unknown;
}

enum MoveReviewSubjectType {
  unknown(-1),
  identity(1),
  license(2),
  vehicleDocument(3),
  vehicle(4),
  profile(5),
  kidsEligibility(6);

  const MoveReviewSubjectType(this.value);
  final int value;
  static MoveReviewSubjectType fromValue(Object? value) =>
      values.where((item) => item.value == value).firstOrNull ?? unknown;
}

enum MoveDriverStatus {
  unknown('Unknown'),
  draft('Draft'),
  pendingReview('PendingReview'),
  approved('Approved'),
  rejected('Rejected'),
  suspended('Suspended'),
  blocked('Blocked');

  const MoveDriverStatus(this.wireName);
  final String wireName;
  static MoveDriverStatus fromValue(Object? value) {
    if (value is int) {
      return switch (value) {
        0 => draft,
        1 => pendingReview,
        2 => approved,
        3 => rejected,
        4 => suspended,
        5 => blocked,
        _ => unknown,
      };
    }
    final text = value?.toString().trim().toLowerCase();
    return values
            .where((item) => item.wireName.toLowerCase() == text)
            .firstOrNull ??
        unknown;
  }
}

enum MoveDocumentStatus {
  unknown(-1),
  pending(1),
  approved(2),
  rejected(3),
  expired(4);

  const MoveDocumentStatus(this.value);
  final int value;
  static MoveDocumentStatus fromValue(Object? value) =>
      values.where((item) => item.value == value).firstOrNull ?? unknown;
}

enum MoveVehicleStatus {
  unknown(-1),
  pendingReview(1),
  active(2),
  rejected(3),
  inactive(4);

  const MoveVehicleStatus(this.value);
  final int value;
  static MoveVehicleStatus fromValue(Object? value) =>
      values.where((item) => item.value == value).firstOrNull ?? unknown;
}
