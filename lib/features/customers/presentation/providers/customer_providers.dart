import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../data/repositories/customer_repository.dart';
import '../../domain/entities/customer.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) => CustomerRepository());

final customerSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final customerListProvider = FutureProvider.autoDispose<List<Customer>>((ref) async {
  final business = ref.watch(activeBusinessProvider);
  final query = ref.watch(customerSearchQueryProvider);
  if (business == null) return [];
  return ref.watch(customerRepositoryProvider).fetchCustomers(
        businessId: business.id,
        query: query,
      );
});

final customerDetailProvider =
    FutureProvider.autoDispose.family<Customer, String>((ref, customerId) async {
  return ref.watch(customerRepositoryProvider).fetchCustomer(customerId);
});

class CustomerFormController extends StateNotifier<AsyncValue<void>> {
  final CustomerRepository _repo;
  CustomerFormController(this._repo) : super(const AsyncData(null));

  Future<Customer?> create(Customer draft) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.createCustomer(draft);
      state = const AsyncData(null);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> update(String id, Map<String, dynamic> changes) async {
    state = const AsyncLoading();
    try {
      await _repo.updateCustomer(id, changes);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final customerFormControllerProvider =
    StateNotifierProvider.autoDispose<CustomerFormController, AsyncValue<void>>((ref) {
  return CustomerFormController(ref.watch(customerRepositoryProvider));
});
