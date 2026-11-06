import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/sub/eld_daily_logs_backend.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/backend/http/eld_endpoints.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/network/api_client.dart';
import 'package:golden_feather_eld/core/network/api_response.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/models/certify_dto.dart';
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

    test('uses the unified /events endpoint', () async {
      when(
        () => api.get<RawJson>(
          EldEndpoints.dailyLogEvents(logId.value),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer(
        (_) async => ok(
          const ApiResponse<RawJson>(
            statusCode: 200,
            isSuccess: true,
            data: {'events': <dynamic>[], 'graphGrid': <String, dynamic>{}},
          ),
        ),
      );

      final result = await backend.getEvents(logId);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?['events'], isNotNull);
    });

    test('surfaces a server failure without retrying another path', () async {
      when(
        () => api.get<RawJson>(
          EldEndpoints.dailyLogEvents(logId.value),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer(
        (_) async =>
            err(const ServerError(code: 'server.500', statusCode: 500)),
      );

      final result = await backend.getEvents(logId);

      expect(result.isFailure, isTrue);
    });
  });

  group('EldDailyLogsBackend.getSummary', () {
    late MockApiClient api;
    late EldDailyLogsBackend backend;

    setUpAll(() {
      registerFallbackValue((dynamic _) => <String, dynamic>{});
      registerFallbackValue(<String, dynamic>{});
    });

    setUp(() {
      api = MockApiClient();
      backend = EldDailyLogsBackend(api);
    });

    test('sends page/size and surfaces pagination from the envelope', () async {
      when(
        () => api.get<RawJson>(
          EldEndpoints.dailyLogSummary,
          queryParameters: any(named: 'queryParameters'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer(
        (_) async => ok(
          const ApiResponse<RawJson>(
            statusCode: 200,
            isSuccess: true,
            data: {'totalLogs': 3},
            pagination: PaginationInfo(
              page: 0,
              size: 20,
              totalElements: 3,
              totalPages: 1,
              hasNext: false,
              hasPrevious: false,
            ),
          ),
        ),
      );

      final result = await backend.getSummary();

      expect(result.isSuccess, isTrue);
      final pagination =
          result.valueOrNull?['pagination'] as Map<String, dynamic>?;
      expect(pagination?['totalElements'], 3);
      expect(pagination?['hasNext'], isFalse);

      final captured = verify(
        () => api.get<RawJson>(
          EldEndpoints.dailyLogSummary,
          queryParameters: captureAny(named: 'queryParameters'),
          parser: any(named: 'parser'),
        ),
      ).captured;
      final query = captured.single as Map<String, dynamic>;
      expect(query['page'], 0);
      expect(query['size'], 20);
    });

    test('parser accepts a list payload (summary list)', () async {
      RawJson Function(dynamic)? capturedParser;
      when(
        () => api.get<RawJson>(
          EldEndpoints.dailyLogSummary,
          queryParameters: any(named: 'queryParameters'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer((invocation) async {
        capturedParser =
            invocation.namedArguments[#parser] as RawJson Function(dynamic);
        return ok(
          const ApiResponse<RawJson>(
            statusCode: 200,
            isSuccess: true,
            data: {'totalLogs': 0},
          ),
        );
      });

      await backend.getSummary();

      expect(capturedParser, isNotNull);
      expect(
        capturedParser!([
          {'id': 1, 'logDate': '2026-10-16'},
        ]),
        {
          'data': [
            {'id': 1, 'logDate': '2026-10-16'},
          ],
        },
      );
    });
  });

  group('EldDailyLogsBackend.getReadiness', () {
    late MockApiClient api;
    late EldDailyLogsBackend backend;

    const logId = DailyLogId(102);

    setUp(() {
      api = MockApiClient();
      backend = EldDailyLogsBackend(api);
    });

    test('maps GET /certify to ReadinessDto', () async {
      when(
        () => api.get<CertifyStateDto>(
          EldEndpoints.certifyLog(logId.value),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer(
        (_) async => ok(
          const ApiResponse<CertifyStateDto>(
            statusCode: 200,
            isSuccess: true,
            data: CertifyStateDto(
              dailyLogId: 102,
              logDate: '2026-10-22',
              statementText: 'I hereby certify...',
              canCertify: true,
              certified: false,
              validationCodes: ['SIGNATURE_REQUIRED'],
            ),
          ),
        ),
      );

      final result = await backend.getReadiness(logId);

      expect(result.isSuccess, isTrue);
      final readiness = result.valueOrNull!;
      expect(readiness.dailyLogId, 102);
      expect(readiness.logDate, '2026-10-22');
      expect(readiness.readinessStatus, 'READY');
      expect(readiness.missingRequirements, ['SIGNATURE_REQUIRED']);
      expect(readiness.availableActions, ['CERTIFY']);
    });

    test(
      'propagates a certify failure (no separate readiness endpoint)',
      () async {
        when(
          () => api.get<CertifyStateDto>(
            EldEndpoints.certifyLog(logId.value),
            parser: any(named: 'parser'),
          ),
        ).thenAnswer((_) async => err(const NotFoundError()));

        final result = await backend.getReadiness(logId);

        expect(result.isFailure, isTrue);
      },
    );

    test(
      'deduplicates successive getCertifyState and getReadiness calls within cache window',
      () async {
        const certifyDto = CertifyStateDto(
          dailyLogId: 102,
          logDate: '2026-10-22',
          statementText: 'Legal Statement',
          ruleReference: 'FMCSA 395.15',
          hasSignature: false,
          signatureImageData: null,
          certificationStatus: 'NOT_CERTIFIED',
          certified: false,
          canCertify: true,
          validationCodes: ['SIGNATURE_REQUIRED'],
        );

        when(
          () => api.get<CertifyStateDto>(
            EldEndpoints.certifyLog(logId.value),
            parser: any(named: 'parser'),
          ),
        ).thenAnswer((_) async => ok(const ApiResponse(statusCode: 200, isSuccess: true, data: certifyDto)));

        final r1 = await backend.getReadiness(logId);
        final r2 = await backend.getCertifyState(logId);

        expect(r1.isSuccess, isTrue);
        expect(r2.isSuccess, isTrue);
        verify(
          () => api.get<CertifyStateDto>(
            EldEndpoints.certifyLog(logId.value),
            parser: any(named: 'parser'),
          ),
        ).called(1);
      },
    );

    test(
      'certify cache invalidated after certify POST: next getCertifyState hits network',
      () async {
        final certifyDto = CertifyStateDto(
          dailyLogId: logId.value,
          logDate: '2026-10-22',
          statementText: 'Legal Statement',
          ruleReference: 'FMCSA 395.15',
          hasSignature: false,
          signatureImageData: null,
          certificationStatus: 'NOT_CERTIFIED',
          certified: false,
          canCertify: true,
          validationCodes: ['SIGNATURE_REQUIRED'],
        );

        when(
          () => api.get<CertifyStateDto>(
            EldEndpoints.certifyLog(logId.value),
            parser: any(named: 'parser'),
          ),
        ).thenAnswer(
          (_) async => ok(
            ApiResponse(
              statusCode: 200,
              isSuccess: true,
              data: certifyDto,
            ),
          ),
        );

        when(
          () => api.post<CertifyResponseDto>(
            EldEndpoints.certifyLog(logId.value),
            data: any(named: 'data'),
            parser: any(named: 'parser'),
            expectedOwnerDriverId: any(named: 'expectedOwnerDriverId'),
          ),
        ).thenAnswer(
          (_) async => ok(
            ApiResponse(
              statusCode: 200,
              isSuccess: true,
              data: CertifyResponseDto(
                dailyLogId: logId.value,
                certificationStatus: 'CERTIFIED',
                isCertified: true,
              ),
            ),
          ),
        );

        // 1. Initial fetch caches the certify state
        final r1 = await backend.getCertifyState(logId);
        expect(r1.isSuccess, isTrue);

        // 2. Submitting certify() POST invalidates the cache
        final certifyResult = await backend.certify(
          CertifyRequestDto(
            dailyLogId: logId.value,
            certified: true,
            signatureImage: 'signature_data',
          ),
        );
        expect(certifyResult.isSuccess, isTrue);

        // 3. Next getCertifyState() must hit the network again (call count 2)
        final r2 = await backend.getCertifyState(logId);
        expect(r2.isSuccess, isTrue);

        verify(
          () => api.get<CertifyStateDto>(
            EldEndpoints.certifyLog(logId.value),
            parser: any(named: 'parser'),
          ),
        ).called(2);
      },
    );
  });

  group('EldDailyLogsBackend.updateEvent', () {
    late MockApiClient api;
    late EldDailyLogsBackend backend;

    const logId = DailyLogId(7);
    const eventId = DutyStatusId(9002);

    setUpAll(() {
      registerFallbackValue(<String, dynamic>{});
    });

    setUp(() {
      api = MockApiClient();
      backend = EldDailyLogsBackend(api);
    });

    test('HTTP 200 + success:false is a failure, not a saved edit', () async {
      when(
        () => api.put<RawJson>(
          EldEndpoints.dailyLogEvent(logId.value, eventId.value),
          data: any(named: 'data'),
          parser: any(named: 'parser'),
          expectedOwnerDriverId: any(named: 'expectedOwnerDriverId'),
        ),
      ).thenAnswer(
        (_) async => ok(
          const ApiResponse<RawJson>(
            statusCode: 200,
            isSuccess: false,
            message: 'reason is required',
            errorCode: 'validation.reason',
            errors: [
              ApiFieldError(field: 'reason', message: 'reason is required'),
            ],
            requestId: 'req-42',
          ),
        ),
      );

      final result = await backend.updateEvent(
        logId: logId,
        eventId: eventId,
        event: const {'status': 'ON_DUTY'},
        expectedOwnerDriverId: 101,
      );

      expect(result.isFailure, isTrue);
      final error = result.errorOrNull!;
      expect(error, isA<ValidationError>());
      expect(
        (error as ValidationError).fieldErrors?['reason'],
        'reason is required',
      );
      expect(error.context?['requestId'], 'req-42');
      expect(error.context?['serverMessage'], 'reason: reason is required');
    });

    test('HTTP 200 + success:true returns the event payload', () async {
      when(
        () => api.put<RawJson>(
          EldEndpoints.dailyLogEvent(logId.value, eventId.value),
          data: any(named: 'data'),
          parser: any(named: 'parser'),
          expectedOwnerDriverId: any(named: 'expectedOwnerDriverId'),
        ),
      ).thenAnswer(
        (_) async => ok(
          const ApiResponse<RawJson>(
            statusCode: 200,
            isSuccess: true,
            data: {
              'event': {'id': 9002, 'status': 'ON_DUTY'},
            },
            requestId: 'req-ok',
          ),
        ),
      );

      final result = await backend.updateEvent(
        logId: logId,
        eventId: eventId,
        event: const {'status': 'ON_DUTY'},
        expectedOwnerDriverId: 101,
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?['event'], isNotNull);
    });

    test(
      'updateEvent invalidates certify cache: next getCertifyState hits network',
      () async {
        final certifyDto = CertifyStateDto(
          dailyLogId: logId.value,
          logDate: '2026-10-22',
          statementText: 'Legal Statement',
          ruleReference: 'FMCSA 395.15',
          hasSignature: false,
          signatureImageData: null,
          certificationStatus: 'CERTIFIED',
          certified: true,
          canCertify: false,
          validationCodes: const [],
        );

        when(
          () => api.get<CertifyStateDto>(
            EldEndpoints.certifyLog(logId.value),
            parser: any(named: 'parser'),
          ),
        ).thenAnswer(
          (_) async => ok(
            ApiResponse(
              statusCode: 200,
              isSuccess: true,
              data: certifyDto,
            ),
          ),
        );

        when(
          () => api.put<RawJson>(
            EldEndpoints.dailyLogEvent(logId.value, eventId.value),
            data: any(named: 'data'),
            parser: any(named: 'parser'),
            expectedOwnerDriverId: any(named: 'expectedOwnerDriverId'),
          ),
        ).thenAnswer(
          (_) async => ok(
            const ApiResponse<RawJson>(
              statusCode: 200,
              isSuccess: true,
              data: {'event': {'id': 9002, 'status': 'OFF_DUTY'}},
            ),
          ),
        );

        // 1. Initial fetch caches the certify state
        final r1 = await backend.getCertifyState(logId);
        expect(r1.isSuccess, isTrue);

        // 2. Editing an event in the log invalidates the certify cache
        final updateRes = await backend.updateEvent(
          logId: logId,
          eventId: eventId,
          event: const {'status': 'OFF_DUTY'},
        );
        expect(updateRes.isSuccess, isTrue);

        // 3. Next getCertifyState() must hit network again because cache was invalidated
        final r2 = await backend.getCertifyState(logId);
        expect(r2.isSuccess, isTrue);

        verify(
          () => api.get<CertifyStateDto>(
            EldEndpoints.certifyLog(logId.value),
            parser: any(named: 'parser'),
          ),
        ).called(2);
      },
    );

    test(
      'in-flight getCertifyState completing after updateEvent does NOT re-cache stale certify state',
      () async {
        final completer = Completer<Result<ApiResponse<CertifyStateDto>>>();
        final staleCertifyDto = CertifyStateDto(
          dailyLogId: logId.value,
          logDate: '2026-10-22',
          statementText: 'Legal Statement',
          ruleReference: 'FMCSA 395.15',
          hasSignature: false,
          signatureImageData: null,
          certificationStatus: 'CERTIFIED',
          certified: true,
          canCertify: false,
          validationCodes: const [],
        );

        when(
          () => api.get<CertifyStateDto>(
            EldEndpoints.certifyLog(logId.value),
            parser: any(named: 'parser'),
          ),
        ).thenAnswer((_) => completer.future);

        when(
          () => api.put<RawJson>(
            EldEndpoints.dailyLogEvent(logId.value, eventId.value),
            data: any(named: 'data'),
            parser: any(named: 'parser'),
            expectedOwnerDriverId: any(named: 'expectedOwnerDriverId'),
          ),
        ).thenAnswer(
          (_) async => ok(
            const ApiResponse<RawJson>(
              statusCode: 200,
              isSuccess: true,
              data: {'event': {'id': 9002, 'status': 'OFF_DUTY'}},
            ),
          ),
        );

        // 1. Start in-flight getCertifyState
        final inFlightCertify = backend.getCertifyState(logId);

        // 2. While in-flight, updateEvent is executed
        final updateRes = await backend.updateEvent(
          logId: logId,
          eventId: eventId,
          event: const {'status': 'OFF_DUTY'},
        );
        expect(updateRes.isSuccess, isTrue);

        // 3. Complete the in-flight GET request with stale data
        completer.complete(
          ok(
            ApiResponse(
              statusCode: 200,
              isSuccess: true,
              data: staleCertifyDto,
            ),
          ),
        );
        await inFlightCertify;

        // 4. Now set up fresh mock response for next call
        final freshCertifyDto = CertifyStateDto(
          dailyLogId: logId.value,
          logDate: '2026-10-22',
          statementText: 'Legal Statement',
          ruleReference: 'FMCSA 395.15',
          hasSignature: false,
          signatureImageData: null,
          certificationStatus: 'NOT_CERTIFIED',
          certified: false,
          canCertify: true,
          validationCodes: const ['SIGNATURE_REQUIRED'],
        );

        when(
          () => api.get<CertifyStateDto>(
            EldEndpoints.certifyLog(logId.value),
            parser: any(named: 'parser'),
          ),
        ).thenAnswer(
          (_) async => ok(
            ApiResponse(
              statusCode: 200,
              isSuccess: true,
              data: freshCertifyDto,
            ),
          ),
        );

        // The subsequent call must NOT hit cache with the stale response; it must hit network!
        final nextResult = await backend.getCertifyState(logId);
        expect(nextResult.isSuccess, isTrue);
        expect(nextResult.valueOrNull?.certified, isFalse,
            reason: 'Stale in-flight certify state must not be cached after event edit');

        verify(
          () => api.get<CertifyStateDto>(
            EldEndpoints.certifyLog(logId.value),
            parser: any(named: 'parser'),
          ),
        ).called(2);
      },
    );
  });
}
