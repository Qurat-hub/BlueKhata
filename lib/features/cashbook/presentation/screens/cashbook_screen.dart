import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/shared/widgets/app_card.dart';
import '../../../../core/shared/widgets/state_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/cashbook_entry.dart';
import '../providers/cashbook_providers.dart';

class CashbookScreen extends ConsumerWidget {
  const CashbookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(cashbookEntriesProvider);
    final cashInHandAsync = ref.watch(cashInHandProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Book'),
        actions: [
          IconButton(
            tooltip: 'Cash Report',
            icon: const Icon(Icons.description_outlined),
            onPressed: () => context.push(AppRoutes.cashReport),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'cashOut',
            backgroundColor: AppColors.danger,
            onPressed: () => context.push(AppRoutes.cashEntry, extra: false),
            icon: const Icon(Icons.remove_rounded),
            label: const Text('Cash Out'),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'cashIn',
            backgroundColor: AppColors.success,
            onPressed: () => context.push(AppRoutes.cashEntry, extra: true),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Cash In'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(cashbookEntriesProvider);
          ref.invalidate(cashInHandProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            AppCard(
              gradient: AppColors.staffBannerGradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cash In Hand',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  cashInHandAsync.when(
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
            const Text('Recent Entries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            entriesAsync.when(
              loading: () => const AppLoading(),
              error: (e, st) => AppErrorState(
                message: 'Failed to load cash book.\n$e',
                onRetry: () => ref.invalidate(cashbookEntriesProvider),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No cash entries yet',
                    subtitle: 'Record your first Cash In or Cash Out to start tracking cash in hand.',
                  );
                }
                return Column(
                  children: entries.map((e) => _CashTile(entry: e)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

}

class _CashTile extends StatelessWidget {
  final CashbookEntry entry;
  const _CashTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isInflow = cashbookEntryIsInflow(entry.type);
    final color = isInflow ? AppColors.success : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(isInflow ? Icons.south_west_rounded : Icons.north_east_rounded, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.category ?? (isInflow ? 'Cash In' : 'Cash Out'),
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
              '${isInflow ? '+' : '-'}Rs. ${entry.amount.toStringAsFixed(0)}',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
