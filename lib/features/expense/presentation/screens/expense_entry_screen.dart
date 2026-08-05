import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared/widgets/app_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../../cashbook/domain/entities/cashbook_entry.dart';
import '../providers/expense_providers.dart';

class ExpenseEntryScreen extends ConsumerStatefulWidget {
  const ExpenseEntryScreen({super.key});

  @override
  ConsumerState<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends ConsumerState<ExpenseEntryScreen> {
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
      type: CashbookEntryType.expense,
      amount: amount,
      category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      entryDate: _date,
      createdAt: DateTime.now(),
      createdBy: '',
    );

    final ok = await ref.read(expenseEntryControllerProvider.notifier).addEntry(entry);
    if (ok && mounted) {
      ref.invalidate(expenseEntriesProvider);
      ref.invalidate(expenseThisMonthProvider);
      ref.invalidate(totalExpenseProvider);
      ref.invalidate(expenseReportEntriesProvider);
      ref.invalidate(expenseByCategoryProvider);
      context.pop();
    } else if (mounted) {
      final err = ref.read(expenseEntryControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const color = AppColors.warning;
    final state = ref.watch(expenseEntryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: color.withValues(alpha: 0.08),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Amount', style: TextStyle(fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
              decoration: const InputDecoration(prefixText: 'Rs. '),
            ),
            const SizedBox(height: 20),
            const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: expenseCategories.map((c) {
                final selected = _categoryController.text == c;
                return ChoiceChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (_) => setState(() => _categoryController.text = c),
                  selectedColor: color.withValues(alpha: 0.18),
                  labelStyle: TextStyle(
                    color: selected ? color : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(hintText: 'Or type a custom category'),
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
            const SizedBox(height: 28),
            AppButton(
              label: 'Save Expense',
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
