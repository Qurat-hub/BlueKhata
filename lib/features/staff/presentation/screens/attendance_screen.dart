import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/shared/widgets/app_card.dart';
import '../../../../core/shared/widgets/state_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/staff_member.dart';
import '../providers/staff_providers.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  String _statusLabel(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.leave:
        return 'Leave';
      case AttendanceStatus.halfDay:
        return 'Half Day';
    }
  }

  Color _statusColor(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.danger;
      case AttendanceStatus.leave:
        return AppColors.warning;
      case AttendanceStatus.halfDay:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(attendanceDateProvider);
    final staffAsync = ref.watch(staffListProvider);
    final attendanceAsync = ref.watch(attendanceForDateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  ref.read(attendanceDateProvider.notifier).state = picked;
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${date.day}/${date.month}/${date.year}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: staffAsync.when(
              loading: () => const AppLoading(),
              error: (e, st) => AppErrorState(
                message: 'Failed to load staff.\n$e',
                onRetry: () => ref.invalidate(staffListProvider),
              ),
              data: (staffList) {
                if (staffList.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.groups_2_outlined,
                    title: 'No staff to mark',
                    subtitle: 'Add staff members first from the Staff Book.',
                  );
                }
                return attendanceAsync.when(
                  loading: () => const AppLoading(),
                  error: (e, st) => AppErrorState(
                    message: 'Failed to load attendance.\n$e',
                    onRetry: () => ref.invalidate(attendanceForDateProvider),
                  ),
                  data: (records) {
                    final byStaffId = {for (final r in records) r.staffId: r};
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: staffList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _AttendanceTile(
                        staff: staffList[i],
                        existing: byStaffId[staffList[i].id],
                        date: date,
                        statusLabel: _statusLabel,
                        statusColor: _statusColor,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceTile extends ConsumerWidget {
  final StaffMember staff;
  final AttendanceRecord? existing;
  final DateTime date;
  final String Function(AttendanceStatus) statusLabel;
  final Color Function(AttendanceStatus) statusColor;

  const _AttendanceTile({
    required this.staff,
    required this.existing,
    required this.date,
    required this.statusLabel,
    required this.statusColor,
  });

  Future<void> _mark(BuildContext context, WidgetRef ref, AttendanceStatus status) async {
    final business = ref.read(activeBusinessProvider);
    if (business == null) return;
    final ok = await ref.read(attendanceControllerProvider.notifier).mark(AttendanceRecord(
          id: '',
          staffId: staff.id,
          businessId: business.id,
          date: date,
          status: status,
          createdAt: DateTime.now(),
        ));
    if (ok) {
      ref.invalidate(attendanceForDateProvider);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(staff.fullName, style: const TextStyle(fontWeight: FontWeight.w600))),
              if (existing != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor(existing!.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel(existing!.status),
                      style: TextStyle(fontSize: 11, color: statusColor(existing!.status), fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AttendanceStatus.values
                .map((s) => ChoiceChip(
                      label: Text(statusLabel(s)),
                      selected: existing?.status == s,
                      onSelected: (_) => _mark(context, ref, s),
                      selectedColor: statusColor(s).withValues(alpha: 0.15),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
