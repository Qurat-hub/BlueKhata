import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
      (ref) => AuthRepository(),
);

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider).valueOrNull;
  return authState?.session?.user ??
      ref.watch(authRepositoryProvider).currentUser;
});

class AuthStateModel {
  final bool loading;
  final String? error;

  const AuthStateModel({
    this.loading = false,
    this.error,
  });

  AuthStateModel copyWith({
    bool? loading,
    String? error,
  }) {
    return AuthStateModel(
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class AuthController extends StateNotifier<AuthStateModel> {
  final AuthRepository _repo;

  AuthController(this._repo) : super(const AuthStateModel());

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      loading: true,
      error: null,
    );

    try {
      await _repo.signIn(
        email: email,
        password: password,
      );

      await _repo.ensureProfile();

      state = state.copyWith(
        loading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );

      print("LOGIN ERROR:");
      print(e);

      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      loading: true,
      error: null,
    );

    try {
      await _repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      state = state.copyWith(
        loading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );

      return false;
    }
  }

  Future<void> forgotPassword(
      String email,
      ) async {
    state = state.copyWith(
      loading: true,
      error: null,
    );

    try {
      await _repo.resetPassword(email);

      state = state.copyWith(
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _repo.signOut();
  }
}

final authControllerProvider =
StateNotifierProvider<AuthController, AuthStateModel>(
      (ref) {
    return AuthController(
      ref.watch(authRepositoryProvider),
    );
  },
);