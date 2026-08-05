import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/cashbook_entry.dart';

class CashbookRepository {
  final SupabaseClient _client;
  CashbookRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  /// Fetches cash_in/cash_out entries newest-first, optionally bounded to a
  /// date range (used by the Cash Report screen). `cashbook_entries` has no
  /// balance trigger like `ledger_entries` does, so "Cash In Hand" is a
  /// running total computed client-side in [CashbookRepository.dailyBalances]
  /// / the providers layer — nothing here writes a derived balance to the DB.
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
        .inFilter('type', ['cash_in', 'cash_out']);

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

  /// Ascending, all cash_in/cash_out entries up to (and including) [to],
  /// with no lower bound — needed to compute an accurate running
  /// "Cash In Hand" per day on the Cash Report screen (the running total on
  /// any given day depends on everything before it, not just the entries
  /// inside the selected date range).
  Future<List<CashbookEntry>> fetchEntriesUpTo({
    required String businessId,
    required DateTime to,
  }) async {
    final result = await _client
        .from('cashbook_entries')
        .select()
        .eq('business_id', businessId)
        .eq('is_deleted', false)
        .inFilter('type', ['cash_in', 'cash_out'])
        .lte('entry_date', DateTime(to.year, to.month, to.day, 23, 59, 59).toIso8601String())
        .order('entry_date', ascending: true);
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

  /// Current cash-in-hand balance: sum of every non-deleted cash_in/cash_out
  /// entry for the business, all-time. Computed here (not stored) since the
  /// schema intentionally has no running-balance column on this table.
  Future<double> cashInHand(String businessId) async {
    final rows = await _client
        .from('cashbook_entries')
        .select('type, amount')
        .eq('business_id', businessId)
        .eq('is_deleted', false)
        .inFilter('type', ['cash_in', 'cash_out']);

    double balance = 0;
    for (final row in (rows as List)) {
      final amount = (row['amount'] as num).toDouble();
      final type = cashbookEntryTypeFromString(row['type'] as String);
      balance += cashbookEntryIsInflow(type) ? amount : -amount;
    }
    return balance;
  }
}
