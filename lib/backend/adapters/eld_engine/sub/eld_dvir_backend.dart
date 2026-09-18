// ignore_for_file: unused_field, unused_import

import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/dvir_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';

/// ELD Engine implementation of [DvirBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldDvirBackend implements DvirBackend {
  final ApiClient _apiClient;

  const EldDvirBackend(this._apiClient);

  @override
  Future<Result<RawJson>> list({
    DriverId? driverId,
    String? uniqueId,
    DateTime? date,
    String? status,
    int limit = 50,
    int offset = 0,
  }) =>
      throw UnimplementedError('EldDvirBackend.list — Phase 2');

  @override
  Future<Result<void>> create(RawJson report) =>
      throw UnimplementedError('EldDvirBackend.create — Phase 2');

  @override
  Future<Result<RawJson>> getById(DvirId dvirId) =>
      throw UnimplementedError('EldDvirBackend.getById — Phase 2');

  @override
  Future<Result<void>> certifyRepair({
    required DvirId dvirId,
    required RawJson repair,
  }) =>
      throw UnimplementedError('EldDvirBackend.certifyRepair — Phase 2');

  @override
  Future<Result<void>> review({
    required DvirId dvirId,
    required RawJson review,
  }) =>
      throw UnimplementedError('EldDvirBackend.review — Phase 2');

  @override
  Future<Result<RawJson>> getDefectsCatalog() =>
      throw UnimplementedError('EldDvirBackend.getDefectsCatalog — Phase 2');

  @override
  Future<Result<RawJson>> getPreviousDvir(String uniqueId) =>
      throw UnimplementedError('EldDvirBackend.getPreviousDvir — Phase 2');
}
