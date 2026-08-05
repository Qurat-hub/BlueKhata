import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/shared/widgets/app_card.dart';
import '../../../../core/shared/widgets/state_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/product.dart';
import '../providers/stock_providers.dart';

class StockListScreen extends ConsumerWidget {
  const StockListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    final lowStockAsync = ref.watch(lowStockProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Book')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addEditProduct),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search products, SKU, barcode...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => ref.read(productSearchQueryProvider.notifier).state = v,
            ),
          ),
          lowStockAsync.maybeWhen(
            data: (lowStock) {
              if (lowStock.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${lowStock.length} product${lowStock.length == 1 ? '' : 's'} running low on stock',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const AppLoading(),
              error: (e, st) => AppErrorState(
                message: 'Failed to load products.\n$e',
                onRetry: () => ref.invalidate(productListProvider),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No products yet',
                    subtitle: 'Add your first product to start tracking stock.',
                    actionLabel: 'Add Product',
                    onAction: () => context.push(AppRoutes.addEditProduct),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(productListProvider);
                    ref.invalidate(lowStockProductsProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _ProductTile(product: products[i]),
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

class _ProductTile extends StatelessWidget {
  final Product product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final stockColor = product.isLowStock ? AppColors.danger : AppColors.success;

    return AppCard(
      onTap: () => context.push('/stock/${product.id}'),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: product.imageUrl != null ? NetworkImage(product.imageUrl!) : null,
            child: product.imageUrl == null
                ? const Icon(Icons.inventory_2_rounded, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                if (product.sku != null)
                  Text('SKU: ${product.sku}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text('Rs. ${product.sellingPrice.toStringAsFixed(0)} / ${product.unit}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.stockQuantity.toStringAsFixed(product.stockQuantity % 1 == 0 ? 0 : 1)} ${product.unit}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: stockColor),
              ),
              Text(
                product.isLowStock ? 'Low Stock' : 'In Stock',
                style: TextStyle(fontSize: 10, color: stockColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
