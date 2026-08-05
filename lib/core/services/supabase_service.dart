import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// Thin wrapper around the Supabase client lifecycle.
///
/// Call [SupabaseService.initialize] once in `main()` before `runApp`.
class SupabaseService {
  SupabaseService._();

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 10,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
}
