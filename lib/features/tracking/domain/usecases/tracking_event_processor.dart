import 'dart:async';

import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';

import '../../../../core/domain/entities/location_point.dart';
import '../../../../core/utils/logger.dart';
import '../entities/connection_status.dart';
import '../entities/tracking_event.dart';
// ARCH-CRIT-01 fix: Use Domain port instead of Data DataSource
import '../ports/tracking_data_source_port.dart';

/// المحرك المركزي الذي يستقبل أحداث التتبع (TrackingEvent) من المصدر
/// ويقوم بتوزيعها على محركات التطبيق (HOS, Diagnostics, Distance)
/// عبر محول (Mapper) داخلي بحيث لا تعرف هذه المحركات أي شيء عن Traccar.
///
/// **ARCH-CRIT-03 fix:** [TrackingDataSourcePort] is now mandatory.
/// Mock mode is handled by [MockTrackingEventProcessor], not by passing null.
class TrackingEventProcessor {
  final TrackingDataSourcePort _trackingDataSource;
  final StreamController<EldEvent> _eldEventsController =
      StreamController<EldEvent>.broadcast();
  final StreamController<LocationPoint> _locationEventsController =
      StreamController<LocationPoint>.broadcast();
  final StreamController<ConnectionStatus> _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  StreamSubscription? _subscription;
  StreamSubscription? _connectionSubscription;

  /// DataSource is **required** — no null fallback to mock.
  TrackingEventProcessor({
    required TrackingDataSourcePort trackingDataSource,
  }) : _trackingDataSource = trackingDataSource;

  Stream<EldEvent> get eldEventsStream => _eldEventsController.stream;
  Stream<LocationPoint> get locationStream => _locationEventsController.stream;
  Stream<ConnectionStatus> get connectionStatusStream =>
      _connectionStatusController.stream;

  void startProcessing() {
    _subscription = _trackingDataSource.events.listen(_processTrackingEvent);
    _connectionSubscription =
        _trackingDataSource.connectionStatusStream.listen((status) {
      _connectionStatusController.add(status);
    });
  }

  void _processTrackingEvent(TrackingEvent event) {
    AppLogger.info(
        '📍 [TrackingEventProcessor] Received event: Lat=${event.latitude}, Lon=${event.longitude}, Speed=${event.speed}');
    final eldEvent = _mapToEldEvent(event);
    _eldEventsController.add(eldEvent);

    final locationPoint = _mapToLocationPoint(event);
    _locationEventsController.add(locationPoint);
  }

  EldEvent _mapToEldEvent(TrackingEvent event) {
    return EldEvent(
      timestamp: event.timestampUtc,
      speedMph: event.speed,
      speedDurationSeconds: 0,
      odometerMiles: event.odometer,
      engineHours: event.engineHours,
    );
  }

  LocationPoint _mapToLocationPoint(TrackingEvent event) {
    return LocationPoint(
      latitude: event.latitude,
      longitude: event.longitude,
      timestamp: event.timestampUtc,
    );
  }

  void dispose() {
    _subscription?.cancel();
    _connectionSubscription?.cancel();
    _eldEventsController.close();
    _locationEventsController.close();
    _connectionStatusController.close();
  }
}

// =============================================================================
// Mock implementation — used ONLY in development/test environments
// Explicitly instantiated, never activated by null fallback.
// =============================================================================

/// Mock processor for development only.
/// Generates fake GPS/ELD data when no real device is connected.
///
/// **Usage:** Only create this when `AppEnvironmentConfig.current == mock`.
/// Never use in production.
class MockTrackingEventProcessor extends TrackingEventProcessor {
  final StreamController<EldEvent> _mockEldController =
      StreamController<EldEvent>.broadcast();
  final StreamController<LocationPoint> _mockLocationController =
      StreamController<LocationPoint>.broadcast();
  final StreamController<ConnectionStatus> _mockConnectionController =
      StreamController<ConnectionStatus>.broadcast();
  Timer? _mockTimer;

  MockTrackingEventProcessor({required TrackingDataSourcePort mockSource})
      : super(trackingDataSource: mockSource);

  @override
  Stream<EldEvent> get eldEventsStream => _mockEldController.stream;
  @override
  Stream<LocationPoint> get locationStream => _mockLocationController.stream;
  @override
  Stream<ConnectionStatus> get connectionStatusStream =>
      _mockConnectionController.stream;

  @override
  void startProcessing() {
    AppLogger.warning(
        '⚠️ [MockTrackingEventProcessor] Running in MOCK mode — development only!');
    _mockConnectionController.add(ConnectionStatus.connected);

    double mockSpeed = 0.0;
    double mockLat = 24.7136;
    double mockLon = 46.6753;

    _mockTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      mockSpeed = (mockSpeed < 60.0) ? mockSpeed + 5.0 : 60.0;
      mockLat += 0.0001;
      mockLon += 0.0001;

      final now = DateTime.now();

      _mockEldController.add(EldEvent(
        timestamp: now,
        speedMph: mockSpeed,
        speedDurationSeconds: 5,
        odometerMiles: null,
        engineHours: null,
      ));

      _mockLocationController.add(LocationPoint(
        latitude: mockLat,
        longitude: mockLon,
        timestamp: now,
      ));
    });
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    _mockEldController.close();
    _mockLocationController.close();
    _mockConnectionController.close();
  }
}
