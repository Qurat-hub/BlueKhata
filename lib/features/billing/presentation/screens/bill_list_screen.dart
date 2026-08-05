import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/shared/widgets/app_card.dart';
import '../../../../core/shared/widgets/state_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/invoice.dart';
import '../providers/invoice_providers.dart';

class BillListScreen extends ConsumerWidget {
  const BillListScreen({super.key});

  Color _statusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return AppColors.success;
      case InvoiceStatus.pending:
        return AppColors.warning;
      case InvoiceStatus.partial:
        return AppColors.primary;
      case InvoiceStatus.cancelled:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.pending:
        return 'Pending';
      case InvoiceStatus.partial:
        return 'Partial';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoiceListProvider);
    final filter = ref.watch(invoiceStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bill Book')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createInvoice),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Invoice'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: filter == null,
                    onTap: () => ref.read(invoiceStatusFilterProvider.notifier).state = null,
                  ),
                  for (final s in InvoiceStatus.values)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FilterChip(
                        label: _statusLabel(s),
                        selected: filter == s,
                        onTap: () => ref.read(invoiceStatusFilterProvider.notifier).state = s,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: invoicesAsync.when(
              loading: () => const AppLoading(),
              error: (e, st) => AppErrorState(
                message: 'Failed to load invoices.\n$e',
                onRetry: () => ref.invalidate(invoiceListProvider),
              ),
              data: (invoices) {
                if (invoices.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No invoices yet',
                    subtitle: 'Create your first invoice to start billing customers.',
                    actionLabel: 'New Invoice',
                    onAction: () => context.push(AppRoutes.createInvoice),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(invoiceListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: invoices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final invoice = invoices[i];
                      final color = _statusColor(invoice.status);
                      return AppCard(
                        onTap: () => context.push('/bills/${invoice.id}'),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: Icon(Icons.receipt_long_rounded, color: color),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(invoice.invoiceNumber,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(
                                    '${invoice.createdAt.day}/${invoice.createdAt.month}/${invoice.createdAt.year}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Rs. ${invoice.total.toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(_statusLabel(invoice.status),
                                      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
    );
  }
}
