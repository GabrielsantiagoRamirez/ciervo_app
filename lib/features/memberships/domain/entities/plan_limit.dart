class PlanLimit {
  const PlanLimit({
    required this.isEnabled,
    this.limitValue,
    this.multiplier,
  });

  final bool isEnabled;
  final int? limitValue;
  final double? multiplier;

  factory PlanLimit.fromJson(dynamic json) {
    if (json is! Map) {
      return const PlanLimit(isEnabled: false);
    }
    final map = Map<String, dynamic>.from(json);
    final rawLimit = map['limitValue'] ?? map['limit'];
    int? limitValue;
    if (rawLimit is num) {
      limitValue = rawLimit.toInt();
    } else {
      limitValue = int.tryParse('${rawLimit ?? ''}');
    }
    final rawMultiplier = map['multiplier'];
    double? multiplier;
    if (rawMultiplier is num) {
      multiplier = rawMultiplier.toDouble();
    } else {
      multiplier = double.tryParse('${rawMultiplier ?? ''}');
    }
    return PlanLimit(
      isEnabled: map['isEnabled'] == true ||
          map['isEnabled']?.toString().toLowerCase() == 'true',
      limitValue: limitValue,
      multiplier: multiplier,
    );
  }
}
