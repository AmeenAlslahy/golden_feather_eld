import 'package:golden_feather_eld/core/engine/hos_models.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/engine/hos_rules_engine.dart';
import '../../../../core/engine/hos_state_machine.dart';
import '../../../../core/utils/logger.dart';

import '../../../../core/engine/tracking/duty_status_tracker.dart';

/// مزود حالة HOS
final hosStatusProvider = StateNotifierProvider<HosNotifier, HosStatusUpdate>((ref) {
  final engine = ref.watch(hosEngineProvider);
  final tracker = ref.watch(dutyStatusTrackerProvider);
  return HosNotifier(engine, tracker);
});

class HosNotifier extends StateNotifier<HosStatusUpdate> {
  final HosRulesEngine _engine;
  final DutyStatusTracker _tracker;
  Timer? _refreshTimer;
  StreamSubscription? _trackerSub;

  HosNotifier(this._engine, this._tracker) : super(_engine.currentStatus) {
    _startRefreshTimer();
    _trackerSub = _tracker.onTransition.listen((transition) {
      final status = _mapStatus(transition.newStatus);
      if (state.currentStatus != status) {
        AppLogger.info('🔄 Syncing HOS UI with DutyStatusTracker: ${transition.newStatus}');
        _engine.manualTransition(status, annotation: transition.annotation);
        refresh();
      }
    });
  }

  DutyStatus _mapStatus(String s) {
    switch (s) {
      case 'driving': return DutyStatus.driving;
      case 'on_duty': return DutyStatus.onDutyNotDriving;
      case 'sleeper_berth': return DutyStatus.sleeperBerth;
      default: return DutyStatus.offDuty;
    }
  }

  void _startRefreshTimer() {
    // تحديث الحالة كل دقيقة لتحديث المؤقتات في الواجهة
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      refresh();
    });
  }

  /// تغيير حالة الخدمة
  bool changeStatus(DutyStatus newStatus, {String? annotation, double? currentSpeed}) {
    if (state.currentStatus == DutyStatus.driving && newStatus != DutyStatus.driving) {
      if (currentSpeed != null && currentSpeed >= 8.0) {
        AppLogger.warning('⚠️ Cannot manually change from DRIVING while vehicle is moving');
        // تم رفض التغيير
        return false;
      }
    }
    
    _engine.manualTransition(newStatus, annotation: annotation);
    refresh();
    return true;
  }
  
  /// تحديث الحالة
  void refresh() {
    state = _engine.currentStatus;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _trackerSub?.cancel();
    super.dispose();
  }
}



