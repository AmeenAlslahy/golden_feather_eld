import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/sub/eld_daily_logs_backend.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/backend/http/eld_endpoints.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/network/api_client.dart';
import 'package:golden_feather_eld/core/network/api_response.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  group('EldDailyLogsBackend.getEvents', () {
    late MockApiClient api;
    late EldDailyLogsBackend backend;

    const logId = DailyLogId(7);

    setUpAll(() {
      registerFallbackValue((dynamic _) => <String, dynamic>{});
    });

    setUp(() {
      api = MockApiClient();
      backend = EldDailyLogsBackend(api);
    });

    test('uses the unified /events endpoint when it exists', () async {
      when(() => api.get<RawJson>(
            EldEndpoints.dailyLogEvents(logId.value),
            parser: any(named: 'parser'),
          )).thenAnswer(
        (_) async => ok(const ApiResponse<RawJson>(
          statusCode: 200,
          isSuccess: true,
          data: {'events': <dynamic>[], 'graphGrid': <String, dynamic>{}},
        )),
      );

      final result = await backend.getEvents(logId);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?['events'], isNotNull);
      verifyNever(() => api.get<RawJson>(
            EldEndpoints.dailyLogGraphGrid(logId.value),
            parser: any(named: 'parser'),
          ));
    });

    test('falls back to the legacy graph-grid path when /events is 404',
        () async {
      when(() => api.get<RawJson>(
            EldEndpoints.dailyLogEvents(logId.value),
            parser: any(named: 'parser'),
          )).thenAnswer((_) async => err(const NotFoundError()));
      when(() => api.get<RawJson>(
            EldEndpoints.dailyLogGraphGrid(logId.value),
            parser: any(named: 'parser'),
          )).thenAnswer(
        (_) async => ok(const ApiResponse<RawJson>(
          statusCode: 200,
          isSuccess: true,
          data: {
            'events': [
              {'id': '1', 'status': 'OFF'},
            ],
          },
        )),
      );

      final result = await backend.getEvents(logId);

      expect(result.isSuccess, isTrue);
      expect((result.valueOrNull?['events'] as List).length, 1);
      verify(() => api.get<RawJson>(
            EldEndpoints.dailyLogGraphGrid(logId.value),
            parser: any(named: 'parser'),
          )).called(1);
    });

    test('does not fall back on other failures (e.g. 500)', () async {
      when(() => api.get<RawJson>(
            EldEndpoints.dailyLogEvents(logId.value),
            parser: any(named: 'parser'),
          )).thenAnswer(
        (_) async => err(const ServerError(
          code: 'server.500',
          statusCode: 500,
        )),
      );

      final result = await backend.getEvents(logId);

      expect(result.isFailure, isTrue);
      verifyNever(() => api.get<RawJson>(
            EldEndpoints.dailyLogGraphGrid(logId.value),
            parser: any(named: 'parser'),
          ));
    });
  });
}
