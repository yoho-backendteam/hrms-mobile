import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  AppConfig._();

  /// Default API Gateway base URL.
  /// On Android emulator: 10.0.2.2:3000
  /// On local machine / web: http://localhost:3000
  /// On LAN / physical device: http://10.120.120.240:3000
  static String get defaultApiBaseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000';
      if (Platform.isIOS) return 'http://localhost:3000';
    } catch (_) {}
    return 'http://10.120.120.240:3000';
  }

  static String apiBaseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  ).isNotEmpty
      ? const String.fromEnvironment('API_BASE_URL')
      : defaultApiBaseUrl;

  static const String appName = 'HRMS Enterprise';
  static const String appVersion = '1.0.0';

  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;
}
