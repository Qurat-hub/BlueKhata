import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../cashbook/domain/entities/cashbook_entry.dart';

/// Expense Book reads/writes the same `cashbook_entries` table as Cash Book,
/// filtered to `type = 'expense'` — the variant the schema already reserved
/// for this module (see the comment on [CashbookEntryType]). No new table,
/// no new entity: [CashbookEntry] is reused as-is.
class ExpenseRepository {
  final SupabaseClient _client;
  ExpenseRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  Future<List<CashbookEntry>> fetchEntries({
    required String businessId,
    DateTime? from,
    DateTime? to,
    int limit = 200,
  }) async {
    var builder = _client
        .from('cashbook_entries')
        .select()
        .eq('business_id', businessId)
        .eq('is_deleted', false)
        .eq('type', 'expense');

    if (from != null) {
      builder = builder.gte('entry_date', DateTime(from.year, from.month, from.day).toIso8601String());
    }
    if (to != null) {
      builder = builder.lte(
          'entry_date', DateTime(to.year, to.month, to.day, 23, 59, 59).toIso8601String());
    }

    final result = await builder.order('entry_date', ascending: false).limit(limit);
    return (result as List).map((m) => CashbookEntry.fromMap(m)).toList();
  }

  Future<CashbookEntry> addEntry(CashbookEntry entry) async {
    final userId = _client.auth.currentUser!.id;
    final result = await _client
        .from('cashbook_entries')
        .insert(entry.toInsertMap(createdByUserId: userId))
        .select()
        .single();
    return CashbookEntry.fromMap(result);
  }

  Future<void> softDeleteEntry(String entryId) async {
    await _client.from('cashbook_entries').update({
      'is_deleted': true,
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', entryId);
  }

  /// All-time total expense for the business — sum of every non-deleted
  /// `expense` row. Computed here rather than stored, matching how
  /// [CashbookRepository.cashInHand] handles Cash Book's running total.
  Future<double> totalExpense(String businessId) async {
    final rows = await _client
        .from('cashbook_entries')
        .select('amount')
        .eq('business_id', businessId)
        .eq('is_deleted', false)
        .eq('type', 'expense');

    double total = 0;
    for (final row in (rows as List)) {
      total += (row['amount'] as num).toDouble();
    }
    return total;
  }
}
