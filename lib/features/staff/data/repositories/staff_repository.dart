import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/salary_payment.dart';
import '../../domain/entities/staff_member.dart';

class StaffRepository {
  final SupabaseClient _client;
  StaffRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  // ---------------------------------------------------------------------
  // Staff
  // ---------------------------------------------------------------------

  Future<List<StaffMember>> fetchStaff({
    required String businessId,
    String? query,
    bool activeOnly = true,
  }) async {
    var builder = _client.from('staff').select().eq('business_id', businessId);
    if (activeOnly) {
      builder = builder.eq('is_active', true);
    }
    if (query != null && query.trim().isNotEmpty) {
      builder = builder.ilike('full_name', '%${query.trim()}%');
    }
    final result = await builder.order('full_name');
    return (result as List).map((m) => StaffMember.fromMap(m)).toList();
  }

  Future<StaffMember> fetchStaffMember(String staffId) async {
    final result = await _client.from('staff').select().eq('id', staffId).single();
    return StaffMember.fromMap(result);
  }

  Future<StaffMember> createStaff(StaffMember draft) async {
    final result = await _client.from('staff').insert(draft.toInsertMap()).select().single();
    return StaffMember.fromMap(result);
  }

  Future<void> updateStaff(String staffId, StaffMember changes) async {
    await _client.from('staff').update(changes.toUpdateMap()).eq('id', staffId);
  }

  /// Removing staff is modeled as deactivation (`is_active = false`) —
  /// there is no `is_deleted` column on this table to soft-delete with.
  Future<void> deactivateStaff(String staffId) async {
    await _client.from('staff').update({'is_active': false}).eq('id', staffId);
  }

  // ---------------------------------------------------------------------
  // Attendance
  // ---------------------------------------------------------------------

  /// All attendance rows for [businessId] on [date] — used by the daily
  /// "mark attendance" screen to show who's already been marked today.
  Future<List<AttendanceRecord>> fetchAttendanceForDate({
    required String businessId,
    required DateTime date,
  }) async {
    final result = await _client
        .from('attendance')
        .select()
        .eq('business_id', businessId)
        .eq('date', dateOnlyString(date));
    return (result as List).map((m) => AttendanceRecord.fromMap(m)).toList();
  }

  Future<List<AttendanceRecord>> fetchAttendanceForMonth({
    required String staffId,
    required DateTime month,
  }) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    final result = await _client
        .from('attendance')
        .select()
        .eq('staff_id', staffId)
        .gte('date', dateOnlyString(start))
        .lte('date', dateOnlyString(end))
        .order('date');
    return (result as List).map((m) => AttendanceRecord.fromMap(m)).toList();
  }

  /// `(staff_id, date)` is unique in the schema — marking the same staff
  /// member twice on the same day updates that day's row instead of
  /// creating a duplicate.
  Future<void> markAttendance(AttendanceRecord record) async {
    await _client.from('attendance').upsert(
          record.toUpsertMap(),
          onConflict: 'staff_id,date',
        );
  }

  // ---------------------------------------------------------------------
  // Salary
  // ---------------------------------------------------------------------

  Future<List<SalaryPayment>> fetchSalaryHistory(String staffId) async {
    final result = await _client
        .from('salary')
        .select()
        .eq('staff_id', staffId)
        .order('month', ascending: false);
    return (result as List).map((m) => SalaryPayment.fromMap(m)).toList();
  }

  Future<SalaryPayment> paySalary(SalaryPayment draft) async {
    final result = await _client.from('salary').insert(draft.toInsertMap()).select().single();
    return SalaryPayment.fromMap(result);
  }
}
