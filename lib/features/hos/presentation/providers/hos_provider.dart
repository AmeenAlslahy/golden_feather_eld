import "../../data/providers/hos_audit_providers.dart";
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/hos/domain/engine/hos_rules_engine.dart';
import 'hos_engine_provider.dart';
import '../../../../core/utils/logger.dart';

import '../../../../features/hos/domain/engine/tracking/duty_status_tracker.dart';
import '../../../../core/events/eld_events_provider.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../domain/duty_status/duty_status_code.dart';

/// مزود حالة HOS
final hosStatusProvider =
    StateNotifierProvider<HosNotifier, HosEngineResult>((ref) {
  final engine = ref.watch(hosEngineProvider);
  final tracker = ref.watch(dutyStatusTrackerProvider);
  return HosNotifier(engine, tracker, ref);
});

class HosNotifier extends StateNotifier<HosEngineResult> {
  final HosRulesEngine _engine;
  final DutyStatusTracker _tracker;
  final Ref _ref;
  Timer? _refreshTimer;
  StreamSubscription? _trackerSub;

  HosNotifier(this._engine, this._tracker, this._ref)
      : super(_engine.currentStatus) {
    _startRefreshTimer();
    _trackerSub = _tracker.onTransition.listen((transition) {
      final status = _mapStatus(transition.newStatus);
      final currentStatus = state is HosEngineReady
          ? (state as HosEngineReady).update.currentStatus
          : DutyStatus.offDuty;

      if (currentStatus != status) {
        AppLogger.info(
            '🔄 Syncing HOS UI with DutyStatusTracker: ${transition.newStatus}');
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
    // تحديث الحالة كل دقيقة لتحديث المؤقتات في الواجهة
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      refresh();
    });
  }

  /// تغيير حالة الخدمة. null يعني أن الخادم قبل الختم. أي نص آخر سبب رفض.
  Future<String?> changeStatus(DutyStatus newStatus,
      {String? annotation, bool isYardMoves = false}) async {
    if (state is! HosEngineReady) return DutyStampRefusal.notReady;
    final currentHosStatus = (state as HosEngineReady).update.currentStatus;

    final currentSpeedKmh = _ref.read(currentSpeedKmhProvider);

    final validationResult = _engine.validateManualTransition(
      currentStatus: currentHosStatus,
      newStatus: newStatus,
      currentSpeedKmh: currentSpeedKmh,
      speedThresholdKmh:
          _ref.read(hosConfigurationProvider).movingSpeedThresholdKmh,
    );

    if (validationResult.isLeft()) {
      AppLogger.warning('⚠️ ${validationResult.fold((f) => f.message, (_) => '')}');
      return DutyStampRefusal.moving;
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
        statusCode = isYardMoves ? DutyStatusCode.yardMove : DutyStatusCode.onDutyNotDriving;
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

    return _tracker.submitManualChange(statusCode.engineCode,
        annotation: finalAnnotation.isEmpty ? null : finalAnnotation);
  }

  /// تحديث الحالة

  void _processAndLogViolations(HosEngineResult result) {
    if (result is HosEngineReady && result.update.violations.isNotEmpty) {
      final auditRepo = _ref.read(hosAuditRepositoryProvider);
      for (final v in result.update.violations) {
        auditRepo.logViolation(v);
      }
    }
  }

  void refresh() {
    final next = _engine.currentStatus;
    _processAndLogViolations(next);
    if (mounted && next != state) state = next;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _trackerSub?.cancel();
    super.dispose();
  }
}
