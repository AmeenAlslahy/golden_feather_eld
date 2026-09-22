import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/result/result.dart';
import '../../../contracts/dvir_backend.dart';
import '../../../contracts/raw_json.dart';

/// In-memory mock for [DvirBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class MockDvirBackend implements DvirBackend {
  const MockDvirBackend();

  @override
  Future<Result<RawJson>> list({
    DriverId? driverId,
    String? uniqueId,
    DateTime? date,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    return ok({'reports': []});
  }

  @override
  Future<Result<void>> create(RawJson report) async {
    return ok(null);
  }

  @override
  Future<Result<RawJson>> getById(DvirId dvirId) =>
      throw UnimplementedError('MockDvirBackend.getById — Phase 2');

  @override
  Future<Result<void>> certifyRepair({
    required DvirId dvirId,
    required RawJson repair,
  }) =>
      throw UnimplementedError('MockDvirBackend.certifyRepair — Phase 2');

  @override
  Future<Result<void>> review({
    required DvirId dvirId,
    required RawJson review,
  }) =>
      throw UnimplementedError('MockDvirBackend.review — Phase 2');

  @override
  Future<Result<RawJson>> getDefectsCatalog() =>
      throw UnimplementedError('MockDvirBackend.getDefectsCatalog — Phase 2');

  @override
  Future<Result<RawJson>> getPreviousDvir(String uniqueId) =>
      throw UnimplementedError('MockDvirBackend.getPreviousDvir — Phase 2');
}
