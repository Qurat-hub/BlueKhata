import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/ledger_entry.dart';

class LedgerRepository {
  final SupabaseClient _client;
  LedgerRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  /// Fetches entries newest-first. `balance_after` and the customer's
  /// `current_balance` are maintained server-side by the
  /// `trg_ledger_entries_apply_balance` trigger (see supabase/migrations).
  Future<List<LedgerEntry>> fetchEntries({
    required String customerId,
    int limit = 50,
    int offset = 0,
  }) async {
    final result = await _client
        .from('ledger_entries')
        .select()
        .eq('customer_id', customerId)
        .eq('is_deleted', false)
        .order('entry_date', ascending: false)
        .range(offset, offset + limit - 1);
    return (result as List).map((m) => LedgerEntry.fromMap(m)).toList();
  }

  Future<LedgerEntry> addEntry(LedgerEntry entry) async {
    final userId = _client.auth.currentUser!.id;
    final result = await _client
        .from('ledger_entries')
        .insert(entry.toInsertMap(createdByUserId: userId))
        .select()
        .single();
    return LedgerEntry.fromMap(result);
  }

  Future<void> softDeleteEntry(String entryId) async {
    // The reversal trigger (trg_ledger_entries_reverse_on_delete) recomputes
    // the customer's running balance when an entry is soft-deleted.
    await _client.from('ledger_entries').update({
      'is_deleted': true,
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', entryId);
  }

  Future<Map<String, double>> summaryForBusiness(String businessId, DateTime day) async {
    final start = DateTime(day.year, day.month, day.day).toIso8601String();
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59).toIso8601String();

    final rows = await _client
        .from('ledger_entries')
        .select('type, amount')
        .eq('business_id', businessId)
        .eq('is_deleted', false)
        .gte('entry_date', start)
        .lte('entry_date', end);

    double credit = 0, debit = 0;
    for (final row in (rows as List)) {
      final amount = (row['amount'] as num).toDouble();
      if (row['type'] == 'credit') {
        credit += amount;
      } else {
        debit += amount;
      }
    }
    return {'credit': credit, 'debit': debit};
  }
}
