import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/config/app_environment.dart';

void main() {
  group('AppEnvironmentConfig', () {
    test('should parse mock environment correctly', () async {
      await AppEnvironmentConfig.init(testEnv: {
        'TRACCAR_ENVIRONMENT': 'mock',
      });
      expect(AppEnvironmentConfig.current, AppEnvironment.mock);
      expect(AppEnvironmentConfig.isValidTemporaryTraccarConfig,
          isTrue); // Not temporaryTraccar, so true
    });

    test('should parse temporaryTraccar environment correctly', () async {
      await AppEnvironmentConfig.init(testEnv: {
        'TRACCAR_ENVIRONMENT': 'temporaryTraccar',
        'API_BASE_URL': 'https://test.traccar.com',
        'TRACCAR_USERNAME': 'testuser',
        'TRACCAR_PASSWORD': 'testpass',
        'TRACCAR_DEVICE_ID': '1',
        'TRACCAR_DEVICE_UNIQUE_ID': '1234567890',
      });
      expect(AppEnvironmentConfig.current, AppEnvironment.temporaryTraccar);

      expect(AppEnvironmentConfig.apiBaseUrl, 'https://test.traccar.com');
      expect(AppEnvironmentConfig.traccarUsername, 'testuser');
      expect(AppEnvironmentConfig.traccarPassword, 'testpass');
      expect(AppEnvironmentConfig.traccarDeviceId, '1');
      expect(AppEnvironmentConfig.traccarDeviceUniqueId, '1234567890');

      expect(AppEnvironmentConfig.isValidTemporaryTraccarConfig, isTrue);
    });

    test('should invalidate temporaryTraccar if missing fields', () async {
      await AppEnvironmentConfig.init(testEnv: {
        'TRACCAR_ENVIRONMENT': 'temporaryTraccar',
        'API_BASE_URL': '',
        'TRACCAR_USERNAME': 'testuser',
      });
      expect(AppEnvironmentConfig.current, AppEnvironment.temporaryTraccar);
      expect(AppEnvironmentConfig.isValidTemporaryTraccarConfig, isFalse);
    });

    test('should fallback to development if empty env', () async {
      await AppEnvironmentConfig.init(testEnv: {});
      expect(AppEnvironmentConfig.current, AppEnvironment.development);
    });
  });
}
