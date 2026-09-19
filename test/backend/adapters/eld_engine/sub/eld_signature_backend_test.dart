import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/sub/eld_signature_backend.dart';
import 'package:golden_feather_eld/backend/http/api_client.dart';
import 'package:golden_feather_eld/backend/http/api_response.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/domain/signature/signature.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  group('EldSignatureBackend', () {
    late MockApiClient mockApiClient;
    late EldSignatureBackend backend;

    setUp(() {
      mockApiClient = MockApiClient();
      backend = EldSignatureBackend(mockApiClient);
    });

    test('save calls API and returns certificate', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            parser: any(named: 'parser'),
          )).thenAnswer((_) async => ok(const ApiResponse<Map<String, dynamic>>(
            statusCode: 200,
            isSuccess: true,
            data: {
              'signatureId': 'sig-1',
              'driverId': 42,
              'logDate': '2026-09-15',
              'signatureHash': 'hash',
              'signedAt': '2026-09-15T12:00:00Z',
              'certificateStatus': 'VALID',
            },
          )));

      final result = await backend.save(
        driverId: const DriverId(42),
        logDate: '2026-09-15',
        signatureDataBase64: 'base64',
        type: SignatureType.driverCertification,
      );

      expect(result.isSuccess, isTrue);
      final cert = result.valueOrNull;
      expect(cert, isNotNull);
      
      verify(() => mockApiClient.post<Map<String, dynamic>>(
            '/eld/signatures/42',
            data: {
              'driverId': 42,
              'logDate': '2026-09-15',
              'signatureData': 'base64',
              'signatureType': 'DRIVER_CERTIFICATION',
            },
            parser: any(named: 'parser'),
          )).called(1);
    });
  });
}
