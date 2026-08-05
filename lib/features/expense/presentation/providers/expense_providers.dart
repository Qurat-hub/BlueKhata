import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../../cashbook/domain/entities/cashbook_entry.dart';
import '../../../cashbook/presentation/providers/cashbook_providers.dart' show DateRange;
import '../../data/repositories/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) => ExpenseRepository());

/// Common expense categories shown as quick-pick chips on the entry screen.
/// The field is free text underneath, so a custom category still works.
const List<String> expenseCategories = [
  'Rent',
  'Salaries',
  'Utilities',
  'Transport',
  'Supplies',
  'Maintenance',
  'Marketing',
  'Other',
];

final expenseReportRangeProvider = StateProvider<DateRange>((ref) {
  final now = DateTime.now();
  return DateRange(from: DateTime(now.year, now.month, 1), to: now);
});

final expenseEntriesProvider = FutureProvider.autoDispose<List<CashbookEntry>>((ref) async {
  final business = ref.watch(activeBusinessProvider);
  if (business == null) return [];
  return ref.watch(expenseRepositoryProvider).fetchEntries(businessId: business.id);
});

final expenseReportEntriesProvider = FutureProvider.autoDispose<List<CashbookEntry>>((ref) async {
  final business = ref.watch(activeBusinessProvider);
  if (business == null) return [];
  final range = ref.watch(expenseReportRangeProvider);
  return ref.watch(expenseRepositoryProvider).fetchEntries(
        businessId: business.id,
        from: range.from,
        to: range.to,
      );
});

final totalExpenseProvider = FutureProvider.autoDispose<double>((ref) async {
  final business = ref.watch(activeBusinessProvider);
  if (business == null) return 0;
  return ref.watch(expenseRepositoryProvider).totalExpense(business.id);
});

/// This-calendar-month total — the headline number on the Expense Book home
/// card (mirrors "Cash In Hand" on Cash Book, but scoped to the current
/// month since an all-time expense total is less actionable than a running
/// cash balance).
final expenseThisMonthProvider = FutureProvider.autoDispose<double>((ref) async {
  final business = ref.watch(activeBusinessProvider);
  if (business == null) return 0;
  final now = DateTime.now();
  final entries = await ref.watch(expenseRepositoryProvider).fetchEntries(
        businessId: business.id,
        from: DateTime(now.year, now.month, 1),
        to: now,
      );
  return entries.fold<double>(0, (sum, e) => sum + e.amount);
});

/// Category → total, for the Expense Report breakdown, over the selected
/// [expenseReportRangeProvider] window.
final expenseByCategoryProvider = FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final entries = await ref.watch(expenseReportEntriesProvider.future);
  final Map<String, double> totals = {};
  for (final e in entries) {
    final key = (e.category == null || e.category!.trim().isEmpty) ? 'Uncategorized' : e.category!;
    totals[key] = (totals[key] ?? 0) + e.amount;
  }
  return totals;
});

class ExpenseEntryController extends StateNotifier<AsyncValue<void>> {
  final ExpenseRepository _repo;
  ExpenseEntryController(this._repo) : super(const AsyncData(null));

  Future<bool> addEntry(CashbookEntry entry) async {
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

final expenseEntryControllerProvider =
    StateNotifierProvider.autoDispose<ExpenseEntryController, AsyncValue<void>>((ref) {
  return ExpenseEntryController(ref.watch(expenseRepositoryProvider));
});
