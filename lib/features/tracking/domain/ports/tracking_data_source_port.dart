/// Domain-facing port for tracking data sources.
///
/// **ARCH-CRIT-01 fix:** This port lives in Domain and defines what
/// the Domain layer *needs* from a tracking data source.
/// Implementations (TraccarDataSource, mock sources) live in Data.
library;

import '../entities/connection_status.dart';
import '../entities/tracking_event.dart';

/// Port for receiving live tracking events.
///
/// The Domain layer depends only on this contract.
/// Concrete implementations (Traccar, GPS, mock) live in the Data layer.
abstract class TrackingDataSourcePort {
  /// Stream of live tracking events (position, speed, odometer, etc.)
  Stream<TrackingEvent> get events;

  /// Stream of connection status changes.
  Stream<ConnectionStatus> get connectionStatusStream;

  /// Start receiving tracking events.
  Future<void> start();

  /// Stop receiving tracking events.
  Future<void> stop();

  /// Retrieve the last recorded tracking event.
  Future<TrackingEvent?> getLastEvent();
}
