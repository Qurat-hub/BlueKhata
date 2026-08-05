import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/shared/widgets/state_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../../cashbook/domain/entities/cashbook_entry.dart';
import '../../../cashbook/presentation/providers/cashbook_providers.dart' show DateRange;
import '../providers/expense_providers.dart';

class ExpenseReportScreen extends ConsumerWidget {
  const ExpenseReportScreen({super.key});

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')} '
      '${_month(d.month)} ${(d.year % 100).toString().padLeft(2, '0')}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String _month(int m) => _months[m - 1];

  Future<void> _pickRange(BuildContext context, WidgetRef ref, DateRange current) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: current.from ?? DateTime(now.year, now.month, 1),
        end: current.to ?? now,
      ),
    );
    if (picked != null) {
      ref.read(expenseReportRangeProvider.notifier).state =
          DateRange(from: picked.start, to: picked.end);
    }
  }

  Future<void> _exportPdf(
    BuildContext context,
    WidgetRef ref,
    String businessName,
    List<CashbookEntry> entries,
    Map<String, double> byCategory,
    DateRange range,
  ) async {
    final doc = pw.Document();
    final currencyOrange = PdfColor.fromInt(AppColors.warning.toARGB32());
    final total = entries.fold<double>(0, (sum, e) => sum + e.amount);

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(businessName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text('Expense Report', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(
            '${range.from != null ? _fmtDate(range.from!) : ''} - ${range.to != null ? _fmtDate(range.to!) : ''}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Total Expense: Rs ${total.toStringAsFixed(0)}',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: currencyOrange)),
          pw.SizedBox(height: 16),
          pw.Text('By Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: currencyOrange),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellAlignment: pw.Alignment.centerLeft,
            headers: const ['Category', 'Total'],
            data: byCategory.entries
                .map((e) => [e.key, 'Rs ${e.value.toStringAsFixed(0)}'])
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Entries', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: currencyOrange),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellAlignment: pw.Alignment.centerLeft,
            headers: const ['Date', 'Category', 'Note', 'Amount'],
            data: entries
                .map((e) => [
                      _fmtDate(e.entryDate),
                      e.category ?? '-',
                      e.note ?? '-',
                      'Rs ${e.amount.toStringAsFixed(0)}',
                    ])
                .toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(expenseReportRangeProvider);
    final entriesAsync = ref.watch(expenseReportEntriesProvider);
    final byCategoryAsync = ref.watch(expenseByCategoryProvider);
    final business = ref.watch(activeBusinessProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Report')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: InkWell(
              onTap: () => _pickRange(context, ref, range),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      range.from != null && range.to != null
                          ? '${_fmtDate(range.from!)}   —   ${_fmtDate(range.to!)}'
                          : 'Select report duration',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Icon(Icons.calendar_month_rounded, color: AppColors.warning, size: 18),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: entriesAsync.when(
              loading: () => const AppLoading(),
              error: (e, st) => AppErrorState(
                message: 'Failed to load report.\n$e',
                onRetry: () => ref.invalidate(expenseReportEntriesProvider),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.description_outlined,
                    title: 'No expenses in this range',
                    subtitle: 'Pick a different date range or record an expense.',
                  );
                }
                final total = entries.fold<double>(0, (sum, e) => sum + e.amount);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Expense', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('Rs ${total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('By Category',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    byCategoryAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, st) => const SizedBox.shrink(),
                      data: (byCategory) => Column(
                        children: byCategory.entries.map((entry) {
                          final share = total == 0 ? 0.0 : entry.value / total;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    Text('Rs ${entry.value.toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: share,
                                    minHeight: 6,
                                    backgroundColor: AppColors.divider,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Entries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    ...entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.category ?? 'Expense',
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(_fmtDate(e.entryDate),
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Text('-Rs ${e.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger)),
                            ],
                          ),
                        )),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: entriesAsync.maybeWhen(
                    data: (entries) => entries.isEmpty
                        ? null
                        : () => _exportPdf(
                              context,
                              ref,
                              business?.name ?? 'BlueKhata',
                              entries,
                              byCategoryAsync.maybeWhen(data: (v) => v, orElse: () => {}),
                              range,
                            ),
                    orElse: () => null,
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('PDF'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
