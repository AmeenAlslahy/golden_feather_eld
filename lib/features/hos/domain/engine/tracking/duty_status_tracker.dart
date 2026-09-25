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



abstract final class DutyStampRefusal {
  static const timeUnavailable = 'trusted_time_unavailable';
  static const sessionMissing = 'driver_session_missing';
  static const unmapped = 'unmapped_duty_status';
  static const moving = 'moving';
  static const notReady = 'duty_status_not_ready';
}

String? _wireDutyStatus(String status) {
  switch (status) {
    case 'driving':
      return 'DRIVING';
    case 'on_duty':
      return 'ON_DUTY';
    case 'off_duty':
      return 'OFF_DUTY';
    case 'sleeper':
    case 'sleeper_berth':
      return 'SLEEPER';
    case 'yard_move':
      return 'YARD_MOVE';
    case 'personal_use':
    case 'personal_conveyance':
      return 'PERSONAL_CONVEYANCE';
    default:
      return null;
  }
}

class DutyStatusTracker {
  final LogRepository _logRepository;
  final LocalStorageService _localStorage;
  final SyncEngine _syncEngine;
  final TrustedTimeProvider _timeProvider;
  final int? Function()? _readDriverId;

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
    int? Function()? readDriverId,
  })  : _logRepository = logRepository,
        _localStorage = localStorage,
        _syncEngine = syncEngine,
        _timeProvider = timeProvider,
        _readDriverId = readDriverId {
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
    // Phone GPS and simulated speed are not ECM. They must not create a
    // legal driving record. The server applies automatic driving from
    // POST /eld/hardware/telemetry.
    if (!eldEvent.fromEcm) return;

    if (eldEvent.speedMph > 5.0) {
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
            origin: 'ECM',
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

  DateTime? _getCurrentTime() {
    final timeResult = _timeProvider.currentTime;
    if (timeResult is TrustedTimeAvailable) {
      return timeResult.utc;
    }
    return null;
  }

  void _evaluateStationaryState(
      {DateTime? eventTimestamp, double? odometer, double? engineHours}) {
    if (_stationarySince == null || _currentStatus != 'driving') return;

    final currentTime = _getCurrentTime();
    if (currentTime == null) return;
    final elapsed = currentTime.difference(_stationarySince!);

    if (elapsed.inMinutes >= 5) {
      // Met the 5-minute stationary rule
      final effectiveTimestamp = eventTimestamp ?? currentTime;
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

  String? _legalRefusal() {
    if (_getCurrentTime() == null) return DutyStampRefusal.timeUnavailable;
    final reader = _readDriverId;
    if (reader != null) {
      final driverId = reader();
      if (driverId == null || driverId <= 0) {
        return DutyStampRefusal.sessionMissing;
      }
    }
    return null;
  }

  PendingEvent _stampedDutyEvent({
    required String wireStatus,
    required DateTime trustedUtc,
    double? latitude,
    double? longitude,
    double? odometer,
    double? engineHours,
    String? annotation,
    String? origin,
  }) {
    final stamp = trustedUtc.toUtc();
    return PendingEvent(
      id: const Uuid().v4(),
      type: 'duty_status',
      payload: {
        'status': wireStatus,
        'startTime': stamp.toIso8601String(),
        if (annotation != null && annotation.isNotEmpty) 'notes': annotation,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (latitude != null && longitude != null)
          'locationText': '$latitude, $longitude',
        if (odometer != null) 'odometerKm': odometer * 1.609344,
        if (engineHours != null) 'engineHours': engineHours,
        if (origin != null) 'origin': origin,
      },
      createdAt: stamp,
    );
  }

  void _transitionTo({
    required String newStatus,
    required DateTime timestamp,
    double? latitude,
    double? longitude,
    double? odometer,
    double? engineHours,
    String? annotation,
    String? origin,
    bool enqueue = true,
  }) {
    if (_currentStatus == newStatus) return;

    final trusted = _getCurrentTime();
    if (trusted == null) {
      AppLogger.warning('Refusing duty transition: trusted time unavailable');
      return;
    }
    if (_legalRefusal() == DutyStampRefusal.sessionMissing) {
      AppLogger.warning('Refusing duty transition: driver session is missing');
      return;
    }

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
          (failure) =>
              AppLogger.error('Failed to save period', failure.message),
          (success) => AppLogger.info('Period saved successfully'),
        );
      });
    }

    _currentStatus = newStatus;
    _localStorage.setCurrentDutyStatus(newStatus);
    _lastEvent = event;
    AppLogger.info('📊 Duty Status: $currentStatus');

    // The legal stamp is the anchored clock, never the movement timestamp
    // and never DateTime.now(). Missing odometer stays absent.
    final wireStatus = _wireDutyStatus(newStatus);
    if (!enqueue) {
      // The caller already sent this stamp and got a server result.
    } else if (wireStatus == null) {
      AppLogger.warning('Refusing to sync unmapped duty status: $newStatus');
    } else {
      _syncEngine.submitEvent(_stampedDutyEvent(
        wireStatus: wireStatus,
        trustedUtc: trusted,
        latitude: latitude,
        longitude: longitude,
        odometer: odometer,
        engineHours: engineHours,
        annotation: annotation,
        origin: origin,
      ));
    }

    _transitionController.add(DutyTransition(
      newStatus: newStatus,
      annotation: annotation ?? 'Manual/System Transition',
    ));
  }

  String? manualTransition(String newStatus,
      {double? lat, double? lon, String? annotation}) {
    final refusal = _legalRefusal();
    if (refusal != null) {
      AppLogger.warning('Refusing duty transition: $refusal');
      return refusal;
    }
    _applyManualLocal(
      newStatus: newStatus,
      timestamp: _getCurrentTime()!,
      lat: lat,
      lon: lon,
      annotation: annotation,
      enqueue: true,
    );
    return null;
  }

  /// Stamp with trusted time, send, and change local status only after accept.
  Future<String?> submitManualChange(String newStatus,
      {double? lat, double? lon, String? annotation}) async {
    final refusal = _legalRefusal();
    if (refusal != null) {
      AppLogger.warning('Refusing duty transition: $refusal');
      return refusal;
    }
    final trusted = _getCurrentTime()!;
    final wireStatus = _wireDutyStatus(newStatus);
    if (wireStatus == null) {
      AppLogger.warning('Refusing to sync unmapped duty status: $newStatus');
      return DutyStampRefusal.unmapped;
    }

    final result = await _syncEngine.submitEventAndReport(_stampedDutyEvent(
      wireStatus: wireStatus,
      trustedUtc: trusted,
      latitude: lat,
      longitude: lon,
      annotation: annotation,
    ));
    return result.fold((failure) {
      final message = failure.message.trim();
      return message.isEmpty ? 'Duty status was rejected' : message;
    }, (_) {
      _applyManualLocal(
        newStatus: newStatus,
        timestamp: trusted,
        lat: lat,
        lon: lon,
        annotation: annotation,
        enqueue: false,
      );
      return null;
    });
  }

  void _applyManualLocal({
    required String newStatus,
    required DateTime timestamp,
    double? lat,
    double? lon,
    String? annotation,
    required bool enqueue,
  }) {
    if (_currentStatus == 'driving' && newStatus != 'driving') {
      AppLogger.warning(
          'Cannot manually transition from driving while moving.');
    }

    _stationarySince = null;
    _localStorage.setStationarySince('');
    _wakeupTimer?.cancel();
    _movingSince = null;
    _consecutiveMovingEvents = 0;

    _transitionTo(
      newStatus: newStatus,
      timestamp: timestamp,
      latitude: lat,
      longitude: lon,
      annotation: annotation,
      enqueue: enqueue,
    );

    if (newStatus == 'driving') {
      _stationarySince = timestamp;
      _localStorage.setStationarySince(_stationarySince!.toIso8601String());
      _evaluateStationaryState();
    }
  }

  Map<String, double> getTodayStats() {
    final now = _getCurrentTime();
    if (now == null) {
      return {
        'driving': 0,
        'on_duty': 0,
        'off_duty': 0,
        'sleeper': 0,
        'distance': 0,
      };
    }
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
    final now = _getCurrentTime();
    if (now == null) {
      return {
        'driving': 0,
        'work': 0,
        'rest': 0,
        'distance': 0,
      };
    }
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
    _localStorage.setCurrentDutyStatus('off_duty');
    _stationarySince = null;
    _localStorage.setStationarySince('');
    _wakeupTimer?.cancel();

    _movingSince = null;
    _consecutiveMovingEvents = 0;
  }

  void dispose() {
    _wakeupTimer?.cancel();
    _transitionController.close();
  }
}
