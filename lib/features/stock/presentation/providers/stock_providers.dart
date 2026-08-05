import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../data/repositories/stock_repository.dart';
import '../../domain/entities/inventory_log.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) => StockRepository());

final productSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final productListProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final business = ref.watch(activeBusinessProvider);
  final query = ref.watch(productSearchQueryProvider);
  if (business == null) return [];
  return ref.watch(stockRepositoryProvider).fetchProducts(businessId: business.id, query: query);
});

final productDetailProvider =
    FutureProvider.autoDispose.family<Product, String>((ref, productId) async {
  return ref.watch(stockRepositoryProvider).fetchProduct(productId);
});

final productLogsProvider =
    FutureProvider.autoDispose.family<List<InventoryLog>, String>((ref, productId) async {
  return ref.watch(stockRepositoryProvider).fetchLogsForProduct(productId);
});

final lowStockProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final business = ref.watch(activeBusinessProvider);
  if (business == null) return [];
  return ref.watch(stockRepositoryProvider).fetchLowStock(business.id);
});

final categoriesProvider = FutureProvider.autoDispose<List<ProductCategory>>((ref) async {
  final business = ref.watch(activeBusinessProvider);
  if (business == null) return [];
  return ref.watch(stockRepositoryProvider).fetchCategories(business.id);
});

class ProductFormController extends StateNotifier<AsyncValue<void>> {
  final StockRepository _repo;
  ProductFormController(this._repo) : super(const AsyncData(null));

  Future<Product?> create(Product draft, {double openingStock = 0}) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.createProduct(draft, openingStock: openingStock);
      state = const AsyncData(null);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> update(String id, Product changes) async {
    state = const AsyncLoading();
    try {
      await _repo.updateProduct(id, changes);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final productFormControllerProvider =
    StateNotifierProvider.autoDispose<ProductFormController, AsyncValue<void>>((ref) {
  return ProductFormController(ref.watch(stockRepositoryProvider));
});

class StockAdjustmentController extends StateNotifier<AsyncValue<void>> {
  final StockRepository _repo;
  StockAdjustmentController(this._repo) : super(const AsyncData(null));

  Future<bool> adjust({
    required String businessId,
    required String productId,
    required StockChangeType changeType,
    required double quantityDelta,
    String? note,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.adjustStock(
        businessId: businessId,
        productId: productId,
        changeType: changeType,
        quantityDelta: quantityDelta,
        note: note,
      );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final stockAdjustmentControllerProvider =
    StateNotifierProvider.autoDispose<StockAdjustmentController, AsyncValue<void>>((ref) {
  return StockAdjustmentController(ref.watch(stockRepositoryProvider));
});

class CategoryFormController extends StateNotifier<AsyncValue<void>> {
  final StockRepository _repo;
  CategoryFormController(this._repo) : super(const AsyncData(null));

  Future<ProductCategory?> create(ProductCategory draft) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.createCategory(draft);
      state = const AsyncData(null);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final categoryFormControllerProvider =
    StateNotifierProvider.autoDispose<CategoryFormController, AsyncValue<void>>((ref) {
  return CategoryFormController(ref.watch(stockRepositoryProvider));
});
