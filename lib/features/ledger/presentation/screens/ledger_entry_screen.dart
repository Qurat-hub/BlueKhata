import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared/widgets/app_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../../customers/presentation/providers/customer_providers.dart';
import '../../domain/entities/ledger_entry.dart';
import '../providers/ledger_providers.dart';

class LedgerEntryScreen extends ConsumerStatefulWidget {
  final String customerId;
  final bool isCredit;

  const LedgerEntryScreen({super.key, required this.customerId, required this.isCredit});

  @override
  ConsumerState<LedgerEntryScreen> createState() => _LedgerEntryScreenState();
}

class _LedgerEntryScreenState extends ConsumerState<LedgerEntryScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
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

    final entry = LedgerEntry(
      id: '',
      businessId: business.id,
      customerId: widget.customerId,
      type: widget.isCredit ? LedgerEntryType.credit : LedgerEntryType.debit,
      amount: amount,
      balanceAfter: 0,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      entryDate: _date,
      createdAt: DateTime.now(),
      createdBy: '',
    );

    final ok = await ref.read(ledgerEntryControllerProvider.notifier).addEntry(entry);
    if (ok && mounted) {
      ref.invalidate(customerLedgerProvider(widget.customerId));
      ref.invalidate(customerDetailProvider(widget.customerId));
      ref.invalidate(customerListProvider);
      context.pop();
    } else if (mounted) {
      final err = ref.read(ledgerEntryControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = widget.isCredit;
    final color = isCredit ? AppColors.danger : AppColors.success;
    final label = isCredit ? 'You Gave (Credit)' : 'You Received (Payment)';
    final state = ref.watch(ledgerEntryControllerProvider);

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
              label: 'Save Entry',
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
