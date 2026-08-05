import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/inventory_log.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';

class StockRepository {
  final SupabaseClient _client;
  StockRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  // ---------------------------------------------------------------------
  // Products
  // ---------------------------------------------------------------------

  Future<List<Product>> fetchProducts({
    required String businessId,
    String? query,
    String? categoryId,
  }) async {
    var builder = _client
        .from('products')
        .select()
        .eq('business_id', businessId)
        .eq('is_deleted', false);

    if (categoryId != null) {
      builder = builder.eq('category_id', categoryId);
    }
    if (query != null && query.trim().isNotEmpty) {
      builder = builder.or('name.ilike.%${query.trim()}%,sku.ilike.%${query.trim()}%,'
          'barcode.ilike.%${query.trim()}%');
    }

    final result = await builder.order('name');
    return (result as List).map((m) => Product.fromMap(m)).toList();
  }

  Future<Product> fetchProduct(String productId) async {
    final result = await _client.from('products').select().eq('id', productId).single();
    return Product.fromMap(result);
  }

  Future<Product?> fetchProductByBarcode({required String businessId, required String barcode}) async {
    final result = await _client
        .from('products')
        .select()
        .eq('business_id', businessId)
        .eq('barcode', barcode)
        .eq('is_deleted', false)
        .maybeSingle();
    return result == null ? null : Product.fromMap(result);
  }

  Future<List<Product>> fetchLowStock(String businessId) async {
    // Postgrest can't compare two columns of the same row in a single
    // .filter() call, so pull the (already business/is_deleted scoped) set
    // and filter low-stock client-side — this table is small per business.
    final result = await _client
        .from('products')
        .select()
        .eq('business_id', businessId)
        .eq('is_deleted', false);
    return (result as List)
        .map((m) => Product.fromMap(m))
        .where((p) => p.isLowStock)
        .toList();
  }

  /// Creates the product row, then — if [openingStock] is greater than
  /// zero — writes one `inventory_logs` 'purchase' entry so the opening
  /// balance is auditable from day one, exactly like every other stock
  /// change. `products.stock_quantity` itself is never written directly.
  Future<Product> createProduct(Product draft, {double openingStock = 0}) async {
    final userId = _client.auth.currentUser!.id;
    final inserted =
        await _client.from('products').insert(draft.toInsertMap()).select().single();
    final created = Product.fromMap(inserted);

    if (openingStock > 0) {
      await _client.from('inventory_logs').insert(InventoryLog(
            id: '',
            businessId: draft.businessId,
            productId: created.id,
            changeType: StockChangeType.purchase,
            quantityDelta: openingStock,
            note: 'Opening stock',
            createdAt: DateTime.now(),
            createdBy: userId,
          ).toInsertMap(createdByUserId: userId));
      return fetchProduct(created.id);
    }
    return created;
  }

  Future<Product> updateProduct(String productId, Product changes) async {
    final result = await _client
        .from('products')
        .update(changes.toUpdateMap())
        .eq('id', productId)
        .select()
        .single();
    return Product.fromMap(result);
  }

  Future<void> softDeleteProduct(String productId) async {
    await _client.from('products').update({'is_deleted': true}).eq('id', productId);
  }

  // ---------------------------------------------------------------------
  // Inventory logs (the only writable path to stock_quantity)
  // ---------------------------------------------------------------------

  Future<List<InventoryLog>> fetchLogsForProduct(String productId) async {
    final result = await _client
        .from('inventory_logs')
        .select()
        .eq('product_id', productId)
        .order('created_at', ascending: false);
    return (result as List).map((m) => InventoryLog.fromMap(m)).toList();
  }

  /// [quantityDelta] is signed — positive adds stock (purchase/return),
  /// negative removes it (sale, or a negative adjustment). The
  /// `trg_inventory_logs_apply` trigger applies it to
  /// `products.stock_quantity` atomically.
  Future<void> adjustStock({
    required String businessId,
    required String productId,
    required StockChangeType changeType,
    required double quantityDelta,
    String? note,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('inventory_logs').insert(InventoryLog(
          id: '',
          businessId: businessId,
          productId: productId,
          changeType: changeType,
          quantityDelta: quantityDelta,
          note: note,
          createdAt: DateTime.now(),
          createdBy: userId,
        ).toInsertMap(createdByUserId: userId));
  }

  // ---------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------

  Future<List<ProductCategory>> fetchCategories(String businessId) async {
    final result =
        await _client.from('categories').select().eq('business_id', businessId).order('name');
    return (result as List).map((m) => ProductCategory.fromMap(m)).toList();
  }

  Future<ProductCategory> createCategory(ProductCategory draft) async {
    final result =
        await _client.from('categories').insert(draft.toInsertMap()).select().single();
    return ProductCategory.fromMap(result);
  }
}
