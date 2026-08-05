class ProductCategory {
  final String id;
  final String businessId;
  final String name;
  final DateTime createdAt;

  const ProductCategory({
    required this.id,
    required this.businessId,
    required this.name,
    required this.createdAt,
  });

  factory ProductCategory.fromMap(Map<String, dynamic> map) => ProductCategory(
        id: map['id'] as String,
        businessId: map['business_id'] as String,
        name: map['name'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toInsertMap() => {
        'business_id': businessId,
        'name': name,
      };
}
