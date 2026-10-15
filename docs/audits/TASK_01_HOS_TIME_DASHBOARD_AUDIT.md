# TASK 01 — FORENSIC AUDIT: HOS TIME & STATUS DASHBOARD

**Audit type:** Evidence-gathering / verification only. **No production code was modified.**
**Repository:** `golden_feather_eld` (branch `temp-fixes`, HEAD `67134cc`)
**Date:** 2026-10-12
**Toolchain:** Flutter 3.47.2 / Dart 3.13.2 (stable), Windows x64

---

## IMPORTANT — AUDITED CODE STATE

At the time of this audit the working tree contained **uncommitted modifications to four
production HOS files** that were already present before the audit began and were not
authored by this audit:

```
lib/features/hos/domain/engine/hos_rules_engine.dart
lib/features/hos/domain/engine/hos_state_machine.dart
lib/features/hos/domain/engine/tracking/duty_status_tracker.dart
lib/features/hos/presentation/providers/change_status_provider.dart
```

`git diff --stat` → `4 files changed, 114 insertions(+), 17 deletions(-)`.

All findings below describe **this working-tree state**, not `HEAD`. Two of these diffs are
directly load-bearing for the findings:

* `hos_state_machine.dart` replaced an accumulating `Timer.periodic` counter
  (`_totalDrivingHours += 1/60`) with **derived** session arithmetic
  (`_accumulatedDrivingHours + (now - _drivingSessionStartTime)`), and added
  `_lastWeeklyRestartAt`.
* `hos_rules_engine.dart` added the `lastRestart` skip so the same rest interval cannot
  trigger repeated 34-hour restarts.

A read-only baseline check was performed by temporarily stashing those four files and
re-running the failing test; the failure reproduced identically with and without them, so
**the one failing test in the suite is pre-existing and independent of these changes.**
The stash was popped and the working tree verified byte-identical (same diffstat).

---

## SECTION 1 — Investigation Scope

### 1.1 Files inspected (production)

**Application entry & wiring**
| Path | Role |
|---|---|
| `lib/main.dart` | Entry point, `AppInitializer`, `ProviderContainer` |
| `lib/app.dart` | Router mount, `ref.listen` → `ref.invalidate(statusDashboardProvider)` |
| `lib/app/app_initializer.dart` | Startup sequence, DI container overrides |
| `lib/app/orchestrators/tracking_orchestrator.dart` | Telemetry, `AppEvent.logDataChanged` |
| `lib/routes.dart`, `lib/routes/home_routes.dart` | go_router route table |

**Home / navigation**
| Path | Role |
|---|---|
| `lib/features/home/presentation/pages/home_page.dart` | `IndexedStack` [StatusDashboardPage, RecapPage] |
| `lib/features/home/presentation/pages/` providers | `homeNavIndexProvider` |

**Time authorities**
| Path | Role |
|---|---|
| `lib/core/time/trusted_time_provider.dart` | `TrustedTimeProvider`, `MonotonicTrustedTimeProvider`, `FakeTrustedTimeProvider`, `trustedTimeProvider` |
| `lib/core/time/time_authority.dart` | `TimeAuthority` interface, `TrustLevel` |
| `lib/core/time/monotonic_time_authority.dart` | `MonotonicTimeAuthority` (device-anchored) |
| `lib/core/time/time_authority_provider.dart` | `timeAuthorityProvider` |
| `lib/backend/http/interceptors/time_drift_interceptor.dart` | Server `Date:` header → `anchor()` |
| `lib/core/services/utc_sync_service.dart` | `DateTime.now()`-based (documented as not usable for anchoring) |

**HOS engine**
| Path | Role |
|---|---|
| `lib/features/hos/domain/engine/hos_state_machine.dart` | Accumulator, transitions, weekly restart |
| `lib/features/hos/domain/engine/hos_rules_engine.dart` | Weekly-restart detection, alerts, violations |
| `lib/features/hos/domain/engine/hos_calculator.dart` | Drive / shift / cycle / break limits |
| `lib/core/config/hos_configuration.dart` | `usa70_8()`, `usa60_7()` |
| `lib/core/domain/entities/hos_models.dart` | `HosLimits`, `HosStatusUpdate`, `HosViolation`, `DutyPeriod` |
| `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart` | Legal duty stamps, ECM transitions, sync queue |

**Dashboard**
| Path | Role |
|---|---|
| `lib/features/hos/presentation/providers/status_dashboard_providers.dart` | `StatusDashboardNotifier`, snapshot timestamp provider |
| `lib/features/hos/presentation/providers/hos_provider.dart` | `hosStatusProvider` / `HosNotifier` |
| `lib/features/hos/presentation/providers/hos_engine_provider.dart` | Engine + tracker DI |
| `lib/features/hos/presentation/providers/change_status_provider.dart` | Duty change orchestration |
| `lib/features/hos/presentation/pages/status_dashboard_page.dart` | Dashboard page |
| `lib/features/hos/presentation/pages/change_status_page.dart` | Duty change page |
| `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart` | Countdown widget |
| `lib/features/hos/presentation/widgets/status_dashboard/circular_timer_logic.dart` | Pure countdown math |
| `lib/features/hos/presentation/widgets/status_dashboard/hos_indicators_card.dart` | HOS table |
| `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart` | Cache + offline fallbacks |
| `lib/features/hos/domain/usecases/get_status_dashboard_use_case.dart` | Use case |
| `lib/backend/adapters/eld_engine/mappers/status_dashboard_mapper.dart` | JSON → domain |
| `lib/backend/contracts/status_dashboard_backend.dart` | Backend contract |
| `lib/domain/duty_status/status_dashboard.dart` | Freezed domain models |

**Supporting**
| Path | Role |
|---|---|
| `lib/core/network/network_guard.dart` | `guardedNetwork` |
| `lib/core/network/network_info.dart` | Connectivity |
| `lib/core/events/app_events.dart` | `AppEventBus` |
| `lib/core/events/eld_events_provider.dart` | ELD event stream |
| `lib/features/sync/domain/usecases/sync_engine.dart` | Retry scheduling authority |
| `lib/features/logs/data/repositories/log_repository_impl.dart` | Period/audit persistence authority |
| `lib/core/services/local_storage_service.dart` | Prefs: `hos_configuration`, duty status, anchor |
| `lib/features/hos/data/repositories/hos_audit_repository_impl.dart` | Violation audit box |

### 1.2 Test files inspected

`test/features/hos/**` (6 files), `test/core/time/**` (5 files), `test/core/engine/tracking/duty_status_tracker_test.dart`,
`test/domain/duty_status/status_dashboard_test.dart`, `test/hos_calculator_test.dart`,
`test/backend/adapters/eld_engine/mappers/status_dashboard_mapper_test.dart`,
`test/features/hos/presentation/helpers/pump_page.dart`.

### 1.3 Files created by this audit

| Path | Purpose | Production impact |
|---|---|---|
| `test/audit_task01/hos_dashboard_forensic_test.dart` | 28 isolated regression tests (28/28 pass) | **None** |

Temporary probe files (`probe_existing_failure_test.dart`, `probe_clock_test.dart`,
`probe_host_test.dart`) were created and **deleted** during investigation.

---

## SECTION 2 — Architecture Reconstruction

### 2.1 The critical structural fact

**The displayed HOS numbers do NOT come from the local HOS engine.** They come from the
server. This single fact reframes most of the audit.

```
LEGAL DUTY STAMP PATH (local, trusted time)
  ELD/ECM event ──► DutyStatusTracker.processEldEvent
      └─► DutyStatusTracker._transitionTo
            ├─► _stampedDutyEvent(trustedUtc)      ← TrustedTimeProvider
            ├─► SyncEngine.submitEvent (offline queue)
            └─► onTransition stream ──► HosNotifier ──► _engine.manualTransition

LOCAL HOS ENGINE (trusted time)  — NOT the source of displayed values
  hosEngineProvider ──► HosRulesEngine ──► HosCalculator ──► HosStatusUpdate
      consumed ONLY by:
        • HosNotifier._processAndLogViolations  → HosAuditRepositoryImpl (Hive)
        • hosStatusProvider.update.currentStatus → tracking start/stop, Change Status initial option,
          Codriver role-switch guard, StatusDashboardNotifier refresh trigger

DISPLAYED DASHBOARD (server + wall clock)
  GET /eld/status ──► StatusDashboardMapper ──► StatusDashboardRepositoryImpl
      └─► GetStatusDashboardUseCase ──► StatusDashboardNotifier (statusDashboardProvider)
            ├─► statusDashboardSnapshotTimestampProvider  ← DateTime.now()  (device clock)
            └─► StatusDashboardPage ──► MainCircularTimer ──► CircularTimerLogic
```

