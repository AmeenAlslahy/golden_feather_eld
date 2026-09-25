import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/value_objects.dart';

part 'signature.freezed.dart';

/// A driver's electronic signature certificate.
@freezed
abstract class SignatureCertificate with _$SignatureCertificate {
  const factory SignatureCertificate({
    required String signatureId,
    required DriverId driverId,
    required String logDate,
    required String signatureHash,
    required DateTime signedAt,
    required CertificateStatus status,
  }) = _SignatureCertificate;
}

enum CertificateStatus {
  valid('VALID'),
  revoked('REVOKED'),
  unknown('UNKNOWN');

  const CertificateStatus(this.wire);
  final String wire;

  static CertificateStatus fromWire(String? value) {
    final upper = value?.toUpperCase() ?? '';
    return CertificateStatus.values.firstWhere(
      (s) => s.wire == upper,
      orElse: () => CertificateStatus.unknown,
    );
  }
}

enum SignatureType {
  driverCertification('DRIVER_CERTIFICATION'),
  inspectorCertification('INSPECTOR_CERTIFICATION');

  const SignatureType(this.wire);
  final String wire;
}
