class InvoiceItem {
  final String id;
  final String invoiceId;
  final String? productId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double lineTotal;

  const InvoiceItem({
    required this.id,
    required this.invoiceId,
    this.productId,
    required this.description,
    this.quantity = 1,
    this.unitPrice = 0,
    this.lineTotal = 0,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> map) => InvoiceItem(
        id: map['id'] as String,
        invoiceId: map['invoice_id'] as String,
        productId: map['product_id'] as String?,
        description: map['description'] as String,
        quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
        unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0,
        lineTotal: (map['line_total'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toInsertMap({required String invoiceId}) => {
        'invoice_id': invoiceId,
        'product_id': productId,
        'description': description,
        'quantity': quantity,
        'unit_price': unitPrice,
        'line_total': lineTotal,
      };
}
