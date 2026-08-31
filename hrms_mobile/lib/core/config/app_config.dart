class AppConfig {
  AppConfig._();

  /// Default API Gateway base URL.
  /// On Android emulator, localhost is mapped to 10.0.2.2:3000.
  /// On iOS simulator or web/desktop, localhost is 127.0.0.1:3000.
  static const String defaultApiBaseUrl = 'http://10.0.2.2:3000';
  
  static String apiBaseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultApiBaseUrl,
  );

  static const String appName = 'HRMS Enterprise';
  static const String appVersion = '1.0.0';
  
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;
}
