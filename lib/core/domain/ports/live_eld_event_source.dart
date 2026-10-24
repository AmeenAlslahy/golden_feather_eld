import '../entities/connection_status.dart';
import '../entities/hos_models.dart';

/// Core-owned port for the live ELD streams consumed by HOS, sync, and logs.
///
/// The tracking feature implements this port; core must not import the
/// tracking data source or its entities directly.
abstract interface class LiveEldEventSource {
  Stream<EldEvent> get events;

  Stream<ConnectionStatus> get connectionStatus;
}
