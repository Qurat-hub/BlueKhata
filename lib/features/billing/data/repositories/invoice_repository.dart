import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';

class InvoiceWithItems {
  final Invoice invoice;
  final List<InvoiceItem> items;
  const InvoiceWithItems({required this.invoice, required this.items});
}

class InvoiceRepository {
  final SupabaseClient _client;
  InvoiceRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  Future<List<Invoice>> fetchInvoices({
    required String businessId,
    String? query,
    InvoiceStatus? status,
  }) async {
    var builder = _client
        .from('invoices')
        .select()
        .eq('business_id', businessId)
        .eq('is_deleted', false)
        .eq('invoice_type', 'invoice');

    if (status != null) {
      builder = builder.eq('status', invoiceStatusToString(status));
    }
    if (query != null && query.trim().isNotEmpty) {
      builder = builder.ilike('invoice_number', '%${query.trim()}%');
    }

    final result = await builder.order('created_at', ascending: false);
    return (result as List).map((m) => Invoice.fromMap(m)).toList();
  }

  Future<InvoiceWithItems> fetchInvoiceWithItems(String invoiceId) async {
    final invoiceRow = await _client.from('invoices').select().eq('id', invoiceId).single();
    final itemRows =
        await _client.from('invoice_items').select().eq('invoice_id', invoiceId).order('description');
    return InvoiceWithItems(
      invoice: Invoice.fromMap(invoiceRow),
      items: (itemRows as List).map((m) => InvoiceItem.fromMap(m)).toList(),
    );
  }

  /// Next invoice number for the business, formatted `INV-0001`,
  /// `INV-0002`, ... Counts existing 'invoice'-type rows rather than
  /// requiring a DB sequence, so no schema change is needed.
  Future<String> nextInvoiceNumber(String businessId) async {
    final result = await _client
        .from('invoices')
        .select('id')
        .eq('business_id', businessId)
        .eq('invoice_type', 'invoice')
        .count(CountOption.exact);
    final next = result.count + 1;
    return 'INV-${next.toString().padLeft(4, '0')}';
  }

  /// Creates the invoice, its line items, and — for every item tied to a
  /// product — a matching `inventory_logs` 'sale' entry with a negative
  /// quantity_delta so `products.stock_quantity` is decremented by the
  /// same trigger the Stock module already relies on
  /// (`trg_inventory_logs_apply`). Freeform line items (no `product_id`)
  /// don't touch stock at all.
  ///
  /// These are sequential inserts, not a single DB transaction — matching
  /// how `CashbookRepository`/`StockRepository` already do multi-step
  /// writes in this codebase, since introducing an RPC/stored procedure
  /// would be a schema change outside this pass's scope.
  Future<Invoice> createInvoice(Invoice draft, List<InvoiceItem> items) async {
    final userId = _client.auth.currentUser!.id;

    final invoiceRow = await _client
        .from('invoices')
        .insert(draft.toInsertMap(createdByUserId: userId))
        .select()
        .single();
    final invoice = Invoice.fromMap(invoiceRow);

    if (items.isNotEmpty) {
      await _client
          .from('invoice_items')
          .insert(items.map((i) => i.toInsertMap(invoiceId: invoice.id)).toList());
    }

    for (final item in items) {
      if (item.productId == null || item.quantity <= 0) continue;
      await _client.from('inventory_logs').insert({
        'business_id': draft.businessId,
        'product_id': item.productId,
        'change_type': 'sale',
        'quantity_delta': -item.quantity,
        'note': 'Invoice ${invoice.invoiceNumber}',
        'created_by': userId,
      });
    }

    return invoice;
  }

  Future<void> recordPayment(String invoiceId, {required double amountPaid, required InvoiceStatus status}) async {
    await _client.from('invoices').update({
      'amount_paid': amountPaid,
      'status': invoiceStatusToString(status),
    }).eq('id', invoiceId);
  }

  Future<void> softDeleteInvoice(String invoiceId) async {
    await _client.from('invoices').update({'is_deleted': true}).eq('id', invoiceId);
  }
}
