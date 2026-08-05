/// Mirrors the `invoice_type` check constraint on `public.invoices`:
/// ('invoice','quotation','receipt','purchase_bill'). Bill Book (this
/// module) only creates 'invoice' rows for now — the other types are
/// reserved for later screens (Quotation, POS receipt, purchase entry)
/// that will read/write the same table.
enum InvoiceType { invoice, quotation, receipt, purchaseBill }

InvoiceType invoiceTypeFromString(String value) {
  switch (value) {
    case 'invoice':
      return InvoiceType.invoice;
    case 'quotation':
      return InvoiceType.quotation;
    case 'receipt':
      return InvoiceType.receipt;
    case 'purchase_bill':
      return InvoiceType.purchaseBill;
    default:
      throw ArgumentError('Unknown invoice type: $value');
  }
}

String invoiceTypeToString(InvoiceType type) {
  switch (type) {
    case InvoiceType.invoice:
      return 'invoice';
    case InvoiceType.quotation:
      return 'quotation';
    case InvoiceType.receipt:
      return 'receipt';
    case InvoiceType.purchaseBill:
      return 'purchase_bill';
  }
}

/// Mirrors the `status` check constraint: ('paid','pending','partial','cancelled').
enum InvoiceStatus { paid, pending, partial, cancelled }

InvoiceStatus invoiceStatusFromString(String value) {
  switch (value) {
    case 'paid':
      return InvoiceStatus.paid;
    case 'pending':
      return InvoiceStatus.pending;
    case 'partial':
      return InvoiceStatus.partial;
    case 'cancelled':
      return InvoiceStatus.cancelled;
    default:
      throw ArgumentError('Unknown invoice status: $value');
  }
}

String invoiceStatusToString(InvoiceStatus status) {
  switch (status) {
    case InvoiceStatus.paid:
      return 'paid';
    case InvoiceStatus.pending:
      return 'pending';
    case InvoiceStatus.partial:
      return 'partial';
    case InvoiceStatus.cancelled:
      return 'cancelled';
  }
}

class Invoice {
  final String id;
  final String businessId;
  final String? customerId;
  final InvoiceType invoiceType;
  final String invoiceNumber;
  final InvoiceStatus status;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final double amountPaid;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Invoice({
    required this.id,
    required this.businessId,
    this.customerId,
    this.invoiceType = InvoiceType.invoice,
    required this.invoiceNumber,
    this.status = InvoiceStatus.pending,
    this.subtotal = 0,
    this.discount = 0,
    this.tax = 0,
    this.total = 0,
    this.amountPaid = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  double get balanceDue => total - amountPaid;

  factory Invoice.fromMap(Map<String, dynamic> map) => Invoice(
        id: map['id'] as String,
        businessId: map['business_id'] as String,
        customerId: map['customer_id'] as String?,
        invoiceType: invoiceTypeFromString(map['invoice_type'] as String? ?? 'invoice'),
        invoiceNumber: map['invoice_number'] as String,
        status: invoiceStatusFromString(map['status'] as String? ?? 'pending'),
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
        discount: (map['discount'] as num?)?.toDouble() ?? 0,
        tax: (map['tax'] as num?)?.toDouble() ?? 0,
        total: (map['total'] as num?)?.toDouble() ?? 0,
        amountPaid: (map['amount_paid'] as num?)?.toDouble() ?? 0,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toInsertMap({required String createdByUserId}) => {
        'business_id': businessId,
        'customer_id': customerId,
        'invoice_type': invoiceTypeToString(invoiceType),
        'invoice_number': invoiceNumber,
        'status': invoiceStatusToString(status),
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'total': total,
        'amount_paid': amountPaid,
        'notes': notes,
        'created_by': createdByUserId,
      };
}
