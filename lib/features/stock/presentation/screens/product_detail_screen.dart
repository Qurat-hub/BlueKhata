import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared/widgets/app_card.dart';
import '../../../../core/shared/widgets/state_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/inventory_log.dart';
import '../../domain/entities/product.dart';
import '../providers/stock_providers.dart';
import 'stock_adjustment_screen.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          productAsync.maybeWhen(
            data: (product) => IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => context.push('/stock/edit', extra: product.id),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: productAsync.when(
        loading: () => const AppLoading(),
        error: (e, st) => AppErrorState(
          message: 'Failed to load product.\n$e',
          onRetry: () => ref.invalidate(productDetailProvider(productId)),
        ),
        data: (product) => _ProductDetailBody(product: product),
      ),
    );
  }
}

class _ProductDetailBody extends ConsumerWidget {
  final Product product;
  const _ProductDetailBody({required this.product});

  Future<void> _openAdjustment(BuildContext context, {required bool isAddingStock}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StockAdjustmentScreen(product: product, isAddingStock: isAddingStock),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(productLogsProvider(product.id));
    final stockColor = product.isLowStock ? AppColors.danger : AppColors.success;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(productDetailProvider(product.id));
        ref.invalidate(productLogsProvider(product.id));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: product.imageUrl != null ? NetworkImage(product.imageUrl!) : null,
                      child: product.imageUrl == null
                          ? const Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 28)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          if (product.sku != null)
                            Text('SKU: ${product.sku}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          if (product.barcode != null)
                            Text('Barcode: ${product.barcode}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoStat(label: 'In Stock', value: '${product.stockQuantity.toStringAsFixed(0)} ${product.unit}', color: stockColor),
                    _InfoStat(label: 'Purchase Price', value: 'Rs. ${product.purchasePrice.toStringAsFixed(0)}'),
                    _InfoStat(label: 'Selling Price', value: 'Rs. ${product.sellingPrice.toStringAsFixed(0)}'),
                  ],
                ),
                if (product.isLowStock) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                        const SizedBox(width: 8),
                        Text('Below threshold of ${product.lowStockThreshold.toStringAsFixed(0)} ${product.unit}',
                            style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openAdjustment(context, isAddingStock: false),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                  icon: const Icon(Icons.remove_rounded),
                  label: const Text('Reduce Stock'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openAdjustment(context, isAddingStock: true),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Stock'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Stock History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          logsAsync.when(
            loading: () => const AppLoading(),
            error: (e, st) => const SizedBox.shrink(),
            data: (logs) {
              if (logs.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.history_rounded,
                  title: 'No stock movements yet',
                  subtitle: 'Add or reduce stock to see the history here.',
                );
              }
              return Column(children: logs.map((l) => _LogTile(log: l, unit: product.unit)).toList());
            },
          ),
        ],
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _InfoStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _LogTile extends StatelessWidget {
  final InventoryLog log;
  final String unit;
  const _LogTile({required this.log, required this.unit});

  String _typeLabel(StockChangeType t) {
    switch (t) {
      case StockChangeType.purchase:
        return 'Purchase';
      case StockChangeType.sale:
        return 'Sale';
      case StockChangeType.adjustment:
        return 'Adjustment';
      case StockChangeType.returnStock:
        return 'Return';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInflow = log.quantityDelta > 0;
    final color = isInflow ? AppColors.success : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(isInflow ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_typeLabel(log.changeType), style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (log.note != null)
                    Text(log.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('${log.createdAt.day}/${log.createdAt.month}/${log.createdAt.year}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(
              '${isInflow ? '+' : ''}${log.quantityDelta.toStringAsFixed(0)} $unit',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
