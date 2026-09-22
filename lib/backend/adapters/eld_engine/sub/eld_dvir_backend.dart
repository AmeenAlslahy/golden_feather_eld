import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/result/result.dart';
import '../../../contracts/dvir_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';
import '../../../http/eld_endpoints.dart';

/// ELD Engine implementation of [DvirBackend].
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
  }) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dvir,
      queryParameters: {
        if (driverId != null) 'driverId': driverId.value,
        if (uniqueId != null) 'uniqueId': uniqueId,
        if (date != null) 'date': date.toIso8601String().split('T').first,
        if (status != null) 'status': status,
        'limit': limit,
        'offset': offset,
      },
      parser: (data) => data is List ? {'data': data} : (data is Map<String, dynamic> ? data : {}),
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<void>> create(RawJson report) async {
    final res = await _apiClient.post<dynamic>(
      EldEndpoints.dvir,
      data: report,
    );
    return res.map((r) => r.isSuccess ? null : throw Exception(r.message));
  }

  @override
  Future<Result<RawJson>> getById(DvirId dvirId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dvirDetails(dvirId.value),
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<void>> certifyRepair({
    required DvirId dvirId,
    required RawJson repair,
  }) async {
    final res = await _apiClient.post<dynamic>(
      EldEndpoints.certifyDvirRepair(dvirId.value),
      data: repair,
    );
    return res.map((r) => r.isSuccess ? null : throw Exception(r.message));
  }

  @override
  Future<Result<void>> review({
    required DvirId dvirId,
    required RawJson review,
  }) async {
    final res = await _apiClient.post<dynamic>(
      EldEndpoints.dvirNextDriverReview(dvirId.value),
      data: review,
    );
    return res.map((r) => r.isSuccess ? null : throw Exception(r.message));
  }

  @override
  Future<Result<RawJson>> getDefectsCatalog() =>
      throw UnimplementedError('EldDvirBackend.getDefectsCatalog — Phase 2');

  @override
  Future<Result<RawJson>> getPreviousDvir(String uniqueId) =>
      throw UnimplementedError('EldDvirBackend.getPreviousDvir — Phase 2');
}
