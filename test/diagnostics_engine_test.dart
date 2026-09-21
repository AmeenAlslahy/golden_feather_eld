import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/diagnostics/diagnostics_engine.dart';
import 'package:golden_feather_eld/core/services/live_tracking_data_source.dart';
import 'package:golden_feather_eld/features/hos/data/datasources/hos_local_data_source.dart';
import 'package:golden_feather_eld/core/domain/entities/location_point.dart';

class MockLiveTrackingDataSource extends Mock
    implements LiveTrackingDataSource {}

class MockHosLocalDataSource extends Mock implements HosLocalDataSource {}

void main() {
  late DiagnosticsEngine engine;
  late MockLiveTrackingDataSource mockTracking;
  late MockHosLocalDataSource mockDb;
  late StreamController<LocationPoint> locationController;
  late StreamController<EldEvent> eventController;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockTracking = MockLiveTrackingDataSource();
    mockDb = MockHosLocalDataSource();

    locationController = StreamController<LocationPoint>.broadcast();
    eventController = StreamController<EldEvent>.broadcast();

    when(() => mockTracking.locations)
        .thenAnswer((_) => locationController.stream);
    when(() => mockTracking.events).thenAnswer((_) => eventController.stream);

    when(() => mockDb.saveDiagnostic(any())).thenAnswer((_) async => true);
    engine = DiagnosticsEngine(mockTracking, mockDb,
        FakeTrustedTimeProvider(initialUtcTime: DateTime.now().toUtc()));
  });

  tearDown(() {
    engine.dispose();
    locationController.close();
    eventController.close();
  });

  group('Diagnostics Engine Tests', () {
    test(
        'processDataPoint should detect positioning malfunction when speed is high and coords are zero',
        () {
      engine.processDataPoint(
        timestamp: DateTime.now(),
        speed: 10.0,
        ignition: true,
        latitude: 0.0,
        longitude: 0.0,
      );

      expect(engine.state.hasActiveMalfunctions, true);
      expect(engine.state.activeMalfunctions.first.type,
          MalfunctionType.positioningMalfunction);
    });

    test('processDataPoint should detect data gap', () {
      final now = DateTime.now();

      // First point
      engine.processDataPoint(
        timestamp: now,
        speed: 10.0,
        ignition: true,
        latitude: 24.0,
        longitude: 46.0,
      );

      expect(engine.state.hasActiveMalfunctions, false);

      // Second point after 6 minutes (threshold is 300 seconds)
      engine.processDataPoint(
        timestamp: now.add(const Duration(minutes: 6)),
        speed: 10.0,
        ignition: true,
        latitude: 24.1,
        longitude: 46.1,
      );

      expect(engine.state.hasActiveMalfunctions, true);
      expect(
          engine.state.activeMalfunctions.last.type, MalfunctionType.dataGap);
    });

    test('processDataPoint should detect unidentified drive', () {
      engine.processDataPoint(
        timestamp: DateTime.now(),
        speed: 15.0, // Moving
        ignition: false, // No ignition
        latitude: 24.0,
        longitude: 46.0,
      );

      expect(engine.state.hasActiveMalfunctions, true);
      expect(
          engine.state.activeMalfunctions
              .any((m) => m.type == MalfunctionType.unidentifiedDrive),
          true);
    });
  });
}
