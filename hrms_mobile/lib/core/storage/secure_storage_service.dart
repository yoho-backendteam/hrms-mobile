import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static const String _keyAccessToken = 'hrms_access_token';
  static const String _keyRefreshToken = 'hrms_refresh_token';
  static const String _keyTenant = 'hrms_tenant';
  static const String _keyTenantId = 'hrms_tenant_id';
  static const String _keyUser = 'hrms_user_json';
  static const String _keyPermissions = 'hrms_user_permissions';
  static const String _keyBiometricEnabled = 'hrms_biometric_enabled';
  static const String _keyServerUrl = 'hrms_server_url';

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  Future<void> saveTenant({
    required String tenantSubdomain,
    String? tenantId,
  }) async {
    await _storage.write(key: _keyTenant, value: tenantSubdomain);
    if (tenantId != null) {
      await _storage.write(key: _keyTenantId, value: tenantId);
    }
  }

  Future<String?> getTenant() async {
    return await _storage.read(key: _keyTenant);
  }

  Future<String?> getTenantId() async {
    return await _storage.read(key: _keyTenantId);
  }

  Future<void> saveUserData(String userJson) async {
    await _storage.write(key: _keyUser, value: userJson);
  }

  Future<String?> getUserData() async {
    return await _storage.read(key: _keyUser);
  }

  Future<void> savePermissions(List<String> permissions) async {
    await _storage.write(key: _keyPermissions, value: permissions.join(','));
  }

  Future<List<String>> getPermissions() async {
    final raw = await _storage.read(key: _keyPermissions);
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  Future<void> saveServerUrl(String url) async {
    await _storage.write(key: _keyServerUrl, value: url);
  }

  Future<String?> getServerUrl() async {
    return await _storage.read(key: _keyServerUrl);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUser);
    await _storage.delete(key: _keyPermissions);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
