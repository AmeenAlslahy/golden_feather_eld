import '../../../../domain/shared/value_objects.dart';
import '../../../../domain/signature/signature.dart';

class SignatureMapper {
  const SignatureMapper._();

  static SignatureCertificate fromJson(Map<String, dynamic> json) {
    return SignatureCertificate(
      signatureId: json['signatureId']?.toString() ?? '',
      driverId: DriverId(_asInt(json['driverId'])),
      logDate: json['logDate']?.toString() ?? '',
      signatureHash: json['signatureHash']?.toString() ?? '',
      signedAt: _parseDate(json['signedAt']),
      status: CertificateStatus.fromWire(json['certificateStatus'] as String?),
    );
  }

  static int _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime _parseDate(Object? v) {
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now().toUtc();
    return DateTime.now().toUtc();
  }
}
