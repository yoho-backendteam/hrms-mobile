import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/models/organization_model.dart';
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
    if (tenantSubdomain != null && tenantSubdomain.isNotEmpty) {
      await _storage.saveTenant(tenantSubdomain: tenantSubdomain);
    }

    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {
        'email': email.trim(),
        'password': password,
        if (tenantSubdomain != null && tenantSubdomain.isNotEmpty) 'tenantCode': tenantSubdomain,
      },
    );

    // Check if multi-tenant selection is required
    if (response['requiresTenantSelection'] == true) {
      final rawOrgs = response['organizations'] as List? ?? [];
      final organizations = rawOrgs
          .map((o) => OrganizationModel.fromJson(o is Map<String, dynamic> ? o : {}))
          .toList();

      return {
        'requiresTenantSelection': true,
        'selectionToken': response['selectionToken']?.toString(),
        'organizations': organizations,
      };
    }

    final data = response['data'] ?? response;
    final token = data['token'] ?? data['accessToken'] ?? data['access_token'];
    final refreshToken = data['refreshToken'] ?? data['refresh_token'];
    final userRaw = response['user'] ?? data['user'] ?? data;
    final tenantRaw = response['tenant'] ?? data['tenant'];

    if (token != null) {
      await _storage.saveTokens(
        accessToken: token.toString(),
        refreshToken: refreshToken?.toString(),
      );
    }

    final user = UserModel.fromJson(userRaw is Map<String, dynamic> ? userRaw : {});
    await _storage.saveUserData(jsonEncode(user.toJson()));
    await _storage.savePermissions(user.permissions);

    final resolvedTenantCode = tenantRaw?['code'] ?? tenantRaw?['domain'] ?? user.tenantId ?? tenantSubdomain ?? '';
    final resolvedTenantId = tenantRaw?['id'] ?? user.tenantId;

    await _storage.saveTenant(
      tenantSubdomain: resolvedTenantCode.toString(),
      tenantId: resolvedTenantId?.toString(),
    );

    return {
      'requiresTenantSelection': false,
      'user': user,
      'token': token,
      'refreshToken': refreshToken,
      'tenant': tenantRaw,
    };
  }

  Future<Map<String, dynamic>> selectTenant({
    required String selectionToken,
    required String tenantId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.selectTenant,
      data: {
        'selectionToken': selectionToken,
        'tenantId': tenantId,
      },
    );

    final data = response['data'] ?? response;
    final token = data['token'] ?? data['accessToken'] ?? data['access_token'];
    final refreshToken = data['refreshToken'] ?? data['refresh_token'];
    final userRaw = response['user'] ?? data['user'] ?? data;
    final tenantRaw = response['tenant'] ?? data['tenant'];

    if (token != null) {
      await _storage.saveTokens(
        accessToken: token.toString(),
        refreshToken: refreshToken?.toString(),
      );
    }

    final user = UserModel.fromJson(userRaw is Map<String, dynamic> ? userRaw : {});
    await _storage.saveUserData(jsonEncode(user.toJson()));
    await _storage.savePermissions(user.permissions);

    final resolvedTenantCode = tenantRaw?['code'] ?? tenantRaw?['domain'] ?? tenantId;

    await _storage.saveTenant(
      tenantSubdomain: resolvedTenantCode.toString(),
      tenantId: tenantId,
    );

    return {
      'user': user,
      'token': token,
      'refreshToken': refreshToken,
      'tenant': tenantRaw,
    };
  }

  Future<Map<String, dynamic>> switchTenant({
    required String targetTenantId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.switchTenant,
      data: {
        'tenantId': targetTenantId,
      },
    );

    final data = response['data'] ?? response;
    final token = data['token'] ?? data['accessToken'] ?? data['access_token'];
    final refreshToken = data['refreshToken'] ?? data['refresh_token'];
    final userRaw = response['user'] ?? data['user'] ?? data;
    final tenantRaw = response['tenant'] ?? data['tenant'];

    if (token != null) {
      await _storage.saveTokens(
        accessToken: token.toString(),
        refreshToken: refreshToken?.toString(),
      );
    }

    final user = UserModel.fromJson(userRaw is Map<String, dynamic> ? userRaw : {});
    await _storage.saveUserData(jsonEncode(user.toJson()));
    await _storage.savePermissions(user.permissions);

    final resolvedTenantCode = tenantRaw?['code'] ?? tenantRaw?['domain'] ?? targetTenantId;

    await _storage.saveTenant(
      tenantSubdomain: resolvedTenantCode.toString(),
      tenantId: targetTenantId,
    );

    return {
      'user': user,
      'token': token,
      'refreshToken': refreshToken,
      'tenant': tenantRaw,
    };
  }

  Future<List<OrganizationModel>> getUserOrganizations() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.userOrganizations);
      final list = (response['data'] ?? response) as List? ?? [];
      return list.map((o) => OrganizationModel.fromJson(o is Map<String, dynamic> ? o : {})).toList();
    } catch (_) {
      return [];
    }
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
        const Duration(milliseconds: 800),
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

  Future<bool> hasValidSession() async {
    final token = await _storage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>> verifySessionOtp({
    required String challengeId,
    String? code,
    String? otp,
    String? tenantSubdomain,
  }) async {
    final effectiveCode = code ?? otp ?? '';
    final response = await _apiClient.post(
      ApiEndpoints.verifySessionOtp,
      data: {
        'challengeId': challengeId,
        'code': effectiveCode,
      },
    );

    final data = response['data'] ?? response;
    final token = data['token'] ?? data['accessToken'] ?? data['access_token'];
    final refreshToken = data['refreshToken'] ?? data['refresh_token'];
    final userRaw = response['user'] ?? data['user'] ?? data;

    if (token != null) {
      await _storage.saveTokens(
        accessToken: token.toString(),
        refreshToken: refreshToken?.toString(),
      );
    }

    final user = UserModel.fromJson(userRaw is Map<String, dynamic> ? userRaw : {});
    await _storage.saveUserData(jsonEncode(user.toJson()));
    await _storage.savePermissions(user.permissions);

    return {
      'user': user,
      'token': token,
      'refreshToken': refreshToken,
    };
  }

  Future<Map<String, dynamic>> resendSessionOtp({
    required String challengeId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.resendSessionOtp,
      data: {
        'challengeId': challengeId,
      },
    );
    return response is Map<String, dynamic> ? response : {'success': true};
  }

  Future<void> logout() async {
    await _storage.clearSession();
  }
}
