import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/domain/signature/signature.dart';

void main() {
  group('CertificateStatus', () {
    test('fromWire valid', () {
      expect(CertificateStatus.fromWire('VALID'), CertificateStatus.valid);
      expect(CertificateStatus.fromWire('valid'), CertificateStatus.valid);
    });

    test('fromWire revoked', () {
      expect(CertificateStatus.fromWire('REVOKED'), CertificateStatus.revoked);
    });

    test('fromWire unknown', () {
      expect(CertificateStatus.fromWire('random'), CertificateStatus.unknown);
      expect(CertificateStatus.fromWire(null), CertificateStatus.unknown);
    });
  });
}
