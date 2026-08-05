import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../data/repositories/ledger_repository.dart';
import '../../domain/entities/ledger_entry.dart';

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) => LedgerRepository());

final customerLedgerProvider =
    FutureProvider.autoDispose.family<List<LedgerEntry>, String>((ref, customerId) async {
  return ref.watch(ledgerRepositoryProvider).fetchEntries(customerId: customerId);
});

final todaySummaryProvider = FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final business = ref.watch(activeBusinessProvider);
  if (business == null) return {'credit': 0, 'debit': 0};
  return ref.watch(ledgerRepositoryProvider).summaryForBusiness(business.id, DateTime.now());
});

class LedgerEntryController extends StateNotifier<AsyncValue<void>> {
  final LedgerRepository _repo;
  LedgerEntryController(this._repo) : super(const AsyncData(null));

  Future<bool> addEntry(LedgerEntry entry) async {
    state = const AsyncLoading();
    try {
      await _repo.addEntry(entry);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final ledgerEntryControllerProvider =
    StateNotifierProvider.autoDispose<LedgerEntryController, AsyncValue<void>>((ref) {
  return LedgerEntryController(ref.watch(ledgerRepositoryProvider));
});
