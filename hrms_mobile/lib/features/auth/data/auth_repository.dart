import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(apiClient: apiClient, storage: storage);
});

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthRepository({
    required ApiClient apiClient,
    required SecureStorageService storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? tenantSubdomain,
  }) async {
    final effectiveTenant = tenantSubdomain ?? 'csktech';

    // Store tenant subdomain before sending request so TenantInterceptor attaches it
    await _storage.saveTenant(tenantSubdomain: effectiveTenant);

    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    final data = response['data'] ?? response;
    final token = data['token'] ?? data['accessToken'] ?? data['access_token'];
    final refreshToken = data['refreshToken'] ?? data['refresh_token'];
    final userRaw = data['user'] ?? data;

    if (token != null) {
      await _storage.saveTokens(
        accessToken: token.toString(),
        refreshToken: refreshToken?.toString(),
      );
    }

    final user = UserModel.fromJson(userRaw is Map<String, dynamic> ? userRaw : {});
    await _storage.saveUserData(jsonEncode(user.toJson()));
    await _storage.savePermissions(user.permissions);

    if (user.tenantId != null) {
      await _storage.saveTenant(
        tenantSubdomain: effectiveTenant,
        tenantId: user.tenantId,
      );
    }

    return {
      'user': user,
      'token': token,
      'refreshToken': refreshToken,
    };
  }

  Future<UserModel?> getCurrentUser() async {
    final userJson = await _storage.getUserData();
    if (userJson != null && userJson.isNotEmpty) {
      try {
        return UserModel.fromJson(jsonDecode(userJson));
      } catch (_) {}
    }

    try {
      final response = await _apiClient.get(ApiEndpoints.userAuthorization).timeout(
        const Duration(seconds: 2),
      );
      final data = response['data'] ?? response;
      if (data is Map<String, dynamic>) {
        final user = UserModel.fromJson(data);
        await _storage.saveUserData(jsonEncode(user.toJson()));
        await _storage.savePermissions(user.permissions);
        return user;
      }
    } catch (_) {}

    return null;
  }

  Future<void> logout() async {
    await _storage.clearSession();
  }

  Future<bool> hasValidSession() async {
    final token = await _storage.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
