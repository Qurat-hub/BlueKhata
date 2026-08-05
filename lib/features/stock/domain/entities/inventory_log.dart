/// Mirrors the `change_type` check constraint on `public.inventory_logs`:
/// ('purchase','sale','adjustment','return').
enum StockChangeType { purchase, sale, adjustment, returnStock }

StockChangeType stockChangeTypeFromString(String value) {
  switch (value) {
    case 'purchase':
      return StockChangeType.purchase;
    case 'sale':
      return StockChangeType.sale;
    case 'adjustment':
      return StockChangeType.adjustment;
    case 'return':
      return StockChangeType.returnStock;
    default:
      throw ArgumentError('Unknown inventory change type: $value');
  }
}

String stockChangeTypeToString(StockChangeType type) {
  switch (type) {
    case StockChangeType.purchase:
      return 'purchase';
    case StockChangeType.sale:
      return 'sale';
    case StockChangeType.adjustment:
      return 'adjustment';
    case StockChangeType.returnStock:
      return 'return';
  }
}

/// One row of `public.inventory_logs`. Inserting one of these is the only
/// way `products.stock_quantity` changes — `trg_inventory_logs_apply`
/// applies [quantityDelta] to the product server-side, race-safely.
class InventoryLog {
  final String id;
  final String businessId;
  final String productId;
  final StockChangeType changeType;
  final double quantityDelta;
  final String? note;
  final DateTime createdAt;
  final String createdBy;

  const InventoryLog({
    required this.id,
    required this.businessId,
    required this.productId,
    required this.changeType,
    required this.quantityDelta,
    this.note,
    required this.createdAt,
    required this.createdBy,
  });

  factory InventoryLog.fromMap(Map<String, dynamic> map) => InventoryLog(
        id: map['id'] as String,
        businessId: map['business_id'] as String,
        productId: map['product_id'] as String,
        changeType: stockChangeTypeFromString(map['change_type'] as String),
        quantityDelta: (map['quantity_delta'] as num).toDouble(),
        note: map['note'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        createdBy: map['created_by'] as String,
      );

  Map<String, dynamic> toInsertMap({required String createdByUserId}) => {
        'business_id': businessId,
        'product_id': productId,
        'change_type': stockChangeTypeToString(changeType),
        'quantity_delta': quantityDelta,
        'note': note,
        'created_by': createdByUserId,
      };
}
