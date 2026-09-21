import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'dart:async';

import '../../../../../core/utils/logger.dart';
import '../../../../../core/services/live_tracking_data_source.dart';
import '../../../data/datasources/hos_local_data_source.dart';
import '../../../../../core/domain/entities/location_point.dart'; // For LocationPoint
import '../../../../../core/time/trusted_time_provider.dart';

/// أنواع الأعطال
enum MalfunctionType {
  dataGap,
  positioningMalfunction,
  motionSensorMalfunction,
  engineSyncMalfunction,
  missingCertification,
  unidentifiedDrive,
}

/// مستويات الخطورة
enum MalfunctionSeverity {
  minor('بسيط', 'Minor'),
  major('رئيسي', 'Major'),
  critical('حرج', 'Critical');

  final String arabicName;
  final String englishName;
  const MalfunctionSeverity(this.arabicName, this.englishName);
}

/// نموذج العطل
class MalfunctionEvent {
  final MalfunctionType type;
  final MalfunctionSeverity severity;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  const MalfunctionEvent({
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'severity': severity.name,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
    };
  }
}

/// حالة التشخيص
class DiagnosticsState {
  final List<MalfunctionEvent> activeMalfunctions;
  final List<MalfunctionEvent> history;
  final bool hasActiveMalfunctions;

  const DiagnosticsState({
    this.activeMalfunctions = const [],
    this.history = const [],
    this.hasActiveMalfunctions = false,
  });

  DiagnosticsState copyWith({
    List<MalfunctionEvent>? activeMalfunctions,
    List<MalfunctionEvent>? history,
    bool? hasActiveMalfunctions,
  }) {
    return DiagnosticsState(
      activeMalfunctions: activeMalfunctions ?? this.activeMalfunctions,
      history: history ?? this.history,
      hasActiveMalfunctions:
          hasActiveMalfunctions ?? this.hasActiveMalfunctions,
    );
  }
}

/// محرك التشخيص الذاتي
class DiagnosticsEngine {
  final LiveTrackingDataSource _trackingDataSource;
  final HosLocalDataSource _localDb;
  final TrustedTimeProvider _timeProvider;
  final _stateController = StreamController<DiagnosticsState>.broadcast();

  StreamSubscription<EldEvent>? _eventSubscription;
  StreamSubscription<LocationPoint>? _locationSubscription;

  DiagnosticsState _state = const DiagnosticsState();
  DateTime? _lastDataPoint;
  double? _lastSpeed;
  int _engineRunningWithoutMotion = 0; // دقائق
  static const int dataGapThreshold = 300; // 5 دقائق
  static const int engineSyncThreshold = 60; // 60 دقيقة
  static const int motionSensorThreshold = 80; // 80 كم/س تغير مفاجئ

  double _lastLat = 0.0;
  double _lastLon = 0.0;

  DiagnosticsEngine(
      this._trackingDataSource, this._localDb, this._timeProvider) {
    _startListening();
  }

  DateTime _getCurrentTime() {
    final timeResult = _timeProvider.currentTime;
    return timeResult is TrustedTimeAvailable
        ? timeResult.utc
        : DateTime.now().toUtc();
  }

  DiagnosticsState get state => _state;
  Stream<DiagnosticsState> get stateStream => _stateController.stream;

  void _startListening() {
    _locationSubscription = _trackingDataSource.locations.listen((location) {
      _lastLat = location.latitude;
      _lastLon = location.longitude;
    });

    _eventSubscription = _trackingDataSource.events.listen((event) {
      // نستنتج حالة التشغيل من السرعة وعداد المحرك في هذا التطبيق الوهمي
      bool ignition = event.speedMph > 0 || event.speedDurationSeconds > 0;
      processDataPoint(
        timestamp: event.timestamp,
        speed: event.speedMph,
        ignition: ignition,
        latitude: _lastLat,
        longitude: _lastLon,
      );
    });
  }

  /// معالجة نقطة بيانات جديدة
  void processDataPoint({
    required DateTime timestamp,
    required double speed,
    required bool ignition,
    required double latitude,
    required double longitude,
  }) {
    _checkDataGap(timestamp);
    _checkPositioning(speed, latitude, longitude);
    _checkMotionSensor(speed);
    _checkEngineSync(ignition, speed);
    _checkUnidentifiedDrive(ignition, speed);

    _lastDataPoint = timestamp;
    _lastSpeed = speed;
  }

