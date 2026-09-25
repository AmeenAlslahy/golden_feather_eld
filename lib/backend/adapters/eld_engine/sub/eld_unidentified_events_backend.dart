// ignore_for_file: unused_field, unused_import

import '../../../../core/error/app_error.dart';
import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/contract_enums.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/unidentified_events_backend.dart';
import '../../../http/api_client.dart';
import '../../../http/eld_endpoints.dart';

/// Driver claim/reject of unidentified driving (SRS §7.13, §8.8, §11).
class EldUnidentifiedEventsBackend implements UnidentifiedEventsBackend {
  final ApiClient _apiClient;

  const EldUnidentifiedEventsBackend(this._apiClient);

  RawJson _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List) return {'items': data};
    return <String, dynamic>{};
  }

  Future<Result<void>> _postVoid(String path, Map<String, dynamic> data) async {
    final res = await _apiClient.post<RawJson>(
      path,
      data: data,
      parser: _asMap,
    );
    return res.fold(
      err,
      (response) => response.isSuccess
          ? ok(null)
          : err(ServerError(
              code: 'eld.request_failed',
              context: {'message': response.message},
            )),
    );
  }

  @override
  Future<Result<RawJson>> list({
    UnidentifiedTab tab = UnidentifiedTab.unclaimed,
    String? uniqueId,
    DriverId? driverId,
  }) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.unidentifiedEvents,
      queryParameters: {
        'tab': tab.wire,
        if (uniqueId != null && uniqueId.isNotEmpty) 'uniqueId': uniqueId,
        if (driverId != null) 'driverId': driverId.value,
      },
      parser: _asMap,
    );
    return res.mapValue((response) => response.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<void>> claim({
    required DutyStatusId id,
    required DriverId driverId,
    required String annotation,
  }) {
    return _postVoid(EldEndpoints.claimUnidentified(id.value), {
      'driverId': driverId.value,
      'annotation': annotation,
    });
  }

  @override
  Future<Result<void>> reject({
    required DutyStatusId id,
    required DriverId driverId,
    required String rejectionReason,
  }) {
    return _postVoid(EldEndpoints.rejectUnidentified(id.value), {
      'driverId': driverId.value,
      'rejectionReason': rejectionReason,
    });
  }
}
