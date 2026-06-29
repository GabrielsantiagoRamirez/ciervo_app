class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.code,
    required this.name,
    required this.businessCategoryId,
    required this.active,
  });

  final int id;
  final String code;
  final String name;
  final int businessCategoryId;
  final bool active;
}
