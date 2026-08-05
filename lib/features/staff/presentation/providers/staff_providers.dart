import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../data/repositories/staff_repository.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/salary_payment.dart';
import '../../domain/entities/staff_member.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) => StaffRepository());

final staffSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final staffListProvider = FutureProvider.autoDispose<List<StaffMember>>((ref) async {
  final business = ref.watch(activeBusinessProvider);
  final query = ref.watch(staffSearchQueryProvider);
  if (business == null) return [];
  return ref.watch(staffRepositoryProvider).fetchStaff(businessId: business.id, query: query);
});

final staffDetailProvider =
    FutureProvider.autoDispose.family<StaffMember, String>((ref, staffId) async {
  return ref.watch(staffRepositoryProvider).fetchStaffMember(staffId);
});

final attendanceDateProvider = StateProvider.autoDispose<DateTime>((ref) => DateTime.now());

final attendanceForDateProvider = FutureProvider.autoDispose<List<AttendanceRecord>>((ref) async {
  final business = ref.watch(activeBusinessProvider);
  if (business == null) return [];
  final date = ref.watch(attendanceDateProvider);
  return ref.watch(staffRepositoryProvider).fetchAttendanceForDate(businessId: business.id, date: date);
});

final attendanceMonthProvider =
    FutureProvider.autoDispose.family<List<AttendanceRecord>, String>((ref, staffId) async {
  return ref.watch(staffRepositoryProvider).fetchAttendanceForMonth(staffId: staffId, month: DateTime.now());
});

final salaryHistoryProvider =
    FutureProvider.autoDispose.family<List<SalaryPayment>, String>((ref, staffId) async {
  return ref.watch(staffRepositoryProvider).fetchSalaryHistory(staffId);
});

class StaffFormController extends StateNotifier<AsyncValue<void>> {
  final StaffRepository _repo;
  StaffFormController(this._repo) : super(const AsyncData(null));

  Future<StaffMember?> create(StaffMember draft) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.createStaff(draft);
      state = const AsyncData(null);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> update(String id, StaffMember changes) async {
    state = const AsyncLoading();
    try {
      await _repo.updateStaff(id, changes);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> deactivate(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.deactivateStaff(id);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final staffFormControllerProvider =
    StateNotifierProvider.autoDispose<StaffFormController, AsyncValue<void>>((ref) {
  return StaffFormController(ref.watch(staffRepositoryProvider));
});

class AttendanceController extends StateNotifier<AsyncValue<void>> {
  final StaffRepository _repo;
  AttendanceController(this._repo) : super(const AsyncData(null));

  Future<bool> mark(AttendanceRecord record) async {
    state = const AsyncLoading();
    try {
      await _repo.markAttendance(record);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final attendanceControllerProvider =
    StateNotifierProvider.autoDispose<AttendanceController, AsyncValue<void>>((ref) {
  return AttendanceController(ref.watch(staffRepositoryProvider));
});

class SalaryController extends StateNotifier<AsyncValue<void>> {
  final StaffRepository _repo;
  SalaryController(this._repo) : super(const AsyncData(null));

  Future<bool> pay(SalaryPayment draft) async {
    state = const AsyncLoading();
    try {
      await _repo.paySalary(draft);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final salaryControllerProvider =
    StateNotifierProvider.autoDispose<SalaryController, AsyncValue<void>>((ref) {
  return SalaryController(ref.watch(staffRepositoryProvider));
});
