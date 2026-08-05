import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared/widgets/app_button.dart';
import '../../../../core/shared/widgets/state_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ledger/domain/entities/ledger_entry.dart';
import '../../../ledger/presentation/providers/ledger_providers.dart';
import '../providers/customer_providers.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    final ledgerAsync = ref.watch(customerLedgerProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: customerAsync.maybeWhen(
          data: (c) => Text(c.name),
          orElse: () => const Text('Customer'),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/customers/edit', extra: customerId),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: customerAsync.when(
        loading: () => const AppLoading(),
        error: (e, st) => AppErrorState(
          message: 'Could not load customer.\n$e',
          onRetry: () => ref.invalidate(customerDetailProvider(customerId)),
        ),
        data: (customer) {
          final balanceColor = customer.currentBalance == 0
              ? AppColors.textSecondary
              : (customer.owesYou ? AppColors.danger : AppColors.success);

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      customer.owesYou ? 'Balance to receive' : 'Balance to pay',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rs. ${customer.currentBalance.abs().toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'You Gave',
                            color: AppColors.danger,
                            onPressed: () =>
                                context.push('/customers/$customerId/entry', extra: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: 'You Got',
                            color: AppColors.success,
                            onPressed: () =>
                                context.push('/customers/$customerId/entry', extra: false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ledgerAsync.when(
                  loading: () => const AppLoading(),
                  error: (e, st) => AppErrorState(
                    message: 'Could not load ledger.\n$e',
                    onRetry: () => ref.invalidate(customerLedgerProvider(customerId)),
                  ),
                  data: (entries) {
                    if (entries.isEmpty) {
                      return const AppEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No transactions yet',
                        subtitle: 'Entries you record will show up here in a running ledger.',
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) => _LedgerTile(entry: entries[i], balanceColor: balanceColor),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  final LedgerEntry entry;
  final Color balanceColor;
  const _LedgerTile({required this.entry, required this.balanceColor});

  @override
  Widget build(BuildContext context) {
    final isCredit = entry.type == LedgerEntryType.credit;
    final color = isCredit ? AppColors.danger : AppColors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(
              isCredit ? Icons.north_east_rounded : Icons.south_west_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.note?.isNotEmpty == true ? entry.note! : (isCredit ? 'You gave' : 'You received'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${entry.entryDate.day}/${entry.entryDate.month}/${entry.entryDate.year}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}Rs. ${entry.amount.toStringAsFixed(0)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
