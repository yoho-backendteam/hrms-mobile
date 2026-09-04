import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  final Map<String, String?> _memoryCache = {};

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: false,
                resetOnError: true,
              ),
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
    _memoryCache[_keyAccessToken] = accessToken;
    if (refreshToken != null) _memoryCache[_keyRefreshToken] = refreshToken;
    try {
      await _storage.write(key: _keyAccessToken, value: accessToken);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _storage.write(key: _keyRefreshToken, value: refreshToken);
      }
    } catch (_) {}
  }

  Future<String?> getAccessToken() async {
    if (_memoryCache.containsKey(_keyAccessToken)) {
      return _memoryCache[_keyAccessToken];
    }
    try {
      final val = await _storage.read(key: _keyAccessToken).timeout(
        const Duration(milliseconds: 300),
        onTimeout: () => null,
      );
      _memoryCache[_keyAccessToken] = val;
      return val;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    if (_memoryCache.containsKey(_keyRefreshToken)) {
      return _memoryCache[_keyRefreshToken];
    }
    try {
      final val = await _storage.read(key: _keyRefreshToken).timeout(
        const Duration(milliseconds: 300),
        onTimeout: () => null,
      );
      _memoryCache[_keyRefreshToken] = val;
      return val;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTenant({
    required String tenantSubdomain,
    String? tenantId,
  }) async {
    _memoryCache[_keyTenant] = tenantSubdomain;
    if (tenantId != null) _memoryCache[_keyTenantId] = tenantId;
    try {
      await _storage.write(key: _keyTenant, value: tenantSubdomain);
      if (tenantId != null) {
        await _storage.write(key: _keyTenantId, value: tenantId);
      }
    } catch (_) {}
  }

  Future<String?> getTenant() async {
    if (_memoryCache.containsKey(_keyTenant)) {
      return _memoryCache[_keyTenant];
    }
    try {
      final val = await _storage.read(key: _keyTenant).timeout(
        const Duration(milliseconds: 300),
        onTimeout: () => null,
      );
      _memoryCache[_keyTenant] = val;
      return val;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getTenantId() async {
    if (_memoryCache.containsKey(_keyTenantId)) {
      return _memoryCache[_keyTenantId];
    }
    try {
      final val = await _storage.read(key: _keyTenantId).timeout(
        const Duration(milliseconds: 300),
        onTimeout: () => null,
      );
      _memoryCache[_keyTenantId] = val;
      return val;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserData(String userJson) async {
    _memoryCache[_keyUser] = userJson;
    try {
      await _storage.write(key: _keyUser, value: userJson);
    } catch (_) {}
  }

  Future<String?> getUserData() async {
    if (_memoryCache.containsKey(_keyUser)) {
      return _memoryCache[_keyUser];
    }
    try {
      final val = await _storage.read(key: _keyUser).timeout(
        const Duration(milliseconds: 300),
        onTimeout: () => null,
      );
      _memoryCache[_keyUser] = val;
      return val;
    } catch (_) {
      return null;
    }
  }

  Future<void> savePermissions(List<String> permissions) async {
    final joined = permissions.join(',');
    _memoryCache[_keyPermissions] = joined;
    try {
      await _storage.write(key: _keyPermissions, value: joined);
    } catch (_) {}
  }

  Future<List<String>> getPermissions() async {
    if (_memoryCache.containsKey(_keyPermissions)) {
      final raw = _memoryCache[_keyPermissions];
      if (raw == null || raw.isEmpty) return [];
      return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    try {
      final raw = await _storage.read(key: _keyPermissions).timeout(
        const Duration(milliseconds: 300),
        onTimeout: () => null,
      );
      _memoryCache[_keyPermissions] = raw;
      if (raw == null || raw.isEmpty) return [];
      return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _memoryCache[_keyBiometricEnabled] = enabled.toString();
    try {
      await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
    } catch (_) {}
  }

  Future<bool> isBiometricEnabled() async {
    if (_memoryCache.containsKey(_keyBiometricEnabled)) {
      return _memoryCache[_keyBiometricEnabled] == 'true';
    }
    try {
      final val = await _storage.read(key: _keyBiometricEnabled).timeout(
        const Duration(milliseconds: 300),
        onTimeout: () => null,
      );
      _memoryCache[_keyBiometricEnabled] = val;
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> saveServerUrl(String url) async {
    _memoryCache[_keyServerUrl] = url;
    try {
      await _storage.write(key: _keyServerUrl, value: url);
    } catch (_) {}
  }

  Future<String?> getServerUrl() async {
    if (_memoryCache.containsKey(_keyServerUrl)) {
      return _memoryCache[_keyServerUrl];
    }
    try {
      final val = await _storage.read(key: _keyServerUrl).timeout(
        const Duration(milliseconds: 300),
        onTimeout: () => null,
      );
      _memoryCache[_keyServerUrl] = val;
      return val;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    _memoryCache.remove(_keyAccessToken);
    _memoryCache.remove(_keyRefreshToken);
    _memoryCache.remove(_keyUser);
    _memoryCache.remove(_keyPermissions);
    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyUser);
      await _storage.delete(key: _keyPermissions);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    _memoryCache.clear();
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
