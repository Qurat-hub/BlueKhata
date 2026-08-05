import 'staff_member.dart';

/// Mirrors `public.salary`. One row per (staff, month) payment — the
/// schema doesn't enforce uniqueness here (unlike attendance), so paying
/// twice in the same month intentionally creates two rows, e.g. a base
/// payment plus a later bonus top-up.
class SalaryPayment {
  final String id;
  final String staffId;
  final String businessId;
  final DateTime month;
  final double baseAmount;
  final double bonus;
  final double advance;
  final double overtime;
  final double netPaid;
  final DateTime? paidAt;
  final DateTime createdAt;

  const SalaryPayment({
    required this.id,
    required this.staffId,
    required this.businessId,
    required this.month,
    this.baseAmount = 0,
    this.bonus = 0,
    this.advance = 0,
    this.overtime = 0,
    required this.netPaid,
    this.paidAt,
    required this.createdAt,
  });

  factory SalaryPayment.fromMap(Map<String, dynamic> map) => SalaryPayment(
        id: map['id'] as String,
        staffId: map['staff_id'] as String,
        businessId: map['business_id'] as String,
        month: DateTime.parse(map['month'] as String),
        baseAmount: (map['base_amount'] as num?)?.toDouble() ?? 0,
        bonus: (map['bonus'] as num?)?.toDouble() ?? 0,
        advance: (map['advance'] as num?)?.toDouble() ?? 0,
        overtime: (map['overtime'] as num?)?.toDouble() ?? 0,
        netPaid: (map['net_paid'] as num?)?.toDouble() ?? 0,
        paidAt: map['paid_at'] == null ? null : DateTime.parse(map['paid_at'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toInsertMap() => {
        'staff_id': staffId,
        'business_id': businessId,
        'month': dateOnlyString(month),
        'base_amount': baseAmount,
        'bonus': bonus,
        'advance': advance,
        'overtime': overtime,
        'net_paid': netPaid,
        'paid_at': (paidAt ?? DateTime.now()).toIso8601String(),
      };
}
