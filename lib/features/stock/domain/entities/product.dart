/// Mirrors `public.products`.
///
/// [stockQuantity] is intentionally not part of [toUpdateMap] — the
/// `trg_inventory_logs_apply` trigger is the only thing allowed to change
/// it (via an `inventory_logs` insert), exactly like `ledger_entries` owns
/// `customers.current_balance`. Editing a product never touches stock; use
/// [InventoryLog] / `StockRepository.adjustStock` for that.
class Product {
  final String id;
  final String businessId;
  final String? categoryId;
  final String name;
  final String? sku;
  final String? barcode;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final double stockQuantity;
  final double lowStockThreshold;
  final String? supplierId;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.businessId,
    this.categoryId,
    required this.name,
    this.sku,
    this.barcode,
    this.unit = 'pcs',
    this.purchasePrice = 0,
    this.sellingPrice = 0,
    this.stockQuantity = 0,
    this.lowStockThreshold = 5,
    this.supplierId,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => stockQuantity <= lowStockThreshold;

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as String,
        businessId: map['business_id'] as String,
        categoryId: map['category_id'] as String?,
        name: map['name'] as String,
        sku: map['sku'] as String?,
        barcode: map['barcode'] as String?,
        unit: map['unit'] as String? ?? 'pcs',
        purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0,
        sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0,
        stockQuantity: (map['stock_quantity'] as num?)?.toDouble() ?? 0,
        lowStockThreshold: (map['low_stock_threshold'] as num?)?.toDouble() ?? 5,
        supplierId: map['supplier_id'] as String?,
        imageUrl: map['image_url'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  /// [openingStock] seeds the very first `inventory_logs` row (change_type
  /// 'purchase') right after the product is created — see
  /// `StockRepository.createProduct`. It is NOT written to
  /// `products.stock_quantity` directly.
  Map<String, dynamic> toInsertMap() => {
        'business_id': businessId,
        'category_id': categoryId,
        'name': name,
        'sku': sku,
        'barcode': barcode,
        'unit': unit,
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'low_stock_threshold': lowStockThreshold,
        'supplier_id': supplierId,
        'image_url': imageUrl,
      };

  /// Editable fields only — never includes `stock_quantity`.
  Map<String, dynamic> toUpdateMap() => {
        'category_id': categoryId,
        'name': name,
        'sku': sku,
        'barcode': barcode,
        'unit': unit,
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'low_stock_threshold': lowStockThreshold,
        'supplier_id': supplierId,
        'image_url': imageUrl,
      };
}
