import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

enum AppEnvironment {
  mock,
  development,
  staging,
  production,
  temporaryTraccar,
}

class AppEnvironmentConfig {
  static AppEnvironment _current = AppEnvironment.development;
  static AppEnvironment get current => _current;
  
  static Map<String, String>? _testEnv;

  static Future<void> init({Map<String, String>? testEnv}) async {
    _testEnv = testEnv;
    try {
      if (testEnv == null) {
        await dotenv.load(fileName: '.env');
      }
    } catch (e) {
      AppLogger.warning('Failed to load .env file. Falling back to dart-define or default.');
    }

    final envString = const String.fromEnvironment('APP_ENV', defaultValue: '') != '' 
        ? const String.fromEnvironment('APP_ENV') 
        : (_getEnv('TRACCAR_ENVIRONMENT') ?? 'development');
    
    switch (envString) {
      case 'mock':
        _current = AppEnvironment.mock;
        break;
      case 'staging':
        _current = AppEnvironment.staging;
        break;
      case 'production':
        _current = AppEnvironment.production;
        break;
      case 'temporaryTraccar':
        _current = AppEnvironment.temporaryTraccar;
        break;
      case 'development':
      default:
        _current = AppEnvironment.development;
    }
    
    AppLogger.info('Environment initialized as: ${_current.name}');
  }

  static String? _getEnv(String key) {
    if (_testEnv != null) return _testEnv![key];
    return dotenv.env[key];
  }

  // Traccar Settings
  static String get apiBaseUrl => _getEnv('API_BASE_URL') ?? _getEnv('API_BASE_URL') ?? '';
  static String get traccarUsername => _getEnv('TRACCAR_USERNAME') ?? '';
  static String get traccarPassword => _getEnv('TRACCAR_PASSWORD') ?? '';
  static String get traccarDeviceId => _getEnv('TRACCAR_DEVICE_ID') ?? '';
  static String get traccarDeviceUniqueId => _getEnv('TRACCAR_DEVICE_UNIQUE_ID') ?? '';
  
  static bool get isValidTemporaryTraccarConfig {
    if (current != AppEnvironment.temporaryTraccar) return true;
    
    final valid = apiBaseUrl.isNotEmpty &&
        traccarUsername.isNotEmpty &&
        traccarPassword.isNotEmpty &&
        traccarDeviceId.isNotEmpty &&
        traccarDeviceUniqueId.isNotEmpty;
        
    if (!valid) {
      AppLogger.error('Invalid Temporary Traccar Config! Check .env variables.');
    }
    return valid;
  }
}
