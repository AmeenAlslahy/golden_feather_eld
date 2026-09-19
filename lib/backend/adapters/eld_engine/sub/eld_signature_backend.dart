import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../domain/signature/signature.dart';
import '../../../contracts/signature_backend.dart';
import '../../../http/api_client.dart';
import '../mappers/signature_mapper.dart';

class EldSignatureBackend implements SignatureBackend {
  final ApiClient _apiClient;

  const EldSignatureBackend(this._apiClient);

  @override
  Future<Result<SignatureCertificate>> save({
    required DriverId driverId,
    required String logDate,
    required String signatureDataBase64,
    required SignatureType type,
  }) {
    return _apiClient
        .post<Map<String, dynamic>>(
          '/eld/signatures/${driverId.value}',
          data: {
            'driverId': driverId.value,
            'logDate': logDate,
            'signatureData': signatureDataBase64,
            'signatureType': type.wire,
          },
          parser: (data) => data is Map<String, dynamic> ? data : {},
        )
        .then(
          (result) => result.mapValue(
            (response) => SignatureMapper.fromJson(response.data ?? const {}),
          ),
        );
  }
}
