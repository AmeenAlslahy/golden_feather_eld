import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/logger.dart';
import '../../../features/logs/domain/repositories/log_repository.dart';
import '../../../features/logs/data/repositories/log_repository_impl.dart';
import '../../services/live_tracking_data_source.dart';
import '../../services/local_database_service.dart';




/// متتبع حالة السائق (Domain Pure)
import '../hos_models.dart';

class DutyStatusTracker {
  final LogRepository _logRepository;
  final DateTime Function() _now;
  final Future<void> Function(String, String) _saveSetting;
  final String? Function(String) _getSetting;

  final _transitionController = StreamController<DutyTransition>.broadcast();
  Stream<DutyTransition> get onTransition => _transitionController.stream;

  final List<DutyStatusEvent> _events = [];
  final List<DutyPeriod> _periods = [];
  String _currentStatus = 'off_duty';
  DutyStatusEvent? _lastEvent;

  DateTime? _stationarySince;
  Timer? _wakeupTimer;

  DateTime? _movingSince;
  int _consecutiveMovingEvents = 0;

  DutyStatusTracker({
    required LogRepository logRepository,
    required DateTime Function() now,
    required Future<void> Function(String, String) saveSetting,
    required String? Function(String) getSetting,
  })  : _logRepository = logRepository,
        _now = now,
        _saveSetting = saveSetting,
        _getSetting = getSetting {
    _initStationaryState();
  }

  List<DutyStatusEvent> get events => List.unmodifiable(_events);
  List<DutyPeriod> get periods => List.unmodifiable(_periods);
  String get currentStatus => _currentStatus;

  void _initStationaryState() {
    final savedStatus = _getSetting('current_duty_status');
    if (savedStatus != null && savedStatus.isNotEmpty) {
      _currentStatus = savedStatus;
    }

    final savedTime = _getSetting('stationary_since');
    if (savedTime != null && savedTime.isNotEmpty) {
      final parsed = DateTime.tryParse(savedTime);
      if (parsed != null) {
        _stationarySince = parsed;
        _evaluateStationaryState();
      }
    }
  }

  void processEldEvent(EldEvent eldEvent) {
    if (eldEvent.speedMph > 5.0) {
      // Moving logic
      if (_movingSince == null) {
        _movingSince = eldEvent.timestamp;
      }
      _consecutiveMovingEvents++;

      final elapsed = eldEvent.timestamp.difference(_movingSince!);
      
      // Require at least 3 seconds of sustained movement AND 3 consecutive events
      // to reject GPS hardware spikes (Outliers).
      if (_consecutiveMovingEvents >= 3 && elapsed.inSeconds >= 3) {
        if (_stationarySince != null) {
          _stationarySince = null;
          _saveSetting('stationary_since', '');
          _wakeupTimer?.cancel();
        }
        
        if (_currentStatus != 'driving') {
          _transitionTo(
            newStatus: 'driving',
            timestamp: _movingSince!, // Use the timestamp when movement first started
            odometer: eldEvent.odometerMiles,
            engineHours: eldEvent.engineHours,
            annotation: 'Auto Transition to Driving (> 5 mph sustained)',
          );
        }
      }
    } else {
      // Stationary logic
      _movingSince = null;
      _consecutiveMovingEvents = 0;

      if (_currentStatus == 'driving') {
        if (_stationarySince == null) {
          _stationarySince = eldEvent.timestamp;
          _saveSetting('stationary_since', _stationarySince!.toIso8601String());
        }
        _evaluateStationaryState(eventTimestamp: eldEvent.timestamp, odometer: eldEvent.odometerMiles, engineHours: eldEvent.engineHours);
      }
    }
  }

  void _evaluateStationaryState({DateTime? eventTimestamp, double? odometer, double? engineHours}) {
    if (_stationarySince == null || _currentStatus != 'driving') return;

    final currentTime = _now();
    final elapsed = currentTime.difference(_stationarySince!);

    if (elapsed.inMinutes >= 5) {
      // Met the 5-minute stationary rule
      final effectiveTimestamp = eventTimestamp ?? currentTime;
      _stationarySince = null;
      _saveSetting('stationary_since', '');
      _wakeupTimer?.cancel();

      _transitionTo(
        newStatus: 'on_duty',
        timestamp: effectiveTimestamp,
        odometer: odometer,
        engineHours: engineHours,
        annotation: 'Auto Transition to On Duty (Stationary 5+ mins)',
      );
    } else {
      // Schedule wakeup timer if we haven't already
      _wakeupTimer?.cancel();
      final remaining = const Duration(minutes: 5) - elapsed;
      _wakeupTimer = Timer(remaining, () {
        _evaluateStationaryState();
      });
    }
  }

