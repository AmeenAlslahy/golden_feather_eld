import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';

import '../../../../core/utils/logger.dart';
import '../../../../features/hos/domain/engine/hos_rules_engine.dart';
import '../../../../features/hos/domain/engine/tracking/duty_status_tracker.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import 'hos_engine_provider.dart';

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
  }

  DutyStatus _mapStatus(String s) {
    switch (s) {
      case 'driving':
        return DutyStatus.driving;
      case 'on_duty':
        return DutyStatus.onDutyNotDriving;
      case 'sleeper_berth':
        return DutyStatus.sleeperBerth;
      default:
        return DutyStatus.offDuty;
    }
  }

  void _startRefreshTimer() {
    // تحديث الحالة كل دقيقة لتحديث المؤقتات في الواجهة
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      refresh();
    });
  }

  /// تغيير حالة الخدمة
  bool changeStatus(DutyStatus newStatus,
      {String? annotation, bool isYardMoves = false}) {
    if (state is! HosEngineReady) return false;
    final currentHosStatus = (state as HosEngineReady).update.currentStatus;

    final currentSpeedMs = _ref.read(currentVehicleSpeedProvider);
    final currentSpeedKmh = currentSpeedMs != null ? currentSpeedMs * 3.6 : 0.0;
    final speedThreshold =
        _ref.read(hosConfigurationProvider).movingSpeedThresholdKmh;

    final validationResult = _engine.validateManualTransition(
      currentStatus: currentHosStatus,
      newStatus: newStatus,
      currentSpeedKmh: currentSpeedKmh,
      speedThresholdKmh: speedThreshold,
    );

    return validationResult.match(
      (failure) {
        AppLogger.warning('⚠️ ${failure.message}');
        return false;
      },
      (_) {
        String finalAnnotation = annotation ?? '';
        if (isYardMoves && newStatus == DutyStatus.onDutyNotDriving) {
          finalAnnotation = '[YM] $finalAnnotation'.trim();
        }

        String statusStr;
        switch (newStatus) {
          case DutyStatus.driving:
            statusStr = 'driving';
            break;
          case DutyStatus.onDutyNotDriving:
            statusStr = 'on_duty';
            break;
          case DutyStatus.sleeperBerth:
            statusStr = 'sleeper_berth';
            break;
          case DutyStatus.offDuty:
            statusStr = 'off_duty';
            break;
          case DutyStatus.personalUse:
            statusStr = 'personal_use';
            break;
        }

        // This relies on tracking provider deciding to return error if time untrusted.
        _tracker.manualTransition(statusStr,
            annotation: finalAnnotation.isEmpty ? null : finalAnnotation);

        return true;
      },
    );
  }

  /// تحديث الحالة
  void refresh() {
    state = _engine.currentStatus;
  }

  void reset() {
    _tracker.reset();
    _engine.reset();
    refresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _trackerSub?.cancel();
    super.dispose();
  }
}
