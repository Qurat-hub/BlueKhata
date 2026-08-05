import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/shared/widgets/app_button.dart';
import '../../../../core/shared/widgets/app_card.dart';
import '../../../../core/shared/widgets/state_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../business/domain/entities/business.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../../customers/presentation/providers/customer_providers.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../providers/invoice_providers.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  Future<void> _sharePdf(BuildContext context, WidgetRef ref, Business business, InvoiceWithItems data) async {
    String customerName = 'Walk-in customer';
    if (data.invoice.customerId != null) {
      try {
        final c = await ref.read(customerDetailProvider(data.invoice.customerId!).future);
        customerName = c.name;
      } catch (_) {}
    }

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(business.name, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            if (business.address != null) pw.Text(business.address!, style: const pw.TextStyle(color: PdfColors.grey700)),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Bill To', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
                    pw.Text(customerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(data.invoice.invoiceNumber, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${data.invoice.createdAt.day}/${data.invoice.createdAt.month}/${data.invoice.createdAt.year}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              headers: ['Item', 'Qty', 'Price', 'Total'],
              data: data.items
                  .map((i) => [
                        i.description,
                        i.quantity.toStringAsFixed(0),
                        i.unitPrice.toStringAsFixed(0),
                        i.lineTotal.toStringAsFixed(0),
                      ])
                  .toList(),
            ),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Subtotal: Rs ${data.invoice.subtotal.toStringAsFixed(0)}'),
                  pw.Text('Discount: Rs ${data.invoice.discount.toStringAsFixed(0)}'),
                  pw.Text('Tax: Rs ${data.invoice.tax.toStringAsFixed(0)}'),
                  pw.SizedBox(height: 4),
                  pw.Text('Total: Rs ${data.invoice.total.toStringAsFixed(0)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
            if (data.invoice.notes != null) ...[
              pw.SizedBox(height: 16),
              pw.Text('Notes: ${data.invoice.notes}'),
            ],
          ],
        ),
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: '${data.invoice.invoiceNumber}.pdf');
  }

  Future<void> _recordPayment(BuildContext context, WidgetRef ref, Invoice invoice) async {
    final controller = TextEditingController(text: invoice.balanceDue.toStringAsFixed(0));
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Payment'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: 'Rs. '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(double.tryParse(controller.text.trim())),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;

    final newAmountPaid = (invoice.amountPaid + amount).clamp(0, invoice.total);
    final status = newAmountPaid >= invoice.total
        ? InvoiceStatus.paid
        : (newAmountPaid > 0 ? InvoiceStatus.partial : InvoiceStatus.pending);

    final ok = await ref.read(invoiceFormControllerProvider.notifier).recordPayment(
          invoice.id,
          amountPaid: newAmountPaid.toDouble(),
          status: status,
        );
    if (ok) {
      ref.invalidate(invoiceDetailProvider(invoice.id));
      ref.invalidate(invoiceListProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(invoiceDetailProvider(invoiceId));
    final business = ref.watch(activeBusinessProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        actions: [
          detailAsync.maybeWhen(
            data: (data) => IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: business == null ? null : () => _sharePdf(context, ref, business, data),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const AppLoading(),
        error: (e, st) => AppErrorState(
          message: 'Failed to load invoice.\n$e',
          onRetry: () => ref.invalidate(invoiceDetailProvider(invoiceId)),
        ),
        data: (data) => _InvoiceBody(
          data: data,
          onRecordPayment: () => _recordPayment(context, ref, data.invoice),
        ),
      ),
    );
  }
}

class _InvoiceBody extends ConsumerWidget {
  final InvoiceWithItems data;
  final VoidCallback onRecordPayment;
  const _InvoiceBody({required this.data, required this.onRecordPayment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoice = data.invoice;
    final customerAsync = invoice.customerId != null
        ? ref.watch(customerDetailProvider(invoice.customerId!))
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        AppCard(
          gradient: AppColors.staffBannerGradient,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(invoice.invoiceNumber,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('${invoice.createdAt.day}/${invoice.createdAt.month}/${invoice.createdAt.year}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              customerAsync == null
                  ? const Text('Walk-in customer', style: TextStyle(color: Colors.white70))
                  : customerAsync.when(
                      loading: () => const Text('Loading...', style: TextStyle(color: Colors.white70)),
                      error: (e, st) => const Text('Customer', style: TextStyle(color: Colors.white70)),
                      data: (c) => Text(c.name, style: const TextStyle(color: Colors.white70)),
                    ),
              const SizedBox(height: 14),
              Text('Rs. ${invoice.total.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28)),
              if (invoice.balanceDue > 0)
                Text('Rs. ${invoice.balanceDue.toStringAsFixed(0)} due',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (invoice.status != InvoiceStatus.paid && invoice.status != InvoiceStatus.cancelled)
          AppButton(label: 'Record Payment', onPressed: onRecordPayment),
        const SizedBox(height: 20),
        const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Column(
          children: data.items
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(item.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('${item.quantity.toStringAsFixed(0)} × Rs. ${item.unitPrice.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ),
                          Text('Rs. ${item.lineTotal.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            children: [
              _Row('Subtotal', invoice.subtotal),
              _Row('Discount', -invoice.discount),
              _Row('Tax', invoice.tax),
              const Divider(height: 20),
              _Row('Total', invoice.total, bold: true),
              _Row('Paid', invoice.amountPaid),
              _Row('Balance Due', invoice.balanceDue, bold: true, color: invoice.balanceDue > 0 ? AppColors.danger : AppColors.success),
            ],
          ),
        ),
        if (invoice.notes != null) ...[
          const SizedBox(height: 16),
          const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(invoice.notes!),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  final Color? color;
  const _Row(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text('Rs. ${value.toStringAsFixed(0)}',
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
