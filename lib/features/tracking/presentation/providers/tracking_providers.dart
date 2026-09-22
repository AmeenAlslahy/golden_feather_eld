import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/providers/tracking_datasource_providers.dart';
import '../../domain/usecases/tracking_event_processor.dart';

/// GPS service status provider.
final gpsStatusProvider =
    StreamProvider.autoDispose<ServiceStatus>((ref) async* {
  bool isEnabled = await Geolocator.isLocationServiceEnabled();
  yield isEnabled ? ServiceStatus.enabled : ServiceStatus.disabled;
  yield* Geolocator.getServiceStatusStream();
});

// =============================================================================
// مزود المعالج — ARCH-CRIT-03 fix
//
// This provider is DEPRECATED. Use [liveTrackingDataSourceProvider] instead,
// which correctly selects Mock or Real based on [AppEnvironmentConfig].
//
// Kept temporarily for backward compatibility — now requires an explicit
// TrackingDataSource. Never falls back to mock silently.
// =============================================================================

/// @deprecated Use [liveTrackingDataSourceProvider] instead.
final trackingEventProcessorProvider = Provider<TrackingEventProcessor>((ref) {
  final traccarDataSource = ref.watch(traccarDataSourceProvider);
  final processor = TrackingEventProcessor(trackingDataSource: traccarDataSource);
  processor.startProcessing();
  ref.onDispose(() => processor.dispose());
  return processor;
});
