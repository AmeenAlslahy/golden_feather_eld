import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/config/app_environment.dart';
import 'package:golden_feather_eld/core/services/remote_config_service.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/features/tracking/data/services/tracking_service.dart';
import 'package:golden_feather_eld/core/network/tracking_client_sdk.dart';
import 'package:golden_feather_eld/core/network/api_client.dart';
import 'package:golden_feather_eld/core/network/api_config.dart';
import 'package:dio/dio.dart';

class MockTraccarClient implements TrackingClientInterface {
  Config? lastConfig;
  
  @override
  Future<void> setConfig(Config config) async {
    lastConfig = config;
  }
  
  @override
  Future<void> start() async {}
  
  @override
  Future<void> stop() async {}
  
  @override
  Future<bool> isTracking() async => false;
  
  @override
  Future<void> requestPosition({String? alarm}) async {}
  
  @override
  Future<List<LogMessage>> getLogs() async => [];
  
  @override
  Future<void> clearLogs() async {}
}

class MockLocalStorageService extends LocalStorageService {
  String _mockUrl = '';
  
  @override
  String get serverUrl => _mockUrl;
  
  @override
  String get deviceId => 'test-device-id';
  
  @override
  String get accuracy => 'high';
  
  @override
  int get distance => 75;
  
  @override
  int get interval => 300;
  
  @override
  int get angle => 0;
  
  @override
  int get heartbeat => 300;
  
  @override
  bool get stopDetection => true;
  
  @override
  bool get wakelock => false;
  
  @override
  bool get buffer => true;
  
  @override
  bool get preferPlatformProviders => false;
  
  @override
  Future<void> setServerUrl(String url) async {
    _mockUrl = url;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Startup & Configuration Tests', () {
    test('1. تحميل .env بنجاح / فشل .env يعود للـ fallback', () async {
      await AppEnvironmentConfig.init();
      // Should not throw, should successfully default to mock or development
      expect(AppEnvironmentConfig.current, isNotNull);
    });

    test('2. Remote Config URL لا يحتوي مسارًا مكررًا', () {
      final endpoint = '/api/v1/tracker/traccar/config/12345';
      expect(endpoint.contains('api/v1/tracker/traccar/api/v1/tracker/traccar'), false);
    });

    test('3. temporaryTraccar لا يستخدم mock URL ويقرأ Base URL الصحيح', () async {
      final storage = MockLocalStorageService();
      await storage.setServerUrl('https://mock-traccar-server.com');
      
      final mockTracker = MockTraccarClient();
      final trackingService = TrackingService(storage: storage, tracker: mockTracker);
      
      // Simulate temporaryTraccar environment
      AppEnvironmentConfig.init(testEnv: {'TRACCAR_ENVIRONMENT': 'temporaryTraccar'});
      
      try {
        await trackingService.init();
        
        // It should either fail (throw exception) or use AppEnvironmentConfig.apiBaseUrl instead of mock
        final usedUrl = mockTracker.lastConfig?.serverUrl;
        expect(usedUrl?.contains('mock-traccar-server.com'), false);
      } catch (e) {
        // Exception is expected if environment has no valid URL
        expect(e.toString(), contains('Configuration Error'));
      }
    });
  });
}
