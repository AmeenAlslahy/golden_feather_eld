import '../config/app_environment.dart';

class ApiConfig {
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  const ApiConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
  });

  factory ApiConfig.fromEnvironment() {
    String baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (baseUrl.isEmpty) {
      baseUrl = AppEnvironmentConfig.apiBaseUrl;
    }
    return ApiConfig(baseUrl: baseUrl);
  }
}
