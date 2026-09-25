import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
import '../../domain/signature/signature.dart';

abstract interface class SignatureBackend {
  /// POST /eld/signatures/{driverId}
  Future<Result<SignatureCertificate>> save({
    required DriverId driverId,
    required String logDate,
    required String signatureDataBase64,
    required SignatureType type,
  });
}
