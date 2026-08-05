import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/shared/widgets/app_button.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../domain/entities/business.dart';
import '../providers/business_providers.dart';

const _businessTypes = [
  'Retail', 'Wholesale', 'Distributor', 'Service', 'Manufacturing', 'General'
];
const _currencies = ['PKR', 'USD', 'AED', 'SAR', 'INR', 'GBP', 'EUR'];

class CreateBusinessScreen extends ConsumerStatefulWidget {
  const CreateBusinessScreen({super.key});

  @override
  ConsumerState<CreateBusinessScreen> createState() => _CreateBusinessScreenState();
}

class _CreateBusinessScreenState extends ConsumerState<CreateBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _taxController = TextEditingController();
  String _type = _businessTypes.first;
  String _currency = _currencies.first;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ownerId = ref.read(currentUserProvider)?.id;
    if (ownerId == null) return;

    final draft = Business(
      id: '',
      ownerId: ownerId,
      name: _nameController.text.trim(),
      businessType: _type,
      currency: _currency,
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      taxNumber: _taxController.text.trim().isEmpty ? null : _taxController.text.trim(),
      createdAt: DateTime.now(),
    );

    final created = await ref.read(createBusinessControllerProvider.notifier).submit(draft);
    if (created == null) {
      final state = ref.read(createBusinessControllerProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.toString()),
        ),
      );

      return;
    }
    if (created != null && mounted) {
      ref.read(activeBusinessProvider.notifier).state = created;
      ref.invalidate(myBusinessesProvider);
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createBusinessControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Business')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Business Name', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'e.g. Al-Rehman Traders'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Business name is required' : null,
              ),
              const SizedBox(height: 20),
              const Text('Business Type', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: _businessTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 20),
              const Text('Currency', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _currency,
                items: _currencies
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _currency = v ?? _currency),
              ),
              const SizedBox(height: 20),
              const Text('Address (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(controller: _addressController),
              const SizedBox(height: 20),
              const Text('Phone (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(controller: _phoneController, keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              const Text('Tax Number (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(controller: _taxController),
              const SizedBox(height: 32),
              AppButton(
                label: 'Create Business',
                loading: state.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
