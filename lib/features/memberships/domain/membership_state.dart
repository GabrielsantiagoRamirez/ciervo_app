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
  }) =>
      MembershipState(
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
}
