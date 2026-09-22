import '../../core/domain/shared/value_objects.dart';
import '../../core/domain/signature/signature.dart';
import '../../core/result/result.dart';

abstract interface class SignatureBackend {
  /// POST /eld/signatures/{driverId}
  Future<Result<SignatureCertificate>> save({
    required DriverId driverId,
    required String logDate,
    required String signatureDataBase64,
    required SignatureType type,
  });
}
