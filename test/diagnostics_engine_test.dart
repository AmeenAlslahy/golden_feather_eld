import 'package:golden_feather_eld/core/engine/hos_models.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:golden_feather_eld/core/engine/diagnostics/diagnostics_engine.dart';
import 'package:golden_feather_eld/core/services/live_tracking_data_source.dart';
import 'package:golden_feather_eld/core/services/local_database_service.dart';
import 'package:golden_feather_eld/core/engine/hos_rules_engine.dart';
import 'package:golden_feather_eld/core/engine/tracking/distance_tracker.dart';
import 'package:fpdart/fpdart.dart';

class MockLiveTrackingDataSource extends Mock implements LiveTrackingDataSource {}
class MockLocalDatabaseService extends Mock implements LocalDatabaseService {}

void main() {
  late DiagnosticsEngine engine;
  late MockLiveTrackingDataSource mockTracking;
  late MockLocalDatabaseService mockDb;
  late StreamController<LocationPoint> locationController;
  late StreamController<EldEvent> eventController;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockTracking = MockLiveTrackingDataSource();
    mockDb = MockLocalDatabaseService();
    
    locationController = StreamController<LocationPoint>.broadcast();
    eventController = StreamController<EldEvent>.broadcast();
    
    when(() => mockTracking.locations).thenAnswer((_) => locationController.stream);
    when(() => mockTracking.events).thenAnswer((_) => eventController.stream);
    
    when(() => mockDb.saveDiagnostic(any())).thenAnswer((_) async => const Right(true));
    
    engine = DiagnosticsEngine(mockTracking, mockDb);
  });

  tearDown(() {
    engine.dispose();
    locationController.close();
    eventController.close();
  });

  group('Diagnostics Engine Tests', () {
    test('processDataPoint should detect positioning malfunction when speed is high and coords are zero', () {
      engine.processDataPoint(
        timestamp: DateTime.now(),
        speed: 10.0,
        ignition: true,
        latitude: 0.0,
        longitude: 0.0,
      );

      expect(engine.state.hasActiveMalfunctions, true);
      expect(engine.state.activeMalfunctions.first.type, MalfunctionType.positioningMalfunction);
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
      expect(engine.state.activeMalfunctions.last.type, MalfunctionType.dataGap);
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
      expect(engine.state.activeMalfunctions.any((m) => m.type == MalfunctionType.unidentifiedDrive), true);
    });
  });
}
