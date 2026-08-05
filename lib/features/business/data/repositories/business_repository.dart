import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/business.dart';

class BusinessRepository {
  final SupabaseClient _client;
  BusinessRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  Future<List<Business>> fetchMyBusinesses() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // Businesses the user owns OR is a member of (business_members join).
    final owned = await _client
        .from('businesses')
        .select()
        .eq('owner_id', userId)
        .eq('is_archived', false)
        .order('created_at');

    return (owned as List).map((m) => Business.fromMap(m)).toList();
  }

  Future<Business> createBusiness(Business business) async {
    print("========== Supabase Current User ==========");
    print(_client.auth.currentUser?.id);

    print("========== Current Session ==========");
    print(_client.auth.currentSession);

    print("========== Business Data ==========");
    print(business.toInsertMap());

    final result = await _client
        .from('businesses')
        .insert(business.toInsertMap())
        .select()
        .single();
    return Business.fromMap(result);
  }

  Future<void> archiveBusiness(String businessId) async {
    await _client.from('businesses').update({'is_archived': true}).eq('id', businessId);
  }

  Future<void> restoreBusiness(String businessId) async {
    await _client.from('businesses').update({'is_archived': false}).eq('id', businessId);
  }

  Future<void> deleteBusiness(String businessId) async {
    // Soft delete only — hard delete is reserved for admin/audit workflows.
    await _client.from('businesses').update({
      'is_deleted': true,
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', businessId);
  }
}
