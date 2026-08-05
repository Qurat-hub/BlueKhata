import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/shared/widgets/state_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../providers/cashbook_providers.dart';

class CashReportScreen extends ConsumerWidget {
  const CashReportScreen({super.key});

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
      ref.read(cashReportRangeProvider.notifier).state =
          DateRange(from: picked.start, to: picked.end);
    }
  }

  Future<void> _exportPdf(
      BuildContext context,
      WidgetRef ref,
      String businessName,
      List<DailyCashBalance> rows,
      DateRange range,
      ) async {
    final doc = pw.Document();
    final currencyBlue = PdfColor.fromInt(AppColors.primary.toARGB32());

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(businessName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text('Cash Report', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(
            '${range.from != null ? _fmtDate(range.from!) : ''} - ${range.to != null ? _fmtDate(range.to!) : ''}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: currencyBlue),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellAlignment: pw.Alignment.centerLeft,
            headers: const ['Date', 'Daily Balance', 'Cash In Hand'],
            data: rows
                .map((r) => [
              _fmtDate(r.date),
              'Rs ${r.dailyBalance.toStringAsFixed(0)}',
              'Rs ${r.cashInHand.toStringAsFixed(0)}',
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
    final range = ref.watch(cashReportRangeProvider);
    final rowsAsync = ref.watch(cashDailyBalancesProvider);
    final business = ref.watch(activeBusinessProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cash Report')),
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
                    const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Daily Balance', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Cash In Hand', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
              ],
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: rowsAsync.when(
              loading: () => const AppLoading(),
              error: (e, st) => AppErrorState(
                message: 'Failed to load report.\n$e',
                onRetry: () => ref.invalidate(cashDailyBalancesProvider),
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.description_outlined,
                    title: 'No activity in this range',
                    subtitle: 'Pick a different date range or record a cash entry.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = rows[i];
                    final balanceColor = r.dailyBalance == 0
                        ? AppColors.textSecondary
                        : (r.dailyBalance > 0 ? AppColors.success : AppColors.danger);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(_fmtDate(r.date))),
                          Expanded(
                            flex: 2,
                            child: Text('Rs ${r.dailyBalance.abs().toStringAsFixed(0)}',
                                textAlign: TextAlign.right,
                                style: TextStyle(color: balanceColor, fontWeight: FontWeight.w600)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Rs ${r.cashInHand.toStringAsFixed(0)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    );
                  },
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
                  onPressed: rowsAsync.maybeWhen(data: (rows) => rows.isEmpty
                      ? null
                      : () => _exportPdf(context, ref, business?.name ?? 'BlueKhata', rows, range),
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
