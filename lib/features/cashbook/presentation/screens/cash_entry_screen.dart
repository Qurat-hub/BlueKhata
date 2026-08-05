import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared/widgets/app_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../domain/entities/cashbook_entry.dart';
import '../providers/cashbook_providers.dart';

class CashEntryScreen extends ConsumerStatefulWidget {
  final bool isCashIn;

  const CashEntryScreen({super.key, required this.isCashIn});

  @override
  ConsumerState<CashEntryScreen> createState() => _CashEntryScreenState();
}

class _CashEntryScreenState extends ConsumerState<CashEntryScreen> {
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    final business = ref.read(activeBusinessProvider);
    if (business == null) return;

    final entry = CashbookEntry(
      id: '',
      businessId: business.id,
      type: widget.isCashIn ? CashbookEntryType.cashIn : CashbookEntryType.cashOut,
      amount: amount,
      category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      entryDate: _date,
      createdAt: DateTime.now(),
      createdBy: '',
    );

    final ok = await ref.read(cashEntryControllerProvider.notifier).addEntry(entry);
    if (ok && mounted) {
      ref.invalidate(cashbookEntriesProvider);
      ref.invalidate(cashInHandProvider);
      ref.invalidate(cashReportEntriesProvider);
      ref.invalidate(cashDailyBalancesProvider);
      context.pop();
    } else if (mounted) {
      final err = ref.read(cashEntryControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCashIn = widget.isCashIn;
    final color = isCashIn ? AppColors.success : AppColors.danger;
    final label = isCashIn ? 'Cash In' : 'Cash Out';
    final state = ref.watch(cashEntryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(label),
        backgroundColor: color.withValues(alpha: 0.08),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount', style: TextStyle(fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
              decoration: const InputDecoration(prefixText: 'Rs. '),
            ),
            const SizedBox(height: 20),
            const Text('Category (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(hintText: 'e.g. Rent, Sales, Utilities'),
            ),
            const SizedBox(height: 20),
            const Text('Note (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'What is this for?'),
            ),
            const SizedBox(height: 20),
            const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18),
                    const SizedBox(width: 10),
                    Text('${_date.day}/${_date.month}/${_date.year}'),
                  ],
                ),
              ),
            ),
            const Spacer(),
            AppButton(
              label: 'Save $label',
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
