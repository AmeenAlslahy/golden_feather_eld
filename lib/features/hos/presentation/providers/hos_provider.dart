import "../../data/providers/hos_audit_providers.dart";
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/hos/domain/engine/hos_rules_engine.dart';
import 'hos_engine_provider.dart';
import '../../../../core/utils/logger.dart';

import '../../../../features/hos/domain/engine/tracking/duty_status_tracker.dart';
import '../../../../core/events/eld_events_provider.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../domain/duty_status/duty_status_code.dart';

/// مزود حالة HOS
final hosStatusProvider = StateNotifierProvider<HosNotifier, HosEngineResult>((
  ref,
) {
  final engine = ref.watch(hosEngineProvider);
  final tracker = ref.watch(dutyStatusTrackerProvider);
  return HosNotifier(engine, tracker, ref);
});

class HosNotifier extends StateNotifier<HosEngineResult>
    with WidgetsBindingObserver {
  final HosRulesEngine _engine;
  final DutyStatusTracker _tracker;
  final Ref _ref;
  Timer? _refreshTimer;
  StreamSubscription? _trackerSub;

  /// بصمة آخر مخالفات عولجت — تمنع مسح/كتابة Hive عند كل نبضة GPS أو
  /// دقيقة بينما المخالفة نفسها ما زالت قائمة.
  String? _lastViolationSignature;

  HosNotifier(this._engine, this._tracker, this._ref)
    : super(_engine.currentStatus) {
    _attachLifecycle();
    _startRefreshTimer();
    _trackerSub = _tracker.onTransition.listen((transition) {
      final status = _mapStatus(transition.newStatus);
      final currentStatus = state is HosEngineReady
          ? (state as HosEngineReady).update.currentStatus
          : DutyStatus.offDuty;

      if (currentStatus != status) {
        AppLogger.info(
          '🔄 Syncing HOS UI with DutyStatusTracker: ${transition.newStatus}',
        );
        _engine.manualTransition(status, annotation: transition.annotation);
        refresh();
      }
    });

    _ref.listen<AsyncValue<EldEvent>>(eldEventsStreamProvider, (_, next) {
      final event = next.value;
      if (event == null) return;
      if (!_ref.read(authStateProvider).isAuthenticated) return;
      if (event.timestamp.millisecondsSinceEpoch == 0) return;
      final result = _engine.processEvent(event);
      // لا تنشر state جديد إذا لم تتغير القيم فعلياً (كل نبضة GPS كانت
      // تُنشئ كائناً جديداً وتُعيد بناء المستمعين بلا فائدة).
      _processAndLogViolations(result);
      if (mounted && result != state) state = result;
    });
  }

  DutyStatus _mapStatus(String s) {
    final code = DutyStatusCode.fromAny(s);
    switch (code) {
      case DutyStatusCode.driving:
        return DutyStatus.driving;
      case DutyStatusCode.onDutyNotDriving:
      case DutyStatusCode.yardMove:
        return DutyStatus.onDutyNotDriving;
      case DutyStatusCode.sleeperBerth:
        return DutyStatus.sleeperBerth;
      case DutyStatusCode.personalConveyance:
        return DutyStatus.personalUse;
      case DutyStatusCode.offDuty:
        return DutyStatus.offDuty;
    }
  }

  void _startRefreshTimer() {
    // تحديث الحالة كل دقيقة لتحديث المؤقتات في الواجهة.
    // إعادة البدء آمنة: نلغي أي مؤقّت سابق أولاً (العودة للمقدمة).
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      refresh();
    });
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// مراقبة دورة الحياة: كان المؤقّت يعمل طوال عمر العملية حتى في
  /// الخلفية حيث لا واجهة تُحدَّث. الإيقاف في الخلفية يوقف عمل عدّاد
  /// HOS الدوري بلا فقدان أي حساب — كل نبضة تعيد الحساب من الحالة.
  void _attachLifecycle() {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {
      // اختبار وحدات بلا WidgetsBinding — يبقى المؤقّت كما هو.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _startRefreshTimer();
        refresh();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _stopRefreshTimer();
    }
  }

  /// تغيير حالة الخدمة. يُعاد توجيه نتيجة المتتبع كما هي (رفض اختياري
  /// مع لقطة لوحة الخادم عند القبول لتغذية اللوحة فوراً).
  Future<ManualDutyChangeResult> changeStatus(
    DutyStatus newStatus, {
    String? annotation,
    bool isYardMoves = false,
    double? latitude,
    double? longitude,
  }) async {
    if (state is! HosEngineReady || !_tracker.isHydrated) {
      return const ManualDutyChangeResult(refusal: DutyStampRefusal.notReady);
    }
    final currentHosStatus = (state as HosEngineReady).update.currentStatus;

    final currentSpeedKmh = _ref.read(currentSpeedKmhProvider);

    final validationResult = _engine.validateManualTransition(
      currentStatus: currentHosStatus,
      newStatus: newStatus,
      currentSpeedKmh: currentSpeedKmh,
      speedThresholdKmh: _ref
          .read(hosConfigurationProvider)
          .movingSpeedThresholdKmh,
    );

    if (validationResult.isLeft()) {
      AppLogger.warning(
        '⚠️ ${validationResult.fold((f) => f.message, (_) => '')}',
      );
      return const ManualDutyChangeResult(refusal: DutyStampRefusal.moving);
    }

    String finalAnnotation = annotation ?? '';
    if (isYardMoves && newStatus == DutyStatus.onDutyNotDriving) {
      finalAnnotation = '[YM] $finalAnnotation'.trim();
    }

    DutyStatusCode statusCode;
    switch (newStatus) {
      case DutyStatus.driving:
        statusCode = DutyStatusCode.driving;
        break;
      case DutyStatus.onDutyNotDriving:
        statusCode = isYardMoves
            ? DutyStatusCode.yardMove
            : DutyStatusCode.onDutyNotDriving;
        break;
      case DutyStatus.sleeperBerth:
        statusCode = DutyStatusCode.sleeperBerth;
        break;
      case DutyStatus.offDuty:
        statusCode = DutyStatusCode.offDuty;
        break;
      case DutyStatus.personalUse:
        statusCode = DutyStatusCode.personalConveyance;
        break;
    }

    return _tracker.submitManualChange(
      statusCode.engineCode,
      annotation: finalAnnotation.isEmpty ? null : finalAnnotation,
      lat: latitude,
      lon: longitude,
    );
  }

  /// تحديث الحالة

  void _processAndLogViolations(HosEngineResult result) {
    if (result is! HosEngineReady || result.update.violations.isEmpty) {
      _lastViolationSignature = null;
      return;
    }

    final violations = result.update.violations;
    final signature = violations
        .map(
          (v) =>
              '${v.type.name}:${v.timestamp.toIso8601String().substring(0, 10)}',
        )
        .join('|');
    if (signature == _lastViolationSignature) return;
    _lastViolationSignature = signature;

    final auditRepo = _ref.read(hosAuditRepositoryProvider);
    for (final v in violations) {
      auditRepo.logViolation(v);
    }
  }

  void refresh() {
    final next = _engine.currentStatus;
    _processAndLogViolations(next);
    if (mounted && next != state) state = next;
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {
      // بلا WidgetsBinding (اختبار وحدات) — لا شيء يُزال.
    }
    _stopRefreshTimer();
    _trackerSub?.cancel();
    super.dispose();
  }
}
