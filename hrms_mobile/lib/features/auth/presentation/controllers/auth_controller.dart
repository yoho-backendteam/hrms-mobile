import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/auth_repository.dart';
import '../../domain/models/organization_model.dart';
import '../../domain/models/user_model.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  requiresTenantSelection,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final String? selectionToken;
  final List<OrganizationModel> organizations;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.selectionToken,
    this.organizations = const [],
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    String? selectionToken,
    List<OrganizationModel>? organizations,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      selectionToken: selectionToken ?? this.selectionToken,
      organizations: organizations ?? this.organizations,
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthController(repository: repository, storage: storage);
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SecureStorageService _storage;

  AuthController({
    required AuthRepository repository,
    required SecureStorageService storage,
  })  : _repository = repository,
        _storage = storage,
        super(AuthState.initial()) {
    checkAuthSession();
  }

  Future<void> checkAuthSession() async {
    try {
      await _storage.preloadSession();
    } catch (_) {}

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

  Future<Map<String, dynamic>> login({
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

      if (result['requiresTenantSelection'] == true) {
        final orgs = (result['organizations'] as List<OrganizationModel>?) ?? [];
        state = state.copyWith(
          status: AuthStatus.requiresTenantSelection,
          selectionToken: result['selectionToken']?.toString(),
          organizations: orgs,
        );
        return {
          'success': true,
          'requiresTenantSelection': true,
          'organizations': orgs,
          'selectionToken': result['selectionToken'],
        };
      }

      final user = result['user'] as UserModel;
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
      return {'success': true, 'requiresTenantSelection': false, 'user': user};
    } catch (e) {
      final err = e.toString().replaceAll('Exception:', '').trim();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: err,
      );
      return {'success': false, 'error': err};
    }
  }

  Future<bool> selectTenant(String tenantId) async {
    if (state.selectionToken == null) return false;
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final result = await _repository.selectTenant(
        selectionToken: state.selectionToken!,
        tenantId: tenantId,
      );
      final user = result['user'] as UserModel;
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        selectionToken: null,
        organizations: const [],
      );
      return true;
    } catch (e) {
      final err = e.toString().replaceAll('Exception:', '').trim();
      state = state.copyWith(
        status: AuthStatus.requiresTenantSelection,
        errorMessage: err,
      );
      return false;
    }
  }

  Future<bool> switchOrganization(String targetTenantId) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final result = await _repository.switchTenant(targetTenantId: targetTenantId);
      final user = result['user'] as UserModel;
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
      return true;
    } catch (e) {
      final err = e.toString().replaceAll('Exception:', '').trim();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        errorMessage: err,
      );
      return false;
    }
  }

  Future<List<OrganizationModel>> fetchUserOrganizations() async {
    return await _repository.getUserOrganizations();
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
