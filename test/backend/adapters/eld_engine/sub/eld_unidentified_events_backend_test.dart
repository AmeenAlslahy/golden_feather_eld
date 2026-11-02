import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/sub/eld_unidentified_events_backend.dart';
import 'package:golden_feather_eld/backend/contracts/contract_enums.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/backend/contracts/unidentified_events_backend.dart';
import 'package:golden_feather_eld/backend/http/eld_endpoints.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/network/api_client.dart';
import 'package:golden_feather_eld/core/network/api_response.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  group('EldUnidentifiedEventsBackend', () {
    late MockApiClient api;
    late EldUnidentifiedEventsBackend backend;

    setUpAll(() {
      registerFallbackValue(<String, dynamic>{});
    });

    setUp(() {
      api = MockApiClient();
      backend = EldUnidentifiedEventsBackend(api);
    });

    test(
      'list sends only documented query params and the status filter',
      () async {
        when(
          () => api.get<RawJson>(
            EldEndpoints.unidentifiedEvents,
            queryParameters: any(named: 'queryParameters'),
            parser: any(named: 'parser'),
          ),
        ).thenAnswer(
          (_) async => ok(
            const ApiResponse<RawJson>(
              statusCode: 200,
              isSuccess: true,
              data: <String, dynamic>{
                'items': [
                  {'id': 104, 'status': 'REJECTED'},
                ],
              },
            ),
          ),
        );

        final result = await backend.list(
          tab: UnidentifiedTab.rejected,
          page: 2,
          size: 50,
          sortBy: 'startTime',
          sortDirection: 'DESC',
          filters: const [UnidentifiedEventFilter(key: 'deviceId', value: 4)],
        );

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull?['items'], isA<List>());

        final captured =
            verify(
                  () => api.get<RawJson>(
                    EldEndpoints.unidentifiedEvents,
                    queryParameters: captureAny(named: 'queryParameters'),
                    parser: any(named: 'parser'),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['page'], 2);
        expect(captured['size'], 50);
        expect(captured['sortBy'], 'startTime');
        expect(captured['sortDirection'], 'DESC');
        expect(captured.containsKey('tab'), isFalse);
        expect(captured.containsKey('uniqueId'), isFalse);
        expect(captured.containsKey('driverId'), isFalse);

        final filters = jsonDecode(captured['filters'] as String) as List;
        expect(filters, [
          {'key': 'status', 'operator': 'EQ', 'value': 'REJECTED'},
          {'key': 'deviceId', 'operator': 'EQ', 'value': 4},
        ]);
      },
    );

    test('list rejects a failed envelope with field errors', () async {
      when(
        () => api.get<RawJson>(
          EldEndpoints.unidentifiedEvents,
          queryParameters: any(named: 'queryParameters'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer(
        (_) async => ok(
          const ApiResponse<RawJson>(
            statusCode: 200,
            isSuccess: false,
            message: 'Invalid filter',
            errors: [ApiFieldError(field: 'filters', message: 'unknown key')],
          ),
        ),
      );

      final result = await backend.list();

      result.fold((error) {
        expect(error, isA<ValidationError>());
        expect(error.context?['message'], 'Invalid filter');
        expect(error.context?['errors'], contains('filters: unknown key'));
      }, (_) => fail('A failed envelope must not be accepted'));
    });

    test('getById calls the documented detail path', () async {
      when(
        () => api.get<RawJson>(
          EldEndpoints.unidentifiedEvent(104),
          queryParameters: any(named: 'queryParameters'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer(
        (_) async => ok(
          const ApiResponse<RawJson>(
            statusCode: 200,
            isSuccess: true,
            data: {'id': 104, 'status': 'UNCLAIMED'},
          ),
        ),
      );

      final result = await backend.getById(id: const DutyStatusId(104));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?['id'], 104);
      verify(
        () => api.get<RawJson>(
          '/eld/unidentified/104',
          queryParameters: any(named: 'queryParameters'),
          parser: any(named: 'parser'),
        ),
      ).called(1);
    });

    test('summary calls the documented summary path', () async {
      when(
        () => api.get<RawJson>(
          EldEndpoints.unidentifiedSummary,
          queryParameters: any(named: 'queryParameters'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer(
        (_) async => ok(
          const ApiResponse<RawJson>(
            statusCode: 200,
            isSuccess: true,
            data: {
              'totalUnclaimed': 3,
              'totalRejected': 1,
              'pendingOver8DaysCount': 0,
              'complianceAlertActive': false,
            },
          ),
        ),
      );

      final result = await backend.summary();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?['totalUnclaimed'], 3);
      verify(
        () => api.get<RawJson>(
          '/eld/unidentified/summary',
          queryParameters: any(named: 'queryParameters'),
          parser: any(named: 'parser'),
        ),
      ).called(1);
    });

    test('summary rejects a failed envelope without field errors', () async {
      when(
        () => api.get<RawJson>(
          EldEndpoints.unidentifiedSummary,
          queryParameters: any(named: 'queryParameters'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer(
        (_) async => ok(
          const ApiResponse<RawJson>(
            statusCode: 500,
            isSuccess: false,
            message: 'Summary unavailable',
          ),
        ),
      );

      final result = await backend.summary();

      result.fold((error) {
        expect(error, isA<ServerError>());
        expect(error.context?['message'], 'Summary unavailable');
        expect((error as ServerError).statusCode, 500);
      }, (_) => fail('A failed envelope must not be accepted'));
    });

    test('claim posts the documented body to the documented path', () async {
      when(
        () => api.post<RawJson>(
          any(),
          data: any(named: 'data'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer(
        (_) async => ok(
          const ApiResponse<RawJson>(
            statusCode: 200,
            isSuccess: true,
            data: {'eventId': 104},
          ),
        ),
      );

      final result = await backend.claim(
        id: const DutyStatusId(104),
        driverId: const DriverId(10),
        annotation: '  I was driving  ',
      );

      expect(result.isSuccess, isTrue);
      final captured = verify(
        () => api.post<RawJson>(
          EldEndpoints.claimUnidentified(104),
          data: captureAny(named: 'data'),
          parser: any(named: 'parser'),
        ),
      ).captured.single;
      expect(captured, {'driverId': 10, 'annotation': 'I was driving'});
    });

    test('reject posts the documented body to the documented path', () async {
      when(
        () => api.post<RawJson>(
          any(),
          data: any(named: 'data'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer(
        (_) async => ok(
          const ApiResponse<RawJson>(
            statusCode: 200,
            isSuccess: true,
            data: {'eventId': 104},
          ),
        ),
      );

      final result = await backend.reject(
        id: const DutyStatusId(104),
        driverId: const DriverId(10),
        rejectionReason: '  Not my vehicle  ',
      );

      expect(result.isSuccess, isTrue);
      final captured = verify(
        () => api.post<RawJson>(
          EldEndpoints.rejectUnidentified(104),
          data: captureAny(named: 'data'),
          parser: any(named: 'parser'),
        ),
      ).captured.single;
      expect(captured, {'driverId': 10, 'rejectionReason': 'Not my vehicle'});
    });

    test('claim rejects a failed envelope instead of accepting it', () async {
      when(
        () => api.post<RawJson>(
          any(),
          data: any(named: 'data'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer(
        (_) async => ok(
          const ApiResponse<RawJson>(
            statusCode: 200,
            isSuccess: false,
            message: 'Annotation is too short',
            errors: [ApiFieldError(field: 'annotation', message: 'min 4')],
          ),
        ),
      );

      final result = await backend.claim(
        id: const DutyStatusId(104),
        driverId: const DriverId(10),
        annotation: 'abc',
      );

      result.fold((error) {
        expect(error, isA<ValidationError>());
        expect(error.context?['message'], 'Annotation is too short');
      }, (_) => fail('A failed envelope must not be accepted'));
    });
  });
}
