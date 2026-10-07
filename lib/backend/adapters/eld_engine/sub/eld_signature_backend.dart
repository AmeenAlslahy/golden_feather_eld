import '../../../../core/error/app_error.dart';
import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../domain/signature/signature.dart';
import '../../../contracts/signature_backend.dart';
import '../../../../core/network/api_client.dart';

/// The live ELD contract has no `/eld/signatures` resource.
/// Certification uses `POST /eld/daily-logs/{id}/certify` directly.
class EldSignatureBackend implements SignatureBackend {
  // Kept so the adapter constructor stays stable. The live contract has no call to make.
  // ignore: unused_field
  final ApiClient _apiClient;

  const EldSignatureBackend(this._apiClient);

  @override
  Future<Result<SignatureCertificate>> save({
    required DriverId driverId,
    required String logDate,
    required String signatureDataBase64,
    required SignatureType type,
  }) async {
    return err(
      const ServerError(
        code: 'eld.signature_endpoint_absent',
        context: {
          'message':
              'The server contract has no signature upload path. Certify the daily log instead.',
        },
      ),
    );
  }
}
