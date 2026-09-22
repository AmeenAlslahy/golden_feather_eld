import 'dart:async';

/// متتبع حالة السائق (Domain Pure)
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/services/local_storage_service.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../logs/domain/repositories/log_repository.dart';
import '../../../../sync/domain/entities/pending_event.dart';
import '../../../../sync/domain/usecases/sync_engine.dart';


class DutyStatusTracker {
  final LogRepository _logRepository;
  final LocalStorageService _localStorage;
  final SyncEngine _syncEngine;
  final TrustedTimeProvider _timeProvider;

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
    required LocalStorageService localStorage,
    required SyncEngine syncEngine,
    required TrustedTimeProvider timeProvider,
  })  : _logRepository = logRepository,
        _localStorage = localStorage,
        _syncEngine = syncEngine,
        _timeProvider = timeProvider {
    _initStationaryState();
  }

  List<DutyStatusEvent> get events => List.unmodifiable(_events);
  List<DutyPeriod> get periods => List.unmodifiable(_periods);
  String get currentStatus => _currentStatus;

  void _initStationaryState() {
    final savedStatus = _localStorage.currentDutyStatus;
    if (savedStatus.isNotEmpty) {
      _currentStatus = savedStatus;
    }

    final savedTime = _localStorage.stationarySince;
    if (savedTime != null && savedTime.isNotEmpty) {
      final parsed = DateTime.tryParse(savedTime);
      if (parsed != null) {
        _stationarySince = parsed;
        _evaluateStationaryState();
      }
    }
  }

  void processEldEvent(EldEvent eldEvent) {
    if (eldEvent.speed.inMilesPerHour > 5.0) {
      // Moving logic
      _movingSince ??= eldEvent.timestamp;
      _consecutiveMovingEvents++;

      final elapsed = eldEvent.timestamp.difference(_movingSince!);

      // Require at least 3 seconds of sustained movement AND 3 consecutive events
      // to reject GPS hardware spikes (Outliers).
      if (_consecutiveMovingEvents >= 3 && elapsed.inSeconds >= 3) {
        if (_stationarySince != null) {
          _stationarySince = null;
          _localStorage.setStationarySince('');
          _wakeupTimer?.cancel();
        }

        if (_currentStatus != 'driving') {
          _transitionTo(
            newStatus: 'driving',
            timestamp:
                _movingSince!, // Use the timestamp when movement first started
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
          _localStorage.setStationarySince(_stationarySince!.toIso8601String());
        }
        _evaluateStationaryState(
            eventTimestamp: eldEvent.timestamp,
            odometer: eldEvent.odometerMiles,
            engineHours: eldEvent.engineHours);
      }
    }
  }

  DateTime _getCurrentTime() {
    final timeResult = _timeProvider.currentTime;
    if (timeResult is TrustedTimeAvailable) {
      return timeResult.utc;
    }
    // Explicit fallback for tracking events only (HOS calculations are already suspended)
    return DateTime.now().toUtc();
  }

  void _evaluateStationaryState(
      {DateTime? eventTimestamp, double? odometer, double? engineHours}) {
    if (_stationarySince == null || _currentStatus != 'driving') return;

    final referenceTime = eventTimestamp ?? _getCurrentTime();
    final elapsed = referenceTime.difference(_stationarySince!);

    if (elapsed.inMinutes >= 5) {
      // Met the 5-minute stationary rule
      final effectiveTimestamp = referenceTime;
      _stationarySince = null;
      _localStorage.setStationarySince('');
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

  Future<void> _transitionTo({
    required String newStatus,
    required DateTime timestamp,
    double? latitude,
    double? longitude,
    double? odometer,
    double? engineHours,
    String? annotation,
  }) async {
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

    bool periodSaved = true;

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

      final result = await _logRepository.savePeriod(period);
      result.match(
        (failure) {
          AppLogger.error('Failed to save period', failure.message);
          periodSaved = false;
        },
        (success) {
          _periods.add(period);
          AppLogger.info('Period saved successfully');
        }
      );
    }

    if (!periodSaved) {
      return; // Do not broadcast or change memory if save failed
    }

    _currentStatus = newStatus;
    await _localStorage.setCurrentDutyStatus(newStatus);
    _lastEvent = event;
    AppLogger.info('📊 Duty Status: $currentStatus');

    // Queue the transition to be synced with the backend (Transactional Outbox)
    await _syncEngine.submitEvent(PendingEvent(
      id: const Uuid().v4(),
      type: 'duty_status',
      payload: {
        'status': newStatus,
        'timestamp': timestamp.toIso8601String(),
        'deviceId': int.tryParse(_localStorage.deviceId) ?? 0,
        'driverId': int.tryParse(_localStorage.driverId ?? '0') ?? 0,
        'location': latitude != null && longitude != null
            ? '$latitude, $longitude'
            : 'Unknown',
        'odometer': odometer ?? 0.0,
        'engineHours': engineHours ?? 0.0,
        'remarks': annotation ?? '',
        'attributes': const {},
      },
      createdAt: _getCurrentTime(),
    ));

    // Only broadcast to UI AFTER successful persistence
    if (!_transitionController.isClosed) {
      _transitionController.add(DutyTransition(
        newStatus: newStatus,
        annotation: annotation ?? 'Manual/System Transition',
      ));
    }
  }

  void manualTransition(String newStatus,
      {double? lat, double? lon, String? annotation}) {
    if (_currentStatus == 'driving' && newStatus != 'driving') {
      AppLogger.warning(
          'Cannot manually transition from driving while moving.');
    }

    // Clear stationary timer and movement buffers if manually transitioning
    _stationarySince = null;
    _localStorage.setStationarySince('');
    _wakeupTimer?.cancel();

    _movingSince = null;
    _consecutiveMovingEvents = 0;

    _transitionTo(
      newStatus: newStatus,
      timestamp: _getCurrentTime(),
      latitude: lat,
      longitude: lon,
      annotation: annotation,
    );

    // Watchdog timer: If GPS is completely off or not moving, we start counting 5 mins.
    if (newStatus == 'driving') {
      _startWatchdogTimer();
    }
  }

  Timer? _watchdogTimer;

  void reset() {
    _wakeupTimer?.cancel();
    _watchdogTimer?.cancel();
    _events.clear();
    _periods.clear();
    _currentStatus = 'off_duty';
    _stationarySince = null;
    _movingSince = null;
    _consecutiveMovingEvents = 0;
    _lastEvent = null;
  }

  void _startWatchdogTimer() {
    _stationarySince = _getCurrentTime();
    _localStorage.setStationarySince(_stationarySince!.toIso8601String());
    _evaluateStationaryState();
  }

  Duration _getIntersection(DateTime pStart, DateTime pEnd, DateTime wStart, DateTime wEnd) {
    final start = pStart.isAfter(wStart) ? pStart : wStart;
    final end = pEnd.isBefore(wEnd) ? pEnd : wEnd;
    if (end.isAfter(start)) {
      return end.difference(start);
    }
    return Duration.zero;
  }

  Map<String, double> getTodayStats() {
    final now = _getCurrentTime();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    double driving = 0, onDuty = 0, offDuty = 0, sleeper = 0;
    double totalDistance = 0;

    for (final period in _periods) {
      final intersectDuration = _getIntersection(period.startTime, period.endTime, todayStart, todayEnd);
      if (intersectDuration > Duration.zero) {
        final hours = intersectDuration.inMinutes / 60.0;
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
    final now = _getCurrentTime();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    // Usually week boundary ends at now
    final weekEnd = now;

    double driving = 0, work = 0, rest = 0;
    double totalDistance = 0;

    for (final period in _periods) {
      final intersectDuration = _getIntersection(period.startTime, period.endTime, weekStart, weekEnd);
      if (intersectDuration > Duration.zero) {
        final hours = intersectDuration.inMinutes / 60.0;
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
    _localStorage.setCurrentDutyStatus('off_duty');
    _stationarySince = null;
    _localStorage.setStationarySince('');
    _wakeupTimer?.cancel();
    _watchdogTimer?.cancel();

    _movingSince = null;
    _consecutiveMovingEvents = 0;
  }

  void dispose() {
    _wakeupTimer?.cancel();
    _watchdogTimer?.cancel();
    _transitionController.close();
  }
}
