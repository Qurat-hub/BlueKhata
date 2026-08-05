import 'staff_member.dart';

/// Mirrors the `status` check constraint on `public.attendance`:
/// ('present','absent','leave','half_day').
enum AttendanceStatus { present, absent, leave, halfDay }

AttendanceStatus attendanceStatusFromString(String value) {
  switch (value) {
    case 'present':
      return AttendanceStatus.present;
    case 'absent':
      return AttendanceStatus.absent;
    case 'leave':
      return AttendanceStatus.leave;
    case 'half_day':
      return AttendanceStatus.halfDay;
    default:
      throw ArgumentError('Unknown attendance status: $value');
  }
}

String attendanceStatusToString(AttendanceStatus status) {
  switch (status) {
    case AttendanceStatus.present:
      return 'present';
    case AttendanceStatus.absent:
      return 'absent';
    case AttendanceStatus.leave:
      return 'leave';
    case AttendanceStatus.halfDay:
      return 'half_day';
  }
}

/// Mirrors `public.attendance`. `(staff_id, date)` is unique in the schema,
/// so writes always go through an upsert on that pair — see
/// `StaffRepository.markAttendance`.
class AttendanceRecord {
  final String id;
  final String staffId;
  final String businessId;
  final DateTime date;
  final AttendanceStatus status;
  final String? checkIn;
  final String? checkOut;
  final DateTime createdAt;

  const AttendanceRecord({
    required this.id,
    required this.staffId,
    required this.businessId,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    required this.createdAt,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) => AttendanceRecord(
        id: map['id'] as String,
        staffId: map['staff_id'] as String,
        businessId: map['business_id'] as String,
        date: DateTime.parse(map['date'] as String),
        status: attendanceStatusFromString(map['status'] as String),
        checkIn: map['check_in'] as String?,
        checkOut: map['check_out'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toUpsertMap() => {
        'staff_id': staffId,
        'business_id': businessId,
        'date': dateOnlyString(date),
        'status': attendanceStatusToString(status),
        'check_in': checkIn,
        'check_out': checkOut,
      };
}
