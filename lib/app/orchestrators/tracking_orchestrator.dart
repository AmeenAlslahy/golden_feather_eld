import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/tracking/presentation/providers/tracking_provider.dart';
import '../../features/tracking/data/providers/tracking_providers.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/vehicle/presentation/providers/vehicle_provider.dart';
import '../../features/hos/presentation/providers/hos_provider.dart';
import '../../features/hos/domain/engine/hos_rules_engine.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import '../../core/utils/logger.dart';
import '../../domain/hardware/telemetry_reading.dart';
import '../../domain/shared/value_objects.dart';
import '../../backend/providers/backend_providers.dart';
import '../../core/constants/fmcsa_constants.dart';

final trackingOrchestratorProvider = Provider<void>((ref) {
  final notifier = ref.read(trackingStateProvider.notifier);

  notifier.isDrivingChecker = () {
    final hosState = ref.read(hosStatusProvider);
    return hosState is HosEngineReady &&
        hosState.update.currentStatus == DutyStatus.driving;
  };

  DateTime? lastTelemetrySent;
  double? lastSpeedSent;

  // بث السرعة والحركة اللحظية إلى خادم الـ API عبر POST /eld/hardware/telemetry
  ref.listen<TrackingState>(trackingStateProvider, (previous, next) {
    final loc = next.currentLocation;
    if (loc == null || !next.isTracking) return;

    final auth = ref.read(authStateProvider);
    if (!auth.isAuthenticated || auth.user == null) return;

    final now = DateTime.now();
    final speed = loc.speed ?? 0.0; // meters per second

    // بث عند تغير حالة الحركة (> 5 mph / ~2.235 m/s) أو كل 30 ثانية
    final isSpeedTrigger = (lastSpeedSent == null) ||
        (lastSpeedSent! < FmcsaConstants.drivingSpeedThresholdMps &&
            speed >= FmcsaConstants.drivingSpeedThresholdMps) ||
        (lastSpeedSent! >= FmcsaConstants.drivingSpeedThresholdMps &&
            speed < FmcsaConstants.drivingSpeedThresholdMps);

    final isTimeTrigger = lastTelemetrySent == null ||
        now.difference(lastTelemetrySent!).inSeconds >=
            FmcsaConstants.telemetryIntervalSeconds;

    if (isSpeedTrigger || isTimeTrigger) {
      lastTelemetrySent = now;
      lastSpeedSent = speed;

      final reading = TelemetryReading(
        driverId: DriverId(int.tryParse(auth.user!.id) ?? 0),
        speedMps: speed,
        engineOn: speed > 0,
      );

      ref.read(hardwareBackendProvider).sendTelemetry(reading).then((result) {
        result.fold(
          (err) => AppLogger.warning('Telemetry send failed: ${err.code}'),
          (_) => AppLogger.info(
              '📡 Telemetry sent to API server: speed=${speed.toStringAsFixed(1)} m/s'),
        );
      });
    }
  });

  ref.listen<AuthState>(authStateProvider, (previous, next) {
    if (next.status == AuthStatus.authenticated &&
        previous?.status != AuthStatus.authenticated) {
      AppLogger.info('🚀 Auth successful, configuring tracking service');
      // After POST /eld/hardware/connect, configure tracking Plugin (nativeUploadEnabled is implicit in Traccar SDK)
      ref.read(trackingRepositoryProvider).getCurrentConfig().then((config) {
        ref.read(trackingRepositoryProvider).updateConfig(config);
      });
    } else if (next.status == AuthStatus.unauthenticated &&
        previous?.status == AuthStatus.authenticated) {
      // Owner decision 2026-09-25 + SRS §1 / 49 CFR §395.32: the device keeps
      // recording vehicle movement after the driver signs out so that it is
      // captured as Unidentified Driver time instead of being lost.
      AppLogger.info(
          'Driver signed out — tracking continues (unidentified driver mode)');
    }
  });

  ref.listen<VehicleState>(vehicleProvider, (previous, next) {
    if (next.selectedVehicle != null &&
        previous?.selectedVehicle != next.selectedVehicle) {
      if (!notifier.isActiveOrLoading) {
        AppLogger.info('🚀 Auto-starting tracking due to vehicle selection');
        notifier.startTracking();
      }
    }
  });

  ref.listen<HosEngineResult>(hosStatusProvider, (previous, next) {
    if (next is HosEngineReady) {
      final prevStatus =
          (previous is HosEngineReady) ? previous.update.currentStatus : null;
      if (next.update.currentStatus == DutyStatus.driving &&
          prevStatus != DutyStatus.driving) {
        if (!notifier.isActiveOrLoading) {
          AppLogger.info('🚀 Auto-starting tracking because status changed to DRIVING');
          notifier.startTracking();
        }
      }
    }
  });
});
