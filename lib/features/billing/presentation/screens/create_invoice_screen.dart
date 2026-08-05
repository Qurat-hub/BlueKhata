import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared/widgets/app_button.dart';
import '../../../../core/shared/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/presentation/providers/customer_providers.dart';
import '../../../stock/domain/entities/product.dart';
import '../../../stock/presentation/providers/stock_providers.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../providers/invoice_providers.dart';

class _DraftLine {
  final String? productId;
  String description;
  double quantity;
  double unitPrice;
  _DraftLine({this.productId, required this.description, this.quantity = 1, this.unitPrice = 0});
  double get lineTotal => quantity * unitPrice;
}

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  Customer? _customer;
  final List<_DraftLine> _lines = [];
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _discountController.dispose();
    _taxController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal => _lines.fold(0, (sum, l) => sum + l.lineTotal);
  double get _discount => double.tryParse(_discountController.text.trim()) ?? 0;
  double get _tax => double.tryParse(_taxController.text.trim()) ?? 0;
  double get _total => (_subtotal - _discount + _tax).clamp(0, double.infinity);

  Future<void> _pickCustomer() async {
    final picked = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CustomerPickerSheet(),
    );
    if (picked != null) setState(() => _customer = picked);
  }

  Future<void> _addProductLine() async {
    final picked = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ProductPickerSheet(),
    );
    if (picked != null) {
      setState(() => _lines.add(_DraftLine(
            productId: picked.id,
            description: picked.name,
            quantity: 1,
            unitPrice: picked.sellingPrice,
          )));
    }
  }

  void _addFreeformLine() {
    setState(() => _lines.add(_DraftLine(description: '', quantity: 1, unitPrice: 0)));
  }

  Future<void> _save() async {
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Add at least one item')));
      return;
    }
    if (_lines.any((l) => l.description.trim().isEmpty)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Every line needs a description')));
      return;
    }

    final business = ref.read(activeBusinessProvider);
    if (business == null) return;
    final invoiceNumber = await ref.read(nextInvoiceNumberProvider.future);

    final draft = Invoice(
      id: '',
      businessId: business.id,
      customerId: _customer?.id,
      invoiceNumber: invoiceNumber,
      status: InvoiceStatus.pending,
      subtotal: _subtotal,
      discount: _discount,
      tax: _tax,
      total: _total,
      amountPaid: 0,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final items = _lines
        .map((l) => InvoiceItem(
              id: '',
              invoiceId: '',
              productId: l.productId,
              description: l.description.trim(),
              quantity: l.quantity,
              unitPrice: l.unitPrice,
              lineTotal: l.lineTotal,
            ))
        .toList();

    final created = await ref.read(invoiceFormControllerProvider.notifier).create(draft, items);
    if (created != null && mounted) {
      ref.invalidate(invoiceListProvider);
      ref.invalidate(productListProvider);
      ref.invalidate(lowStockProductsProvider);
      context.pushReplacement('/bills/${created.id}');
    } else if (mounted) {
      final err = ref.read(invoiceFormControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(invoiceFormControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Invoice')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text('Customer', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          AppCard(
            onTap: _pickCustomer,
            child: Row(
              children: [
                const Icon(Icons.person_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_customer?.name ?? 'Walk-in customer (optional)',
                      style: TextStyle(
                          color: _customer == null ? AppColors.textSecondary : AppColors.textPrimary)),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Items', style: TextStyle(fontWeight: FontWeight.w600)),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _addProductLine,
                    icon: const Icon(Icons.inventory_2_outlined, size: 18),
                    label: const Text('From Stock'),
                  ),
                  TextButton.icon(
                    onPressed: _addFreeformLine,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Custom'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_lines.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Text('No items added yet', style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            Column(
              children: List.generate(_lines.length, (i) => _LineItemEditor(
                    line: _lines[i],
                    onChanged: () => setState(() {}),
                    onRemove: () => setState(() => _lines.removeAt(i)),
                  )),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Discount', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _discountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(prefixText: 'Rs. '),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tax', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _taxController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(prefixText: 'Rs. '),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Notes (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(controller: _notesController, maxLines: 2),
          const SizedBox(height: 20),
          AppCard(
            gradient: AppColors.staffBannerGradient,
            child: Column(
              children: [
                _TotalsRow(label: 'Subtotal', value: _subtotal),
                _TotalsRow(label: 'Discount', value: -_discount),
                _TotalsRow(label: 'Tax', value: _tax),
                const Divider(color: Colors.white24, height: 20),
                _TotalsRow(label: 'Total', value: _total, bold: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Save Invoice',
            loading: formState.isLoading,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  const _TotalsRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white70, fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.bold : null)),
          Text('Rs. ${value.toStringAsFixed(0)}',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: bold ? 18 : 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LineItemEditor extends StatelessWidget {
  final _DraftLine line;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  const _LineItemEditor({required this.line, required this.onChanged, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: line.description,
                    decoration: const InputDecoration(hintText: 'Item description', isDense: true),
                    enabled: line.productId == null,
                    onChanged: (v) {
                      line.description = v;
                      onChanged();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                  onPressed: onRemove,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: line.quantity.toString(),
                    decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) {
                      line.quantity = double.tryParse(v) ?? line.quantity;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: line.unitPrice.toString(),
                    decoration: const InputDecoration(labelText: 'Price', isDense: true, prefixText: 'Rs. '),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) {
                      line.unitPrice = double.tryParse(v) ?? line.unitPrice;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 90,
                  child: Text('Rs. ${line.lineTotal.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerPickerSheet extends ConsumerWidget {
  const _CustomerPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerListProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(hintText: 'Search customers...', prefixIcon: Icon(Icons.search_rounded)),
              onChanged: (v) => ref.read(customerSearchQueryProvider.notifier).state = v,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: customersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('$e')),
                data: (customers) => ListView.builder(
                  controller: scrollController,
                  itemCount: customers.length,
                  itemBuilder: (context, i) {
                    final c = customers[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
                      title: Text(c.name),
                      subtitle: c.phone != null ? Text(c.phone!) : null,
                      onTap: () => Navigator.of(context).pop(c),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPickerSheet extends ConsumerWidget {
  const _ProductPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(hintText: 'Search products...', prefixIcon: Icon(Icons.search_rounded)),
              onChanged: (v) => ref.read(productSearchQueryProvider.notifier).state = v,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('$e')),
                data: (products) => ListView.builder(
                  controller: scrollController,
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final p = products[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.inventory_2_rounded)),
                      title: Text(p.name),
                      subtitle: Text('Rs. ${p.sellingPrice.toStringAsFixed(0)} · ${p.stockQuantity.toStringAsFixed(0)} ${p.unit} in stock'),
                      onTap: () => Navigator.of(context).pop(p),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
