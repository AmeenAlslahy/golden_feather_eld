import '../../../../core/result/result.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/duty_status/duty_status_code.dart';
import '../../../../domain/duty_status/status_dashboard.dart';
import '../../../../domain/duty_status/weekly_recap.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/status_dashboard_backend.dart';
import '../../../../core/network/api_client.dart';
import '../../../http/eld_endpoints.dart';
import '../mappers/status_dashboard_mapper.dart';

/// ELD Engine implementation of [StatusDashboardBackend].
class EldStatusDashboardBackend implements StatusDashboardBackend {
  final ApiClient _apiClient;
  String? _lastServerMessage;

  EldStatusDashboardBackend(this._apiClient);

  @override
  String? get lastServerMessage => _lastServerMessage;

  @override
  Future<Result<StatusDashboard>> getDashboard({DriverId? driverId}) {
    return _apiClient
        .get<Map<String, dynamic>>(
          EldEndpoints.statusDashboard,
          queryParameters: driverId != null
              ? {'driverId': driverId.value}
              : null,
          parser: (data) => data is Map<String, dynamic> ? data : {},
        )
        .then(
          (result) => result.mapValue(
            (response) => StatusDashboardMapper.fromDashboardJson(
              response.data ?? const {},
            ),
          ),
        );
  }

  @override
  Future<Result<StatusDashboard?>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
    DriverId? driverId,
    VehicleId? vehicleId,
    double? latitude,
    double? longitude,
  }) {
    final effectiveNote = (notes != null && notes.trim().isNotEmpty)
        ? notes.trim()
        : _defaultNoteFor(status);

    final payload = <String, dynamic>{
      'dutyStatus': status.wire,
      'notes': effectiveNote,
    };
    if (driverId != null && driverId.value > 0) {
      payload['driverId'] = driverId.value;
    }
    if (vehicleId != null && vehicleId.value > 0) {
      payload['vehicleId'] = vehicleId.value;
    }
    // إحداثيات لحظة التغيير داخل location متداخل — تُرسل فقط عند توفرهما
    // معًا وقيمتهما ليست 0,0 (0,0 = لا إصلاح GPS حسب أسبقية التطبيق).
    // غيابهما ⇒ حذف الحقل كليًا، لا إحداثيات مُختلَقة.
    final hasValidLocation = latitude != null &&
        longitude != null &&
        !(latitude == 0 && longitude == 0);
    if (hasValidLocation) {
      payload['location'] = {'latitude': latitude, 'longitude': longitude};
    }

    return _apiClient
        .post<Map<String, dynamic>>(
          EldEndpoints.updateDutyStatus,
          data: payload,
          // بلا ResponseType.plain: نفس مسار GET — يفكّ ApiResponse غلاف
          // `{success, data}` تلقائياً، فلا يصل للمحوّل غلافٌ كامل يُقرأ
          // ككائن بلا مفاتيح لوحة (السبب الجذري لعرض أصفار بعد التغيير).
          parser: (data) => data is Map<String, dynamic> ? data : {},
        )
        .then(
          (result) => result.mapValue((response) {
            _lastServerMessage = response.message;
            final json = response.data ?? const <String, dynamic>{};
            final map = Map<String, dynamic>.from(json);
            // لقطة اللوحة فقط إن حملها الجسم فعلاً. سجل حالة بلا حقول
            // اللوحة ≠ لوحة بقيم صفرية — نُعيد null ونتصالح مع الخادم
            // عبر GET بدل اختلاق أصفار تغذّي العدّادات القانونية.
            if (!_hasDashboardSnapshot(map)) {
              AppLogger.info(
                'updateDutyStatus: accepted without dashboard snapshot '
                '(response carries no dashboard fields)',
              );
              return null;
            }
            if (map['currentDutyStatus'] == null) {
              map['currentDutyStatus'] = status.wire;
            }
            return StatusDashboardMapper.fromDashboardJson(map);
          }),
        );
  }

  /// هل يحمل الجسم حقول اللوحة الرقمية؟ (يكفي مؤشر واحد منها كدليل)
  static bool _hasDashboardSnapshot(Map<String, dynamic> json) {
    return json['remainingCircle'] != null || json['hosIndicators'] != null;
  }

  @override
  Future<Result<WeeklyRecap>> getWeeklyRecap({DriverId? driverId}) {
    return _apiClient
        .get<Map<String, dynamic>>(
          EldEndpoints.statusRecap,
          queryParameters: driverId != null
              ? {'driverId': driverId.value}
              : null,
          parser: (data) => data is Map<String, dynamic> ? data : {},
        )
        .then(
          (result) => result.mapValue(
            (response) =>
                StatusDashboardMapper.fromRecapJson(response.data ?? const {}),
          ),
        );
  }

  static String _defaultNoteFor(DutyStatusCode status) {
    switch (status) {
      case DutyStatusCode.onDutyNotDriving:
        return 'Available';
      case DutyStatusCode.sleeperBerth:
        return 'Sleeper Berth';
      case DutyStatusCode.driving:
        return 'Driving';
      case DutyStatusCode.offDuty:
        return 'Off Duty';
      case DutyStatusCode.yardMove:
        return 'Yard Move';
      case DutyStatusCode.personalConveyance:
        return 'Personal Conveyance';
    }
  }
}
