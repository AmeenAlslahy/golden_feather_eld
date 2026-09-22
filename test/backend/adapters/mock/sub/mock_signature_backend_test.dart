import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_signature_backend.dart';
import 'package:golden_feather_eld/core/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/core/domain/signature/signature.dart';
import 'package:golden_feather_eld/core/result/result.dart';

void main() {
  group('MockSignatureBackend', () {
    late MockSignatureBackend backend;

    setUp(() {
      backend = MockSignatureBackend();
    });

    test('save adds to _saved and returns valid certificate', () async {
      final result = await backend.save(
        driverId: const DriverId(12),
        logDate: '2026-09-15',
        signatureDataBase64: 'base64str',
        type: SignatureType.driverCertification,
      );

      final cert = result.valueOrNull;
      expect(cert!.driverId.value, 12);
      expect(cert.status, CertificateStatus.valid);
      
      expect(backend.savedSignatures.length, 1);
      expect(backend.savedSignatures.first['driverId'], 12);
    });

    test('clear resets saved signatures', () async {
      await backend.save(
        driverId: const DriverId(12),
        logDate: '2026-09-15',
        signatureDataBase64: 'base64str',
        type: SignatureType.driverCertification,
      );

      expect(backend.savedSignatures, isNotEmpty);
      backend.clear();
      expect(backend.savedSignatures, isEmpty);
    });
  });
}
