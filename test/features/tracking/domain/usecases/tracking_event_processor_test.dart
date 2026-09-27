import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/tracking/domain/usecases/tracking_event_processor.dart';
import 'package:golden_feather_eld/features/tracking/domain/entities/tracking_event.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'dart:async';
import 'package:golden_feather_eld/features/tracking/data/datasources/tracking_data_source.dart';
import 'package:golden_feather_eld/features/tracking/domain/entities/connection_status.dart';

class MockTrackingDataSource implements TrackingDataSource {
  final _eventsController = StreamController<TrackingEvent>.broadcast();
  final _connectionController = StreamController<ConnectionStatus>.broadcast();

  @override
  Stream<TrackingEvent> get events => _eventsController.stream;

  @override
  Stream<ConnectionStatus> get connectionStatusStream => _connectionController.stream;

  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<TrackingEvent?> getLastEvent() async => null;
  Future<void> dispose() async {
    _eventsController.close();
    _connectionController.close();
  }

  void addEvent(TrackingEvent event) {
    _eventsController.add(event);
  }
}

void main() {
  group('TrackingEventProcessor', () {
    test('does not fabricate odometer or engine hours', () async {
      final mockDataSource = MockTrackingDataSource();
      final processor = TrackingEventProcessor(trackingDataSource: mockDataSource);

      processor.startProcessing();

      // Expect an EldEvent mapped from TrackingEvent without fabrication
      final expectFuture = expectLater(
        processor.eldEventsStream,
        emits(
          isA<EldEvent>()
              // TrackingEvent.speed is m/s (OS/OsmAnd); EldEvent is mph.
              .having((e) => e.speedMph, 'speedMph', closeTo(60.0, 0.01))
              .having((e) => e.odometerMiles, 'odometerMiles', isNull)
              .having((e) => e.engineHours, 'engineHours', isNull),
        ),
      );

      final now = DateTime.now().toUtc();
      mockDataSource.addEvent(
        TrackingEvent(
          id: '123',
          deviceId: 'dev123',
          source: TrackingEventSource.mock,
          latitude: 0.0,
          longitude: 0.0,
          altitude: 0.0,
          bearing: 0.0,
          accuracy: 0.0,
          speed: 26.8224, // m/s == 60 mph
          timestampUtc: now,
          // Explicitly leaving odometer and engineHours as null
        ),
      );

      await expectFuture;
      processor.dispose();
    });
  });
}
