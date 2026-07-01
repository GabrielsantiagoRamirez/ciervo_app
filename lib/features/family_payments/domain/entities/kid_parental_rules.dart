class KidPaymentSource {
  const KidPaymentSource({
    this.cardId,
    this.mode = KidPaymentApprovalMode.autoApproval,
    this.usePrimaryCard = true,
  });

  final String? cardId;
  final KidPaymentApprovalMode mode;
  final bool usePrimaryCard;
}

enum KidPaymentApprovalMode {
  autoApproval,
  manualApproval;

  static KidPaymentApprovalMode fromApi(String? value) {
    final normalized = (value ?? '').toUpperCase().replaceAll('-', '_');
    return switch (normalized) {
      'MANUAL_APPROVAL' => KidPaymentApprovalMode.manualApproval,
      _ => KidPaymentApprovalMode.autoApproval,
    };
  }

  String get apiValue => switch (this) {
        KidPaymentApprovalMode.autoApproval => 'AUTO_APPROVAL',
        KidPaymentApprovalMode.manualApproval => 'MANUAL_APPROVAL',
      };

  String get label => switch (this) {
        KidPaymentApprovalMode.autoApproval => 'Aprobación automática',
        KidPaymentApprovalMode.manualApproval => 'Requiere aprobación',
      };
}

class KidSpendingLimits {
  const KidSpendingLimits({
    this.perPurchaseLimit,
    this.dailyLimit,
    this.monthlyLimit,
  });

  final double? perPurchaseLimit;
  final double? dailyLimit;
  final double? monthlyLimit;
}

class KidMerchantRules {
  const KidMerchantRules({
    this.allowedCategoryIds = const [],
    this.blockedCategoryIds = const [],
    this.allowedBusinessIds = const [],
    this.blockedBusinessIds = const [],
  });

  final List<int> allowedCategoryIds;
  final List<int> blockedCategoryIds;
  final List<String> allowedBusinessIds;
  final List<String> blockedBusinessIds;
}

class KidScheduleRules {
  const KidScheduleRules({
    this.startTime,
    this.endTime,
    this.allowedDays = const [],
  });

  final String? startTime;
  final String? endTime;
  final List<int> allowedDays;
}

class KidAutoPaymentRules {
  const KidAutoPaymentRules({
    this.enabled = false,
    this.maxAutomaticAmount,
  });

  final bool enabled;
  final double? maxAutomaticAmount;
}

class KidApprovalRules {
  const KidApprovalRules({
    this.requireApprovalFromAmount,
    this.alwaysApprovedCategoryIds = const [],
    this.alwaysManualCategoryIds = const [],
  });

  final double? requireApprovalFromAmount;
  final List<int> alwaysApprovedCategoryIds;
  final List<int> alwaysManualCategoryIds;
}

class KidGeofenceRules {
  const KidGeofenceRules({
    this.enabled = false,
    this.latitude,
    this.longitude,
    this.radiusMeters,
  });

  final bool enabled;
  final double? latitude;
  final double? longitude;
  final double? radiusMeters;
}
