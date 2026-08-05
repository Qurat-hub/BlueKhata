import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared/widgets/app_button.dart';
import '../../../../core/shared/widgets/app_card.dart';
import '../../../../core/shared/widgets/state_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/salary_payment.dart';
import '../../domain/entities/staff_member.dart';
import '../providers/staff_providers.dart';
import 'pay_salary_screen.dart';

class StaffDetailScreen extends ConsumerWidget {
  final String staffId;
  const StaffDetailScreen({super.key, required this.staffId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffDetailProvider(staffId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push('/staff/edit', extra: staffId),
          ),
        ],
      ),
      body: staffAsync.when(
        loading: () => const AppLoading(),
        error: (e, st) => AppErrorState(
          message: 'Failed to load staff.\n$e',
          onRetry: () => ref.invalidate(staffDetailProvider(staffId)),
        ),
        data: (staff) => _StaffDetailBody(staff: staff),
      ),
    );
  }
}

class _StaffDetailBody extends ConsumerWidget {
  final StaffMember staff;
  const _StaffDetailBody({required this.staff});

  Map<AttendanceStatus, int> _summarize(List<AttendanceRecord> records) {
    final counts = {for (final s in AttendanceStatus.values) s: 0};
    for (final r in records) {
      counts[r.status] = (counts[r.status] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceMonthProvider(staff.id));
    final salaryAsync = ref.watch(salaryHistoryProvider(staff.id));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(attendanceMonthProvider(staff.id));
        ref.invalidate(salaryHistoryProvider(staff.id));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(staff.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (staff.roleTitle != null)
                        Text(staff.roleTitle!, style: const TextStyle(color: AppColors.textSecondary)),
                      if (staff.phone != null)
                        Text(staff.phone!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Text('Rs. ${staff.monthlySalary.toStringAsFixed(0)}/mo',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('This Month — Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          attendanceAsync.when(
            loading: () => const AppLoading(),
            error: (e, st) => const SizedBox.shrink(),
            data: (records) {
              final counts = _summarize(records);
              return Row(
                children: [
                  Expanded(child: _AttendanceStat(label: 'Present', count: counts[AttendanceStatus.present]!, color: AppColors.success)),
                  Expanded(child: _AttendanceStat(label: 'Absent', count: counts[AttendanceStatus.absent]!, color: AppColors.danger)),
                  Expanded(child: _AttendanceStat(label: 'Leave', count: counts[AttendanceStatus.leave]!, color: AppColors.warning)),
                  Expanded(child: _AttendanceStat(label: 'Half Day', count: counts[AttendanceStatus.halfDay]!, color: AppColors.primary)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Salary History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PaySalaryScreen(staff: staff)),
                  );
                  ref.invalidate(salaryHistoryProvider(staff.id));
                },
                icon: const Icon(Icons.payments_rounded, size: 18),
                label: const Text('Pay Salary'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          salaryAsync.when(
            loading: () => const AppLoading(),
            error: (e, st) => const SizedBox.shrink(),
            data: (payments) {
              if (payments.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.payments_outlined,
                  title: 'No payments recorded',
                  subtitle: 'Use Pay Salary to record this staff member\'s first payment.',
                );
              }
              return Column(children: payments.map((p) => _SalaryTile(payment: p)).toList());
            },
          ),
        ],
      ),
    );
  }
}

class _AttendanceStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _AttendanceStat({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SalaryTile extends StatelessWidget {
  final SalaryPayment payment;
  const _SalaryTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_monthLabel(payment.month)} ${payment.month.year}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (payment.bonus > 0 || payment.advance > 0)
                    Text(
                      [
                        if (payment.bonus > 0) 'Bonus Rs. ${payment.bonus.toStringAsFixed(0)}',
                        if (payment.advance > 0) 'Advance Rs. ${payment.advance.toStringAsFixed(0)}',
                      ].join(' · '),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            Text('Rs. ${payment.netPaid.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
          ],
        ),
      ),
    );
  }

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  String _monthLabel(DateTime d) => _months[d.month - 1];
}
