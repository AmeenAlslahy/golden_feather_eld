import '../../../../core/error/app_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/contract_enums.dart';
import '../../../contracts/driver_session_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/eld_endpoints.dart';
import '../session_connect.dart';

/// ELD Engine implementation of [DriverSessionBackend].
class EldDriverSessionBackend implements DriverSessionBackend {
  final ApiClient _apiClient;

  const EldDriverSessionBackend(this._apiClient);

  @override
  Future<Result<RawJson>> getActiveSession(DriverId driverId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.eldSession(driverId.value),
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getCurrentCoDriver() async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.manageCoDriver,
      parser: (data) {
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        throw const FormatException('co-driver body is not an object');
      },
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<List<dynamic>>> getAvailableDrivers() async {
    final response = await _apiClient.get<List<dynamic>>(
      EldEndpoints.availableCoDrivers,
      parser: (data) {
        if (data is List) return data;
        if (data is Map && data['availableCoDrivers'] is List) {
          return (data['availableCoDrivers'] as List).cast<dynamic>();
        }
        if (data is Map && data['data'] is List) {
          return (data['data'] as List).cast<dynamic>();
        }
        return <dynamic>[];
      },
    );
    return response.mapValue((r) => r.data ?? <dynamic>[]);
  }

  @override
  Future<Result<RawJson>> connect({
    String? uniqueId,
    bool disconnected = false,
    DriverId? driverId,
    DriverId? coDriverId,
  }) async {
    // العقد الحيّ: لا Query Parameters، والجسم يحمل
    // driverId / coDriverId / deviceId / manualMode / manualModeEnabled.
    // بناء الجسم والمسار (مع بديل /start عند 404) مشترك في [EldSessionConnect].
    final res = await EldSessionConnect.post(
      apiClient: _apiClient,
      payload: EldSessionConnect.payload(
        uniqueId: uniqueId,
        disconnected: disconnected,
        driverId: driverId,
        coDriverId: coDriverId,
      ),
      // ملاحظة: هذا القارئ المتراخي هو السلوك القديم المحفوظ عن قصد —
      // لا يُوحّد مع قارئ مسار الأجهزة (انظر [EldSessionConnect]).
      parser: EldSessionConnect.parseTypedMapBody,
    );
    return res.mapValue(EldSessionConnect.dataOrEmpty);
  }

  @override
  Future<Result<RawJson>> disconnect() async {
    final res = await _apiClient.post<RawJson>(
      EldEndpoints.disconnectSession,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<void>> switchPrimaryDriver({
    required DutyStatusAction action,
    required DriverId coDriverId,
    String? reason,
  }) async {
    final payload = <String, dynamic>{
      'action': action.wire,
      'coDriverId': coDriverId.value,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    };
    final res = await _apiClient.post<RawJson>(
      EldEndpoints.switchPrimaryDriver,
      queryParameters: payload,
      data: payload,
      parser: (data) =>
          data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
    return res.fold(
      err,
      (response) => response.isSuccess
          ? ok(null)
          : err(
              ServerError(
                code: 'eld.request_failed',
                context: {'message': response.message},
              ),
            ),
    );
  }
}
