import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:golden_feather_eld/core/config/app_environment.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/core/domain/entities/location_point.dart'; // For LocationPoint
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/network/traccar/traccar_api_client_impl.dart';
import 'package:golden_feather_eld/core/network/traccar/traccar_websocket_client_impl.dart';
import 'package:golden_feather_eld/features/tracking/data/datasources/traccar_data_source.dart';
import 'package:golden_feather_eld/features/tracking/data/datasources/traccar_sdk/traccar_native_client_impl.dart';
import 'package:golden_feather_eld/features/tracking/domain/entities/connection_status.dart';
import 'package:golden_feather_eld/features/tracking/domain/usecases/tracking_event_processor.dart';
import 'package:golden_feather_eld/features/tracking/data/providers/tracking_providers.dart';

abstract class LiveTrackingDataSource {
  Stream<EldEvent> get events;
  Stream<LocationPoint> get locations;
  Stream<ConnectionStatus> get connectionStatus;
  Future<bool> start();
  Future<void> stop();
}

class MockLiveTrackingDataSource implements LiveTrackingDataSource {
  final _eventsController = StreamController<EldEvent>.broadcast();
  final _locationsController = StreamController<LocationPoint>.broadcast();
  final _connectionController = StreamController<ConnectionStatus>.broadcast();
  Timer? _timer;

  double _mockSpeed = 0.0;
  double _mockOdometer = 150000.0;
  double _mockEngineHours = 3500.0;
  double _mockLat = 24.7136;
  double _mockLon = 46.6753;

  @override
  Stream<EldEvent> get events => _eventsController.stream;

  @override
  Stream<LocationPoint> get locations => _locationsController.stream;

  @override
  Stream<ConnectionStatus> get connectionStatus => _connectionController.stream;

  @override
  Future<bool> start() async {
    _connectionController.add(ConnectionStatus.connected);
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _mockSpeed = (_mockSpeed < 60.0) ? _mockSpeed + 5.0 : 60.0;
      _mockOdometer += (_mockSpeed / 3600.0) * 5;
      _mockEngineHours += (5.0 / 3600.0);
      _mockLat += 0.0001;
      _mockLon += 0.0001;

      final now = DateTime.now();

      _eventsController.add(EldEvent(
        timestamp: now,
        speedMph: _mockSpeed,
        speedDurationSeconds: 5,
        odometerMiles: _mockOdometer,
        engineHours: _mockEngineHours,
      ));

      _locationsController.add(LocationPoint(
        latitude: _mockLat,
        longitude: _mockLon,
        timestamp: now,
      ));
    });
    return true;
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _mockSpeed = 0.0;
    _connectionController.add(ConnectionStatus.disconnected);

    final now = DateTime.now();
    _eventsController.add(EldEvent(
      timestamp: now,
      speedMph: _mockSpeed,
      speedDurationSeconds: 0,
      odometerMiles: _mockOdometer,
      engineHours: _mockEngineHours,
    ));
  }

  void dispose() {
    _timer?.cancel();
    _eventsController.close();
    _locationsController.close();
    _connectionController.close();
  }
}

class ProcessorLiveTrackingDataSource implements LiveTrackingDataSource {
  final TrackingEventProcessor processor;

  ProcessorLiveTrackingDataSource({required this.processor});

  @override
  Stream<EldEvent> get events => processor.eldEventsStream;

  @override
  Stream<LocationPoint> get locations => processor.locationStream;

  @override
  Stream<ConnectionStatus> get connectionStatus =>
      processor.connectionStatusStream;

  @override
  Future<bool> start() async {
    processor.startProcessing();
    return true;
  }

  @override
  Future<void> stop() async {
    processor.dispose();
  }
}

// تم استبدال الـ Dummy بـ TraccarNativeClientImpl الحقيقي

final liveTrackingDataSourceProvider = Provider<LiveTrackingDataSource>((ref) {
  if (AppEnvironmentConfig.current == AppEnvironment.mock) {
    final dataSource = MockLiveTrackingDataSource();
    dataSource.start();
    ref.onDispose(() {
      dataSource.dispose();
    });
    return dataSource;
  } else {
    final traccarDataSource = TraccarDataSource(
      apiClient: TraccarApiClientImpl(
        apiClient: ref.watch(apiClientProvider),
      ),
      webSocketClient: TraccarWebSocketClientImpl(),
      nativeClient: TraccarNativeClientImpl(),
      nativeEventClient: ref.watch(nativeEventChannelClientProvider),
    );

    // إنشاء EventProcessor
    final processor =
        TrackingEventProcessor(trackingDataSource: traccarDataSource);

    final dataSource = ProcessorLiveTrackingDataSource(
      processor: processor,
    );

    // Start processing (starts native tracking)
    dataSource.start();

    // WebSocket connection is disabled to focus entirely on GPS events over OsmAnd.
    // The connection status will effectively remain disconnected or only reflect Native state.

    ref.onDispose(() {
      traccarDataSource.dispose();
      processor.dispose();
    });

    return dataSource;
  }
});
