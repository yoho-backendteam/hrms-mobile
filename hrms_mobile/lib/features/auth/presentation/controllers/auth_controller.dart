import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../domain/models/user_model.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository: repository);
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController({required AuthRepository repository})
      : _repository = repository,
        super(AuthState.initial()) {
    checkAuthSession();
  }

  Future<void> checkAuthSession() async {
    final hasSession = await _repository.hasValidSession();
    if (!hasSession) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    final user = await _repository.getCurrentUser();
    if (user != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    String? tenantSubdomain,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final result = await _repository.login(
        email: email,
        password: password,
        tenantSubdomain: tenantSubdomain,
      );

      final user = result['user'] as UserModel;
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? location,
  }) async {
    if (state.user == null) return;
    final updated = state.user!.copyWith(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      location: location,
    );
    state = state.copyWith(user: updated);
  }

  Future<void> updateAvatar(String avatarUrl) async {
    if (state.user == null) return;
    final updated = state.user!.copyWith(avatarUrl: avatarUrl);
    state = state.copyWith(user: updated);
  }

  Future<void> removeAvatar() async {
    if (state.user == null) return;
    final updated = state.user!.copyWith(clearAvatar: true);
    state = state.copyWith(user: updated);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
    );
  }
}
