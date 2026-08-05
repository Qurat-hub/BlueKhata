import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../data/repositories/cashbook_repository.dart';
import '../../domain/entities/cashbook_entry.dart';

final cashbookRepositoryProvider = Provider<CashbookRepository>((ref) => CashbookRepository());

/// Optional date range filter for the Cash Report screen. `null` means
/// "all time" (used by the main Cash Book list).
class DateRange {
  final DateTime? from;
  final DateTime? to;
  const DateRange({this.from, this.to});
}

final cashReportRangeProvider = StateProvider<DateRange>((ref) {
  final now = DateTime.now();
  return DateRange(from: DateTime(now.year, now.month, 1), to: now);
});

final cashbookEntriesProvider = FutureProvider.autoDispose<List<CashbookEntry>>((ref) async {
  final business = ref.watch(activeBusinessProvider);
  if (business == null) return [];
  return ref.watch(cashbookRepositoryProvider).fetchEntries(businessId: business.id);
});

final cashReportEntriesProvider = FutureProvider.autoDispose<List<CashbookEntry>>((ref) async {
  final business = ref.watch(activeBusinessProvider);
  if (business == null) return [];
  final range = ref.watch(cashReportRangeProvider);
  return ref.watch(cashbookRepositoryProvider).fetchEntries(
        businessId: business.id,
        from: range.from,
        to: range.to,
      );
});

final cashInHandProvider = FutureProvider.autoDispose<double>((ref) async {
  final business = ref.watch(activeBusinessProvider);
  if (business == null) return 0;
  return ref.watch(cashbookRepositoryProvider).cashInHand(business.id);
});

/// One row of the Cash Report table: a calendar day, the net change that
/// day, and the running cash-in-hand total as of the end of that day.
class DailyCashBalance {
  final DateTime date;
  final double dailyBalance;
  final double cashInHand;
  const DailyCashBalance({required this.date, required this.dailyBalance, required this.cashInHand});
}

/// Builds the Cash Report table rows for the selected [cashReportRangeProvider]
/// window, newest day first — matching the DigiKhata Cash Report screenshot
/// (Date / Daily Balance / Cash In Hand columns).
final cashDailyBalancesProvider = FutureProvider.autoDispose<List<DailyCashBalance>>((ref) async {
  final business = ref.watch(activeBusinessProvider);
  if (business == null) return [];
  final range = ref.watch(cashReportRangeProvider);
  final to = range.to ?? DateTime.now();
  final from = range.from ?? DateTime(to.year, to.month, 1);

  final history =
      await ref.watch(cashbookRepositoryProvider).fetchEntriesUpTo(businessId: business.id, to: to);

  final Map<DateTime, double> netByDay = {};
  for (final e in history) {
    final day = DateTime(e.entryDate.year, e.entryDate.month, e.entryDate.day);
    final signedAmount = cashbookEntryIsInflow(e.type) ? e.amount : -e.amount;
    netByDay[day] = (netByDay[day] ?? 0) + signedAmount;
  }

  final fromDay = DateTime(from.year, from.month, from.day);
  final toDay = DateTime(to.year, to.month, to.day);

  // Walk day-by-day across the whole history range so the running total is
  // correct, then keep only the rows inside [fromDay, toDay] for display.
  final firstDay = history.isEmpty
      ? fromDay
      : DateTime(history.first.entryDate.year, history.first.entryDate.month, history.first.entryDate.day);
  final walkStart = firstDay.isBefore(fromDay) ? firstDay : fromDay;

  double running = 0;
  final rows = <DailyCashBalance>[];
  for (var day = walkStart; !day.isAfter(toDay); day = day.add(const Duration(days: 1))) {
    final net = netByDay[day] ?? 0;
    running += net;
    if (!day.isBefore(fromDay)) {
      rows.add(DailyCashBalance(date: day, dailyBalance: net, cashInHand: running));
    }
  }

  return rows.reversed.toList();
});

class CashEntryController extends StateNotifier<AsyncValue<void>> {
  final CashbookRepository _repo;
  CashEntryController(this._repo) : super(const AsyncData(null));

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

final cashEntryControllerProvider =
    StateNotifierProvider.autoDispose<CashEntryController, AsyncValue<void>>((ref) {
  return CashEntryController(ref.watch(cashbookRepositoryProvider));
});
