import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Register a new user
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
      },
    );
  }


  /// Login existing user
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Forgot Password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
    );
  }

  /// Logout
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  /// Create user profile if it doesn't already exist
  Future<void> ensureProfile() async {
    final user = currentUser;

    if (user == null) return;

    final existing = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      await _createProfile(
        id: user.id,
        fullName: user.userMetadata?['full_name'] ?? '',
      );
    }
  }

  Future<void> _createProfile({
    required String id,
    required String fullName,
  }) async {
    await _client.from('profiles').insert({
      'id': id,
      'full_name': fullName,
    });
  }
}