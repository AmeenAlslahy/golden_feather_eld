import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/network/api_config.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/sub/eld_status_dashboard_backend.dart';
import 'package:golden_feather_eld/core/network/api_client.dart';
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

      final result = await backend.getDashboard(driverId: const DriverId(101));

      result.tap(
        onSuccess: (StatusDashboard data) {
          expect(
            data.currentDutyStatus,
            equals(DutyStatusCode.onDutyNotDriving),
          );
          expect(data.driver.id, equals(const DriverId(101)));
        },
      );
      expect(result.isSuccess, isTrue);
    });
  });

  group('EldStatusDashboardBackend.updateDutyStatus', () {
    Map<String, dynamic> fullDashboard() => {
          'driver': {'id': 101, 'name': 'Ahmed', 'displayText': 'A.'},
          'currentDutyStatus': 'DRIVING',
          'remainingCircle': {
            'time': '10:25',
            'label': 'Remaining',
            'progress': 0.94,
          },
          'hosIndicators': {
            'drive': {
              'label': 'DRIVE',
              'value': '10:25',
              'type': 'remaining',
            },
          },
        };

    test('sends POST with dutyStatus wire value and notes, parses a full '
        'dashboard body', () async {
      adapter.onPost(
        '/eld/status/duty-status',
        (server) => server.reply(200, fullDashboard()),
        data: {'dutyStatus': 'DRIVING', 'notes': 'Trip started'},
      );

      final result = await backend.updateDutyStatus(
        status: DutyStatusCode.driving,
        notes: 'Trip started',
      );

      result.tap(
        onSuccess: (StatusDashboard? data) {
          expect(data, isNotNull);
          expect(data!.currentDutyStatus, equals(DutyStatusCode.driving));
          expect(
            data.remainingCircle.remaining,
            equals(const Duration(hours: 10, minutes: 25)),
          );
          expect(data.driver.id, equals(const DriverId(101)));
        },
      );
      expect(result.isSuccess, isTrue);
    });

    test('unwraps a {success, data} envelope and maps the inner dashboard',
        () async {
      adapter.onPost(
        '/eld/status/duty-status',
        (server) => server.reply(200, {
          'success': true,
          'data': fullDashboard(),
          'requestId': 'req-1',
        }),
        data: {'dutyStatus': 'DRIVING', 'notes': 'Trip started'},
      );

      final result = await backend.updateDutyStatus(
        status: DutyStatusCode.driving,
        notes: 'Trip started',
      );

      result.tap(
        onSuccess: (StatusDashboard? data) {
          expect(data, isNotNull);
          expect(data!.currentDutyStatus, equals(DutyStatusCode.driving));
          expect(
            data.hosIndicators.drive.value,
            equals(const Duration(hours: 10, minutes: 25)),
          );
        },
      );
      expect(result.isSuccess, isTrue);
    });

    test('works without notes (default note is sent)', () async {
      adapter.onPost(
        '/eld/status/duty-status',
        (server) => server.reply(200, {
          ...fullDashboard(),
          'currentDutyStatus': 'OFF_DUTY',
        }),
        data: {'dutyStatus': 'OFF_DUTY', 'notes': 'Off Duty'},
      );

      final result = await backend.updateDutyStatus(
        status: DutyStatusCode.offDuty,
      );

      result.tap(
        onSuccess: (StatusDashboard? data) {
          expect(data, isNotNull);
          expect(data!.currentDutyStatus, equals(DutyStatusCode.offDuty));
        },
      );
      expect(result.isSuccess, isTrue);
    });

    test(
        'a record inside the envelope is accepted WITHOUT a snapshot '
        '(regression: used to fabricate an all-zero dashboard)', () async {
      adapter.onPost(
        '/eld/status/duty-status',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'id': 7,
            'dutyStatus': 'DRIVING',
            'notes': 'Trip started',
            'timestamp': '2026-10-16T17:52:19Z',
          },
          'requestId': 'req-2',
        }),
        data: {'dutyStatus': 'DRIVING', 'notes': 'Trip started'},
      );

      final result = await backend.updateDutyStatus(
        status: DutyStatusCode.driving,
        notes: 'Trip started',
      );

      expect(result.isSuccess, isTrue);
      result.tap(onSuccess: (StatusDashboard? data) => expect(data, isNull));
    });

    test(
        'a bare status-only body is not a snapshot — returns null instead of '
        'zeros with the new status injected', () async {
      adapter.onPost(
        '/eld/status/duty-status',
        (server) => server.reply(200, {'currentDutyStatus': 'DRIVING'}),
        data: {'dutyStatus': 'DRIVING', 'notes': 'Trip started'},
      );

      final result = await backend.updateDutyStatus(
        status: DutyStatusCode.driving,
        notes: 'Trip started',
      );

      expect(result.isSuccess, isTrue);
      result.tap(onSuccess: (StatusDashboard? data) => expect(data, isNull));
    });

    test('a non-JSON 200 body is accepted without a snapshot', () async {
      adapter.onPost(
        '/eld/status/duty-status',
        (server) => server.reply(200, 'OK'),
        data: {'dutyStatus': 'DRIVING', 'notes': 'Trip started'},
      );

      final result = await backend.updateDutyStatus(
        status: DutyStatusCode.driving,
        notes: 'Trip started',
      );

      expect(result.isSuccess, isTrue);
      result.tap(onSuccess: (StatusDashboard? data) => expect(data, isNull));
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
            {'date': '2026-09-18T10:00:00Z', 'dayOfWeek': 'Friday'},
          ],
        }),
      );

      final result = await backend.getWeeklyRecap();

      result.tap(
        onSuccess: (WeeklyRecap data) {
          expect(
            data.cycleUsed,
            equals(const Duration(hours: 61, minutes: 23)),
          );
          expect(data.days.length, 1);
          expect(data.days.first.dayOfWeek, 'Friday');
        },
      );
      expect(result.isSuccess, isTrue);
    });
  });
}
