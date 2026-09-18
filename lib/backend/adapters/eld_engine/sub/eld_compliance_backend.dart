// ignore_for_file: unused_field, unused_import

import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/compliance_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';

/// ELD Engine implementation of [ComplianceBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldComplianceBackend implements ComplianceBackend {
  final ApiClient _apiClient;

  const EldComplianceBackend(this._apiClient);

  @override
  Future<Result<RawJson>> evaluate(DriverId driverId) =>
      throw UnimplementedError('EldComplianceBackend.evaluate — Phase 2');

  @override
  Future<Result<RawJson>> getRemaining(DriverId driverId) =>
      throw UnimplementedError('EldComplianceBackend.getRemaining — Phase 2');
}
