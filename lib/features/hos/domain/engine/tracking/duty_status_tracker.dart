import 'dart:async';

import '../../../../../core/utils/logger.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/error/app_error.dart';
import '../../../../../core/services/local_storage_service.dart';
import '../../repositories/duty_period_store.dart';

/// متتبع حالة السائق (Domain Pure)
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import '../../../../sync/domain/usecases/sync_engine.dart';
import '../../../../sync/domain/entities/duty_event_record.dart';
import '../../../../sync/domain/entities/pending_event.dart';
import '../../../../sync/domain/repositories/duty_event_journal.dart';
import 'package:uuid/uuid.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import '../../../../../backend/contracts/status_dashboard_backend.dart';
import '../../../../../domain/duty_status/duty_status_code.dart';
import '../../../../../domain/duty_status/status_dashboard.dart';
import '../../../../../domain/shared/value_objects.dart';

abstract final class DutyStampRefusal {
  static const timeUnavailable = 'trusted_time_unavailable';
  static const sessionMissing = 'driver_session_missing';
  static const unmapped = 'unmapped_duty_status';
  static const moving = 'moving';
  static const notReady = 'duty_status_not_ready';
  static const serverRejected = 'server_rejected';
  static const storageUnavailable = 'duty_storage_unavailable';
}

// Mapping replaced by DutyStatusCode.fromAny()

/// نتيجة تغيير الحالة اليدوي: سبب الرفض (`null` = قَبِل الخادم) مع لقطة
/// لوحة الخادم عند حملها — تستخدمها الواجهة لتغذية اللوحة مباشرة من
/// استجابة POST بدل انتظار GET لاحق (تقليل زمن الاستجابة المرئية).
///
/// `dashboard == null` مع `accepted` تعني: قُبل التغيير لكن الاستجابة لم
/// تحمل لقطة (جسم بلا حقول لوحة) أو كان الفشل شبكياً — على الواجهة ألا
/// تختلق أرقاماً، بل تُصحّح من GET (متصل) أو من المحرك المحلي (أوفلاين).
class ManualDutyChangeResult {
  final String? refusal;
  final StatusDashboard? dashboard;
  final String? serverMessage;

  const ManualDutyChangeResult({
    this.refusal,
    this.dashboard,
    this.serverMessage,
  });

  bool get accepted => refusal == null;
}

class DutyStatusTracker {
  final DutyPeriodStore _periodStore;
  final LocalStorageService _localStorage;
  final SyncEngine _syncEngine;
  final StatusDashboardBackend _dashboardBackend;
  final TrustedTimeProvider _timeProvider;
  final int? Function()? _readDriverId;

  /// P1.1 — append-only evidence. `null` keeps the legacy (pre-journal)
  /// behaviour for existing tests and call sites; production always injects it.
  final DutyEventJournal? _journal;

  final _transitionController = StreamController<DutyTransition>.broadcast();
  Stream<DutyTransition> get onTransition => _transitionController.stream;

  final List<DutyStatusEvent> _events = [];
  final List<DutyPeriod> _periods = [];
  final Set<String> _appliedEventIds = {};
  String _currentStatus = 'off_duty';
  DutyStatusEvent? _lastEvent;

  bool _hydrated = false;
  bool _hydrationFailed = false;
  bool _disposed = false;
  bool _journalCorrupted = false;
  int? _hydratedOwnerId;
  Future<void>? _hydration;
  Future<void> _persistChain = Future<void>.value();

  bool get isHydrated => _hydrated;
  bool get hydrationFailed => _hydrationFailed;
  bool get journalHasCorruption => _journalCorrupted;

  /// Completes after every scheduled journal commit has settled.
  Future<void> get persistenceIdle => _persistChain;

  DateTime? _stationarySince;
  Timer? _wakeupTimer;

  DateTime? _movingSince;
  int _consecutiveMovingEvents = 0;
  int get consecutiveMovingEvents => _consecutiveMovingEvents;

  // Decision 3 (P0): Active ECM telemetry state tracking for Priority 1 & Conflict Resolution
  //
  // Time Source Decision & Clock Skew Guard:
  // `_lastEcmTimestamp` is captured directly from `eldEvent.timestamp` (the legal hardware frame timestamp).
  // Freshness comparisons calculate `age = (_getCurrentTime() ?? DateTime.now().toUtc()).difference(_lastEcmTimestamp!).abs()`.
  // Using `.abs()` safely prevents failure if minor clock drift exists between the phone OS clock and device hardware.
  DateTime? _lastEcmTimestamp;
  double? _lastEcmSpeedMph;

  DateTime? get lastEcmTimestamp => _lastEcmTimestamp;
  double? get lastEcmSpeedMph => _lastEcmSpeedMph;

  /// Decision 3 (P0): Active ECM stationary state check.
  /// Considered active if latest confirmed ECM packet is within [AppConstants.ecmActiveWindowSeconds] (30s)
  /// and speed <= 5.0 mph.
  bool get isEcmStationaryActive {
    if (_lastEcmTimestamp == null || _lastEcmSpeedMph == null) return false;
    final now = _getCurrentTime() ?? DateTime.now().toUtc();
    final ageMs = now.difference(_lastEcmTimestamp!).abs().inMilliseconds;
    return ageMs <= (AppConstants.ecmActiveWindowSeconds * 1000) && _lastEcmSpeedMph! <= 5.0;
  }

