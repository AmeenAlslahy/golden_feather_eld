import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/tracking/data/datasources/live_tracking_data_source.dart';
import '../domain/entities/hos_models.dart';
import '../../features/tracking/domain/entities/connection_status.dart';

/// Domain-level provider exposing the live ELD events stream.
///
/// This decouples the HOS/Sync/Logs domains from directly importing
/// the tracking data source.
final eldEventsStreamProvider = StreamProvider<EldEvent>((ref) {
  return ref.watch(liveTrackingDataSourceProvider).events;
});

/// Domain-level provider exposing the live ELD connection status.
final eldConnectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  return ref.watch(liveTrackingDataSourceProvider).connectionStatus;
});
