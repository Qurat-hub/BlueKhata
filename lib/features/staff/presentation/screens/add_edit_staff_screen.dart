import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared/widgets/app_button.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../domain/entities/staff_member.dart';
import '../providers/staff_providers.dart';

class AddEditStaffScreen extends ConsumerStatefulWidget {
  final String? staffId;
  const AddEditStaffScreen({super.key, this.staffId});

  @override
  ConsumerState<AddEditStaffScreen> createState() => _AddEditStaffScreenState();
}

class _AddEditStaffScreenState extends ConsumerState<AddEditStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roleController = TextEditingController();
  final _salaryController = TextEditingController(text: '0');
  DateTime _joinedAt = DateTime.now();
  bool _prefilled = false;

  bool get isEditing => widget.staffId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _prefillIfNeeded(StaffMember s) {
    if (_prefilled) return;
    _nameController.text = s.fullName;
    _phoneController.text = s.phone ?? '';
    _roleController.text = s.roleTitle ?? '';
    _salaryController.text = s.monthlySalary.toString();
    _joinedAt = s.joinedAt;
    _prefilled = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final business = ref.read(activeBusinessProvider);
    if (business == null) return;

    final draft = StaffMember(
      id: '',
      businessId: business.id,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      roleTitle: _roleController.text.trim().isEmpty ? null : _roleController.text.trim(),
      monthlySalary: double.tryParse(_salaryController.text.trim()) ?? 0,
      joinedAt: _joinedAt,
      createdAt: DateTime.now(),
    );

    if (isEditing) {
      final ok = await ref.read(staffFormControllerProvider.notifier).update(widget.staffId!, draft);
      if (ok && mounted) {
        ref.invalidate(staffDetailProvider(widget.staffId!));
        ref.invalidate(staffListProvider);
        context.pop();
      }
    } else {
      final created = await ref.read(staffFormControllerProvider.notifier).create(draft);
      if (created != null && mounted) {
        ref.invalidate(staffListProvider);
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(staffFormControllerProvider);

    if (isEditing) {
      final asyncStaff = ref.watch(staffDetailProvider(widget.staffId!));
      asyncStaff.whenData(_prefillIfNeeded);
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Staff' : 'Add Staff')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600)),
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
              const Text('Role', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(controller: _roleController, decoration: const InputDecoration(hintText: 'e.g. Cashier, Manager')),
              const SizedBox(height: 20),
              const Text('Monthly Salary', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _salaryController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(prefixText: 'Rs. '),
              ),
              if (!isEditing) ...[
                const SizedBox(height: 20),
                const Text('Joined On', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _joinedAt,
                      firstDate: DateTime(2015),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _joinedAt = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(),
                    child: Text('${_joinedAt.day}/${_joinedAt.month}/${_joinedAt.year}'),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              AppButton(
                label: isEditing ? 'Save Changes' : 'Add Staff',
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
