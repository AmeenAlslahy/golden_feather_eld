import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/sub/eld_inspection_backend.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/network/api_client.dart';
import 'package:golden_feather_eld/core/network/api_response.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  group('EldInspectionBackend', () {
    late MockApiClient mockApiClient;
    late EldInspectionBackend backend;

    setUp(() {
      mockApiClient = MockApiClient();
      backend = EldInspectionBackend(mockApiClient);
    });

    test('getScreen calls API and returns screen', () async {
      when(
        () => mockApiClient.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer(
        (_) async => ok(
          const ApiResponse<Map<String, dynamic>>(
            statusCode: 200,
            isSuccess: true,
            data: {'screenTitle': 'Test DOT'},
          ),
        ),
      );

      final result = await backend.getScreen(driverId: const DriverId(101));

      result.fold((l) => fail('Expected right'), (r) {
        expect(r.screenTitle, 'Test DOT');
      });

      verify(
        () => mockApiClient.get<Map<String, dynamic>>(
          '/eld/inspections',
          queryParameters: {'driverId': 101},
          parser: any(named: 'parser'),
        ),
      ).called(1);
    });

    test('getCycle calls API and returns list', () async {
      when(
        () => mockApiClient.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer(
        (_) async => ok(
          const ApiResponse<List<dynamic>>(
            statusCode: 200,
            isSuccess: true,
            data: [
              {'displayLocation': 'Riyadh'},
            ],
          ),
        ),
      );

      final result = await backend.getCycle(
        driverId: const DriverId(101),
        days: 8,
      );

      result.fold((l) => fail('Expected right'), (r) {
        expect(r.length, 1);
        expect(r.first.displayLocation, 'Riyadh');
      });
    });

    test('getLogs calls API and returns log', () async {
      when(
        () => mockApiClient.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer(
        (_) async => ok(
          const ApiResponse<Map<String, dynamic>>(
            statusCode: 200,
            isSuccess: true,
            data: {'displayLocation': 'Dammam'},
          ),
        ),
      );

      final result = await backend.getLogs(driverId: const DriverId(101));

      result.fold((l) => fail('Expected right'), (r) {
        expect(r.displayLocation, 'Dammam');
      });
    });

    test(
      'emailLogs posts to the documented transfer path with documented fields',
      () async {
        when(
          () => mockApiClient.post<RawJson>(
            any(),
            data: any(named: 'data'),
            parser: any(named: 'parser'),
            expectedOwnerDriverId: any(named: 'expectedOwnerDriverId'),
          ),
        ).thenAnswer(
          (_) async => ok(
            const ApiResponse<RawJson>(
              statusCode: 200,
              isSuccess: true,
              data: {'status': 'PENDING', 'message': 'queued'},
            ),
          ),
        );

        final result = await backend.emailLogs(
          driverId: const DriverId(101),
          recipientEmail: ' inspector@dot.gov ',
          comment: '  roadside check  ',
          // Unconfirmed by Swagger: must stay out of the wire body.
          routingCode: 'R-1',
          daysCount: 8,
          endDate: DateTime(2026, 10, 30),
        );

        result.fold((error) => fail('Expected right, got ${error.code}'), (
          json,
        ) {
          expect(json['status'], 'PENDING');
          expect(json['message'], 'queued');
        });

        final captured = verify(
          () => mockApiClient.post<RawJson>(
            '/eld/transfer/email-logs',
            data: captureAny(named: 'data'),
            parser: any(named: 'parser'),
            expectedOwnerDriverId: any(named: 'expectedOwnerDriverId'),
          ),
        ).captured;

        expect(captured, hasLength(1));
        expect(captured.single, {
          'driverId': 101,
          'recipientEmail': 'inspector@dot.gov',
          'comment': 'roadside check',
        });
      },
    );

    test(
      'emailLogs rejects a failed envelope instead of accepting it',
      () async {
        when(
          () => mockApiClient.post<RawJson>(
            any(),
            data: any(named: 'data'),
            parser: any(named: 'parser'),
            expectedOwnerDriverId: any(named: 'expectedOwnerDriverId'),
          ),
        ).thenAnswer(
          (_) async => ok(
            const ApiResponse<RawJson>(
              statusCode: 200,
              isSuccess: false,
              message: 'Comment length is invalid',
              errors: [
                ApiFieldError(field: 'comment', message: 'must be 4-60'),
              ],
            ),
          ),
        );

        final result = await backend.emailLogs(
          driverId: const DriverId(101),
          recipientEmail: 'inspector@dot.gov',
          comment: 'bad',
        );

        result.fold((error) {
          expect(error, isA<ValidationError>());
          expect(error.code, 'inspection.transfer.rejected');
          expect(error.context?['message'], 'Comment length is invalid');
          expect(error.context?['errors'], contains('comment: must be 4-60'));
        }, (_) => fail('A failed envelope must not be accepted'));
      },
    );
  });
}
