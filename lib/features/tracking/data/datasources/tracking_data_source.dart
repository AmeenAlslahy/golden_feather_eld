import '../../domain/entities/connection_status.dart';
import '../../domain/entities/tracking_event.dart';
// ARCH-CRIT-01 fix: Data implements the Domain port
import '../../domain/ports/tracking_data_source_port.dart';

/// Data-layer contract for tracking data sources.
///
/// The abstract contract now lives in Domain as [TrackingDataSourcePort].
/// This class is kept as a type alias for backward compatibility;
/// new code should reference [TrackingDataSourcePort] directly.
///
/// Implementations: TraccarDataSource, MockTrackingDataSource, etc.
abstract class TrackingDataSource implements TrackingDataSourcePort {
  /// Stream of live tracking events (position, speed, odometer, etc.)
  @override
  Stream<TrackingEvent> get events;

  /// Stream of connection status changes.
  @override
  Stream<ConnectionStatus> get connectionStatusStream;

  /// Start receiving tracking events.
  @override
  Future<void> start();

  /// Stop receiving tracking events.
  @override
  Future<void> stop();

  /// Retrieve the last recorded tracking event.
  @override
  Future<TrackingEvent?> getLastEvent();
}
