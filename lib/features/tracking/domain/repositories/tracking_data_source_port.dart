import 'dart:async';
import '../entities/tracking_event.dart';
import '../../../../core/domain/entities/connection_status.dart';

abstract class TrackingDataSourcePort {
  Stream<TrackingEvent> get events;
  Stream<ConnectionStatus> get connectionStatusStream;
}
