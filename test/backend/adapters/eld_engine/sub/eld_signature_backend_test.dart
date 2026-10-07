import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/sub/eld_signature_backend.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/network/api_client.dart';
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

    test('save does not call a path absent from the live contract', () async {
      final result = await backend.save(
        driverId: const DriverId(42),
        logDate: '2026-09-15',
        signatureDataBase64: 'base64',
        type: SignatureType.driverCertification,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.code, 'eld.signature_endpoint_absent');
      verifyZeroInteractions(mockApiClient);
    });
  });
}
