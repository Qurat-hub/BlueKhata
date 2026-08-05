import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared/widgets/app_button.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../domain/entities/customer.dart';
import '../providers/customer_providers.dart';

class AddEditCustomerScreen extends ConsumerStatefulWidget {
  final String? customerId;
  const AddEditCustomerScreen({super.key, this.customerId});

  @override
  ConsumerState<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends ConsumerState<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _openingBalanceController = TextEditingController(text: '0');
  bool _prefilled = false;

  bool get isEditing => widget.customerId != null;

  void _prefillIfNeeded(Customer c) {
    if (_prefilled) return;
    _nameController.text = c.name;
    _phoneController.text = c.phone ?? '';
    _addressController.text = c.address ?? '';
    _openingBalanceController.text = c.openingBalance.toString();
    _prefilled = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final business = ref.read(activeBusinessProvider);
    if (business == null) return;

    if (isEditing) {
      final ok = await ref.read(customerFormControllerProvider.notifier).update(
        widget.customerId!,
        {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          'address':
              _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        },
      );
      if (ok && mounted) {
        ref.invalidate(customerDetailProvider(widget.customerId!));
        ref.invalidate(customerListProvider);
        context.pop();
      }
    } else {
      final draft = Customer(
        id: '',
        businessId: business.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address:
            _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        openingBalance: double.tryParse(_openingBalanceController.text.trim()) ?? 0,
        createdAt: DateTime.now(),
      );
      final created = await ref.read(customerFormControllerProvider.notifier).create(draft);
      if (created != null && mounted) {
        ref.invalidate(customerListProvider);
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(customerFormControllerProvider);

    if (isEditing) {
      final asyncCustomer = ref.watch(customerDetailProvider(widget.customerId!));
      asyncCustomer.whenData(_prefillIfNeeded);
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Customer' : 'Add Customer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Name', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 20),
              const Text('Phone', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(controller: _phoneController, keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              const Text('Address', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(controller: _addressController),
              if (!isEditing) ...[
                const SizedBox(height: 20),
                const Text('Opening Balance', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _openingBalanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
              const SizedBox(height: 32),
              AppButton(
                label: isEditing ? 'Save Changes' : 'Add Customer',
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
