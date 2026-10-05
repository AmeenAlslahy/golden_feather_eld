import '../../../../core/error/app_error.dart';
import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
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

  Future<Result<void>> _accepted(Result<dynamic> res) {
    return Future.value(res.fold(
      err,
      (response) => response.isSuccess
          ? ok(null)
          : err(ServerError(
              code: 'eld.request_failed',
              context: {'message': response.message},
            )),
    ));
  }

  @override
  Future<Result<void>> create(RawJson report) async {
    final res = await _apiClient.post<RawJson>(
      EldEndpoints.dvir,
      data: report,
      parser: (data) => data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
    return _accepted(res);
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
  Future<Result<void>> review({
    required DvirId dvirId,
    required RawJson review,
  }) async {
    final res = await _apiClient.post<RawJson>(
      EldEndpoints.dvirNextDriverReview(dvirId.value),
      data: review,
      parser: (data) => data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
    return _accepted(res);
  }

  RawJson _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List) return {'items': data};
    return <String, dynamic>{};
  }

  @override
  Future<Result<RawJson>> getDefectsCatalog() async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dvirCatalog,
      parser: _asMap,
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getPreviousDvir(String uniqueId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dvirPrevious(uniqueId),
      parser: _asMap,
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getDefectDetails(int defectId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dvirDefectDetails(defectId),
      parser: _asMap,
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getVehicleDefects(String uniqueId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dvirVehicleDefects(uniqueId),
      parser: _asMap,
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }
}
