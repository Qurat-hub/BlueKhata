import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) => InvoiceRepository());

final invoiceStatusFilterProvider = StateProvider.autoDispose<InvoiceStatus?>((ref) => null);

final invoiceListProvider = FutureProvider.autoDispose<List<Invoice>>((ref) async {
  final business = ref.watch(activeBusinessProvider);
  if (business == null) return [];
  final status = ref.watch(invoiceStatusFilterProvider);
  return ref.watch(invoiceRepositoryProvider).fetchInvoices(businessId: business.id, status: status);
});

final invoiceDetailProvider =
    FutureProvider.autoDispose.family<InvoiceWithItems, String>((ref, invoiceId) async {
  return ref.watch(invoiceRepositoryProvider).fetchInvoiceWithItems(invoiceId);
});

final nextInvoiceNumberProvider = FutureProvider.autoDispose<String>((ref) async {
  final business = ref.watch(activeBusinessProvider);
  if (business == null) return 'INV-0001';
  return ref.watch(invoiceRepositoryProvider).nextInvoiceNumber(business.id);
});

class InvoiceFormController extends StateNotifier<AsyncValue<void>> {
  final InvoiceRepository _repo;
  InvoiceFormController(this._repo) : super(const AsyncData(null));

  Future<Invoice?> create(Invoice draft, List<InvoiceItem> items) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.createInvoice(draft, items);
      state = const AsyncData(null);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> recordPayment(String invoiceId,
      {required double amountPaid, required InvoiceStatus status}) async {
    state = const AsyncLoading();
    try {
      await _repo.recordPayment(invoiceId, amountPaid: amountPaid, status: status);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final invoiceFormControllerProvider =
    StateNotifierProvider.autoDispose<InvoiceFormController, AsyncValue<void>>((ref) {
  return InvoiceFormController(ref.watch(invoiceRepositoryProvider));
});
