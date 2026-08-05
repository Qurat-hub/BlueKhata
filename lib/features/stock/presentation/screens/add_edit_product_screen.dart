import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared/widgets/app_button.dart';
import '../../../../core/shared/widgets/barcode_scanner_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';
import '../providers/stock_providers.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final String? productId;
  const AddEditProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _unitController = TextEditingController(text: 'pcs');
  final _purchasePriceController = TextEditingController(text: '0');
  final _sellingPriceController = TextEditingController(text: '0');
  final _lowStockController = TextEditingController(text: '5');
  final _openingStockController = TextEditingController(text: '0');
  String? _categoryId;
  bool _prefilled = false;

  bool get isEditing => widget.productId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _unitController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _lowStockController.dispose();
    _openingStockController.dispose();
    super.dispose();
  }

  void _prefillIfNeeded(Product p) {
    if (_prefilled) return;
    _nameController.text = p.name;
    _skuController.text = p.sku ?? '';
    _barcodeController.text = p.barcode ?? '';
    _unitController.text = p.unit;
    _purchasePriceController.text = p.purchasePrice.toString();
    _sellingPriceController.text = p.sellingPrice.toString();
    _lowStockController.text = p.lowStockThreshold.toString();
    _categoryId = p.categoryId;
    _prefilled = true;
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen(title: 'Scan Product Barcode')),
    );
    if (code != null) setState(() => _barcodeController.text = code);
  }

  Future<void> _addCategory() async {
    final business = ref.read(activeBusinessProvider);
    if (business == null) return;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => context.pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final created = await ref.read(categoryFormControllerProvider.notifier).create(
          ProductCategory(id: '', businessId: business.id, name: name, createdAt: DateTime.now()),
        );
    if (created != null) {
      ref.invalidate(categoriesProvider);
      setState(() => _categoryId = created.id);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final business = ref.read(activeBusinessProvider);
    if (business == null) return;

    final draft = Product(
      id: '',
      businessId: business.id,
      categoryId: _categoryId,
      name: _nameController.text.trim(),
      sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
      barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
      unit: _unitController.text.trim().isEmpty ? 'pcs' : _unitController.text.trim(),
      purchasePrice: double.tryParse(_purchasePriceController.text.trim()) ?? 0,
      sellingPrice: double.tryParse(_sellingPriceController.text.trim()) ?? 0,
      lowStockThreshold: double.tryParse(_lowStockController.text.trim()) ?? 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (isEditing) {
      final ok = await ref.read(productFormControllerProvider.notifier).update(
            widget.productId!,
            draft,
          );
      if (ok && mounted) {
        ref.invalidate(productDetailProvider(widget.productId!));
        ref.invalidate(productListProvider);
        ref.invalidate(lowStockProductsProvider);
        context.pop();
      }
    } else {
      final openingStock = double.tryParse(_openingStockController.text.trim()) ?? 0;
      final created = await ref
          .read(productFormControllerProvider.notifier)
          .create(draft, openingStock: openingStock);
      if (created != null && mounted) {
        ref.invalidate(productListProvider);
        ref.invalidate(lowStockProductsProvider);
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(productFormControllerProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    if (isEditing) {
      final asyncProduct = ref.watch(productDetailProvider(widget.productId!));
      asyncProduct.whenData(_prefillIfNeeded);
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Product' : 'Add Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Product Name', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 20),
              const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, st) => const Text('Failed to load categories'),
                data: (categories) => Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                        hint: const Text('Uncategorized'),
                        items: categories
                            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                    ),
                    IconButton(
                      onPressed: _addCategory,
                      icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SKU', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextFormField(controller: _skuController),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Unit', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextFormField(controller: _unitController),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Barcode', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                    onPressed: _scanBarcode,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Purchase Price', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _purchasePriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(prefixText: 'Rs. '),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Selling Price', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _sellingPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(prefixText: 'Rs. '),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Low Stock Alert', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _lowStockController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ],
                    ),
                  ),
                  if (!isEditing) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Opening Stock', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _openingStockController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 32),
              AppButton(
                label: isEditing ? 'Save Changes' : 'Add Product',
                loading: formState.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
