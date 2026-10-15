import 'dart:convert';

import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/utils/logger.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/duty_status/weekly_recap.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';

/// لقطة لوحة محفوظة مع لحظة قياسها.
///
/// **لماذا الحزمة معاً:** `GET /eld/status` لا يحمل أي طابع زمني، والعدّاد
/// التنازلي يطرح `(الآن الموثوقة − لحظة القياس)` من قيمة الخادم. لقطة بلا
/// لحظة قياس تُقرأ كأنها حديثة، فيُقدَّم وقتٌ قديم على أنه رصيد قانوني
/// قائم. حفظ اللحظة بجوار القيمة هو ما يمنع ذلك.
class CachedDashboard {
  const CachedDashboard({required this.dashboard, required this.takenAt});

  final StatusDashboard dashboard;

  /// اللحظة (UTC) التي قِيست عندها القيم، على الساعة الموثوقة.
  final DateTime takenAt;
}

/// تخزين محلي لآخر لوحة/ملخص ناجحين من الخادم.
///
/// السبب: شرط "العمل أوفلاين كالأونلاين" يفرض أن يبقىDriver يرى آخر حالة
/// معروفة عبر إغلاق التطبيق وغياب الشبكة. قبل هذا كانت اللوحة محفوظة في
/// متغيّر داخل الذاكرة فقط فتفقد كل شيء عند إعادة التشغيل.
abstract class DashboardLocalCache {
  /// [takenAt] يجب أن يكون الساعة **الموثوقة**، لا `DateTime.now()`:
  /// ختم اللقطة بساعة الجهاز يسمح للسائق بتجميد العدّاد القانوني أو
  /// تعجيله بتعديل ساعة جهازه.
  Future<void> saveDashboard(StatusDashboard dashboard,
      {required DateTime takenAt});
  CachedDashboard? loadDashboard();

  Future<void> saveRecap(WeeklyRecap recap);
  WeeklyRecap? loadRecap();

  /// مسح البيانات المحفوظة (عند تبديل السائق/الدورة).
  Future<void> clear();
}

class PrefsDashboardLocalCache implements DashboardLocalCache {
  PrefsDashboardLocalCache(this._storage);

  final LocalStorageService _storage;

  static const String _dashKey = 'hos_dashboard_snapshot';
  static const String _recapKey = 'hos_recap_snapshot';

  @override
  Future<void> saveDashboard(StatusDashboard dashboard,
      {required DateTime takenAt}) async {
    try {
      await _storage.prefs.setString(
        _dashKey,
        jsonEncode(_encodeDashboard(dashboard, takenAt: takenAt)),
      );
    } catch (e) {
      AppLogger.warning('DashboardLocalCache.saveDashboard failed: $e');
    }
  }

