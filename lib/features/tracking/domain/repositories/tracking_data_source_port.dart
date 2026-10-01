import 'dart:async';
import '../entities/tracking_event.dart';
import '../entities/connection_status.dart';

abstract class TrackingDataSourcePort {
  Stream<TrackingEvent> get events;
  Stream<ConnectionStatus> get connectionStatusStream;
}
