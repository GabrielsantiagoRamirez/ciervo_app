class BusinessCategory {
  const BusinessCategory({
    required this.id,
    required this.code,
    required this.name,
    required this.active,
    this.experienceBucket = 'allday',
  });

  final int id;
  final String code;
  final String name;
  final bool active;

  /// day | night | allday
  final String experienceBucket;
}