  @override
  CachedDashboard? loadDashboard() {
    try {
      final raw = _storage.prefs.getString(_dashKey);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) return null;

      // 🛡️ لقطة بلا لحظة قياس **غير صالحة للاستخدام العددي**.
      //
      // اللقطة القديمة (قبل هذا الإصلاح) كانت تُحفظ بلا طابع، أو بختم
      // `DateTime.now()` — فتُستأنف كأن عمرها صفر. عرضها يعطي السائق رصيداً
      // قانونياً أكبر من الحقيقي، فلا نقبلها إلا إذا صحّ الطابع. نسجّل
      // ونُهملها فيرجع التطبيق للمحرك المحلي أو لجلب جديد.
      final takenAtRaw = map['takenAtIso'];
      final takenAt =
          takenAtRaw is String ? DateTime.tryParse(takenAtRaw)?.toUtc() : null;
      if (takenAt == null) {
        AppLogger.warning(
            'DashboardLocalCache: snapshot without a trusted measurement '
            'instant — discarded (age unknown)');
        return null;
      }

      final dashboard = _decodeDashboard(map);
      if (dashboard == null) return null;
      return CachedDashboard(dashboard: dashboard, takenAt: takenAt);
    } catch (e) {
      AppLogger.warning('DashboardLocalCache.loadDashboard failed: $e');
      return null;
    }
  }

  @override
  Future<void> saveRecap(WeeklyRecap recap) async {
    try {
      await _storage.prefs
          .setString(_recapKey, jsonEncode(_encodeRecap(recap)));
    } catch (e) {
      AppLogger.warning('DashboardLocalCache.saveRecap failed: $e');
    }
  }

  @override
  WeeklyRecap? loadRecap() {
    try {
      final raw = _storage.prefs.getString(_recapKey);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) return null;
      return _decodeRecap(map);
    } catch (e) {
      AppLogger.warning('DashboardLocalCache.loadRecap failed: $e');
      return null;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.prefs.remove(_dashKey);
      await _storage.prefs.remove(_recapKey);
    } catch (e) {
      AppLogger.warning('DashboardLocalCache.clear failed: $e');
    }
  }

  // ---------------------------------------------------------------------
  // Encoding
  // ---------------------------------------------------------------------

  static Map<String, dynamic> _encodeDashboard(StatusDashboard d,
          {required DateTime takenAt}) =>
      {
        'driver': {'id': d.driver.id.value, 'name': d.driver.name, 'displayText': d.driver.displayText},
        'toolIcon': d.operationalAlerts.toolIcon,
        'warningTriangleIcon': d.operationalAlerts.warningTriangleIcon,
        'connectionStatus': d.operationalAlerts.connectionStatus.wire,
        'currentDutyStatus': d.currentDutyStatus.wire,
        'circle': {'remaining': d.remainingCircle.remaining.inMinutes, 'label': d.remainingCircle.label, 'progress': d.remainingCircle.progress},
        'drive': _encodeIndicator(d.hosIndicators.drive),
        'shift': _encodeIndicator(d.hosIndicators.shift),
        'breakTime': _encodeIndicator(d.hosIndicators.breakTime),
        'cycle': _encodeIndicator(d.hosIndicators.cycle),
        'ruleSet': d.regulatoryConstraints.ruleSet.wire,
        'limits': d.regulatoryConstraints.limits,
        // لحظة القياس على الساعة الموثوقة — لا DateTime.now().
        // ⚠️ هذا هو الحقل الذي كان يُكتب باسم 'snapshotIso' بقيمة ساعة
        // الجهاز ثم **لا يُقرأ أبداً**، فكانت اللقطة تعود من القرص وتُختم
        // بلحظة "الآن" ويُعاد تقديم الوقت القديم كأنه متبقٍّ.
        'takenAtIso': takenAt.toUtc().toIso8601String(),
      };

  static Map<String, dynamic> _encodeIndicator(HosIndicator i) =>
      {'label': i.label, 'value': i.value.inMinutes, 'type': i.type.wire};

  static Map<String, dynamic> _encodeRecap(WeeklyRecap r) => {
        'cycleRule': r.cycleRule.wire,
        'cycleUsed': r.cycleUsed.inMinutes,
        'cycleRemaining': r.cycleRemaining.inMinutes,
        'availableTomorrow': r.availableTomorrow.inMinutes,
        'days': r.days
            .map((d) => {
                  'date': d.date.toIso8601String(),
                  'dayOfWeek': d.dayOfWeek,
                  'driving': d.driving.inMinutes,
                  'onDuty': d.onDuty.inMinutes,
                  'totalWork': d.totalWork.inMinutes,
                })
            .toList(),
      };

  // ---------------------------------------------------------------------
  // Decoding
  // ---------------------------------------------------------------------

  static StatusDashboard? _decodeDashboard(Map<String, dynamic> m) {
    final driver = m['driver'];
    final circle = m['circle'];
    if (circle is! Map<String, dynamic>) return null;

    final indicators = <String, dynamic>{
      'drive': m['drive'],
      'shift': m['shift'],
      'breakTime': m['breakTime'],
      'cycle': m['cycle'],
    };

    HosIndicator ind(String key, String label) {
      final raw = indicators[key];
      if (raw is! Map<String, dynamic>) {
        return HosIndicator(
          label: label,
          value: Duration.zero,
          type: IndicatorType.remaining,
        );
      }
      return HosIndicator(
        label: (raw['label'] as String?) ?? label,
        value: Duration(minutes: (raw['value'] as num?)?.toInt() ?? 0),
        type: IndicatorType.fromWire(raw['type'] as String?),
      );
    }

    return StatusDashboard(
      driver: DriverRef(
        id: DriverId((driver is Map<String, dynamic>)
            ? ((driver['id'] as num?)?.toInt() ?? 0)
            : 0),
        name: (driver is Map<String, dynamic>) ? (driver['name'] as String? ?? '') : '',
        displayText: (driver is Map<String, dynamic>) ? (driver['displayText'] as String? ?? '') : '',
      ),
      operationalAlerts: OperationalAlerts(
        toolIcon: m['toolIcon'] == true,
        warningTriangleIcon: m['warningTriangleIcon'] == true,
        connectionStatus:
            ConnectionStatus.fromWire(m['connectionStatus'] as String?),
      ),
      currentDutyStatus:
          DutyStatusCode.fromWire(m['currentDutyStatus'] as String?),
      remainingCircle: RemainingCircle(
        remaining: Duration(
            minutes: (circle['remaining'] as num?)?.toInt() ?? 0),
        label: (circle['label'] as String?) ?? 'Remaining',
        progress: ((circle['progress'] as num?)?.toDouble() ?? 0.0)
            .clamp(0.0, 1.0),
      ),
      hosIndicators: HosIndicators(
        drive: ind('drive', 'DRIVE'),
        shift: ind('shift', 'SHIFT'),
        breakTime: ind('breakTime', 'BREAK'),
        cycle: ind('cycle', 'CYCLE'),
      ),
      regulatoryConstraints: RegulatoryConstraints(
        ruleSet: CycleRule.fromWire(m['ruleSet'] as String?),
        limits: (m['limits'] as List?)?.map((e) => '$e').toList() ?? const [],
      ),
    );
  }

  static WeeklyRecap? _decodeRecap(Map<String, dynamic> m) {
    final days = <RecapDay>[];
    final rawDays = m['days'];
    if (rawDays is List) {
      for (final e in rawDays) {
        if (e is! Map<String, dynamic>) continue;
        final date = DateTime.tryParse('${e['date']}');
        if (date == null) continue;
        days.add(RecapDay(
          date: date,
          dayOfWeek: (e['dayOfWeek'] as String?) ?? '',
          driving: Duration(minutes: (e['driving'] as num?)?.toInt() ?? 0),
          onDuty: Duration(minutes: (e['onDuty'] as num?)?.toInt() ?? 0),
          totalWork:
              Duration(minutes: (e['totalWork'] as num?)?.toInt() ?? 0),
        ));
      }
    }
    return WeeklyRecap(
      cycleRule: CycleRule.fromWire(m['cycleRule'] as String?),
      cycleUsed: Duration(minutes: (m['cycleUsed'] as num?)?.toInt() ?? 0),
      cycleRemaining:
          Duration(minutes: (m['cycleRemaining'] as num?)?.toInt() ?? 0),
      availableTomorrow:
          Duration(minutes: (m['availableTomorrow'] as num?)?.toInt() ?? 0),
      days: days,
    );
  }
}