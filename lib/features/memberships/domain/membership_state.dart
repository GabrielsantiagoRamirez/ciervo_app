import 'entities/plan_limit.dart';

class MembershipState {
  const MembershipState({
    this.me = const {},
    this.benefits = const {},
    this.limits = const {},
    this.isLoading = false,
    this.isLoaded = false,
    this.error,
  });

  /// Días antes del vencimiento en los que se muestra recordatorio (no mora).
  static const preExpiryReminderDays = {7, 5, 3};

  final Map<String, dynamic> me;
  final Map<String, dynamic> benefits;
  final Map<String, PlanLimit> limits;
  final bool isLoading;
  final bool isLoaded;
  final String? error;

  String? get planCode =>
      _string(me['planCode'] ?? me['code'] ?? benefits['planCode']);

  String get planName {
    final name = _string(me['planName'] ?? me['name'] ?? benefits['planName']);
    if (name != null && name.isNotEmpty) return name;
    final code = planCode;
    if (code != null && code.isNotEmpty) return code.toUpperCase();
    return 'Plan CIERVO';
  }

  String? get planStatus => _string(me['status'] ?? me['membershipStatus']);

  bool get isFreePlan {
    final code = (planCode ?? '').toLowerCase();
    return code.isEmpty || code == 'free';
  }

  DateTime? get startsAt => _date(me['startsAt']);
  DateTime? get endsAt => _date(me['endsAt']);
  DateTime? get graceEndsAt => _date(me['graceEndsAt']);

  int? get remainingDays => _int(me['remainingDays']);
  int? get graceDaysRemaining => _int(me['graceDaysRemaining']);
  int get graceDays => _int(me['graceDays']) ?? 10;

  bool get needsRenewal => me['needsRenewal'] == true;
  bool get isInGrace => me['isInGrace'] == true;
  bool get canCancel => me['canCancel'] == true;
  bool get canRenew => me['canRenew'] == true;

  String? get renewPath => _string(me['renewPath']);
  String? get cancelPath => _string(me['cancelPath']);
  String? get billingPeriod => _string(me['billingPeriod']);
  int? get billingPeriodMonths => _int(me['billingPeriodMonths']);

  /// Clave estable del ciclo actual (para prefs de “no volver a mostrar”).
  String? get renewalCycleKey {
    final end = endsAt?.toUtc().toIso8601String();
    final id = me['membershipId'] ?? me['id'];
    if (end == null && id == null) return null;
    return '${id ?? 'm'}_$end';
  }

  /// ¿Hay que evaluar popup? (hitos 7/5/3 o mora).
  bool get shouldPromptRenewalReminder {
    if (!isLoaded || isFreePlan) return false;
    if (isInGrace) return true;
    final days = remainingDays;
    if (days == null) return false;
    return preExpiryReminderDays.contains(days);
  }

  bool isFeatureEnabled(String key) => limits[key]?.isEnabled == true;

  int? limitValue(String key) => limits[key]?.limitValue;

  bool canUsePrivateChat() {
    if (!isLoaded) return false;
    return limits['private_chat']?.isEnabled == true;
  }

  bool canAddFavorite(int currentCount) {
    if (!isLoaded) return true;
    final item = limits['favorites.max'];
    if (item != null && !item.isEnabled) return false;
    final max = item?.limitValue;
    if (max == null) return true;
    return currentCount < max;
  }

  bool canAddKidProfile(int currentCount) {
    if (!isLoaded) return true;
    final item = limits['kids.profiles.max'];
    if (item != null && !item.isEnabled) return false;
    final max = item?.limitValue;
    if (max == null) return true;
    return currentCount < max;
  }

  MembershipState copyWith({
    Map<String, dynamic>? me,
    Map<String, dynamic>? benefits,
    Map<String, PlanLimit>? limits,
    bool? isLoading,
    bool? isLoaded,
    String? error,
    bool clearError = false,
  }) => MembershipState(
    me: me ?? this.me,
    benefits: benefits ?? this.benefits,
    limits: limits ?? this.limits,
    isLoading: isLoading ?? this.isLoading,
    isLoaded: isLoaded ?? this.isLoaded,
    error: clearError ? null : error ?? this.error,
  );

  static String? _string(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static DateTime? _date(dynamic value) {
    if (value is DateTime) return value.toUtc();
    return DateTime.tryParse('$value')?.toUtc();
  }

  static int? _int(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}
