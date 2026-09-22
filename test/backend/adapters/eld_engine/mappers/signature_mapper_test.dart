import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/mappers/signature_mapper.dart';
import 'package:golden_feather_eld/core/domain/signature/signature.dart';

void main() {
  group('SignatureMapper', () {
    test('fromJson happy path', () {
      final json = {
        'signatureId': 'sig-123',
        'driverId': 42,
        'logDate': '2026-09-15',
        'signatureHash': 'hash123',
        'signedAt': '2026-09-15T12:00:00Z',
        'certificateStatus': 'VALID',
      };

      final cert = SignatureMapper.fromJson(json);

      expect(cert.signatureId, 'sig-123');
      expect(cert.driverId.value, 42);
      expect(cert.logDate, '2026-09-15');
      expect(cert.signatureHash, 'hash123');
      expect(cert.signedAt, DateTime.utc(2026, 9, 15, 12, 0, 0));
      expect(cert.status, CertificateStatus.valid);
    });

    test('fromJson edge cases (nulls and invalid types)', () {
      final json = <String, dynamic>{};

      final cert = SignatureMapper.fromJson(json);

      expect(cert.signatureId, '');
      expect(cert.driverId.value, 0);
      expect(cert.logDate, '');
      expect(cert.signatureHash, '');
      expect(cert.status, CertificateStatus.unknown);
    });
  });
}
