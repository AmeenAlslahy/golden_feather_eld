import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/tracking/presentation/providers/tracking_provider.dart';
import '../../features/tracking/presentation/providers/tracking_providers.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/vehicle/presentation/providers/vehicle_provider.dart';
import '../../features/hos/presentation/providers/hos_provider.dart';
import '../../features/hos/domain/engine/hos_rules_engine.dart';
import '../../core/domain/entities/hos_models.dart';
import '../../core/utils/logger.dart';

final trackingOrchestratorProvider = Provider<void>((ref) {
  final notifier = ref.read(trackingStateProvider.notifier);

  notifier.isDrivingChecker = () {
    final hosState = ref.read(hosStatusProvider);
    return hosState is HosEngineReady &&
        hosState.update.currentStatus == DutyStatus.driving;
  };

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
