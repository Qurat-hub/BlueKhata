import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/business_repository.dart';
import '../../domain/entities/business.dart';

final businessRepositoryProvider = Provider<BusinessRepository>((ref) => BusinessRepository());

final myBusinessesProvider = FutureProvider.autoDispose<List<Business>>((ref) async {
  return ref.watch(businessRepositoryProvider).fetchMyBusinesses();
});

/// The currently active business the user is operating within. All
/// dashboard/customer/ledger queries are scoped to this id.
final activeBusinessProvider = StateProvider<Business?>((ref) => null);

class CreateBusinessController extends StateNotifier<AsyncValue<void>> {
  final BusinessRepository _repo;
  CreateBusinessController(this._repo) : super(const AsyncData(null));

  Future<Business?> submit(Business draft) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.createBusiness(draft);
      state = const AsyncData(null);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final createBusinessControllerProvider =
    StateNotifierProvider.autoDispose<CreateBusinessController, AsyncValue<void>>((ref) {
  return CreateBusinessController(ref.watch(businessRepositoryProvider));
});
