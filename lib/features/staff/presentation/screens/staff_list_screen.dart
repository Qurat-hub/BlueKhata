import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/shared/widgets/app_card.dart';
import '../../../../core/shared/widgets/state_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/staff_member.dart';
import '../providers/staff_providers.dart';

class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Book'),
        actions: [
          IconButton(
            tooltip: 'Mark Attendance',
            icon: const Icon(Icons.fact_check_outlined),
            onPressed: () => context.push(AppRoutes.attendance),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addEditStaff),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Staff'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search staff...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => ref.read(staffSearchQueryProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: staffAsync.when(
              loading: () => const AppLoading(),
              error: (e, st) => AppErrorState(
                message: 'Failed to load staff.\n$e',
                onRetry: () => ref.invalidate(staffListProvider),
              ),
              data: (staff) {
                if (staff.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.groups_2_outlined,
                    title: 'No staff yet',
                    subtitle: 'Add your team to track attendance and salaries.',
                    actionLabel: 'Add Staff',
                    onAction: () => context.push(AppRoutes.addEditStaff),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(staffListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: staff.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _StaffTile(staff: staff[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  final StaffMember staff;
  const _StaffTile({required this.staff});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/staff/${staff.id}'),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.fullName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                if (staff.roleTitle != null)
                  Text(staff.roleTitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text('Rs. ${staff.monthlySalary.toStringAsFixed(0)}/mo',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