  void _transitionTo({
    required String newStatus,
    required DateTime timestamp,
    double? latitude,
    double? longitude,
    double? odometer,
    double? engineHours,
    String? annotation,
  }) {
    if (_currentStatus == newStatus) return;

    final event = DutyStatusEvent(
      status: newStatus,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      odometer: odometer,
      engineHours: engineHours,
    );

    _events.add(event);

    if (_lastEvent != null) {
      final period = DutyPeriod(
        status: _lastEvent!.status,
        startTime: _lastEvent!.timestamp,
        endTime: event.timestamp,
        startOdometer: _lastEvent!.odometer,
        endOdometer: event.odometer,
        startLat: _lastEvent!.latitude,
        startLon: _lastEvent!.longitude,
        endLat: event.latitude,
        endLon: event.longitude,
      );
      
      _periods.add(period);
      
      _logRepository.savePeriod(period).then((result) {
        result.match(
          (failure) => AppLogger.error('Failed to save period', failure.message),
          (success) => AppLogger.info('Period saved successfully'),
        );
      });
    }

    _currentStatus = newStatus;
    _saveSetting('current_duty_status', newStatus);
    _lastEvent = event;
    AppLogger.info('📊 Duty Status: $currentStatus');

    _transitionController.add(DutyTransition(
      newStatus: newStatus,
      annotation: annotation ?? 'Manual/System Transition',
    ));
  }

  void manualTransition(String newStatus, {double? lat, double? lon}) {
    if (_currentStatus == 'driving' && newStatus != 'driving') {
       AppLogger.warning('Cannot manually transition from driving while moving.');
    }
    
    // Clear stationary timer and movement buffers if manually transitioning
    _stationarySince = null;
    _saveSetting('stationary_since', '');
    _wakeupTimer?.cancel();
    
    _movingSince = null;
    _consecutiveMovingEvents = 0;
    
    _transitionTo(
      newStatus: newStatus, 
      timestamp: _now(),
      latitude: lat,
      longitude: lon,
    );
  }

  Map<String, double> getTodayStats() {
    final now = _now();
    final todayStart = DateTime(now.year, now.month, now.day);

    double driving = 0, onDuty = 0, offDuty = 0, sleeper = 0;
    double totalDistance = 0;

    for (final period in _periods) {
      if (period.startTime.isAfter(todayStart)) {
        final hours = period.duration.inMinutes / 60.0;
        switch (period.status) {
          case 'driving':
            driving += hours;
            break;
          case 'on_duty':
            onDuty += hours;
            break;
          case 'off_duty':
            offDuty += hours;
            break;
          case 'sleeper_berth':
            sleeper += hours;
            break;
        }
        if (period.distanceKm != null) {
          totalDistance += period.distanceKm!;
        }
      }
    }

    return {
      'driving': driving,
      'on_duty': onDuty,
      'off_duty': offDuty,
      'sleeper': sleeper,
      'distance': totalDistance,
    };
  }

  Map<String, double> getWeekStats() {
    final now = _now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    double driving = 0, work = 0, rest = 0;
    double totalDistance = 0;

    for (final period in _periods) {
      if (period.startTime.isAfter(weekStart)) {
        final hours = period.duration.inMinutes / 60.0;
        switch (period.status) {
          case 'driving':
            driving += hours;
            work += hours;
            break;
          case 'on_duty':
            work += hours;
            break;
          case 'off_duty':
          case 'sleeper_berth':
            rest += hours;
            break;
        }
        if (period.distanceKm != null) {
          totalDistance += period.distanceKm!;
        }
      }
    }

    return {
      'driving': driving,
      'work': work,
      'rest': rest,
      'distance': totalDistance,
    };
  }

  void clear() {
    _events.clear();
    _periods.clear();
    _lastEvent = null;
    _currentStatus = 'off_duty';
    _saveSetting('current_duty_status', 'off_duty');
    _stationarySince = null;
    _saveSetting('stationary_since', '');
    _wakeupTimer?.cancel();
    
    _movingSince = null;
    _consecutiveMovingEvents = 0;
  }

  void dispose() {
    _wakeupTimer?.cancel();
    _transitionController.close();
  }
}

/// Provider
final dutyStatusTrackerProvider = Provider<DutyStatusTracker>((ref) {
  final repo = ref.watch(logRepositoryProvider);
  final db = ref.watch(localDatabaseServiceProvider);
  final tracker = DutyStatusTracker(
    logRepository: repo,
    now: () => DateTime.now(),
    saveSetting: db.saveSetting,
    getSetting: db.getSetting,
  );
  
  // Wire up the GPS stream to the tracker
  final tracking = ref.watch(liveTrackingDataSourceProvider);
  final sub = tracking.events.listen((event) {
    tracker.processEldEvent(event);
  });
  
  ref.onDispose(() {
    sub.cancel();
    tracker.dispose();
  });
  
  return tracker;
});
