import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/customer.dart';

class CustomerRepository {
  final SupabaseClient _client;
  CustomerRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  Future<List<Customer>> fetchCustomers({
    required String businessId,
    String? query,
  }) async {
    var builder = _client
        .from('customers')
        .select()
        .eq('business_id', businessId)
        .eq('is_deleted', false);

    if (query != null && query.trim().isNotEmpty) {
      builder = builder.ilike('name', '%${query.trim()}%');
    }

    final result = await builder.order('name');
    return (result as List).map((m) => Customer.fromMap(m)).toList();
  }

  Future<Customer> fetchCustomer(String customerId) async {
    final result = await _client.from('customers').select().eq('id', customerId).single();
    return Customer.fromMap(result);
  }

  Future<Customer> createCustomer(Customer customer) async {
    final result =
        await _client.from('customers').insert(customer.toInsertMap()).select().single();
    return Customer.fromMap(result);
  }

  Future<Customer> updateCustomer(String customerId, Map<String, dynamic> changes) async {
    final result =
        await _client.from('customers').update(changes).eq('id', customerId).select().single();
    return Customer.fromMap(result);
  }

  Future<void> softDeleteCustomer(String customerId) async {
    await _client.from('customers').update({
      'is_deleted': true,
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', customerId);
  }

  Future<void> restoreCustomer(String customerId) async {
    await _client
        .from('customers')
        .update({'is_deleted': false, 'deleted_at': null}).eq('id', customerId);
  }

  Future<void> toggleFavorite(String customerId, bool isFavorite) async {
    await _client.from('customers').update({'is_favorite': isFavorite}).eq('id', customerId);
  }
}