  void _checkDataGap(DateTime currentTime) {
    if (_lastDataPoint != null) {
      final gap = currentTime.difference(_lastDataPoint!).inSeconds;
      if (gap > dataGapThreshold) {
        _addMalfunction(MalfunctionEvent(
          type: MalfunctionType.dataGap,
          severity: MalfunctionSeverity.major,
          message: 'Data gap detected: $gap seconds',
          timestamp: currentTime,
          details: {'gap_seconds': gap},
        ));
        AppLogger.warning('⚠️ Data gap: $gap seconds');
      }
    }
  }

  void _checkPositioning(double speed, double lat, double lon) {
    if (speed > 8.0 && (lat == 0.0 || lon == 0.0)) {
      _addMalfunction(MalfunctionEvent(
        type: MalfunctionType.positioningMalfunction,
        severity: MalfunctionSeverity.major,
        message:
            'Positioning malfunction: zero coordinates at speed $speed km/h',
        timestamp: _getCurrentTime(),
      ));
      AppLogger.error('🛰️ Positioning malfunction');
    }
  }

  void _checkMotionSensor(double currentSpeed) {
    if (_lastSpeed != null) {
      final speedChange = (currentSpeed - _lastSpeed!).abs();
      if (speedChange > motionSensorThreshold) {
        _addMalfunction(MalfunctionEvent(
          type: MalfunctionType.motionSensorMalfunction,
          severity: MalfunctionSeverity.major,
          message:
              'Sudden speed change: ${speedChange.toStringAsFixed(0)} km/h',
          timestamp: _getCurrentTime(),
          details: {'speed_change': speedChange},
        ));
        AppLogger.error('📊 Motion sensor malfunction');
      }
    }
  }

  void _checkEngineSync(bool ignition, double speed) {
    if (ignition && speed < 1.0) {
      _engineRunningWithoutMotion++;
      if (_engineRunningWithoutMotion >= engineSyncThreshold) {
        _addMalfunction(MalfunctionEvent(
          type: MalfunctionType.engineSyncMalfunction,
          severity: MalfunctionSeverity.minor,
          message:
              'Engine running without motion for $_engineRunningWithoutMotion minutes',
          timestamp: _getCurrentTime(),
        ));
        AppLogger.warning('🔧 Engine sync malfunction');
      }
    } else if (speed >= 1.0) {
      _engineRunningWithoutMotion = 0;
    }
  }

  void _checkUnidentifiedDrive(bool ignition, double speed) {
    if (!ignition && speed > 8.0) {
      _addMalfunction(MalfunctionEvent(
        type: MalfunctionType.unidentifiedDrive,
        severity: MalfunctionSeverity.major,
        message: 'Unidentified drive: vehicle moving without ignition',
        timestamp: _getCurrentTime(),
      ));
      AppLogger.error('🚨 Unidentified drive');
    }
  }

  void _addMalfunction(MalfunctionEvent event) {
    final updatedActive = [..._state.activeMalfunctions, event];
    final updatedHistory = [..._state.history, event];
    _state = DiagnosticsState(
      activeMalfunctions: updatedActive,
      history: updatedHistory,
      hasActiveMalfunctions: true,
    );
    _stateController.add(_state);

    // حفظ العطل محلياً
    _localDb.saveDiagnostic(event.toJson()).then((success) {
      if (success) {
        AppLogger.info('Diagnostic saved successfully');
      } else {
        AppLogger.error('Failed to save diagnostic');
      }
    }).catchError((e) {
      AppLogger.error('Failed to save diagnostic', e);
    });
  }

  void clearActive() {
    _state = _state.copyWith(
      activeMalfunctions: [],
      hasActiveMalfunctions: false,
    );
    _stateController.add(_state);
  }

  void checkMissingCertification(bool isCertified) {
    if (!isCertified) {
      _addMalfunction(MalfunctionEvent(
        type: MalfunctionType.missingCertification,
        severity: MalfunctionSeverity.major,
        message: 'Missing certification for daily log',
        timestamp: _getCurrentTime(),
      ));
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
    _locationSubscription?.cancel();
    _stateController.close();
  }
}