`grep` for `remainingDriveMinutes|breakRequired|remainingShiftMinutes` across `lib/`
confirms **zero** consumers outside `hos_rules_engine.dart` / `hos_calculator.dart` /
`hos_models.dart`. The engine's computed limits never reach the screen.

### 2.2 Time authority topology — three clocks, not one

| Clock | Definition | Used by | Trust |
|---|---|---|---|
| **A. `TrustedTimeProvider`** | `MonotonicTrustedTimeProvider` — server `Date:` anchor + `Stopwatch` | `HosStateMachine`, `HosCalculator`, `HosRulesEngine`, `DutyStatusTracker`, `TimeDriftInterceptor`, DVIR | Server-anchored, monotonic in-session |
| **B. `TimeAuthority`** | `MonotonicTimeAuthority` — `DateTime.now().toUtc()` + `Stopwatch` | `LogRepositoryImpl`, `SyncEngine` (retry scheduling), edit-log, tracking | **Device-anchored**, `TrustLevel.localDevice` |
| **C. raw `DateTime.now()`** | none | `statusDashboardSnapshotTimestampProvider` (seed + all 3 writes), `MainCircularTimer._computeElapsed` | **Untracked, driver-manipulable** |

Clock **C** governs the one thing the driver actually reads: the remaining-time countdown.

### 2.3 Provider lifetimes

| Provider | Type | Lifetime |
|---|---|---|
| `trustedTimeProvider` | `Provider` | Container lifetime; anchored only by HTTP responses |
| `hosEngineProvider` | `Provider` | Container lifetime; **new `HosStateMachine` on restart** |
| `dutyStatusTrackerProvider` | `Provider` | Container lifetime; restores `currentDutyStatus` from prefs |
| `hosStatusProvider` | `StateNotifierProvider` | Non-autoDispose; invalidated on session epoch change |
| `statusDashboardProvider` | `AsyncNotifierProvider` | Non-autoDispose; survives navigation |
| `statusDashboardSnapshotTimestampProvider` | `StateProvider` | Non-autoDispose |
| `changeStatusProvider` | `StateNotifierProvider.autoDispose` | Page-scoped |

### 2.4 Navigation architecture

`HomePage` renders `IndexedStack(index: homeNavIndexProvider, children: [StatusDashboardPage, RecapPage])`.
`StatusDashboardPage` pushes `ChangeStatusPage` via `Navigator.push(MaterialPageRoute)` onto
the go_router root navigator. Both leave the dashboard **mounted**, not disposed.

---

## SECTION 3 — Execution Traces

### Trace 1 — Dashboard load (online)
```
HomePage.build → ref.watch(statusDashboardProvider)
  → StatusDashboardNotifier.build()                       [status_dashboard_providers.dart:63]
      ref.listen(hosStatusProvider)                       :67
      bus.stream.listen(logDataChanged → refresh())       :88
      auth gate → SessionMissingFailure if no user        :96
      → GetStatusDashboardUseCase.execute()
          → StatusDashboardRepositoryImpl.getDashboard()  [impl:26]  (in-flight de-dup :27-37)
              → guardedNetwork → _backend.getDashboard()
              → StatusDashboardMapper.fromDashboardJson()
      → snapshotTimestampProvider.state = DateTime.now()  :106
  → _DashboardView → MainCircularTimer(snapshotTimestamp: …)
```

### Trace 2 — Manual duty change (online)
```
ChangeStatusPage._handleSave → ChangeStatusNotifier.submit()  [change_status_provider:294]
  → HosNotifier.changeStatus()                                [hos_provider:85]
      → HosRulesEngine.validateManualTransition (speed guard only)
      → DutyStatusTracker.submitManualChange()               [tracker:353]
          → _legalRefusal()  (trusted time + driver session)  :193
          → _dashboardBackend.updateDutyStatus()  POST /eld/status/duty-status
          ├─ success → _applyManualLocal(enqueue:false) + ManualDutyChangeResult(dashboard)
          └─ network error → _applyManualLocal(enqueue:true)  [offline path]
  → applyServerDashboard(merged)                              [change_status_provider:371]
      snapshotTimestamp = DateTime.now()
```

### Trace 3 — Automatic driving (ECM only)
```
eldEventsStreamProvider → dutyStatusTrackerProvider ref.listen  [hos_engine_provider:58]
  → DutyStatusTracker.processEldEvent  (drops non-ECM: `if (!eldEvent.fromEcm) return`)  [tracker:105]
      >5mph ×3 events ≥3s → _transitionTo('driving', timestamp: _movingSince)
      stationary ≥5 min     → _transitionTo('on_duty')
  → onTransition → HosNotifier → _engine.manualTransition + refresh()
  → hosStatusProvider change → StatusDashboardNotifier listener → refresh()
```

### Trace 4 — Trusted time anchoring
```
Any HTTP response/error with a Date header → TimeDriftInterceptor.onResponse/onError
  → throttle (drift < 30s AND < 5min → skip)  [time_drift_interceptor:52-59]
  → timeProvider.anchor(serverUtc)
      → _trustedServerUtcAtSync = serverUtc; Stopwatch.reset()+start()
      → persist {anchorUtc, deviceWallMs: DateTime.now()}
```

### Trace 5 — Countdown tick
```
Timer.periodic(1s) [main_circular_timer.dart:94]  (only when _isActiveDuty)
  → _computeElapsed()
      if (widget.snapshotTimestamp != null)
        DateTime.now().difference(snapshotTimestamp)     ← DEVICE WALL CLOCK
      else
        _stopwatch.elapsed                                ← unreachable in production
  → CircularTimerLogic.calculateUiState(liveRemaining = baseRemaining - elapsed)
  → DurationFormat.hhMm(liveRemaining, signed: true)
```

---

## SECTION 4 — Verified Findings

---

### Finding F-01

**Title:** Dashboard remaining-time countdown is driven by the driver-manipulable device wall clock

**Classification:** CONFIRMED DEFECT
**Severity:** HIGH
**Affected Files:**
- `lib/features/hos/presentation/providers/status_dashboard_providers.dart:59, 106, 120, 146`
- `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:45-51`

**Methods:**
- `statusDashboardSnapshotTimestampProvider` (`:58-59`)
- `StatusDashboardNotifier.build` (`:106`), `applyServerDashboard` (`:120`), `refresh` (`:146`)
- `_MainCircularTimerState._computeElapsed` (`:45-51`)

**Exact Code Evidence:**
```dart
// status_dashboard_providers.dart:58-59
final statusDashboardSnapshotTimestampProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

// status_dashboard_providers.dart:146-147  (refresh)
ref.read(statusDashboardSnapshotTimestampProvider.notifier).state =
    DateTime.now();
```
```dart
// main_circular_timer.dart:45-51
Duration _computeElapsed() {
  if (widget.snapshotTimestamp != null) {
    final diff = DateTime.now().difference(widget.snapshotTimestamp!);
    return diff.isNegative ? Duration.zero : diff;
  }
  return _stopwatch.elapsed;
}
```
`snapshotTimestamp` is non-nullable in the provider and is always passed by
`status_dashboard_page.dart:61`, so the `Stopwatch` branch is unreachable in production.

**Execution Path:**
`GET /eld/status` → `StatusDashboardNotifier.build` → `snapshotTimestamp = DateTime.now()` →
`_DashboardView` → `MainCircularTimer(snapshotTimestamp: …)` → `_computeElapsed()` →
`DateTime.now().difference(...)` → `liveRemaining = baseRemaining − elapsed` → rendered `HH:MM`.

**Trigger Conditions:** Any active-duty screen display. No special condition; this is the default path.

