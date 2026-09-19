import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/sub/eld_status_dashboard_backend.dart';
import 'package:golden_feather_eld/backend/http/api_client.dart';
import 'package:golden_feather_eld/backend/http/api_config.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/duty_status/weekly_recap.dart';
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
    test('returns dashboard data typed as StatusDashboard', () async {
      adapter.onGet(
        '/eld/status',
        (server) => server.reply(200, {
          'currentDutyStatus': 'ON_DUTY',
          'driver': {'id': 101, 'name': 'Ahmed', 'displayText': 'A.'},
        }),
        queryParameters: {'driverId': 101},
      );

      final result = await backend.getDashboard(
        driverId: const DriverId(101),
      );

      result.tap(onSuccess: (StatusDashboard data) {
        expect(data.currentDutyStatus, equals(DutyStatusCode.onDuty));
        expect(data.driver.id, equals(const DriverId(101)));
      });
      expect(result.isSuccess, isTrue);
    });
  });

  group('EldStatusDashboardBackend.updateDutyStatus', () {
    test('sends POST with dutyStatus wire value and notes', () async {
      adapter.onPost(
        '/eld/status/duty-status',
        (server) => server.reply(200, {'currentDutyStatus': 'DRIVING'}),
        data: {'dutyStatus': 'DRIVING', 'notes': 'Trip started'},
      );

      final result = await backend.updateDutyStatus(
        status: DutyStatusCode.driving,
        notes: 'Trip started',
      );

      result.tap(onSuccess: (StatusDashboard data) {
        expect(data.currentDutyStatus, equals(DutyStatusCode.driving));
      });
      expect(result.isSuccess, isTrue);
    });

    test('works without notes', () async {
      adapter.onPost(
        '/eld/status/duty-status',
        (server) => server.reply(200, {'currentDutyStatus': 'OFF_DUTY'}),
        data: {'dutyStatus': 'OFF_DUTY'},
      );

      final result = await backend.updateDutyStatus(
        status: DutyStatusCode.offDuty,
      );

      result.tap(onSuccess: (StatusDashboard data) {
        expect(data.currentDutyStatus, equals(DutyStatusCode.offDuty));
      });
      expect(result.isSuccess, isTrue);
    });
  });

  group('EldStatusDashboardBackend.getWeeklyRecap', () {
    test('returns recap data typed as WeeklyRecap', () async {
      adapter.onGet(
        '/eld/status/recap',
        (server) => server.reply(200, {
          'cycleUsed': '61:23',
          'cycleRemaining': '08:37',
          'days': [
            {
              'date': '2026-09-18T10:00:00Z',
              'dayOfWeek': 'Friday',
            }
          ]
        }),
      );

      final result = await backend.getWeeklyRecap();

      result.tap(onSuccess: (WeeklyRecap data) {
        expect(
          data.cycleUsed,
          equals(const Duration(hours: 61, minutes: 23)),
        );
        expect(data.days.length, 1);
        expect(data.days.first.dayOfWeek, 'Friday');
      });
      expect(result.isSuccess, isTrue);
    });
  });
}
