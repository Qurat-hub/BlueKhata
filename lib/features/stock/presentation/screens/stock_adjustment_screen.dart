import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared/widgets/app_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/inventory_log.dart';
import '../../domain/entities/product.dart';
import '../providers/stock_providers.dart';

/// Add or reduce a product's stock. Every submission writes one signed
/// `inventory_logs` row — the server trigger applies it to
/// `products.stock_quantity`. This screen never touches stock_quantity
/// directly.
class StockAdjustmentScreen extends ConsumerStatefulWidget {
  final Product product;
  final bool isAddingStock;

  const StockAdjustmentScreen({super.key, required this.product, required this.isAddingStock});

  @override
  ConsumerState<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends ConsumerState<StockAdjustmentScreen> {
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  late StockChangeType _changeType =
      widget.isAddingStock ? StockChangeType.purchase : StockChangeType.sale;

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final qty = double.tryParse(_quantityController.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid quantity')));
      return;
    }

    final signedDelta = widget.isAddingStock ? qty : -qty;
    final ok = await ref.read(stockAdjustmentControllerProvider.notifier).adjust(
          businessId: widget.product.businessId,
          productId: widget.product.id,
          changeType: _changeType,
          quantityDelta: signedDelta,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );

    if (ok && mounted) {
      ref.invalidate(productDetailProvider(widget.product.id));
      ref.invalidate(productLogsProvider(widget.product.id));
      ref.invalidate(productListProvider);
      ref.invalidate(lowStockProductsProvider);
      context.pop();
    } else if (mounted) {
      final err = ref.read(stockAdjustmentControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  List<StockChangeType> get _availableTypes => widget.isAddingStock
      ? [StockChangeType.purchase, StockChangeType.returnStock, StockChangeType.adjustment]
      : [StockChangeType.sale, StockChangeType.adjustment];

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
    final color = widget.isAddingStock ? AppColors.success : AppColors.danger;
    final label = widget.isAddingStock ? 'Add Stock' : 'Reduce Stock';
    final state = ref.watch(stockAdjustmentControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('$label — ${widget.product.name}'),
        backgroundColor: color.withValues(alpha: 0.08),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quantity (${widget.product.unit})',
                style: TextStyle(fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 8),
            TextField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 20),
            const Text('Reason', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _availableTypes
                  .map((t) => ChoiceChip(
                        label: Text(_typeLabel(t)),
                        selected: _changeType == t,
                        onSelected: (_) => setState(() => _changeType = t),
                        selectedColor: color.withValues(alpha: 0.15),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            const Text('Note (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'e.g. Supplier name, invoice #'),
            ),
            const SizedBox(height: 20),
            Text(
              'Current stock: ${widget.product.stockQuantity.toStringAsFixed(0)} ${widget.product.unit}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const Spacer(),
            AppButton(
              label: 'Save',
              color: color,
              loading: state.isLoading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
