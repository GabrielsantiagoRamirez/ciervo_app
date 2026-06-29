class CashbackRule {
  const CashbackRule({
    required this.id,
    required this.name,
    required this.description,
    required this.percentage,
    required this.pointsMultiplier,
    required this.membershipTier,
    required this.isActive,
  });

  final String id;
  final String name;
  final String description;
  final double percentage;
  final double pointsMultiplier;
  final String membershipTier;
  final bool isActive;
}
