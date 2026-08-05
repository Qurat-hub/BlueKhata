import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/shared/widgets/app_button.dart';
import '../../../../core/shared/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/salary_payment.dart';
import '../../domain/entities/staff_member.dart';
import '../providers/staff_providers.dart';

class PaySalaryScreen extends ConsumerStatefulWidget {
  final StaffMember staff;
  const PaySalaryScreen({super.key, required this.staff});

  @override
  ConsumerState<PaySalaryScreen> createState() => _PaySalaryScreenState();
}

class _PaySalaryScreenState extends ConsumerState<PaySalaryScreen> {
  late final _baseController = TextEditingController(text: widget.staff.monthlySalary.toString());
  final _bonusController = TextEditingController(text: '0');
  final _advanceController = TextEditingController(text: '0');
  final _overtimeController = TextEditingController(text: '0');
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  void dispose() {
    _baseController.dispose();
    _bonusController.dispose();
    _advanceController.dispose();
    _overtimeController.dispose();
    super.dispose();
  }

  double get _base => double.tryParse(_baseController.text.trim()) ?? 0;
  double get _bonus => double.tryParse(_bonusController.text.trim()) ?? 0;
  double get _advance => double.tryParse(_advanceController.text.trim()) ?? 0;
  double get _overtime => double.tryParse(_overtimeController.text.trim()) ?? 0;
  double get _netPaid => (_base + _bonus + _overtime - _advance).clamp(0, double.infinity);

  Future<void> _save() async {
    final draft = SalaryPayment(
      id: '',
      staffId: widget.staff.id,
      businessId: widget.staff.businessId,
      month: _month,
      baseAmount: _base,
      bonus: _bonus,
      advance: _advance,
      overtime: _overtime,
      netPaid: _netPaid,
      paidAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    final ok = await ref.read(salaryControllerProvider.notifier).pay(draft);
    if (ok && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      final err = ref.read(salaryControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salaryControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Pay ${widget.staff.fullName}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Month', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _month,
                firstDate: DateTime(2020),
                lastDate: DateTime(DateTime.now().year + 1),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) setState(() => _month = DateTime(picked.year, picked.month, 1));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${_months[_month.month - 1]} ${_month.year}'),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Base Amount', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _baseController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(prefixText: 'Rs. '),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bonus', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bonusController,
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
                    const Text('Overtime', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _overtimeController,
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
          const Text('Advance Deduction', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _advanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(prefixText: 'Rs. '),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          AppCard(
            gradient: AppColors.staffBannerGradient,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net Paid', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                Text('Rs. ${_netPaid.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppButton(label: 'Save Payment', loading: state.isLoading, onPressed: _save),
        ],
      ),
    );
  }
}
