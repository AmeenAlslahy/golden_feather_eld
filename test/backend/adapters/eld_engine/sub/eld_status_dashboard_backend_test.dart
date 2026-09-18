import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/sub/eld_status_dashboard_backend.dart';
import 'package:golden_feather_eld/backend/http/api_client.dart';
import 'package:golden_feather_eld/backend/http/api_config.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late EldStatusDashboardBackend backend;

  setUp(() {
    dio = Dio();
    adapter = DioAdapter(dio: dio);
    backend = EldStatusDashboardBackend(
      ApiClient(
        config: const ApiConfig(baseUrl: 'https://api.example.com/api'),
        dio: dio,
      ),
    );
  });

  group('EldStatusDashboardBackend.getDashboard', () {
    test('returns dashboard data', () async {
      adapter.onGet(
        '/eld/status',
        (server) => server.reply(200, {
          'currentDutyStatus': 'ON_DUTY',
          'driver': {'id': 101, 'name': 'Ahmed'},
        }),
        queryParameters: {'driverId': 101},
      );

      final result = await backend.getDashboard(
        driverId: const DriverId(101),
      );

      result.tap(onSuccess: (data) {
        expect(data['currentDutyStatus'], 'ON_DUTY');
      });
    });
  });

  group('EldStatusDashboardBackend.updateDutyStatus', () {
    test('sends POST with status and notes', () async {
      adapter.onPost(
        '/eld/status/duty-status',
        (server) => server.reply(200, {'currentDutyStatus': 'DRIVING'}),
        data: {'dutyStatus': 'DRIVING', 'notes': 'Trip started'},
      );

      final result = await backend.updateDutyStatus(
        dutyStatus: 'DRIVING',
        notes: 'Trip started',
      );

      result.tap(onSuccess: (data) {
        expect(data['currentDutyStatus'], 'DRIVING');
      });
    });

    test('works without notes', () async {
      adapter.onPost(
        '/eld/status/duty-status',
        (server) => server.reply(200, {'currentDutyStatus': 'OFF_DUTY'}),
        data: {'dutyStatus': 'OFF_DUTY'},
      );

      final result = await backend.updateDutyStatus(
        dutyStatus: 'OFF_DUTY',
      );

      expect(result.isSuccess, isTrue);
    });
  });

  group('EldStatusDashboardBackend.getWeeklyRecap', () {
    test('returns recap data', () async {
      adapter.onGet(
        '/eld/status/recap',
        (server) => server.reply(200, {
          'cycleUsed': '61:23',
          'cycleRemaining': '08:37',
        }),
      );

      final result = await backend.getWeeklyRecap();

      result.tap(onSuccess: (data) {
        expect(data['cycleUsed'], '61:23');
      });
    });
  });
}