  /// Decision 3 (P0): Active ECM driving state check.
  /// Considered active if latest confirmed ECM packet is within [AppConstants.ecmActiveWindowSeconds] (30s)
  /// and speed > 5.0 mph.
  bool get isEcmDrivingActive {
    if (_lastEcmTimestamp == null || _lastEcmSpeedMph == null) return false;
    final now = _getCurrentTime() ?? DateTime.now().toUtc();
    final ageMs = now.difference(_lastEcmTimestamp!).abs().inMilliseconds;
    return ageMs <= (AppConstants.ecmActiveWindowSeconds * 1000) && _lastEcmSpeedMph! > 5.0;
  }

  DutyStatusTracker({
    required DutyPeriodStore dutyPeriodStore,
    required LocalStorageService localStorage,
    required SyncEngine syncEngine,
    required StatusDashboardBackend dashboardBackend,
    required TrustedTimeProvider timeProvider,
    int? Function()? readDriverId,
    DutyEventJournal? journal,

    /// استدعاء [readDriverId] داخل الباني لبدء الترطيب فوراً.
    ///
    /// يبقى `true` للاختبارات والاستخدام المباشر. أما المزوّد فيمرّر
    /// `false` ثم يبدأ الترطيب بعد اكتمال البناء: قراءة مزوّد Riverpod
    /// داخل باني مزوّد آخر تُنعشه وتُطلق مستمعيه أثناء البناء.
    bool hydrateOnCreate = true,
  }) : _periodStore = dutyPeriodStore,
       _localStorage = localStorage,
       _syncEngine = syncEngine,
       _dashboardBackend = dashboardBackend,
       _timeProvider = timeProvider,
       _readDriverId = readDriverId,
       _journal = journal {
    _initStationaryState();
    if (_journal == null) {
      _hydrated = true;
    } else if (hydrateOnCreate) {
      final owner = _readDriverId?.call();
      if (owner != null && owner > 0) {
        unawaited(hydrateForDriver(owner));
      }
    }
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
        unawaited(_evaluateStationaryState());
      }
    }
  }

  /// P1.1 — rebuild derived state from the append-only journal.
  ///
  /// Replay selects by the journal row's own `ownerDriverId`; the current
  /// session only decides which owner to ask for. A row is never re-owned.
  Future<void> hydrateForDriver(int ownerDriverId) async {
    if (_hydrated && _hydratedOwnerId == ownerDriverId) return;
    _hydrationFailed = false;

    // The constructor (or a driver switch) may already be hydrating; never
    // run two replays concurrently. If another caller started a new hydration
    // while we waited, wait for that one and re-check.
    while (true) {
      final inFlight = _hydration;
      if (inFlight == null) break;
      try {
        await inFlight;
      } catch (_) {
        // Retry below.
      }
      if (_hydrated && _hydratedOwnerId == ownerDriverId) return;
      if (identical(_hydration, inFlight)) break;
    }

    if (_hydratedOwnerId != null && _hydratedOwnerId != ownerDriverId) {
      _resetDerivedState();
    }
    // P1.3: stay in `initializing` for the whole replay, including the drain
    // passes that pick up rows committed while a read was in flight.
    _hydrated = false;
    final future = _hydrate(ownerDriverId);
    _hydration = future;
    await future;
  }

  Future<void> _hydrate(int ownerDriverId) async {
    final journal = _journal;
    if (journal == null) {
      _hydrated = true;
      _hydratedOwnerId = ownerDriverId;
      return;
    }

    // P1.1 #7 / P1.3 #4: replay stays in `initializing` until the journal is
    // quiescent. Every pass replays the complete, ordered journal; a row
    // committed while a read was in flight changes `_persistChain`, so the
    // pass repeats and the late row is replayed in legal-time order instead
    // of being applied on top of newer derived state.
    var corruptedRows = 0;
    while (true) {
      try {
        await _persistChain;
      } catch (_) {
        // A failed earlier commit must not block recovery.
      }
      final chainBeforeLoad = _persistChain;

      DutyEventJournalLoad load;
      try {
        load = await journal.load(ownerDriverId: ownerDriverId);
      } catch (e) {
        AppLogger.error('DutyEventJournal: hydration read failed', e);
        _hydrated = false;
        _hydrationFailed = true;
        _hydration = null;
        return;
      }
      if (_disposed) return;

      corruptedRows = load.corruptedRows;
      _journalCorrupted = load.hasCorruption;
      _resetDerivedState();

      if (load.records.isEmpty) {
        // Migration window: existing installs have prefs but no journal yet.
        final saved = _localStorage.currentDutyStatus;
        if (saved.isNotEmpty) _currentStatus = saved;
      } else {
        _replayRecords(load.records, ownerDriverId);
        unawaited(
          _contain(
            () => _localStorage.setCurrentDutyStatus(_currentStatus),
            'Failed to persist replayed duty status',
          ),
        );
      }

      if (identical(_persistChain, chainBeforeLoad)) break;
    }

    if (_disposed) return;
    _hydrated = true;
    _hydratedOwnerId = ownerDriverId;

    AppLogger.info(
      'DutyStatusTracker: journal hydrated ${_events.length} events '
      '($corruptedRows corrupt rows retained)',
    );
  }

  void _resetDerivedState() {
    _events.clear();
    _periods.clear();
    _appliedEventIds.clear();
    _lastEvent = null;
    _currentStatus = 'off_duty';
  }

  void _replayRecords(List<DutyEventRecord> records, int ownerDriverId) {
    for (final record in records) {
      if (record.ownerDriverId != ownerDriverId) continue;
      if (record.syncState == DutyEventSyncState.pendingReview) continue;
      final time = record.eventTimeUtc;
      if (time == null) continue;
      if (!_appliedEventIds.add(record.eventId)) continue;
      _appendDerived(
        DutyStatusEvent(
          status: record.status,
          timestamp: time,
          latitude: _asDouble(record.payload['latitude']),
          longitude: _asDouble(record.payload['longitude']),
          odometer: _asDouble(record.payload['odometerMiles']),
          engineHours: _asDouble(record.payload['engineHours']),
        ),
      );
    }
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return null;
  }

  DutyPeriod? _closedPeriodFor(DutyStatusEvent event) {
    final previous = _lastEvent;
    if (previous == null) return null;
    final effectiveEndTime = event.timestamp.isBefore(previous.timestamp)
        ? previous.timestamp
        : event.timestamp;
    return DutyPeriod(
      status: previous.status,
      startTime: previous.timestamp,
      endTime: effectiveEndTime,
      startOdometer: previous.odometer,
      endOdometer: event.odometer,
      startLat: previous.latitude,
      startLon: previous.longitude,
      endLat: event.latitude,
      endLon: event.longitude,
    );
  }

  /// Adds an event to the derived state and returns the segment it closes.
  DutyPeriod? _appendDerived(DutyStatusEvent event) {
    final closedPeriod = _closedPeriodFor(event);
    _events.add(event);
    if (closedPeriod != null) _periods.add(closedPeriod);
    _currentStatus = event.status;
    _lastEvent = event;
    return closedPeriod;
  }

  Future<void> processEldEvent(EldEvent eldEvent) async {
    // Phone GPS and simulated speed are not ECM. They must not create a
    // legal driving record. The server applies automatic driving from
    // POST /eld/hardware/telemetry.
    if (!eldEvent.fromEcm) return;

    // Decision 3 (P0): Update active ECM state
    _lastEcmTimestamp = eldEvent.timestamp;
    _lastEcmSpeedMph = eldEvent.speedMph;

    if (eldEvent.speedMph > 5.0) {
      // Decision 3 (P0) - Priority 1: Immediate transition to driving (> 5 mph from confirmed ECM).
      // No debounce: instantaneous transition on the very first packet when valid ECM speed exceeds 5 mph threshold.
      final isNewMovement = _movingSince == null;
      _movingSince ??= eldEvent.timestamp;
      _consecutiveMovingEvents++;

      if (_stationarySince != null) {
        _stationarySince = null;
        _localStorage.setStationarySince('');
        _wakeupTimer?.cancel();
      }

      if (_currentStatus != 'driving' && isNewMovement) {
        await _transitionTo(
          newStatus: 'driving',
          timestamp: eldEvent.timestamp,
          odometer: eldEvent.odometerMiles,
          engineHours: eldEvent.engineHours,
          annotation: 'Auto Transition to Driving (> 5 mph ECM)',
          origin: 'ECM',
          source: DutyEventSource.ecm,
        );
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
        await _evaluateStationaryState(
          eventTimestamp: eldEvent.timestamp,
          odometer: eldEvent.odometerMiles,
          engineHours: eldEvent.engineHours,
        );
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

  Future<void> _evaluateStationaryState({
    DateTime? eventTimestamp,
    double? odometer,
    double? engineHours,
  }) async {
    if (_stationarySince == null || _currentStatus != 'driving') return;

    final currentTime = _getCurrentTime();
    if (currentTime == null) return;
    final elapsed = currentTime.difference(_stationarySince!);

    if (elapsed.inMinutes >= 5) {
      // Met the 5-minute stationary rule
      final effectiveTimestamp = eventTimestamp ?? currentTime;
      _stationarySince = null;
      unawaited(
        _contain(
          () => _localStorage.setStationarySince(''),
          'Failed to clear stationary marker',
        ),
      );
      _wakeupTimer?.cancel();

      await _transitionTo(
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
        unawaited(_evaluateStationaryState());
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
    final id = const Uuid().v4();
    return PendingEvent(
      id: id,
      type: 'duty_status',
      payload: {
        // P0 — مفتاح idempotency: نجاح الخادم مع فَقْد الرد (انقطاع بعد
        // commit) كان يُعيد الإرسال ⇒ سجل مزدوج. الخادم يتجاهل الحقل
        // إن لم يدعمه، ووجوده يمكّن إزالة التكرار لاحقاً بلا تغيير عقد.
        'clientId': id,
        'status': wireStatus,
        'startTime': stamp.toIso8601String(),
        if (_readDriverId?.call() != null) 'driverId': _readDriverId!.call(),
        if (annotation != null && annotation.isNotEmpty) 'notes': annotation,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (latitude != null && longitude != null)
          'locationText': '$latitude, $longitude',
        if (odometer != null && odometer >= 0)
          'odometerKm': odometer * 1.609344,
        if (engineHours != null) 'engineHours': engineHours,
        if (origin != null) 'origin': origin,
      },
      createdAt: stamp,
    );
  }

  /// P0 — تثبيت آثار انتقال الحالة مع احتواء كامل للأخطاء.
  ///
  /// قبل P0: `setCurrentDutyStatus` و`submitEvent` كانا يُطلقان بلا انتظار
  /// و`savePeriod(...).then` لا يلتقط الاستثناء — فأي فشل كتابة كان يضيع
  /// الحدث صامتاً (unhandled rejection) بينما الواجهة تعرض الحالة الجديدة.
  ///
  /// الآن: الثلاثة تبدأ فورياً (فيبقى الإدراج مرئياً للمسارات المتزامنة
  /// كما كان) لكن كل نتيجة محتواة ومسجلة — لا فشل صامت.
  Future<void> _persistTransition({
    required String status,
    DutyPeriod? period,
    PendingEvent? event,
  }) async {
    final statusDone = _contain(
      () => _localStorage.setCurrentDutyStatus(status),
      'Failed to persist declared duty status',
    );
    final eventDone = event == null
        ? Future<void>.value()
        : _contain(
            () => _syncEngine.submitEvent(event),
            'Failed to queue duty event ${event.id}',
          );

    if (period != null) {
      try {
        await _periodStore.savePeriod(period);
        AppLogger.info('Period saved successfully');
      } catch (e) {
        AppLogger.error('Failed to save period', e);
      }
    }

    await statusDone;
    await eventDone;
  }

  Future<void> _contain(Future<void> Function() action, String message) async {
    try {
      await action();
    } catch (e) {
      AppLogger.error(message, e);
    }
  }

  /// P1.1 — durable transition path.
  ///
  /// With a journal: journal row + queue row commit atomically **before** the
  /// tracker's public state changes or `DutyTransition` is emitted. Without a
  /// journal (legacy tests/call sites) the previous synchronous behaviour is
  /// kept unchanged.
  /// Decision 3 (P0): Priority 2 - Server telemetry fallback to driving.
  ///
  /// AUTHORIZATION & INVOCATION CONSTRAINTS:
  /// - Only `TrackingOrchestrator` is authorized to invoke this method upon receiving
  ///   confirmed `transitionedToDriving == true` from backend telemetry (POST /eld/hardware/telemetry).
  /// - Phone GPS and manual UI flows MUST NOT invoke this method.
  /// - Governed strictly by Conflict Policy: if active local ECM telemetry contradicts
  ///   (`isEcmStationaryActive == true`), this transition is REJECTED and ECM wins.
  Future<bool> transitionToDriving({
    DutyEventSource source = DutyEventSource.server,
    DateTime? timestamp,
    double? odometer,
    double? engineHours,
  }) async {
    // Decision 3 Conflict Policy: ECM always wins over server.
    if (source == DutyEventSource.server && isEcmStationaryActive) {
      AppLogger.warning(
        'Decision 3 Conflict: Server reported transitionedToDriving but active ECM indicates stationary. ECM wins.',
      );
      await _recordConflictResolution(
        serverEvent: 'transitionedToDriving',
        reason: 'ecm_override_server',
        ecmSpeedMph: _lastEcmSpeedMph,
        ecmTimestamp: _lastEcmTimestamp,
      );
      return false;
    }

    if (_currentStatus == 'driving') return true;

    final effectiveTime =
        timestamp ?? _getCurrentTime() ?? DateTime.now().toUtc();
    await _transitionTo(
      newStatus: 'driving',
      timestamp: effectiveTime,
      odometer: odometer,
      engineHours: engineHours,
      annotation: source == DutyEventSource.server
          ? 'Auto Transition to Driving (Server Telemetry Fallback)'
          : 'Auto Transition to Driving',
      origin: source == DutyEventSource.server ? 'server' : 'ECM',
      source: source,
    );
    return true;
  }

  /// Decision 3 (P0): External / Server status transition with conflict policy.
  ///
  /// AUTHORIZATION & INVOCATION CONSTRAINTS:
  /// - Used when the server attempts to command a duty status change (e.g. OnDuty, OffDuty).
  /// - Conflict Policy: If server attempts to change status to non-driving while ECM is actively
  ///   driving (> 5 mph, `isEcmDrivingActive == true`), ECM wins: transition is REJECTED, driver
  ///   remains in driving, and `conflict_resolution: ecm_override_server_driving` is recorded in the journal.
  Future<bool> transitionToStatus(
    String newStatus, {
    DutyEventSource source = DutyEventSource.server,
    DateTime? timestamp,
    double? odometer,
    double? engineHours,
    String? annotation,
  }) async {
    if (source == DutyEventSource.server) {
      if (newStatus == 'driving') {
        return transitionToDriving(
          source: source,
          timestamp: timestamp,
          odometer: odometer,
          engineHours: engineHours,
        );
      }

      // Conflict Policy: ECM Driving wins over Server NotDriving / OnDuty.
      if (newStatus != 'driving' && isEcmDrivingActive) {
        AppLogger.warning(
          'Decision 3 Conflict: Server attempted to transition to $newStatus but active ECM indicates driving (> 5 mph). ECM wins.',
        );
        await _recordConflictResolution(
          serverEvent: 'server_transition_$newStatus',
          reason: 'ecm_override_server_driving',
          ecmSpeedMph: _lastEcmSpeedMph,
          ecmTimestamp: _lastEcmTimestamp,
        );
        return false;
      }
    }

    if (_currentStatus == newStatus) return true;

    final effectiveTime =
        timestamp ?? _getCurrentTime() ?? DateTime.now().toUtc();
    await _transitionTo(
      newStatus: newStatus,
      timestamp: effectiveTime,
      odometer: odometer,
      engineHours: engineHours,
      annotation: annotation ?? 'Server Transition to $newStatus',
      origin: source == DutyEventSource.server ? 'server' : 'manual',
      source: source,
    );
    return true;
  }

  /// Decision 3: Record conflict resolution row into append-only journal.
  Future<void> _recordConflictResolution({
    required String serverEvent,
    required String reason,
    double? ecmSpeedMph,
    DateTime? ecmTimestamp,
  }) async {
    if (_journal == null) return;
    final trusted = _getCurrentTime() ?? DateTime.now().toUtc();
    final record = DutyEventRecord(
      eventId: 'conflict_',
      ownerDriverId: _readDriverId?.call(),
      source: DutyEventSource.ecm,
      status: _currentStatus,
      eventTimeUtc: trusted,
      receivedAtUtc: trusted,
      timeSource: DutyTimeSource.device,
      timeConfidence: DutyTimeConfidence.trusted,
      monotonicMs: _timeProvider.monotonicElapsed.inMilliseconds,
      payload: {
        'conflict_resolution': reason, // 'ecm_override_server'
        'server_event': serverEvent,
        'ecm_speed_mph': ecmSpeedMph,
        'ecm_timestamp': ecmTimestamp?.toIso8601String(),
        'current_status': _currentStatus,
      },
      syncState: DutyEventSyncState.localOnly,
      createdAt: trusted,
    );
    await _journal.append(record);
  }

  /// P1.1 — durable transition path.
  ///
  /// With a journal: journal row + queue row commit atomically **before** the
  /// tracker's public state changes or DutyTransition is emitted. Without a
  /// journal (legacy tests/call sites) the previous synchronous behaviour is
  /// kept unchanged.
  Future<void> _transitionTo({
    required String newStatus,
    required DateTime timestamp,
    double? latitude,
    double? longitude,
    double? odometer,
    double? engineHours,
    String? annotation,
    String? origin,
    DutyEventSource? source,
    bool enqueue = true,
  }) async {
    if (_currentStatus == newStatus) return;

    final trusted = _getCurrentTime();
    if (trusted == null) {
      if (_journal != null) {
        // Evidence is retained even when no legal timestamp can be produced.
        // It is not applied to HOS and not enqueued (pendingReview).
        await _journalUntrustedIntent(
          newStatus: newStatus,
          latitude: latitude,
          longitude: longitude,
          odometer: odometer,
          engineHours: engineHours,
          annotation: annotation,
          origin: origin,
          source: source,
        );
      } else {
        AppLogger.warning('Refusing duty transition: trusted time unavailable');
      }
      return;
    }

    if (_legalRefusal() == DutyStampRefusal.sessionMissing) {
      AppLogger.warning('Refusing duty transition: driver session is missing');
      return;
    }

    if (_journal == null) {
      _commitLegacyTransition(
        newStatus: newStatus,
        trusted: trusted,
        timestamp: timestamp,
        latitude: latitude,
        longitude: longitude,
        odometer: odometer,
        engineHours: engineHours,
        annotation: annotation,
        origin: origin,
        enqueue: enqueue,
      );
      return;
    }

    // P1.3 gate: during hydration the intent is journaled and queued but not
    // applied; _hydrate replays it exactly once.
    await _journalTransition(
      newStatus: newStatus,
      trusted: trusted,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      odometer: odometer,
      engineHours: engineHours,
      annotation: annotation,
      origin: origin,
      source: source,
      enqueue: enqueue,
    );
  }

  void _commitLegacyTransition({
    required String newStatus,
    required DateTime trusted,
    required DateTime timestamp,
    double? latitude,
    double? longitude,
    double? odometer,
    double? engineHours,
    String? annotation,
    String? origin,
    required bool enqueue,
  }) {
    final event = DutyStatusEvent(
      status: newStatus,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      odometer: odometer,
      engineHours: engineHours,
    );
    final closedPeriod = _appendDerived(event);
    AppLogger.info('📊 Duty Status: $currentStatus');

    // The legal stamp is the anchored clock, never the movement timestamp
    // and never DateTime.now(). Missing odometer stays absent.
    final code = DutyStatusCode.fromAny(newStatus);
    PendingEvent? pendingEvent;
    if (!enqueue) {
      // The caller already sent this stamp and got a server result.
    } else if (code == DutyStatusCode.offDuty && newStatus != 'off_duty') {
      AppLogger.warning('Refusing to sync unmapped duty status: $newStatus');
    } else {
      pendingEvent = _stampedDutyEvent(
        wireStatus: code.wire,
        trustedUtc: trusted,
        latitude: latitude,
        longitude: longitude,
        odometer: odometer,
        engineHours: engineHours,
        annotation: annotation,
        origin: origin,
      );
    }

    unawaited(
      _persistTransition(
        status: newStatus,
        period: closedPeriod,
        event: pendingEvent,
      ),
    );

    if (!_transitionController.isClosed) {
      _transitionController.add(
        DutyTransition(
          newStatus: newStatus,
          annotation: annotation ?? 'Manual/System Transition',
        ),
      );
    }
  }

  Future<void> _journalTransition({
    required String newStatus,
    required DateTime trusted,
    required DateTime timestamp,
    required bool enqueue,
    double? latitude,
    double? longitude,
    double? odometer,
    double? engineHours,
    String? annotation,
    String? origin,
    DutyEventSource? source,
  }) async {
    final previous = _persistChain;
    final completion = Completer<void>();
    _persistChain = () async {
      try {
        await previous;
      } catch (_) {
        // Keep the chain alive after a failed predecessor.
      }
      try {
        if (_disposed) return;
        if (_currentStatus == newStatus) return;

        // P1.3 gate: when hydration is still in flight the evidence is
        // committed but not applied; hydration replays it exactly once.
        final apply = _hydrated;
        final code = DutyStatusCode.fromAny(newStatus);
        PendingEvent? pendingEvent;
        if (enqueue) {
          if (code == DutyStatusCode.offDuty && newStatus != 'off_duty') {
            AppLogger.warning(
              'Refusing to sync unmapped duty status: $newStatus',
            );
          } else {
            pendingEvent = _stampedDutyEvent(
              wireStatus: code.wire,
              trustedUtc: trusted,
              latitude: latitude,
              longitude: longitude,
              odometer: odometer,
              engineHours: engineHours,
              annotation: annotation,
              origin: origin,
            );
          }
        }

        // Same id in the journal, the queue row, and `clientId`.
        final eventId = pendingEvent?.id ?? const Uuid().v4();
        final eventSource = source ??
            (origin == 'ECM'
                ? DutyEventSource.ecm
                : (origin == 'server'
                    ? DutyEventSource.server
                    : DutyEventSource.manual));

        final record = DutyEventRecord(
          eventId: eventId,
          ownerDriverId: _readDriverId?.call(),
          source: eventSource,
          status: newStatus,
          eventTimeUtc: trusted,
          receivedAtUtc: trusted,
          timeSource: DutyTimeSource.trusted,
          timeConfidence: DutyTimeConfidence.trusted,
          monotonicMs: _timeProvider.monotonicElapsed.inMilliseconds,
          payload: {
            'status': newStatus,
            'clientId': eventId,
            'source': eventSource.name, // Decision 3: explicit source in payload
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
            if (odometer != null) 'odometerMiles': odometer,
            if (engineHours != null) 'engineHours': engineHours,
            if (annotation != null && annotation.isNotEmpty)
              'notes': annotation,
            if (origin != null) 'origin': origin,
          },
          syncState: pendingEvent != null
              ? DutyEventSyncState.queued
              : (enqueue
                    ? DutyEventSyncState.localOnly
                    : DutyEventSyncState.acked),
          createdAt: trusted,
        );

        await _journal!.append(record, syncEvent: pendingEvent);
        if (_disposed) return;

        if (apply && _appliedEventIds.add(eventId)) {
          final event = DutyStatusEvent(
            status: newStatus,
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            odometer: odometer,
            engineHours: engineHours,
          );
          final closedPeriod = _appendDerived(event);
          await _persistDerived(newStatus, closedPeriod);
          AppLogger.info('📊 Duty Status: $currentStatus');
          if (!_transitionController.isClosed) {
            _transitionController.add(
              DutyTransition(
                newStatus: newStatus,
                annotation: annotation ?? 'Manual/System Transition',
              ),
            );
          }
        }

        if (pendingEvent != null) {
          // A sync attempt, not persistence. The durable commit already
          // happened above.
          unawaited(_syncEngine.triggerSync());
        }
      } catch (e) {
        // Transaction failed: no state change, no transition emitted.
        AppLogger.error(
          'Duty transition not committed; tracker state unchanged',
          e,
        );
      } finally {
        if (!completion.isCompleted) completion.complete();
      }
    }();
    await completion.future;
  }

  Future<void> _journalUntrustedIntent({
    required String newStatus,
    double? latitude,
    double? longitude,
    double? odometer,
    double? engineHours,
    String? annotation,
    String? origin,
    DutyEventSource? source,
  }) async {
    final journal = _journal;
    if (journal == null || _disposed) return;
    final receivedAt = DateTime.now().toUtc();
    final eventId = const Uuid().v4();
    try {
      await journal.append(
        DutyEventRecord(
          eventId: eventId,
          ownerDriverId: _readDriverId?.call(),
          source: source ??
              (origin == 'ECM'
                  ? DutyEventSource.ecm
                  : (origin == 'server'
                      ? DutyEventSource.server
                      : DutyEventSource.manual)),
          status: newStatus,
          eventTimeUtc: null,
          receivedAtUtc: receivedAt,
          timeSource: DutyTimeSource.device,
          timeConfidence: DutyTimeConfidence.untrusted,
          monotonicMs: _timeProvider.monotonicElapsed.inMilliseconds,
          payload: {
            'status': newStatus,
            'clientId': eventId,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
            if (odometer != null) 'odometerMiles': odometer,
            if (engineHours != null) 'engineHours': engineHours,
            if (annotation != null && annotation.isNotEmpty)
              'notes': annotation,
            if (origin != null) 'origin': origin,
          },
          syncState: DutyEventSyncState.pendingReview,
          createdAt: receivedAt,
        ),
      );
      AppLogger.warning(
        'Duty transition recorded as pendingReview: trusted time unavailable',
      );
    } catch (e) {
      AppLogger.error('Failed to journal untrusted duty intent', e);
    }
  }

  Future<void> _persistDerived(String status, DutyPeriod? period) async {
    await _contain(
      () => _localStorage.setCurrentDutyStatus(status),
      'Failed to persist declared duty status',
    );
    if (period == null) return;
    try {
      await _periodStore.savePeriod(period);
      AppLogger.info('Period saved successfully');
    } catch (e) {
      AppLogger.error('Failed to save period', e);
    }
  }

  String? manualTransition(
    String newStatus, {
    double? lat,
    double? lon,
    String? annotation,
  }) {
    if (_journal != null && !_hydrated) {
      AppLogger.warning(
        'Refusing duty transition: ${DutyStampRefusal.notReady}',
      );
      return DutyStampRefusal.notReady;
    }
    final refusal = _legalRefusal();
    if (refusal != null) {
      AppLogger.warning('Refusing duty transition: $refusal');
      return refusal;
    }
    unawaited(
      _applyManualLocal(
        newStatus: newStatus,
        timestamp: _getCurrentTime()!,
        lat: lat,
        lon: lon,
        annotation: annotation,
        enqueue: true,
      ),
    );
    return null;
  }

  /// Stamp with trusted time, send, and change local status only after accept.
  ///
  /// التحديث اليدوي من الواجهة دلالته «تحديث حالة السائق» في لوحة الحالة:
  /// POST /eld/status/duty-status بحِمل {dutyStatus, notes} — هوية السائق
  /// تُستخرج من التوكن الأمني على الخادم ولا تُرسل في الحِمل. تسجيل الأحداث
  /// الآلية (المحرّك) يبقى على POST /eld/duty-status عبر SyncEngine.
  Future<ManualDutyChangeResult> submitManualChange(
    String newStatus, {
    double? lat,
    double? lon,
    String? annotation,
  }) async {
    if (_journal != null && !_hydrated) {
      AppLogger.warning(
        'Refusing duty transition: ${DutyStampRefusal.notReady}',
      );
      return const ManualDutyChangeResult(refusal: DutyStampRefusal.notReady);
    }
    final refusal = _legalRefusal();
    if (refusal != null) {
      AppLogger.warning('Refusing duty transition: $refusal');
      return ManualDutyChangeResult(refusal: refusal);
    }
    final trusted = _getCurrentTime()!;
    final code = DutyStatusCode.fromAny(newStatus);
    if (code == DutyStatusCode.offDuty && newStatus != 'off_duty') {
      AppLogger.warning('Refusing to sync unmapped duty status: $newStatus');
      return const ManualDutyChangeResult(refusal: DutyStampRefusal.unmapped);
    }

    final driverIdInt = _readDriverId?.call();
    final driverId = (driverIdInt != null && driverIdInt > 0)
        ? DriverId(driverIdInt)
        : null;

    VehicleId? vehicleId;
    final savedVehicleId = _localStorage.selectedVehicleId;
    if (savedVehicleId != null && savedVehicleId.isNotEmpty) {
      final parsed = int.tryParse(savedVehicleId);
      if (parsed != null && parsed > 0) {
        vehicleId = VehicleId(parsed);
      }
    }

    final result = await _dashboardBackend.updateDutyStatus(
      status: code,
      notes: (annotation == null || annotation.isEmpty) ? null : annotation,
      driverId: driverId,
      vehicleId: vehicleId,
      // إحداثيات لحظة تأكيد التغيير تصل للطلب المباشر (المسار المحلي/الطابور
      // كان يحملها أصلاً — أونلاين كانت تُسقَط هنا قبل هذا التعديل).
      latitude: lat,
      longitude: lon,
    );
    return result.fold(
      (error) async {
        // إذا كان الفشل بسبب انقطاع الشبكة / أوفلاين، يجب الالتزام
        // بـ FMCSA § 395.24 وتطبيق الحالة محلياً وإدراجها في طابور المزامنة:
        final isNetwork =
            error is NetworkError ||
            error.code.contains('network') ||
            error.code.contains('connection') ||
            error.code.contains('timeout') ||
            error.code.contains('offline');

        if (isNetwork) {
          AppLogger.info(
            'Offline network state detected on duty change. Enqueuing event locally...',
          );
          final applied = await _applyManualLocal(
            newStatus: newStatus,
            timestamp: trusted,
            lat: lat,
            lon: lon,
            annotation: annotation,
            enqueue: true,
          );
          if (!applied) {
            return const ManualDutyChangeResult(
              refusal: DutyStampRefusal.storageUnavailable,
            );
          }
          return const ManualDutyChangeResult();
        }

        // الرفض الخادمي الفعلي (مثل خطأ تحقق 400/409) يظهر للسائق
        AppLogger.warning(
          'Duty status change rejected by server: ${error.code}',
        );
        return const ManualDutyChangeResult(
          refusal: DutyStampRefusal.serverRejected,
        );
      },
      (dashboard) async {
        final applied = await _applyManualLocal(
          newStatus: newStatus,
          timestamp: trusted,
          lat: lat,
          lon: lon,
          annotation: annotation,
          enqueue: false,
        );
        if (!applied) {
          return const ManualDutyChangeResult(
            refusal: DutyStampRefusal.storageUnavailable,
          );
        }
        // تمرير لقطة الخادم عند حملها لتغذية اللوحة فوراً — بلا GET ثانٍ.
        // قد تكون null (قبول بلا لقطة): الواجهة تتصالح مع الخادم بنفسها.
        return ManualDutyChangeResult(
          dashboard: dashboard,
          serverMessage: _dashboardBackend.lastServerMessage,
        );
      },
    );
  }

  Future<bool> _applyManualLocal({
    required String newStatus,
    required DateTime timestamp,
    double? lat,
    double? lon,
    String? annotation,
    required bool enqueue,
  }) async {
    if (_disposed) return false;
    if (_currentStatus == 'driving' && newStatus != 'driving') {
      AppLogger.warning(
        'Cannot manually transition from driving while moving.',
      );
    }

    _stationarySince = null;
    unawaited(
      _contain(
        () => _localStorage.setStationarySince(''),
        'Failed to clear stationary marker',
      ),
    );
    _wakeupTimer?.cancel();
    _movingSince = null;
    _consecutiveMovingEvents = 0;

    await _transitionTo(
      newStatus: newStatus,
      timestamp: timestamp,
      latitude: lat,
      longitude: lon,
      annotation: annotation,
      enqueue: enqueue,
    );

    if (_disposed) return false;
    final applied = _currentStatus == newStatus;
    if (applied && newStatus == 'driving') {
      _stationarySince = timestamp;
      await _localStorage.setStationarySince(
        _stationarySince!.toIso8601String(),
      );
      if (_disposed) return applied;
      await _evaluateStationaryState();
    }
    return applied;
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

    if (_lastEvent != null && now.isAfter(_lastEvent!.timestamp)) {
      final effectiveStart = _lastEvent!.timestamp.isBefore(todayStart)
          ? todayStart
          : _lastEvent!.timestamp;
      final currentHours = now.difference(effectiveStart).inMinutes / 60.0;
      switch (_currentStatus) {
        case 'driving':
          driving += currentHours;
          break;
        case 'on_duty':
          onDuty += currentHours;
          break;
        case 'off_duty':
          offDuty += currentHours;
          break;
        case 'sleeper_berth':
          sleeper += currentHours;
          break;
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
      return {'driving': 0, 'work': 0, 'rest': 0, 'distance': 0};
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

    if (_lastEvent != null && now.isAfter(_lastEvent!.timestamp)) {
      final effectiveStart = _lastEvent!.timestamp.isBefore(weekStart)
          ? weekStart
          : _lastEvent!.timestamp;
      final currentHours = now.difference(effectiveStart).inMinutes / 60.0;
      switch (_currentStatus) {
        case 'driving':
          driving += currentHours;
          work += currentHours;
          break;
        case 'on_duty':
          work += currentHours;
          break;
        case 'off_duty':
        case 'sleeper_berth':
          rest += currentHours;
          break;
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
    // Derived state only. The append-only journal is evidence and is never
    // cleared here.
    _resetDerivedState();
    _localStorage.setCurrentDutyStatus('off_duty');
    _stationarySince = null;
    _localStorage.setStationarySince('');
    _wakeupTimer?.cancel();

    _movingSince = null;
    _consecutiveMovingEvents = 0;
    _hydrated = _journal == null;
    _hydrationFailed = false;
    _hydratedOwnerId = null;
    _hydration = null;
    _journalCorrupted = false;
  }

  void dispose() {
    _disposed = true;
    _wakeupTimer?.cancel();
    _transitionController.close();
  }
}
