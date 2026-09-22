import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/result/result.dart';
import '../../../contracts/compliance_backend.dart';
import '../../../contracts/raw_json.dart';

/// In-memory mock for [ComplianceBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class MockComplianceBackend implements ComplianceBackend {
  const MockComplianceBackend();

  @override
  Future<Result<RawJson>> evaluate(DriverId driverId) =>
      throw UnimplementedError('MockComplianceBackend.evaluate — Phase 2');

  @override
  Future<Result<RawJson>> getRemaining(DriverId driverId) =>
      throw UnimplementedError(
        'MockComplianceBackend.getRemaining — Phase 2',
      );
}
