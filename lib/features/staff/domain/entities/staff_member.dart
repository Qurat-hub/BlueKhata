/// Formats a [DateTime] as a plain `YYYY-MM-DD` string for Postgres `date`
/// columns (`staff.joined_at`, `attendance.date`, `salary.month`) — these
/// are not `timestamptz`, so we write them explicitly as dates rather than
/// relying on Postgres to truncate a full ISO datetime string.
String dateOnlyString(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Mirrors `public.staff`. There is no `is_deleted` column here — removing
/// a staff member is modeled as [isActive] = false (matches the schema's
/// own convention), never a hard delete or soft-delete flag that doesn't
/// exist in the table.
class StaffMember {
  final String id;
  final String businessId;
  final String? userId;
  final String fullName;
  final String? phone;
  final String? roleTitle;
  final double monthlySalary;
  final DateTime joinedAt;
  final bool isActive;
  final DateTime createdAt;

  const StaffMember({
    required this.id,
    required this.businessId,
    this.userId,
    required this.fullName,
    this.phone,
    this.roleTitle,
    this.monthlySalary = 0,
    required this.joinedAt,
    this.isActive = true,
    required this.createdAt,
  });

  factory StaffMember.fromMap(Map<String, dynamic> map) => StaffMember(
        id: map['id'] as String,
        businessId: map['business_id'] as String,
        userId: map['user_id'] as String?,
        fullName: map['full_name'] as String,
        phone: map['phone'] as String?,
        roleTitle: map['role_title'] as String?,
        monthlySalary: (map['monthly_salary'] as num?)?.toDouble() ?? 0,
        joinedAt: DateTime.parse(map['joined_at'] as String),
        isActive: map['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toInsertMap() => {
        'business_id': businessId,
        'user_id': userId,
        'full_name': fullName,
        'phone': phone,
        'role_title': roleTitle,
        'monthly_salary': monthlySalary,
        'joined_at': dateOnlyString(joinedAt),
      };

  Map<String, dynamic> toUpdateMap() => {
        'full_name': fullName,
        'phone': phone,
        'role_title': roleTitle,
        'monthly_salary': monthlySalary,
      };
}
