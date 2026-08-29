import 'package:golden_feather_eld/core/engine/hos_models.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/services/live_tracking_data_source.dart';
import '../../../../core/engine/hos_rules_engine.dart';
import '../../../../core/engine/tracking/distance_tracker.dart';
import '../../../../core/mocks/mock_tracking_client_sdk.dart' hide Config, LocationConfig, Accuracy;
import '../../../../core/network/tracking_client_sdk.dart';
import '../../domain/entities/connection_status.dart';

final traccarSdkProvider = Provider<TraccarSdkLocationProvider>((ref) {
  return TraccarSdkLocationProvider();
});

class TraccarSdkLocationProvider implements LiveTrackingDataSource {
  final TrackingClientInterface _traccarClient;

  TraccarSdkLocationProvider({TrackingClientInterface? client})
      : _traccarClient = client ?? (AppEnvironmentConfig.current == AppEnvironment.mock
            ? MockTrackingClient()
            : RealTrackingClient()) {
    // Note: TrackingClientInterface currently does not expose an onLocationUpdate stream.
    // In a full implementation, you would listen to _traccarClient's location stream here.
  }

  final _eventsController = StreamController<EldEvent>.broadcast();
  final _locationsController = StreamController<LocationPoint>.broadcast();
  final _connectionController = StreamController<ConnectionStatus>.broadcast();
  
  StreamSubscription? _locationSubscription;

  @override
  Stream<EldEvent> get events => _eventsController.stream;

  @override
  Stream<LocationPoint> get locations => _locationsController.stream;

  @override
  Stream<ConnectionStatus> get connectionStatus => _connectionController.stream;

  @override
  Future<bool> start() async {
    _connectionController.add(ConnectionStatus.connected);

    final config = Config(
      serverUrl: '', 
      deviceId: 'local_device',
      buffer: false, 
      preferPlatformProviders: true,
      location: LocationConfig(
        accuracy: Accuracy.high,
        distanceMeters: 0,
        intervalSeconds: 5,
        angleDegrees: 0,
        heartbeatIntervalSeconds: 0,
        stopDetection: false,
      ),
      wakeLock: true,
    );

    await _traccarClient.setConfig(config);
    await _traccarClient.start();
    return true;
  }

  @override
  Future<void> stop() async {
    await _traccarClient.stop();
    _connectionController.add(ConnectionStatus.disconnected);
  }

  void dispose() {
    _locationSubscription?.cancel();
    _eventsController.close();
    _locationsController.close();
    _connectionController.close();
  }
}
