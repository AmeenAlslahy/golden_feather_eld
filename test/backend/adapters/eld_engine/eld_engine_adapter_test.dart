import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/eld_engine_adapter.dart';
import 'package:golden_feather_eld/backend/core/backend_kind.dart';
import 'package:golden_feather_eld/backend/http/api_client.dart';
import 'package:golden_feather_eld/backend/http/api_config.dart';

void main() {
  late EldEngineAdapter adapter;

  setUp(() {
    final client = ApiClient(
      config: const ApiConfig(baseUrl: 'https://api.example.com/api'),
      dio: Dio(),
    );
    adapter = EldEngineAdapter.create(
      baseUrl: 'https://api.example.com/api',
      apiClient: client,
    );
  });

  group('EldEngineAdapter — identity', () {
    test('has eldEngine kind', () {
      expect(adapter.identity.kind, BackendKind.eldEngine);
      expect(adapter.isMock, isFalse);
    });

    test('identity url matches input', () {
      expect(adapter.identity.baseUrl, 'https://api.example.com/api');
    });
  });

  group('EldEngineAdapter — contracts all non-null', () {
    test('all 20 contracts are exposed', () {
      expect(adapter.account, isNotNull);
      expect(adapter.statusDashboard, isNotNull);
      expect(adapter.rulesScreen, isNotNull);
      expect(adapter.dailyLogs, isNotNull);
      expect(adapter.dutyStatus, isNotNull);
      expect(adapter.driverSession, isNotNull);
      expect(adapter.dvir, isNotNull);
      expect(adapter.inspection, isNotNull);
      expect(adapter.unidentifiedEvents, isNotNull);
      expect(adapter.vehicle, isNotNull);
      expect(adapter.hardware, isNotNull);
      expect(adapter.rulesEngine, isNotNull);
      expect(adapter.driverRules, isNotNull);
      expect(adapter.logTransfer, isNotNull);
      expect(adapter.health, isNotNull);
      expect(adapter.reports, isNotNull);
      expect(adapter.stats, isNotNull);
      expect(adapter.compliance, isNotNull);
      expect(adapter.config, isNotNull);
      expect(adapter.fleetDashboard, isNotNull);
    });
  });

  group('EldEngineAdapter — dispose', () {
    test('completes without errors', () async {
      await expectLater(adapter.dispose(), completes);
    });
  });
}
