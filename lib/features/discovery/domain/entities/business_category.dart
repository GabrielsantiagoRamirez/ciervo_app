class BusinessCategory {
  const BusinessCategory({
    required this.id,
    required this.code,
    required this.name,
    required this.active,
  });

  final int id;
  final String code;
  final String name;
  final bool active;
}