**Expected Behavior:** The elapsed term driving the driver-facing legal countdown should come
from the same trusted authority that stamps duty records (Appendix A §4.3.1.5(a): *"The ELD
must obtain and record the date and time information automatically without allowing any
external input or interference from a motor carrier, driver, or any other person."*),
or from a monotonic clock.

**Established Actual Behavior:** Both ends of the subtraction use the device wall clock.
Two demonstrated consequences:

1. **Clock moved backwards** → `DateTime.now() < snapshotTimestamp` → delta is negative →
   clamped to `Duration.zero` → the countdown **freezes at the full server value forever**.
   Test: `BACKWARD_CLOCK_TEXTS=[Remaining, 05:00, DRIVING]` after `pump(3s)`.
2. **Clock moved forward** → the countdown decrements by the jump instantly.

Test evidence: `WALLCLOCK_ELAPSED_TEXTS=[Remaining, 04:29, DRIVING]` — a 5:00 server value
against a 30-minute-old snapshot renders 04:29, proving arithmetic on `DateTime.now()` delta
rather than a monotonic stopwatch (a stopwatch started at mount would have rendered ~05:00).

**Root Cause:** Two competing time abstractions exist (F-06); the display path bypassed both
and called `DateTime.now()` directly.

**Test Evidence:** REPRODUCED — 2 dedicated tests in `test/audit_task01/hos_dashboard_forensic_test.dart`
(`displayed remaining is computed from WALL CLOCK delta, not a stopwatch`;
`device clock jump BACKWARD freezes the countdown at the full server value`).

**Missing Evidence:** No device-clock manipulation can be performed inside the Dart VM, so the
OS-clock jump itself is simulated by supplying a future/past snapshot instant — which is
exactly the value the production code stores. The arithmetic is directly asserted.

**Confidence:** HIGH — deterministic arithmetic on observed values, two independent tests.

**Recommended Remediation:** Derive `elapsedSinceSnapshot` from `TrustedTimeProvider`
(anchor + monotonic elapsed) instead of `DateTime.now()`. Remove the `Stopwatch`
fallback so a single authority governs.

---

### Finding F-02

**Title:** Offline with no warm cache displays fabricated full legal limits as the driver's HOS

**Classification:** REPRODUCED DEFECT
**Severity:** HIGH
**Affected File:** `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart:54-58, 61-106`

**Methods:** `getDashboard` → `_fetchDashboard` → `offline:` → `_defaultOfflineDashboard`

**Exact Code Evidence:**
```dart
// status_dashboard_repository_impl.dart:54-58
}, offline: () async {
  final dashboard = _cachedDashboard ?? _defaultOfflineDashboard(driverId);
  _cachedDashboard = dashboard;
  return Right(dashboard);
});

// :61-77 (excerpt)
static StatusDashboard _defaultOfflineDashboard(DriverId? driverId) {
  return StatusDashboard(
    ...
    currentDutyStatus: DutyStatusCode.offDuty,
    remainingCircle: const RemainingCircle(remaining: Duration.zero, ...),
    hosIndicators: const HosIndicators(
      drive: HosIndicator(label:'DRIVE', value: Duration(hours: 11), type: IndicatorType.remaining),
      shift: …Duration(hours: 14)…, breakTime: …Duration(hours: 8)…,
      cycle: …Duration(hours: 70)…),
```

**Execution Path:** App launch offline → `statusDashboardProvider` build → use case →
repository `_fetchDashboard` → `guardedNetwork` sees `isConnected == false` → `offline()`
→ no cache (in-memory only, lost on restart) → `_defaultOfflineDashboard`.

**Trigger Conditions:** First `getDashboard` while offline with an empty in-memory cache —
i.e. any cold start offline, which the repository's own doc comment at `:16-17` explicitly
cites §395.24 as the reason this cache exists.

**Expected Behavior:** Either (a) an explicit "no data" state, or (b) cached values
persisted across restarts. Fabricating *maximum* legal allowances is the least safe option.

**Established Actual Behavior:**
```
OFFLINE_NO_CACHE_STATUS=DutyStatusCode.offDuty
OFFLINE_NO_CACHE_DRIVE=11:00:00.000000
OFFLINE_NO_CACHE_SHIFT=14:00:00.000000
OFFLINE_NO_CACHE_BREAK=8:00:00.000000
OFFLINE_NO_CACHE_CYCLE=70:00:00.000000
```
The dashboard renders a complete, fully-conforming HOS table for a driver whose actual
remaining time is unknown. A driver who had used 10 of 11 driving hours sees `DRIVE 11:00`.

**Root Cause:** In-memory-only cache (F-05) combined with a fabricated-default fallback.

**Test Evidence:** REPRODUCED — `offline with NO cache: dashboard shows fabricated FULL legal limits`.

**Missing Evidence:** None for the client behaviour. Server-side behaviour was not exercised.

**Confidence:** HIGH.

**Recommended Remediation:** Persist the last successful dashboard to disk (it already
persists elsewhere via Hive/prefs) and, on cold start with no cache, render an explicit
unavailable state rather than full limits.

---

### Finding F-03

**Title:** A stale in-flight GET overwrites a newer `applyServerDashboard` snapshot

**Classification:** REPRODUCED DEFECT
**Severity:** MEDIUM
**Affected File:** `lib/features/hos/presentation/providers/status_dashboard_providers.dart:119-123, 126-151`

**Methods:** `applyServerDashboard`, `refresh`

**Exact Code Evidence:**
```dart
// status_dashboard_providers.dart:119-123
void applyServerDashboard(StatusDashboard dashboard) {
  ref.read(statusDashboardSnapshotTimestampProvider.notifier).state = DateTime.now();
  state = AsyncValue.data(dashboard);
}

// :145-149 — no request generation / sequence check
(dashboard) {
  ref.read(statusDashboardSnapshotTimestampProvider.notifier).state = DateTime.now();
  state = AsyncValue.data(dashboard);
},
```

**Execution Path:** `refresh()` starts a GET → meanwhile `ChangeStatusNotifier.submit`
completes `submitManualChange` and calls `applyServerDashboard(fresh)` → the older GET
resolves last → `refresh`'s completion handler overwrites `state` with the older payload
**and** re-stamps `snapshotTimestamp`, re-basing the countdown onto stale data.

**Trigger Conditions:** Any dashboard GET in flight when a duty-status change is accepted.
`refresh()` is triggered by the `hosStatusProvider` listener (`:82`) and by
`AppEvent.logDataChanged` (`:89`), both of which fire on essentially every ECM transition
and telemetry-driven driving transition.

**Expected Behavior:** Last-*initiated* request wins, or responses are discarded when a
newer snapshot has already been applied.

**Established Actual Behavior:**
```
AFTER_APPLY_SERVER_DASHBOARD=5:00:00.000000     ← fresh POST snapshot applied
AFTER_STALE_GET_COMPLETES=1:00:00.000000        ← older in-flight GET clobbers it
```

**Root Cause:** No request-sequencing token in `StatusDashboardNotifier`. The repository's
`_inFlightDashboard` de-dup (`status_dashboard_repository_impl.dart:21-37`) de-duplicates
concurrent GETs but does **not** coordinate GET against `applyServerDashboard`, which
bypasses the repository entirely.

**Test Evidence:** REPRODUCED — `a stale in-flight GET overwrites a NEWER applyServerDashboard result`.

**Missing Evidence:** Whether the server would have returned newer data for the same GET in
production (server not exercised). The client-side ordering defect is independent of that.

**Confidence:** HIGH for the ordering defect; MEDIUM for the real-world magnitude.

**Recommended Remediation:** Add a monotonically increasing request id to `refresh()`;
discard responses whose id is lower than the last applied id.

---

### Finding F-04

**Title:** Local HOS engine counters are memory-only; app restart resets accumulated driving to zero

**Classification:** CONFIRMED DEFECT (scope-limited — see Missing Evidence)
**Severity:** MEDIUM
**Affected Files:**
- `lib/features/hos/domain/engine/hos_state_machine.dart:9-23, 37-57`
- `lib/features/hos/presentation/providers/hos_engine_provider.dart:24-39`

**Methods:** `HosStateMachine` constructor, `totalDrivingHours`, `cycleHours`, `applyWeeklyRestart`, `reset`

**Exact Code Evidence:**
```dart
// hos_state_machine.dart:9-14  — no persistence, no hydration parameter
DutyStatus _currentStatus = DutyStatus.offDuty;
DateTime _shiftStartTime = DateTime.utc(1970);
double _accumulatedDrivingHours = 0.0;
double _accumulatedCycleHours = 0.0;
DateTime? _drivingSessionStartTime;
DateTime? _lastWeeklyRestartAt;
```
`grep` for `restore|replay|hydrate|seed` across `lib/` returns **no** HOS-state
reconstruction path. `hosEngineProvider` builds a fresh `HosStateMachine` per container.

**Execution Path:** Any process restart → new `ProviderContainer` → `hosEngineProvider`
builds `HosStateMachine(timeProvider)` → counters at zero → `HosStatusUpdate` reports a full
11-hour driving allowance.

**Trigger Conditions:** OS kills the app, user force-quits, or device reboot, at any point
during a shift.

**Expected Behavior:** Either local counters are reconstructed, or the engine is explicitly
documented/treated as non-authoritative (which the architecture *is*, for display).

**Established Actual Behavior:**
```
SESSION1_REMAINING_DRIVE_MIN=300    ← 6h driving consumed, 300 min remain
SESSION2_REMAINING_DRIVE_MIN=660    ← after restart: full 660 min again
```
Consumers of the corrupted local value are: `HosAuditRepositoryImpl.logViolation`
(violation detection becomes blind after restart) and the `hosStatusProvider` state used by
`tracking_orchestrator.isDrivingChecker`, `ChangeStatusNotifier` initial option, and the
Codriver role-switch guard.

**Root Cause:** Intentional division of labour (server owns display) was not accompanied by
a documented statement that local counters are advisory-only.

**Test Evidence:** REPRODUCED — `a new engine (app restart) starts from zero with no history replay`.

**Missing Evidence:** Whether the server is authoritative for restart recovery could not be
tested (no server access). If the server fully re-derives HOS, the practical impact is
limited to local violation detection and UI gating — not to displayed values.

**Confidence:** HIGH that the reset occurs; MEDIUM on downstream severity.

**Recommended Remediation:** Either hydrate the engine from the server dashboard on attach,
or add an explicit `isAdvisory` contract + suppress local violation logging when the engine
has no history.

---

### Finding F-05

**Title:** Dashboard cache is in-memory only despite an explicit persistence-compliance rationale

**Classification:** CONFIRMED DEFECT
**Severity:** MEDIUM
**Affected File:** `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart:16-19, 18, 55-57, 136-142`

**Methods:** field declaration `StatusDashboard? _cachedDashboard`; `_fetchDashboard`; `updateDutyStatus`

**Exact Code Evidence:**
```dart
// :16-19
/// Cache last known status dashboard to comply with FMCSA 49 CFR § 395.24
/// (display remaining HOS and status continuously even when offline).
StatusDashboard? _cachedDashboard;
```
A plain in-memory Dart field. It is not written to prefs or Hive anywhere.

**Execution Path:** Process termination → new repository instance → `_cachedDashboard == null`
→ offline branch fabricates defaults (F-02).

**Trigger Conditions:** Any process restart, period.

**Expected Behavior:** The comment claims continuity "even when offline"; an in-memory field
provides continuity only within a single process lifetime.

**Established Actual Behavior:** Cold start offline yields the fabricated dashboard, not the
last known one. The comment's stated intent is not met by the implementation.

**Root Cause:** Comment and implementation diverge; the persistence layer was never added.

**Test Evidence:** Reproduced via F-02's test — the repository produced defaults, proving no
cross-restart cache exists.

**Missing Evidence:** None.

**Confidence:** HIGH.

**Recommended Remediation:** Persist the last successful `StatusDashboard` to the existing
Hive box or prefs and rehydrate on construction.

---

### Finding F-06

**Title:** Three independent time authorities govern HOS-adjacent values

**Classification:** CONFIRMED DEFECT (design-level inconsistency; see Missing Evidence)
**Severity:** MEDIUM
**Affected Files:**
- `lib/core/time/trusted_time_provider.dart` (authority A)
- `lib/core/time/monotonic_time_authority.dart` (authority B)
- `lib/features/hos/presentation/providers/status_dashboard_providers.dart:59` (authority C)

**Methods:** `MonotonicTrustedTimeProvider`, `MonotonicTimeAuthority.initialize`, raw `DateTime.now()`

**Exact Code Evidence:**
```dart
// monotonic_time_authority.dart:22-28
Future<void> initialize() async {
  if (_anchorUtc != null) return;
  _anchorUtc = DateTime.now().toUtc();     // device clock
  _stopwatch..reset()..start();
}
```
```
AUTH_TRUSTED=2026-03-01 08:00:00.000Z
AUTH_TIMEAUTHORITY_TRUST=TrustLevel.localDevice
AUTH_TIMEAUTHORITY_NOW=2026-10-12 …
AUTH_RAW_WALL=2026-10-12 …
```

**Execution Path:** `logRepositoryProvider` (`log_repository_providers.dart:22`) and
`sync_providers.dart:108` inject `timeAuthorityProvider`; `hosEngineProvider`
(`hos_engine_provider.dart:26, 47`) injects `trustedTimeProvider`. The dashboard uses neither.

**Trigger Conditions:** Always.

**Expected Behavior:** One authority for legal/EL D timestamps; `time_authority.dart:4-13`
itself argues the device clock "is trivially manipulable".

**Established Actual Behavior:** `TimeAuthority` is device-anchored and is used by
`SyncEngine.calculateNextRetry(nowUtc:)` (`sync_engine.dart:201`) and by
`LogRepositoryImpl` `createdAt` metadata (`:202, 262, 404, 493, 561`).
`PendingEvent.createdAt` for duty events is stamped from trusted time
(`duty_status_tracker.dart:215, 233`), so the **legal** stamps are correct.

**Root Cause:** Incremental addition of a second abstraction without retiring the first.

**Test Evidence:** `three distinct clocks govern HOS-related values` + `TimeAuthority is
device-anchored and moves with the wall clock`.

**Missing Evidence:** No demonstrated *mathematical* HOS error attributable to authority B
alone — retry scheduling and record metadata, not legal stamps. Severity is driven by
consistency and future-risk, not a proven numeric failure.

**Confidence:** HIGH for the topology; MEDIUM for severity.

**Recommended Remediation:** Collapse to `TrustedTimeProvider` and delete
`timeAuthorityProvider`, or rename authority B to `DeviceLocalTimeProvider` so its
non-legal role is explicit at every call site.

---

### Finding F-07

**Title:** `breakRequired` latches true and never clears after a qualifying 30-minute break

**Classification:** CONFIRMED DEFECT
**Severity:** MEDIUM
**Affected Files:**
- `lib/features/hos/domain/engine/hos_calculator.dart:65-67`
- `lib/features/hos/domain/engine/hos_rules_engine.dart:136-143`

**Methods:** `HosCalculator.calculateAllLimits`, `_generateAlerts`

**Exact Code Evidence:**
```dart
// hos_calculator.dart:64-67
// 4. الاستراحة الإلزامية (30 دقيقة بعد 8 ساعات) - Needs nothing
final breakRequired = drivenMinutes >= config.driveBeforeBreakMinutes;
final breakRemainingMinutes = breakRequired ? config.breakDurationMinutes : 0;
```

**Execution Path:** `drivingHours` from `HosStateMachine.totalDrivingHours` (which only ever
increments between weekly restarts) → `drivenMinutes >= 480` → `breakRequired = true`
→ `HosAlert(breakRequired)`. Nothing in the engine inspects duty status to clear it.

**Trigger Conditions:** Driver accumulates 8 cumulative driving hours in the engine.

**Expected Behavior:** 49 CFR 395.3(a)(3)(ii) counts driving *since the last* qualifying
30-minute interruption; a qualifying break should reset the counter.

**Established Actual Behavior:**
```
BREAK_BEFORE=true    ← after 9h driving
BREAK_AFTER=true     ← after 45 min off duty + return to driving
```

**Root Cause:** The driving accumulator has no per-break reset, so the flag is a threshold on
lifetime-since-weekly-restart driving rather than driving-since-last-break.

**Test Evidence:** REPRODUCED — `breakRequired latches true and never clears after a qualifying break`.

**Missing Evidence:** Whether the break currently gates anything user-visible. It feeds only
`HosAlert`/`HosViolation` (audit log). No blocking behaviour was found, so no unsafe
operation was demonstrated. Displayed break time comes from the server.

**Confidence:** HIGH for the computation; the practical impact is currently limited to a
persistent false audit alert.

**Recommended Remediation:** Track the timestamp of the last ≥30-minute non-driving period and
compute `breakRequired` from driving accumulated since then.

---

### Finding F-08

**Title:** `applyWeeklyRestart` clears the 11-hour driving accumulator, not only the 60/70-hour cycle

**Classification:** POTENTIAL DEFECT
**Severity:** LOW
**Affected File:** `lib/features/hos/domain/engine/hos_state_machine.dart:126-135`

**Methods:** `HosStateMachine.applyWeeklyRestart`

**Exact Code Evidence:**
```dart
void applyWeeklyRestart() {
  _accumulatedCycleHours = 0.0;
  _accumulatedDrivingHours = 0.0;   // ← also clears the 11-hour limit
  final now = _trustedNow() ?? DateTime.utc(1970);
  _shiftStartTime = now;
  _lastWeeklyRestartAt = now;
  if (_currentStatus == DutyStatus.driving) { _drivingSessionStartTime = now; }
}
```

**Execution Path:** `_checkAndApplyWeeklyRestart` → `hasWeeklyRestart(periods)` → `applyWeeklyRestart()`.

**Trigger Conditions:** ≥34 consecutive off-duty/sleeper hours detected by the engine.

**Expected Behavior:** 49 CFR 395.3(c) provides that a 34-hour rest ends the 7/8-day period,
resetting the 60/70-hour limit in 395.3(b).

**Established Actual Behavior:**
```
BEFORE_RESTART_DRIVE=300 CYCLE=64.0
AFTER_RESTART_DRIVE=660 CYCLE=70.0
```
The 11-hour driving accumulator is also reset.

**Why this is only POTENTIAL:** Under 395.3(a)(1) a driver may not drive without first taking
10 consecutive hours off duty. A driver who has genuinely been off duty for 34 hours has
already satisfied that, so clearing the driving accumulator is *arguably* conformant here.
The defect would be real only if `hasWeeklyRestart` could be satisfied by a period during
which the driver was not actually off duty.

**Missing Evidence:** Whether `_checkAndApplyWeeklyRestart`'s period reconstruction can produce
a false ≥34h period. Its inputs are `_stateMachine.transitions` only, so periods are built
from actual off-duty transitions — I found no path to a false period. Severity therefore
stays LOW and classification stays POTENTIAL.

**Test Evidence:** Observed (`34h off-duty weekly restart wipes the 11-hour DRIVING accumulator too`).

**Confidence:** LOW–MEDIUM. Depends on an unproven false-positive path.

**Recommended Remediation:** Make the intent explicit — either document that clearing driving
is intentional because a 34-hour rest implies a new work shift, or restrict the reset to the
cycle counter.

---

### Finding F-09

**Title:** Restored trusted-time anchor measures the offline gap with the device clock

**Classification:** CONFIRMED DEFECT (declared design tradeoff — see INTENDED BEHAVIOR note)
**Severity:** MEDIUM
**Affected File:** `lib/core/time/trusted_time_provider.dart:62-85, 88-104`

**Methods:** `MonotonicTrustedTimeProvider._restore`, `state`

**Exact Code Evidence:**
```dart
// :78-80
_trustedServerUtcAtSync = anchorUtc.add(
  DateTime.now().difference(restoredDeviceWall),   // ← manipulable device clock
);

// :91-97
if (_restoredFromDisk && _restoredDeviceWallMs != null) {
  if (DateTime.now().difference(_restoredDeviceWallMs!) >=
      const Duration(days: 7)) {
    return TrustedTimeState.stale;
  }
  return TrustedTimeState.trusted;
}
```

**Execution Path:** `trustedTimeProvider` construct → `_restore()` reads prefs
`trusted_time_anchor` → re-bases using `DateTime.now()`.

**Trigger Conditions:** Any offline restart that has a persisted anchor.

**Expected Behavior:** Trusted time should not become a function of a clock the driver controls.

**Established Actual Behavior:**
```
RESTORED_STATE=TrustedTimeState.trusted
RESTORED_DRIFT_VS_SERVER=48:00:00.004413     ← a 2-day gap reproduces exactly from device time
```
And the staleness gate itself reads the device clock on every call:
`BACKDATED_STATE=TrustedTimeState.stale`, `currentTime = TrustedTimeUnavailable`.
A driver who winds the device clock ≥7 days can force `TrustedTimeState.stale`, which makes
`HosRulesEngine` return `HosEngineTimeUnavailable` and `HosStateMachine.transitionTo` refuse
all duty transitions (`hos_state_machine.dart:64-69`).

**Root Cause:** A single persisted pair (`anchorUtc`, `deviceWallMs`) cannot distinguish
"device clock correct" from "device clock moved".

**Test Evidence:** REPRODUCED — `restored anchor advances by the DEVICE-CLOCK delta across
shutdown`; `trusted time becomes UNAVAILABLE when the device clock is >=7d ahead`.

**Missing Evidence:** Whether a server anchor always follows within the window (throttled to
≥5 min / >30 s drift) so the stale state is transient in practice.

**Confidence:** HIGH for the mechanism.

**INTENDED BEHAVIOR note:** The class doc comment (`trusted_time_provider.dart:38-43`)
**explicitly declares** this as an accepted owner decision dated 2026-10-03, including the
security caveat. This finding records the residual risk of that decision, not an
unintended bug.

**Recommended Remediation:** Persist a monotonic-monotonic anchor pair (e.g. store the
`Stopwatch` reading plus `elapsedRealtime` from an unmanipulable platform clock) or shorten
the offline trust window and surface a "time unverified" state to the driver.

---

### Finding F-10

**Title:** Offline duty-status change fabricates `RemainingCircle` values from hard-coded constants

**Classification:** CONFIRMED DEFECT
**Severity:** MEDIUM
**Affected File:** `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart:135-172`

**Methods:** `updateDutyStatus` `offline:` branch, `_circleForStatus`

**Exact Code Evidence:**
```dart
// :156-163
if (status == DutyStatusCode.driving) {
  const remaining = Duration(minutes: 35);
  const total = Duration(hours: 11);
  return RemainingCircle(remaining: remaining, ...);
}
// :165-172
const remaining = Duration(hours: 2, minutes: 8);
```

**Execution Path:** `DutyStatusTracker.submitManualChange` network error →
`_applyManualLocal` … and independently, repository `updateDutyStatus` offline branch →
`_cachedDashboard.copyWith(remainingCircle: _circleForStatus(status))`.

**Trigger Conditions:** Driver changes duty status while offline.

**Expected Behavior:** The circle should be marked unavailable/unknown rather than populated
with a constant unrelated to the driver's actual accounting.

**Established Actual Behavior:**
```
OFFLINE_DUTY_CHANGE_CIRCLE=0:35:00.000000  STATUS=DutyStatusCode.driving  DRIVE_INDICATOR=11:00:00.000000
```
A driver with 10 hours 55 minutes used is shown a circle of 00:35 after going DRIVING.

**Root Cause:** Same root as F-02 — constants substituted for unknown server state.

**Test Evidence:** REPRODUCED — `offline duty change fabricates a RemainingCircle from constants`.

**Missing Evidence:** None for the repository path. The `DutyStatusTracker` offline path was
not separately instrumented (it delegates to the same repository method).

**Confidence:** HIGH.

**Recommended Remediation:** Return an explicit "unknown" marker and let
`CircularTimerLogic` render an unavailable state instead of a numeric value.

---

### Finding F-11

**Title:** `remainingCircle.remaining` and `hosIndicators` disagree on disk; the indicators win

**Classification:** INTENDED BEHAVIOR (documented design, verified)
**Severity:** LOW (documentation clarity only)
**Affected Files:**
- `lib/features/hos/presentation/widgets/status_dashboard/circular_timer_logic.dart:44-51, 70-101`
- `lib/features/hos/presentation/widgets/status_dashboard/hos_indicators_card.dart:107-149`

**Methods:** `CircularTimerLogic._remainingOf`, `calculateUiState`; `HosIndicatorsCard._IndicatorRow`

**Exact Code Evidence:**
```dart
// circular_timer_logic.dart:44-51
static Duration _remainingOf(HosIndicator? ind, Duration limit, Duration fallback) {
  if (ind == null) return fallback;
  if (ind.type == IndicatorType.used) return limit - ind.value;
  return ind.value;
}
```
`hosIndicators` takes precedence over `circle.remaining` in every branch
(`:72-76` driving, `:89-93` break, `:96-100` shift). The card renders
`hosIndicators` verbatim.

**Established Actual Behavior:** The circle and the HOS table are both derived from
`hosIndicators`; `remainingCircle.remaining` is only a fallback when
`hosIndicators` is absent. This is coherent, not contradictory — but the two domain fields
carrying overlapping data with no stated precedence rule is a maintenance hazard.

**Test Evidence:** Verified in `offline with NO cache` (both agree) and in the scripted-backend
tests (circle and drive indicator carry identical values).

**Confidence:** HIGH.

**Recommended Remediation:** Document the precedence rule at the domain level or remove
`RemainingCircle.remaining` from the wire contract.

---

## SECTION 5 — Disproved Previous Claims

### C-01 — "Navigating away and back resets the dashboard timer"

**Claim source:** previous audit hypothesis (Stopwatch reset on widget reconstruction).

**DISPROVEN.** `HomePage` uses `IndexedStack` (`home_page.dart:200-204`), which keeps all
children mounted. Test `IndexedStack keeps the SAME MainCircularTimer State mounted (no dispose)`
asserts `identical(stateBefore, stateAfter) == true` across a tab switch — `initState` and
`dispose` do not run. The countdown continued correctly (`07:54` → `07:34`).

### C-02 — "Route replacement destroys and rebuilds the timer, losing time"

**DISPROVEN.** Test `full route replacement re-runs initState but preserves the countdown`
confirms a new `State` is created (`NAV_ROUTE_STATE_CHANGED=true`) **but** the rendered value
is still `07:34`, because `initState` re-derives elapsed from the persisted
`snapshotTimestamp`, not from widget-local state. Time is preserved.

### C-03 — "`didUpdateWidget` resets the stopwatch on `circle.remaining` change, causing a jump"

**DISPROVEN in production; the code path exists but is unreachable.**
The pattern named in the task brief is *not* present in that form. The actual code is
`main_circular_timer.dart:64-77`:

```dart
if (oldWidget.snapshotTimestamp != widget.snapshotTimestamp ||
    oldWidget.dutyStatus != widget.dutyStatus) { … _elapsedNotifier.value = _computeElapsed(); }
else if (widget.snapshotTimestamp == null &&
    (oldWidget.circle.remaining != widget.circle.remaining ||
        oldWidget.hosIndicators != widget.hosIndicators)) {
  _stopwatch.reset(); _stopwatch.start(); _elapsedNotifier.value = Duration.zero; …
}
```

The second branch is gated on `snapshotTimestamp == null`, which never holds on the
production path (`status_dashboard_page.dart:61` always passes the non-nullable provider
value). Test evidence:

* Production path — `D3_BEFORE=[Remaining, 01:50, DRIVING]`, `D3_AFTER=[Remaining, 08:50, DRIVING]`.
  Changing `circle.remaining` 2h→9h produced 08:50, not 09:00: the wall-clock offset was
  retained, proving the branch did not fire.
* Test-only path (no snapshot) — `D3_NOSNAP_MID=[…, 01:59, …]` → `D3_NOSNAP_AFTER=[…, 09:00, …]`.
  The branch **does** grant back elapsed time, confirming the mechanism exists but is
  test-only.

**Residual risk:** the branch is live dead-code. Any future caller that passes
`snapshotTimestamp: null` re-introduces a legal-time-granting jump. Recommend deleting it.

### C-04 — "Delayed `Timer.periodic` callbacks corrupt driving-time accounting"

**DISPROVEN.** The working-tree implementation *fixed* this. `hos_state_machine.dart:109-114`:
```dart
void _startDrivingTimer() {
  _drivingTimer?.cancel();
  _drivingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
    // Timer acts as a periodic heartbeat for external readers
  });
}
```
Driving time is **derived** from `now.difference(_drivingSessionStartTime)` (`:37-46`), not
accumulated per tick. A late or coalesced callback cannot add or lose accounting time.
`git diff` confirms the previous implementation *did* do `_totalDrivingHours += 1/60`, which
would have been vulnerable — but that version is not the audited state.

The dashboard's 1-second ticker is also immune: `_computeElapsed()` recomputes the wall-clock
delta on each tick rather than adding one second, so a delayed tick yields the correct
value, not an accumulated one.

### C-05 — "An unanchored cold start seeds the shift window at the Unix epoch, producing a false 14-hour violation"

**HYPOTHESIS RAISED, THEN DISPROVEN BY TEST.** `HosStateMachine._shiftStartTime` does default
to `DateTime.utc(1970)` when trusted time is unavailable (`hos_state_machine.dart:20-23`), and
I predicted a permanent `dailyWorkExceeded` violation. The test disproved it:

```
UNANCHORED_SHIFT_START=1970-01-01T00:00:00.000Z
LATE_ANCHOR_SHIFT_REMAINING_MIN=840 VIOLATIONS=[] SHIFT_START=2026-03-01T08:00:00.000Z
```

Root cause of the self-heal: `_checkAndApplyWeeklyRestart` (`hos_rules_engine.dart:53-57`)
sees `offDuty` + empty transitions, sets `offDutyStart = shiftStartTime` (1970), producing a
56-year "rest period" that qualifies for the 34-hour restart, which re-bases
`_shiftStartTime` onto the current trusted time. The full 840 minutes remain and no false
violation is raised. **No defect.**

### C-06 — "A 34-hour rest interval can trigger repeated resets"

**DISPROVEN.** The working-tree `lastRestart` guard (`hos_rules_engine.dart:51, 60-62`)
skips transitions at or before `_lastWeeklyRestartAt`, and `applyWeeklyRestart` advances that
marker. Test `same qualifying off-duty interval cannot restart twice (idempotent)` confirms
a second evaluation produces an identical `remainingDriveMinutes`.

### C-07 — "`49 CFR § 395.24` requires displaying remaining HOS continuously while offline"

**REGULATORY CLAIM DISPROVEN.** Verified against eCFR. §395.24 is titled *"Driver
responsibilities—In general"* and its full text covers (a) providing information the ELD
requires, (b) selecting duty status, (c) miscellaneous data entry, and (d) producing and
transferring records. The words **"display"** and **"offline"** do not appear.

This makes the comment at `status_dashboard_repository_impl.dart:16-17` an **inaccurate
regulatory citation**. The cache that the comment justifies is also not persisted (F-05),
so it does not achieve the stated goal regardless.

### C-08 — "`FMCSA §4.3.2.2` requires ELD time to be non-manipulable"

**CITATION MISATTRIBUTED.** Verified against Appendix A to Subpart B of Part 395:
§4.3.2.2 is *"Driver's Status Inputs"* (4.3.2.2.1 duty status categories, 4.3.2.2.2 special
driving situations). It contains no time language. The correct provision is **§4.3.1.5
"Date and Time"**:

> (a) The ELD must obtain and record the date and time information automatically without
> allowing any external input or interference from a motor carrier, driver, or any other person.
> (b) The ELD time must be synchronized to Coordinated Universal Time (UCT) and the absolute
> deviation from UCT must not exceed 10 minutes at any point in time.

The source comment in `lib/core/time/time_authority.dart:3-5` cites §4.3.2.2. The
*intent* — a driver-non-manipulable time source — is correctly aligned with §4.3.1.5(a);
only the section number is wrong. This directly strengthens F-01: §4.3.1.5(a) is precisely
the rule the dashboard countdown bypasses.

---

## SECTION 6 — Unverified Claims

| # | Claim | Why unverified | Evidence that would resolve it |
|---|---|---|---|
| U-01 | Server re-derives HOS authoritatively after client restart, making F-04's impact cosmetic | No server access; `openapi.yaml` alone cannot confirm runtime behaviour | An integration test booting a second client against a seeded server and asserting continuity |
| U-02 | Whether the stale GET in F-03 actually returns pre-POST data in production (server-side ordering) | Server not exercised; the client defect is proven independently | Capture a real `GET /eld/status` response during a duty change |
| U-03 | Whether `hasWeeklyRestart` can ever build a false ≥34h period (would upgrade F-08) | Requires analysis of multi-session transition logs | Unit-test `_checkAndApplyWeeklyRestart` with transitions spanning restarts |
| U-04 | Exact real-world trigger frequency of F-01's clock manipulation | Requires a physical device and driver action | Instrumented on-device session with deliberate clock change |
| U-05 | Whether `TimeAuthority` (authority B) causes any numeric error in `LogRepositoryImpl` period boundaries | Requires end-to-end log-certification test with skewed clocks | Certify a daily log with a deliberately skewed device clock |
| U-06 | Android/iOS OS behaviour when the app is backgrounded for hours (timer suspension vs. wall-clock drift) | Emulator/device unavailable | On-device soak test with the countdown observed across backgrounding |
| U-07 | Whether `HosNotifier`'s 1-minute `Timer.periodic` survives Doze/App Standby and whether that matters | Requires Android power-management testing | `adb shell dumpsys deviceidle` + on-device soak |
| U-08 | Backend `GET /eld/status` field semantics: is `remainingCircle.time` the remaining or the used value? | No live contract test with the real server | Contract test against a staging server |

---

## SECTION 7 — Test Results

### 7.1 Commands executed

```
# Environment
flutter --version            -> Flutter 3.47.2 • Dart 3.13.2 • stable
dart  --version              -> Dart SDK 3.13.2 (stable) on "windows_x64"

# Pre-existing suite, HOS + time + dashboard subset
flutter test test/core/time test/features/hos test/domain/duty_status \
  test/backend/adapters/eld_engine/mappers/status_dashboard_mapper_test.dart \
  test/hos_calculator_test.dart test/core/engine/tracking --reporter expanded

# Full repository suite
flutter test --reporter compact
flutter test --reporter expanded          # (to enumerate [E] failures)

# Audit regression suite (created by this task)
flutter test test/audit_task01/hos_dashboard_forensic_test.dart --reporter expanded

# Isolated failing test
flutter test test/features/hos/presentation/widgets/status_dashboard/main_circular_timer_test.dart \
  --reporter expanded --plain-name "renders remaining time in HH:MM"

# Baseline check (production files temporarily stashed, then restored)
git stash push -- lib/features/hos/...{4 files}
flutter test test/features/hos/presentation/widgets/status_dashboard/main_circular_timer_test.dart
git stash pop
```

### 7.2 Results

| Suite | Passed | Failed | Skipped |
|---|---|---|---|
| Full repository suite | **794** | **1** | 2 |
| HOS/time/dashboard subset | 121 | 1 | 0 |
| Audit regression suite (new) | **28** | 0 | 0 |

**Environment limitations:** No device/emulator available — all evidence is from the Dart VM
and `flutter_test`. `tester.pump(duration)` in this binding advances the fake `Timer` queue
but **not** `DateTime.now()`; verified empirically (`PROBE_CLOCK_DELTA_AFTER_PUMP20MIN=0:00:00.001002`).
Consequently wall-clock progression was simulated by moving the snapshot timestamp, which is
the exact value production stores. This is a *test-harness* limitation, not a product finding.

### 7.3 The single pre-existing failure

```
test/features/hos/presentation/widgets/status_dashboard/main_circular_timer_test.dart:
  MainCircularTimer renders remaining time in HH:MM
```

Failure: `Expected: exactly one matching candidate / Actual: Found 0 widgets with text "08:37"`.
Rendered value is `08:36` (`RENDERED_TEXTS=[Remaining, 08:36, ON DUTY]`).

**Cause:** test-setup fragility, not a product defect. The test passes
`remaining: Duration(hours: 8, minutes: 37)` with **no** `snapshotTimestamp`, so
`_computeElapsed()` falls back to `_stopwatch.elapsed`. A few milliseconds of real elapsed
time turn 8:37:00 into 8:36:59, and `DurationFormat.hhMm` truncates to `08:36`. The
production path is never affected (it never uses the stopwatch).

**Verified pre-existing:** reproduced identically with the four uncommitted HOS files stashed,
so it is independent of the working-tree changes.

**Secondary note:** this is the *only* place the `Stopwatch` fallback is exercised, and it is
the test that fails — indirect corroboration of C-03's recommendation to delete that branch.

### 7.4 Audit regression suite inventory (28 tests, all passing)

| Phase | Test | Result |
|---|---|---|
| D1 | offline with NO cache → fabricated full limits | PASS (defect reproduced) |
| D1 | online + 500 + no cache → surfaces error | PASS |
| B5/D1 | snapshot timestamp seeded from `DateTime.now()` | PASS |
| B5/D1 | displayed remaining from wall-clock delta | PASS (F-01) |
| B5/D1 | backward clock freezes countdown | PASS (F-01) |
| D4 | stale GET overwrites newer `applyServerDashboard` | PASS (F-03) |
| C1/C6 | restart resets engine counters | PASS (F-04) |
| C5 | 34h restart clears driving accumulator | PASS (F-08) |
| C5 | weekly restart idempotent | PASS (C-06) |
| C2 | shift window starts at construction | PASS |
| B2 | unanchored engine → `HosEngineTimeUnavailable` | PASS |
| B2 | epoch seed **masked** by weekly restart | PASS (C-05 disproved) |
| B2 | transitions refused while unanchored | PASS |
| B2 | normal cold start unaffected | PASS |
| C4 | `breakRequired` never clears | PASS (F-07) |
| B3/B4 | restored anchor uses device-clock delta | PASS (F-09) |
| B3/B4 | stale state when clock ≥7d off | PASS (F-09) |
| B3/B4 | `currentTime` monotonic in-session | PASS |
| F | offline duty change → 35-min constant | PASS (F-10) |
| F | online load retained | PASS |
| F | failed refresh does not wipe value | PASS |
| B5 | three distinct clocks | PASS (F-06) |
| B5 | `TimeAuthority` device-anchored | PASS (F-06) |
| D3 | reset branch unreachable in production | PASS (C-03) |
| D3 | reset branch fires without snapshot | PASS (C-03) |
| E | IndexedStack keeps State mounted | PASS (C-01) |
| E | route replacement preserves countdown | PASS (C-02) |
| E | duty change re-bases countdown | PASS |

---

## SECTION 8 — Root Cause Analysis

### RC-1 — Three uncoordinated time authorities (F-01, F-06, F-09)
`trustedTimeProvider` (server-anchored) was introduced for **legal duty stamps**.
`timeAuthorityProvider` (device-anchored) predates it and survives for **logs and retry
scheduling**. The **display path** was never migrated and calls `DateTime.now()` directly.
Symptoms: F-01 (countdown on wall clock), F-06 (mixed authorities), F-09 (restoration gap
on wall clock). All three are the same architectural gap — no single authority governs
"what time is it, legally" across the app.

### RC-2 — The server is authoritative but the client never says so (F-02, F-04, F-05, F-10)
The split of responsibility is real and largely correct: the server computes HOS, the client
stamps duty events with trusted time. But the client kept a *second*, independent, incomplete
HOS model (`HosStateMachine` counters) and *fabricated* fallback values where server data is
unavailable. Symptoms: F-02 and F-10 (fabricated constants shown as real HOS), F-04 (local
counters reset with no reconstruction), F-05 (cache that does not survive restart despite a
comment claiming it does). Root cause: no explicit "advisory vs authoritative" contract.

### RC-3 — Unsequenced async state application (F-03)
`applyServerDashboard` writes `state` directly and is not coordinated with `refresh()`'s
completion handler. Classic last-writer-wins with no generation token.

### RC-4 — Accumulators without reset conditions (F-07, F-08)
`HosStateMachine` models driving as a single monotonically increasing number whose only reset
is the weekly restart. Real HOS rules key off *interruption windows* (§395.3(a)(3)(ii)), which
this model does not represent. F-07 is the direct consequence; F-08 is a downstream artefact
of the same simplification.

---

## SECTION 9 — Remediation Plan

Ordered by risk-reduction per unit of change. No architectural rewrite is proposed; each item
targets a single verified finding.

**R1 — Single time authority for the countdown (F-01, HIGH).**
Feed `elapsedSinceSnapshot` from `TrustedTimeProvider` instead of `DateTime.now()`.
Minimal change: add a `snapshotTrustedUtc`/`snapshotMonotonicElapsed` pair alongside the
existing provider (or store the `Stopwatch` reading at snapshot time and use
`TrustedTimeProvider.monotonicElapsed` deltas). Delete the now-unused `Stopwatch` fallback in
`_computeElapsed`. **This is the highest-value single change in this report.**

**R2 — Delete the unreachable reset branch (C-03).**
Remove `main_circular_timer.dart:70-77`. It is live dead-code that would grant back legal time
if any future caller passes `snapshotTimestamp: null`.

**R3 — Persist the dashboard cache; stop fabricating limits (F-02, F-05, F-10).**
(a) Write the last successful `StatusDashboard` to the existing Hive box/prefs and rehydrate
`_cachedDashboard`. (b) Replace `_defaultOfflineDashboard` and `_circleForStatus` constants
with an explicit *unknown* state that `CircularTimerLogic` renders as unavailable, rather than
11:00/14:00/70:00/00:35.

**R4 — Sequence dashboard writes (F-03).**
Add a private `_requestSeq` to `StatusDashboardNotifier`; capture it before each fetch and
drop the response if a newer one has already been applied.

**R5 — Fix the 30-minute break model (F-07).**
Track `_lastQualifyingBreakAt` in `HosStateMachine` (set when a non-driving period ≥30 min
completes) and compute `breakRequired` from driving accumulated *since* that timestamp.

**R6 — Fix the two regulatory citations (C-07, C-08).**
`status_dashboard_repository_impl.dart:16` §395.24 → correct reference (or drop the citation
and state the engineering rationale). `time_authority.dart:4` §4.3.2.2 → **§4.3.1.5**.
These are one-line comment changes but they currently mislead reviewers about compliance.

**R7 — Collapse or rename the second time authority (F-06).**
Migrate `LogRepositoryImpl` and `SyncEngine` to `TrustedTimeProvider`, or rename authority B
to `DeviceLocalTimeProvider` so its non-legal role is self-documenting at every call site.

**R8 — Document the authoritative/ advisory split (F-04).**
Add an explicit contract comment at `hosEngineProvider` stating that engine counters are
advisory, are not displayed, and are reset on restart — and gate local violation logging on
"engine has history" so a post-restart engine cannot log spurious violations.

**R9 — Fix the brittle pre-existing test.**
`main_circular_timer_test.dart` should assert a ±1 minute window (or pass an explicit
`snapshotTimestamp`) rather than the exact string `08:37`.

---

## SECTION 10 — Final Verification Matrix

| # | Scenario | Result | Evidence |
|---|---|---|---|
| 1 | Normal operation — countdown ticks down correctly | **PASS** | `WALLCLOCK_ELAPSED_TEXTS=[…, 04:29, …]` — 5:00 server − 30 min wall clock |
| 2 | Navigation away and back — no incorrect jump | **PASS** | C-01: `identical(stateBefore, stateAfter)==true`; `07:54`→`07:34` |
| 3 | Dashboard refresh produces correct remaining time | **PASS** | `STATUS_T1=03:59` — new snapshot re-bases correctly |
| 4 | Duty-status change updates the appropriate counters | **PASS** | Traces 2/3; `OFFLINE_DUTY_CHANGE_STATUS=DutyStatusCode.driving` |
| 5 | Offline period does not erase accumulated driving | **PASS** | `ONLINE_LOADED_DRIVE=5:00` retained; no value-wipe branch |
| 6 | App restart reconstructs accounting state | **FAIL** | F-04: `SESSION1=300` → `SESSION2=660` |
| 7 | Device wall-clock change does not corrupt calcs | **FAIL** | F-01: `BACKWARD_CLOCK_TEXTS=[…, 05:00, …]` frozen |
| 8 | Delayed periodic callbacks do not corrupt accounting | **PASS** | C-04: derived arithmetic, empty heartbeat timer |
| 9 | Overlapping async requests do not overwrite newer state | **FAIL** | F-03: `5:00` → `1:00` |
| 10 | Trusted-time restoration follows documented implementation | **PASS** | F-09: `RESTORED_DRIFT_VS_SERVER=48:00:00` matches the documented device-clock method |
| 11 | Offline with warm cache shows real values | **NOT TESTED** | Requires flipping `NetworkInfo` on a live container mid-session (U-06-style harness gap) |
| 12 | Reconnection triggers state reconciliation | **NOT TESTED** | Sync system explicitly out of scope for this task |
| 13 | Application backgrounding / foregrounding | **NOT TESTED** | No device/emulator (U-06, U-07) |
| 14 | Dashboard offline with no cache is legally correct | **FAIL** | F-02: fabricated 11:00/14:00/70:00 |
| 15 | 30-minute break clears `breakRequired` | **FAIL** | F-07: `BREAK_AFTER=true` |
| 16 | 34-hour restart cannot repeat | **PASS** | C-06 idempotency test |
| 17 | Epoch shift-window false violation | **PASS (disproven)** | C-05: `LATE_ANCHOR_SHIFT_REMAINING_MIN=840 VIOLATIONS=[]` |
| 18 | Unanchored clock → engine safely degrades | **PASS** | `UNANCHORED_ENGINE_RESULT=HosEngineTimeUnavailable` |
| 19 | Route replacement preserves countdown | **PASS** | C-02: `NAV_ROUTE_REPLACE=07:34` |
| 20 | Regulatory citations accurate | **FAIL** | C-07, C-08: §395.24 and §4.3.2.2 miscited |
| 21 | Server authority after restart (U-01) | **NOT TESTED** | No server access |
| 22 | Cross-restart offline dashboard cache | **FAIL** | F-05: in-memory only |

**Totals:** PASS 11 · FAIL 7 · NOT TESTED 4 (of 22).

---

## SECTION 11 — Mandatory Completeness Self-Audit

| Required item | Status |
|---|---|
| Every relevant provider dependency traced | ✅ Section 2.1–2.3; grep-verified zero display consumers of engine limits |
| Every important timer lifecycle inspected | ✅ 3 timers: `MainCircularTimer` 1 s ticker, `HosNotifier` 1 min, `HosStateMachine` heartbeat (all in `initState`/`didUpdateWidget`/`dispose`/provider `onDispose`) |
| All dashboard update paths identified | ✅ `build()`, `refresh()`, `applyServerDashboard()`, `ref.invalidate` (app.dart:42, codriver_page:303), `hosStatusProvider` listener, `AppEvent.logDataChanged` |
| Navigation verified against actual widget tree | ✅ `IndexedStack` confirmed by source + `identical()` State-identity assertion |
| Offline behaviour distinguished from server behaviour | ✅ F-02/F-05/F-10 isolate the client; U-01/U-02 flag server unknowns |
| Time restoration inspected | ✅ F-09; `trusted_time_anchor` prefs key + `_restore()` traced |
| Existing tests reviewed | ✅ 14 test files; pre-existing failure root-caused |
| Relevant executable tests run | ✅ Full suite (794/1) + 28 new |
| Regulatory claims verified against authoritative sources | ✅ eCFR §395.3, §395.24, Appendix A §4.3.1.5/§4.3.2.2/§4.3.2.8 — all quoted verbatim; two citations disproven |
| Every confirmed defect has reproducible evidence or deterministic proof | ✅ All 8 CONFIRMED/REPRODUCED findings carry test output |
| Previous audit claims independently reassessed | ✅ Section 5 — 8 claims, **4 disproven**, 1 regulatory citation disproven |
| No speculative statement presented as proven defect | ✅ F-08 held at POTENTIAL; U-01…U-08 recorded as NOT VERIFIED |
| **No production source code modified** | ✅ `git status` shows the same 4 pre-existing modified lib files; diffstat identical before/after (114 insertions, 17 deletions). Only addition: `test/audit_task01/hos_dashboard_forensic_test.dart` |

**Incomplete items:** U-01 through U-08 (Section 6) remain unverified — chiefly because no
device/emulator and no server access were available in this environment. They are recorded
as NOT VERIFIED rather than assumed either way.

---

*End of audit.*