import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/shared/widgets/app_card.dart';
import '../../../../core/shared/widgets/state_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../cashbook/domain/entities/cashbook_entry.dart';
import '../providers/expense_providers.dart';

class ExpenseScreen extends ConsumerWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(expenseEntriesProvider);
    final thisMonthAsync = ref.watch(expenseThisMonthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Book'),
        actions: [
          IconButton(
            tooltip: 'Expense Report',
            icon: const Icon(Icons.description_outlined),
            onPressed: () => context.push(AppRoutes.expenseReport),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.warning,
        onPressed: () => context.push(AppRoutes.expenseEntry),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(expenseEntriesProvider);
          ref.invalidate(expenseThisMonthProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            AppCard(
              gradient: AppColors.staffBannerGradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('This Month\'s Expense',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  thisMonthAsync.when(
                    loading: () => const SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4)),
                    error: (e, st) => const Text('Rs. —', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    data: (value) => Text('Rs. ${value.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Recent Expenses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            entriesAsync.when(
              loading: () => const AppLoading(),
              error: (e, st) => AppErrorState(
                message: 'Failed to load expense book.\n$e',
                onRetry: () => ref.invalidate(expenseEntriesProvider),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.payments_outlined,
                    title: 'No expenses yet',
                    subtitle: 'Record your first expense to start tracking where money goes.',
                  );
                }
                return Column(
                  children: entries.map((e) => _ExpenseTile(entry: e)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final CashbookEntry entry;
  const _ExpenseTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.north_east_rounded, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.category ?? 'Expense',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (entry.note != null)
                    Text(entry.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('${entry.entryDate.day}/${entry.entryDate.month}/${entry.entryDate.year}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(
              '-Rs. ${entry.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
            ),
          ],
        ),
      ),
    );
  }
}
