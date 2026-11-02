import '../../../../core/error/app_error.dart';
import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/dvir_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../../core/network/api_client.dart';
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
    final page = limit > 0 ? offset ~/ limit : 0;
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dvir,
      queryParameters: {
        if (driverId != null) 'driverId': driverId.value,
        if (uniqueId != null) 'uniqueId': uniqueId,
        if (date != null) 'date': date.toIso8601String().split('T').first,
        if (status != null) 'status': status,
        'page': page,
        'size': limit,
        'limit': limit,
        'offset': offset,
      },
      parser: (data) => data is List
          ? {'data': data}
          : (data is Map<String, dynamic> ? data : {}),
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  Future<Result<void>> _accepted(Result<dynamic> res) {
    return Future.value(
      res.fold(
        err,
        (response) => response.isSuccess
            ? ok(null)
            : err(
                ServerError(
                  code: 'eld.request_failed',
                  context: {'message': response.message},
                ),
              ),
      ),
    );
  }

  @override
  Future<Result<void>> create(
    RawJson report, {
    int? expectedOwnerDriverId,
  }) async {
    final query = <String, dynamic>{};
    if (report['deviceId'] != null) {
      query['deviceId'] = report['deviceId'];
    }
    final res = await _apiClient.post<RawJson>(
      EldEndpoints.dvir,
      queryParameters: query.isNotEmpty ? query : null,
      data: report,
      parser: (data) =>
          data is Map<String, dynamic> ? data : <String, dynamic>{},
      expectedOwnerDriverId: expectedOwnerDriverId,
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
    int? expectedOwnerDriverId,
  }) async {
    final payload = Map<String, dynamic>.from(review);
    payload.putIfAbsent('previousDvirId', () => dvirId.value);
    payload.putIfAbsent(
      'driverSatisfiedSafe',
      () => review['driverAgreed'] ?? true,
    );

    final res = await _apiClient.post<RawJson>(
      EldEndpoints.dvirPreviousReview,
      data: payload,
      parser: (data) =>
          data is Map<String, dynamic> ? data : <String, dynamic>{},
      expectedOwnerDriverId: expectedOwnerDriverId,
    );

    return res.fold(
      (error) async {
        if (error is ServerError &&
            (error.code == 'http_404' || error.code.contains('404'))) {
          final fallbackRes = await _apiClient.post<RawJson>(
            EldEndpoints.dvirNextDriverReview(dvirId.value),
            data: payload,
            parser: (data) =>
                data is Map<String, dynamic> ? data : <String, dynamic>{},
            expectedOwnerDriverId: expectedOwnerDriverId,
          );
          return _accepted(fallbackRes);
        }
        return err(error);
      },
      (success) => _accepted(res),
    );
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
      EldEndpoints.dvirPreviousReport,
      queryParameters: {
        'uniqueId': uniqueId,
        'deviceId': uniqueId,
      },
      parser: _asMap,
    );
    return res.fold(
      (error) async {
        if (error is ServerError &&
            (error.code == 'http_404' || error.code.contains('404'))) {
          final fallback = await _apiClient.get<RawJson>(
            EldEndpoints.dvirPrevious(uniqueId),
            parser: _asMap,
          );
          return fallback.mapValue((r) => r.data ?? <String, dynamic>{});
        }
        return err(error);
      },
      (success) => ok(success.data ?? <String, dynamic>{}),
    );
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
