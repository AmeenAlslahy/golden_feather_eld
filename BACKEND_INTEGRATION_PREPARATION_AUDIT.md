# BACKEND INTEGRATION PREPARATION & ARCHITECTURAL DECOUPLING AUDIT

**Project:** Golden Feather ELD  
**Date:** 2026-09-01  
**Scope:** READ-ONLY Forensic Architectural Audit — Flutter ↔ Backend (OpenAPI)  
**Status:** Analysis Complete — No Source Code Modified

---

## TABLE OF CONTENTS

1. [Executive Summary](#1-executive-summary)
2. [Current Flutter Architecture](#2-current-flutter-architecture)
3. [Current Data Flow](#3-current-data-flow)
4. [Current Business Logic Distribution](#4-current-business-logic-distribution)
5. [Local Engine Inventory](#5-local-engine-inventory)
6. [Local Engine Coupling Analysis](#6-local-engine-coupling-analysis)
7. [OpenAPI Contract Inventory](#7-openapi-contract-inventory)
8. [Flutter ↔ OpenAPI Comparison](#8-flutter--openapi-comparison)
9. [JSON Contract Differences](#9-json-contract-differences)
10. [DTO Requirements](#10-dto-requirements)
11. [Mapper Requirements](#11-mapper-requirements)
12. [Repository Requirements](#12-repository-requirements)
13. [RemoteDataSource Requirements](#13-remotedatasource-requirements)
14. [API Client Requirements](#14-api-client-requirements)
15. [Error Handling Requirements](#15-error-handling-requirements)
16. [Time/Timezone Requirements](#16-timetimezone-requirements)
17. [Enum Requirements](#17-enum-requirements)
18. [ID Requirements](#18-id-requirements)
19. [Unit Requirements](#19-unit-requirements)
20. [Offline Requirements](#20-offline-requirements)
21. [Cache Requirements](#21-cache-requirements)
22. [Sync Requirements](#22-sync-requirements)
23. [Reconciliation Requirements](#23-reconciliation-requirements)
24. [Target Architecture](#24-target-architecture)
25. [Responsibility Boundaries](#25-responsibility-boundaries)
26. [Isolation Plan](#26-isolation-plan)
27. [Migration Plan](#27-migration-plan)
28. [Migration Readiness Matrix](#28-migration-readiness-matrix)
29. [Risk Matrix](#29-risk-matrix)
30. [MUST CHANGE](#30-must-change)
31. [SHOULD CHANGE](#31-should-change)
32. [MUST NOT CHANGE](#32-must-not-change)
33. [Migration Blockers](#33-migration-blockers)
34. [Future Backend Connection Procedure](#34-future-backend-connection-procedure)
35. [Final Verdict](#35-final-verdict)

---

## 1 — EXECUTIVE SUMMARY

### Current State

Golden Feather ELD is a **100% locally-operating** Flutter ELD application. All HOS calculations, compliance checks, violation detection, diagnostics monitoring, and duty status management happen **entirely on-device** using custom local engines backed by Hive/SharedPreferences storage.

### Key Findings

| Metric | Value |
|--------|-------|
| Total Dart Files | 113+ |
| Features | 15 modules |
| Local Engines | 7 (HOS Calculator, Rules Engine, State Machine, Violations Engine, Diagnostics Engine, Duty Status Tracker, Distance Tracker) |
| Existing Repositories | 5 (Auth, Vehicle, Tracking, Log, Sync) |
| Existing RemoteDataSources | 3 (Auth, Vehicle, Tracking/Traccar) |
| OpenAPI Endpoints | 65+ across 14 tag groups |
| Backend Domains Covered | 14 (Duty Status, Compliance, Violations, Reports, Documents, Inspection, Signatures, Diagnostics, Stats, Dashboard, Rules, Sessions, Config, Health) |
| Flutter Domains with Backend Equivalent | ~8 partially, ~6 missing |
| DTOs for Backend | **0** |
| Mappers for Backend | **1** (TraccarMapper only) |
| Backend API Client | **0** (only Traccar REST client exists) |

### Critical Insight

The app has a **well-structured local engine architecture** that is already partially decoupled. The `TrackingEventProcessor` already serves as a mapper layer between raw tracking data and domain engines. However, **no abstraction exists between local computation and backend computation** — the local engines ARE the only source of truth.

### What Works Well

- Clean Architecture feature-first organization
- Riverpod dependency injection
- `Either<Failure, T>` error handling pattern
- Repository interfaces exist for key features
- `TrackingDataSource` abstraction already exists
- `TraccarMapper` proves mapper pattern is already in use
- `HosConfiguration` is parameterized (can be driven by backend)

### What Needs Preparation

- No `RemoteDataSource` for HOS/Compliance/Violations/Diagnostics/Reports
- No DTOs matching OpenAPI schemas
- No backend API client for ELD-specific endpoints
- Local engines are tightly coupled to direct SQLite/Hive persistence
- No repository abstraction for HOS (UI calls engine directly)
- No offline queue for duty status events destined for backend

---

## 2 — CURRENT FLUTTER ARCHITECTURE

### Layer Map

```
PRESENTATION
├── features/hos/presentation/pages/         (hos_page, change_status_page, recap_page)
├── features/hos/presentation/providers/     (hos_provider, recap_provider, diagnostics_state_provider)
├── features/hos/presentation/widgets/       (main_circular_timer, hos_timer_list, status_option_tiles, etc.)
├── features/tracking/presentation/          (tracking_page, tracking_provider, tracking_providers)
├── features/logs/presentation/              (logs_list_page, log_detail_page, logs_provider)
├── features/inspection/presentation/        (dot_inspection_page, inspection_provider)
├── features/dvir/presentation/              (dvir_form_page, dvir_list_page, dvir_provider)
├── features/auth/presentation/              (auth_page, login_form, auth_state_provider)
├── features/vehicle/presentation/           (select_vehicle_page, vehicle_provider)
├── features/sync/presentation/              (sync_status_indicator, sync_provider)
├── features/reports/presentation/           (reports_page, reports_provider)
├── features/home/presentation/              (home_page, dashboard_provider)
├── features/settings/presentation/          (settings_page, developer_options_page)
├── features/account/presentation/           (account_page, rules_page)
├── features/codriver/presentation/          (codriver_page, codriver_provider)
└── features/connection/presentation/        (eld_connection_page)

APPLICATION
├── features/hos/domain/usecases/            (get_recap_use_case)
├── features/tracking/domain/usecases/       (tracking_event_processor)
└── features/sync/domain/usecases/           (sync_engine)

DOMAIN
├── features/auth/domain/                    (auth_repository, auth_session, user)
├── features/vehicle/domain/                 (vehicle_repository, vehicle)
├── features/tracking/domain/                (tracking_repository, location_entity, tracking_event)
├── features/logs/domain/                    (log_repository, daily_log, audit_entry)
├── features/sync/domain/                    (sync_repository, sync_item, pending_event, offline_queue)
├── features/hos/domain/                     (recap_data)
├── features/dvir/domain/                    (dvir_report)
├── features/inspection/domain/              (inspection_data)
├── features/codriver/domain/                (codriver)
└── features/vehicle/domain/                 (vehicle)

LOCAL DATA
├── features/logs/data/datasources/          (log_local_data_source → Hive)
├── features/sync/data/datasources/          (sync_local_data_source → SharedPreferences)
├── features/sync/data/repositories/         (sqlite_offline_queue → SQLite, memory_offline_queue)
├── features/tracking/data/datasources/      (tracking_local_data_source → SharedPreferences)
├── core/services/local_database_service.dart (Hive boxes + SharedPreferences)
├── core/services/local_storage_service.dart  (SharedPreferences + SecureStorage)
└── features/auth/data/datasources/          (auth_session_store → SecureStorage, user_store)

REMOTE DATA
├── features/auth/data/datasources/          (auth_remote_data_source → Dio → Traccar /api/session)
├── features/vehicle/data/datasources/       (vehicle_remote_data_source → Dio → Traccar /api/devices)
├── features/tracking/data/datasources/      (traccar_data_source → Traccar API/WS/Native)
└── features/sync/data/repositories/         (traccar_remote_event_dispatcher → Dio → /api/events)

INFRASTRUCTURE
├── core/network/                            (api_client, api_config, api_endpoints, auth_interceptor, etc.)
├── core/network/traccar/                    (traccar_api_client, traccar_websocket_client, traccar_native_client)
├── core/engine/                             (hos_calculator, hos_rules_engine, hos_state_machine, etc.)
├── core/config/                             (hos_configuration, app_environment)
├── core/services/                           (app_initializer, battery_optimization, bluetooth, etc.)
└── core/error/                              (failure, exception)

DEVICE
├── features/tracking/data/datasources/      (native_event_channel_client → Platform Channels)
├── core/services/bluetooth_service.dart
└── core/mocks/mock_tracking_client_sdk.dart
```

---

## 3 — CURRENT DATA FLOW

### Flow 1: Duty Status Change (Primary Flow)

```
UI (change_status_page.dart:42)
  ↓ ref.read(hosStatusProvider.notifier).changeStatus()
HosNotifier (hos_provider.dart:68)
  ↓ _engine.manualTransition()
HosRulesEngine (hos_rules_engine.dart:120)
  ↓ _stateMachine.transitionTo()
HosStateMachine (hos_state_machine.dart:60)
  ↓ updates _currentStatus, _shiftStartTime
  ↓ returns HosStatusUpdate
HosNotifier refreshes state
  ↓ state = _engine.currentStatus
UI rebuilds with new timers
```

**CRITICAL:** No persistence happens here. The status lives only in memory within `HosStateMachine`.

### Flow 2: GPS Event → HOS Calculation

```
Platform GPS (Android/iOS)
  ↓ EventChannel
NativeEventChannelClient (native_event_channel_client.dart)
  ↓ Stream<LocationEvent>
TraccarDataSource (traccar_data_source.dart:90)
  ↓ Stream<TrackingEvent>
TrackingEventProcessor (tracking_event_processor.dart:80)
  ↓ _mapToEldEvent() → EldEvent
  ↓ _mapToLocationPoint() → LocationPoint
LiveTrackingDataSource (live_tracking_data_source.dart:150)
  ↓ Stream<EldEvent>, Stream<LocationPoint>
DutyStatusTracker (duty_status_tracker.dart:70)
  ↓ processEldEvent() → auto transitions
  ↓ _transitionTo() → saves period to LogRepository
  ↓ Stream<DutyTransition>
HosNotifier (hos_provider.dart:40)
  ↓ listens to _tracker.onTransition
  ↓ _engine.manualTransition()
HosRulesEngine recalculates
  ↓
UI updates
```

### Flow 3: Duty Period Persistence

```
DutyStatusTracker._transitionTo() (duty_status_tracker.dart:145)
  ↓ creates DutyPeriod
  ↓ _logRepository.savePeriod(period)
LogRepositoryImpl (log_repository_impl.dart:35)
  ↓ executeWithHandling()
LogLocalDataSourceImpl (log_local_data_source.dart:75)
  ↓ _localDb.savePeriod(map)
LocalDatabaseService (local_database_service.dart:100)
  ↓ _saveToBox(_periodsBox, data, 'start_time', 'period')
  ↓ Hive box.put(dateStr, jsonEncode(currentList))
```

### Flow 4: Violation Detection

```
Timer (every 60 seconds) (hos_violations_engine.dart:35)
  ↓ checkAll()
HosViolationsEngine
  ↓ reads _engine.currentStatus.limits
  ↓ checks 7 violation types
  ↓ creates HosViolation objects
  ↓ _localDb.saveViolation(violation.toJson())
  ↓ Stream<List<HosViolation>>
UI (diagnostics_alert_card.dart) listens
```

### Flow 5: Diagnostics Detection

```
LiveTrackingDataSource.events (diagnostics_engine.dart:55)
  ↓ Stream<EldEvent>
DiagnosticsEngine._startListening()
  ↓ processDataPoint()
  ↓ checks: dataGap, positioning, motionSensor, engineSync, unidentifiedDrive
  ↓ _addMalfunction() → saves to _localDb.saveDiagnostic()
  ↓ Stream<DiagnosticsState>
DiagnosticsStateProvider (diagnostics_state_provider.dart)
  ↓
UI
```

---

## 4 — CURRENT BUSINESS LOGIC DISTRIBUTION

| Component | Responsibility | Location |
|-----------|---------------|----------|
| HosCalculator | Computes remaining driving/shift/cycle minutes | `core/engine/hos_calculator.dart` |
| HosRulesEngine | Orchestrates calculator + state machine, generates alerts | `core/engine/hos_rules_engine.dart` |
| HosStateMachine | Manages duty status transitions, driving timer | `core/engine/hos_state_machine.dart` |
| HosViolationsEngine | Periodic violation monitoring (7 types), persists violations | `core/engine/hos_violations_engine.dart` |
| DiagnosticsEngine | ELD device diagnostics (5 malfunction types) | `core/engine/diagnostics/diagnostics_engine.dart` |
| DutyStatusTracker | Auto driving/on_duty transitions based on speed | `core/engine/tracking/duty_status_tracker.dart` |
| DistanceTracker | Haversine distance calculation from GPS points | `core/engine/tracking/distance_tracker.dart` |
| TrackingEventProcessor | Maps TrackingEvent → EldEvent + LocationPoint | `features/tracking/domain/usecases/tracking_event_processor.dart` |
| HosConfiguration | Configurable HOS limits (USA 70/8, 60/7) | `core/config/hos_configuration.dart` |
| GetRecapUseCase | Computes 7-day recap from LogRepository | `features/hos/domain/usecases/get_recap_use_case.dart` |
| SyncEngine | Offline queue + retry + dispatch | `features/sync/domain/usecases/sync_engine.dart` |
| ErodsGenerator | XML/CSV eRODS file generation | `core/services/erods_generator.dart` |

---

## 5 — LOCAL ENGINE INVENTORY

### Engine 1: HosCalculator

| Attribute | Detail |
|-----------|--------|
| File | `lib/core/engine/hos_calculator.dart` |
| Class | `HosCalculator` |
| Input | `List<DutyStatusEvent>`, `DateTime shiftStart`, `HosConfiguration` |
| Output | `HosLimits` (remaining drive/shift/cycle/break minutes) |
| Caller | `HosRulesEngine.processEvent()`, `HosRulesEngine.manualTransition()` |
| Consumers | `HosRulesEngine` → `HosNotifier` → UI |
| Persistence | None (pure calculation) |
| State | Stateless |
| Timers | None |
| Dependencies | `HosConfiguration`, `DutyStatus` enum |
| Side Effects | None |
| Backend Equivalent | `GET /eld/compliance/{driverId}/remaining` → `ComplianceSummaryResponse` |
| Can Isolate? | **YES** — already pure function, no side effects |

### Engine 2: HosRulesEngine

| Attribute | Detail |
|-----------|--------|
| File | `lib/core/engine/hos_rules_engine.dart` |
| Class | `HosRulesEngine` |
| Input | `EldEvent` or manual `DutyStatus` transition |
| Output | `HosStatusUpdate` (status + limits + alerts + violations) |
| Caller | `HosNotifier` |
| Consumers | `HosNotifier` → UI |
| Persistence | None directly (delegates to StateMachine) |
| State | Internal `_currentStatus`, `_shiftStartTime`, `_cycleStart` |
| Timers | None |
| Dependencies | `HosCalculator`, `HosStateMachine` |
| Side Effects | Updates state machine, generates alerts |
| Backend Equivalent | `GET /eld/compliance/{driverId}/evaluate` |
| Can Isolate? | **YES** — already self-contained, but manages its own state |

### Engine 3: HosStateMachine

| Attribute | Detail |
|-----------|--------|
| File | `lib/core/engine/hos_state_machine.dart` |
| Class | `HosStateMachine` |
| Input | `DutyStatus` transition request |
| Output | `StatusTransition` record, updated `_currentStatus` |
| Caller | `HosRulesEngine` |
| Consumers | `HosRulesEngine` |
| Persistence | In-memory only (lost on restart) |
| State | `_currentStatus`, `_shiftStartTime`, `_cycleStart`, `_drivingTimer` |
| Timers | `_drivingTimer` (counts up while driving) |
| Dependencies | `DutyStatus`, `DutyTransition` models |
| Side Effects | Timer management, state mutation |
| Backend Equivalent | `POST /eld/status` (updateStatus), `GET /eld/status/{driverId}` |
| Can Isolate? | **PARTIAL** — state management is tightly coupled |

### Engine 4: HosViolationsEngine

| Attribute | Detail |
|-----------|--------|
| File | `lib/core/engine/hos_violations_engine.dart` |
| Class | `HosViolationsEngine` |
| Input | Current `HosStatusUpdate` (limits + alerts) |
| Output | `List<HosViolation>` (7 violation types) |
| Caller | Timer (every 60 seconds) |
| Consumers | UI via `diagnosticsStateProvider` (indirectly) |
| Persistence | `_localDb.saveViolation()` → Hive `_violationsBox` |
| State | `_lastViolationKey` (dedup), `_subscription` |
| Timers | `Timer.periodic(Duration(minutes: 1))` |
| Dependencies | `HosRulesEngine`, `LocalDatabaseService` |
| Side Effects | **Writes to Hive database** |
| Backend Equivalent | `GET /eld/violations` |
| Can Isolate? | **PARTIAL** — depends on engine state + writes to DB |

### Engine 5: DiagnosticsEngine

| Attribute | Detail |
|-----------|--------|
| File | `lib/core/engine/diagnostics/diagnostics_engine.dart` |
| Class | `DiagnosticsEngine` |
| Input | `EldEvent` stream from `LiveTrackingDataSource` |
| Output | `DiagnosticsState` (active malfunctions + history) |
| Caller | Event-driven (listens to tracking events) |
| Consumers | `diagnosticsStateProvider` → UI |
| Persistence | `_localDb.saveDiagnostic()` → Hive `_diagnosticsBox` |
| State | `_lastDataPoint`, `_lastSpeed`, `_engineRunningWithoutMotion` |
| Timers | None (event-driven) |
| Dependencies | `LiveTrackingDataSource`, `LocalDatabaseService` |
| Side Effects | **Writes to Hive database** |
| Backend Equivalent | `GET /eld/diagnostics/{driverId}` |
| Can Isolate? | **PARTIAL** — depends on tracking data stream |

### Engine 6: DutyStatusTracker

| Attribute | Detail |
|-----------|--------|
| File | `lib/core/engine/tracking/duty_status_tracker.dart` |
| Class | `DutyStatusTracker` |
| Input | `EldEvent` stream (speed, odometer, engine hours) |
| Output | `DutyTransition` stream, `DutyPeriod` list |
| Caller | Event-driven (listens to `LiveTrackingDataSource.events`) |
| Consumers | `HosNotifier` (listens to `onTransition`) |
| Persistence | `_logRepository.savePeriod()` → Hive, `_saveSetting()` → SharedPreferences |
| State | `_currentStatus`, `_stationarySince`, `_movingSince`, `_consecutiveMovingEvents` |
| Timers | `_wakeupTimer` (for 5-min stationary check) |
| Dependencies | `LogRepository`, `LocalDatabaseService` (for settings) |
| Side Effects | **Writes to Hive + SharedPreferences**, triggers transitions |
| Backend Equivalent | `POST /eld/status` (updateStatus) |
| Can Isolate? | **PARTIAL** — auto-driving logic is local, but period saving could be redirected |

### Engine 7: DistanceTracker

| Attribute | Detail |
|-----------|--------|
| File | `lib/core/engine/tracking/distance_tracker.dart` |
| Class | `DistanceTracker` |
| Input | `LocationPoint` stream |
| Output | `totalDistanceKm`, `getTodayDistance()` |
| Caller | Event-driven (listens to `LiveTrackingDataSource.locations`) |
| Consumers | None currently (no UI consumes this directly) |
| Persistence | None (in-memory only) |
| State | `_points`, `_totalDistanceKm`, `_lastPoint` |
| Timers | None |
| Dependencies | `DistanceCalculator.haversine()` |
| Side Effects | None |
| Backend Equivalent | Implicit in `PeriodResponse.distanceKm` |
| Can Isolate? | **YES** — pure calculation, no side effects |

---

## 6 — LOCAL ENGINE COUPLING ANALYSIS

### Coupling Matrix

| Engine | UI Direct? | SQLite/Hive Direct? | API Direct? | Provider Direct? | Can Isolate Without Behavior Change? |
|--------|-----------|-------------------|------------|-----------------|-------------------------------------|
| HosCalculator | NO | NO | NO | NO | YES |
| HosRulesEngine | NO | NO | NO | YES (Riverpod) | YES |
| HosStateMachine | NO | NO | NO | YES (Riverpod) | PARTIAL |
| HosViolationsEngine | NO | YES (writes) | NO | YES (Riverpod) | PARTIAL |
| DiagnosticsEngine | NO | YES (writes) | NO | YES (Riverpod) | PARTIAL |
| DutyStatusTracker | NO | YES (writes + reads) | NO | YES (Riverpod) | PARTIAL |
| DistanceTracker | NO | NO | NO | YES (Riverpod) | YES |

### Critical Coupling Points

**1. HosProvider → HosRulesEngine (Direct Coupling)**
- File: `lib/features/hos/presentation/providers/hos_provider.dart:25`
- `hosStatusProvider` directly watches `hosEngineProvider` and calls `_engine.manualTransition()`
- **No Repository abstraction exists for HOS**

**2. DutyStatusTracker → LogRepository → LocalDatabaseService (Persistence Coupling)**
- File: `lib/core/engine/tracking/duty_status_tracker.dart:55`
- `_logRepository.savePeriod(period)` writes directly to Hive
- **No option to redirect to remote**

**3. HosViolationsEngine → LocalDatabaseService (Persistence Coupling)**
- File: `lib/core/engine/hos_violations_engine.dart:85`
- `_localDb.saveViolation(violation.toJson())` writes directly to Hive
- **No option to send to backend**

**4. DiagnosticsEngine → LocalDatabaseService (Persistence Coupling)**
- File: `lib/core/engine/diagnostics/diagnostics_engine.dart:140`
- `_localDb.saveDiagnostic(event.toJson())` writes directly to Hive
- **No option to send to backend**

**5. HosStateMachine → In-Memory State (No Persistence)**
- File: `lib/core/engine/hos_state_machine.dart`
- All state is lost on app restart
- **No backend sync, no local persistence of state**

---

## 7 — OPENAPI CONTRACT INVENTORY

### Servers
```yaml
servers:
- url: /api
  description: Current Server (Traccar + ELD)
```

### Security
```yaml
securitySchemes:
  BasicAuth:
    type: http
    scheme: basic
  BearerAuth:
    type: http
    scheme: bearer
```

### All Endpoints (65+)

#### 1. Duty Status (HOS)
| Method | Path | OperationId |
|--------|------|-------------|
| POST | `/eld/status` | updateStatus |
| GET | `/eld/status/{driverId}` | getStatus |
| GET | `/eld/status/{driverId}/history` | getStatusHistory |
| GET | `/eld/status` | getAllStatuses (Fleet Mgr) |
| PUT | `/eld/status/{id}` | updateStatusRecord |
| GET | `/eld/status/edits` | getPendingEdits |
| PUT | `/eld/status/edits/{editId}/approve` | approveEdit |
| PUT | `/eld/status/edits/{editId}/reject` | rejectEdit |

#### 2. Compliance Engine
| Method | Path | OperationId |
|--------|------|-------------|
| GET | `/eld/compliance/{driverId}/evaluate` | evaluateCompliance |
| GET | `/eld/compliance/{driverId}/remaining` | getRemainingHours |

#### 3. Violations
| Method | Path | OperationId |
|--------|------|-------------|
| GET | `/eld/violations` | getViolations |
| GET | `/eld/violations/{id}` | getViolationById |
| PUT | `/eld/violations/{id}/resolve` | resolveViolation |
| PUT | `/eld/violations/{id}/dispute` | disputeViolation |

#### 4. ELD Reports
| Method | Path | OperationId |
|--------|------|-------------|
| POST | `/eld/reports/generate` | generateReportByRequest |
| GET | `/eld/reports/{driverId}/daily` | getDailyReport |
| GET | `/eld/reports/{driverId}/weekly` | getWeeklyReport |
| GET | `/eld/reports/{driverId}/executive` | getExecutiveReport |
| GET | `/eld/reports/{driverId}/pdf` | getPdfReport |
| GET | `/eld/reports/{driverId}/csv` | getCsvReport |
| GET | `/eld/reports/{driverId}/html` | getHtmlReport |
| GET | `/eld/reports/{driverId}/xml` | getXmlReport |

#### 5. Documents & Certification
| Method | Path | OperationId |
|--------|------|-------------|
| GET | `/eld/documents/{driverId}` | getDocuments |
| POST | `/eld/documents/{driverId}` | uploadDocument |
| POST | `/eld/documents/{driverId}/upload-file` | uploadDocumentFile |
| DELETE | `/eld/documents/{id}` | deleteDocument |
| PUT | `/eld/documents/{id}/verify` | verifyDocument |
| GET | `/eld/documents/download/{docId}` | downloadDocumentFile |

#### 6. Roadside Inspection
| Method | Path | OperationId |
|--------|------|-------------|
| POST | `/eld/inspections` | startInspection |
| GET | `/eld/inspections/{id}` | getInspection |
| PUT | `/eld/inspections/{id}/complete` | completeInspection |
| GET | `/eld/inspections/driver/{driverId}` | getDriverInspections |
| GET | `/eld/inspections/{id}/report` | getComprehensiveReport |
| GET | `/eld/inspections/{id}/report/html` | getComprehensiveReportHtml |
| GET | `/eld/inspections/{id}/data-file` | getFmcsaDataFile |
| POST | `/eld/inspections/{id}/transfer` | initiateDataTransfer |
| GET | `/eld/inspections/{id}/transfer/ble-packets` | getBlePackets |
| GET | `/eld/inspections/{id}/transfer/usb` | getUsbPayload |
| GET | `/eld/inspections/{id}/qr` | getQrCode |

#### 7. Signatures & Certificates
| Method | Path | OperationId |
|--------|------|-------------|
| POST | `/eld/signatures/{driverId}` | saveSignature |
| GET | `/eld/signatures/{driverId}` | getSignatures |
| POST | `/eld/signatures/{driverId}/upload-file` | uploadSignatureFile |
| GET | `/eld/signatures/{id}/certificate` | getCertificate |

#### 8. Diagnostics & Malfunctions
| Method | Path | OperationId |
|--------|------|-------------|
| GET | `/eld/diagnostics/{driverId}` | getDriverDiagnostics |
| GET | `/eld/diagnostics/fleet` | getFleetDiagnostics |
| PUT | `/eld/diagnostics/{id}/clear` | clearDiagnostic |

#### 9. Fleet Statistics & Scores
| Method | Path | OperationId |
|--------|------|-------------|
| GET | `/eld/stats` | getFleetStats |
| GET | `/eld/stats/driver/{driverId}` | getDriverComplianceScore |

#### 10. Real-Time Dashboard
| Method | Path | OperationId |
|--------|------|-------------|
| GET | `/eld/dashboard/summary` | getFleetSummary |
| GET | `/eld/dashboard/stream` | streamDashboardUpdates (SSE) |

#### 11. Driver Rules
| Method | Path | OperationId |
|--------|------|-------------|
| GET | `/eld/rules/available` | getAvailableRules |
| GET | `/eld/rules/{driverId}` | getRules |
| PUT | `/eld/rules/driver` | updateByDriver |

#### 12. Driver Sessions
| Method | Path | OperationId |
|--------|------|-------------|
| POST | `/eld/sessions/start` | startSession |
| POST | `/eld/sessions/switch` | switchRole |
| POST | `/eld/sessions/link` | linkCoDriver |
| GET | `/eld/sessions/{driverId}` | getSession |
| POST | `/eld/sessions/telemetry` | processTelemetry |

#### 13. System Configuration
| Method | Path | OperationId |
|--------|------|-------------|
| GET | `/eld/config` | getConfiguration |
| PUT | `/eld/config` | updateConfiguration |
| GET | `/eld/config/db-settings` | getDatabaseSettings |
| PUT | `/eld/config/db-settings` | updateDatabaseSetting |
| GET | `/eld/config/regulations` | getSupportedRegulations |
| PUT | `/eld/config/regulations/active` | switchActiveRegulation |

#### 14. System Health & Diagnostics
| Method | Path | OperationId |
|--------|------|-------------|
| GET | `/eld/health` | checkHealth |
| GET | `/eld/health/detailed` | checkDetailedHealth |

---

## 8 — FLUTTER ↔ OPENAPI COMPARISON

| Backend Capability | OpenAPI Endpoint | Flutter Equivalent | Current Implementation | Gap |
|--------------------|------------------|--------------------|-----------------------|-----|
| Update Duty Status | `POST /eld/status` | `HosNotifier.changeStatus()` | Local engine only, no backend call | **NO REMOTE DATASOURCE** |
| Get Driver Status | `GET /eld/status/{driverId}` | `HosNotifier.state` (in-memory) | Local engine state, not persisted to backend | **NO REMOTE DATASOURCE** |
| Status History | `GET /eld/status/{driverId}/history` | `DutyStatusTracker._periods` (in-memory) | In-memory list, Hive persistence | **NO REMOTE DATASOURCE** |
| Fleet Status View | `GET /eld/status` | None | Not implemented | **NOT IMPLEMENTED** |
| Evaluate Compliance | `GET /eld/compliance/{driverId}/evaluate` | `HosRulesEngine.processEvent()` | Local calculation only | **NO REMOTE DATASOURCE** |
| Remaining Hours | `GET /eld/compliance/{driverId}/remaining` | `HosCalculator.calculateAllLimits()` | Local calculation only | **NO REMOTE DATASOURCE** |
| Get Violations | `GET /eld/violations` | `HosViolationsEngine` (local stream) | Local detection + Hive persistence | **NO REMOTE DATASOURCE** |
| Resolve Violation | `PUT /eld/violations/{id}/resolve` | None | Not implemented | **NOT IMPLEMENTED** |
| Dispute Violation | `PUT /eld/violations/{id}/dispute` | None | Not implemented | **NOT IMPLEMENTED** |
| Get Diagnostics | `GET /eld/diagnostics/{driverId}` | `DiagnosticsEngine` (local stream) | Local detection + Hive persistence | **NO REMOTE DATASOURCE** |
| Clear Diagnostic | `PUT /eld/diagnostics/{id}/clear` | `DiagnosticsEngine.clearActive()` | Local only, no backend call | **NO REMOTE DATASOURCE** |
| Daily Report | `GET /eld/reports/{driverId}/daily` | `LogsProvider._loadLogs()` | Local Hive data only | **NO REMOTE DATASOURCE** |
| Weekly Report | `GET /eld/reports/{driverId}/weekly` | `GetRecapUseCase.execute()` | Local calculation from Hive | **NO REMOTE DATASOURCE** |
| PDF Report | `GET /eld/reports/{driverId}/pdf` | `PdfExportService` | Local generation | **NO REMOTE DATASOURCE** |
| Start Inspection | `POST /eld/inspections` | `InspectionProvider` | Mock data only | **MOCK DATA** |
| Complete Inspection | `PUT /eld/inspections/{id}/complete` | `InspectionProvider` | Mock data only | **MOCK DATA** |
| Get Inspections | `GET /eld/inspections/driver/{driverId}` | `InspectionProvider` | Mock data only | **MOCK DATA** |
| Save Signature | `POST /eld/signatures/{driverId}` | None | Not implemented | **NOT IMPLEMENTED** |
| Get Signatures | `GET /eld/signatures/{driverId}` | None | Not implemented | **NOT IMPLEMENTED** |
| Get Documents | `GET /eld/documents/{driverId}` | None | Not implemented | **NOT IMPLEMENTED** |
| Upload Document | `POST /eld/documents/{driverId}` | None | Not implemented | **NOT IMPLEMENTED** |
| Get Driver Rules | `GET /eld/rules/{driverId}` | `HosConfiguration` (hardcoded) | Static local config | **NO REMOTE DATASOURCE** |
| Update Rules | `PUT /eld/rules/driver` | None | Not implemented | **NOT IMPLEMENTED** |
| Start Session | `POST /eld/sessions/start` | None | Not implemented | **NOT IMPLEMENTED** |
| Switch Role | `POST /eld/sessions/switch` | None | Not implemented | **NOT IMPLEMENTED** |
| Link CoDriver | `POST /eld/sessions/link` | `CodriverProvider` (mock) | Mock data | **MOCK DATA** |
| Get Config | `GET /eld/config` | `HosConfiguration` (hardcoded) | Static local config | **NO REMOTE DATASOURCE** |
| Update Config | `PUT /eld/config` | None | Not implemented (admin) | **NOT IMPLEMENTED** |
| Fleet Stats | `GET /eld/stats` | None | Not implemented | **NOT IMPLEMENTED** |
| Driver Score | `GET /eld/stats/driver/{driverId}` | None | Not implemented | **NOT IMPLEMENTED** |
| Dashboard Summary | `GET /eld/dashboard/summary` | `DashboardProvider` | Local aggregation | **NO REMOTE DATASOURCE** |
| Dashboard SSE | `GET /eld/dashboard/stream` | None | Not implemented | **NOT IMPLEMENTED** |
| Health Check | `GET /eld/health` | None | Not implemented | **NOT IMPLEMENTED** |
| Auth Login | `POST /api/session` | `AuthRemoteDataSource.login()` | **IMPLEMENTED** | READY |
| Auth Register | `POST /api/users` | `AuthRemoteDataSource.register()` | **IMPLEMENTED** | READY |
| Get Devices | `GET /api/devices` | `VehicleRemoteDataSource.getVehicles()` | **IMPLEMENTED** | READY |
| Get Positions | `GET /api/positions` | `TraccarApiClient.getPositions()` | **IMPLEMENTED** | READY |
| Get Events | `GET /api/events` | `TraccarApiClient.getEvents()` | **IMPLEMENTED** | READY |
| DVIR Report | None in OpenAPI (local) | `DvirProvider` | Local mock data | **LOCAL ONLY** |

---

## 9 — JSON CONTRACT DIFFERENCES

### DutyStatusRequest (Flutter vs OpenAPI `CreateDutyStatusRequest`)

**OpenAPI Schema:**
```json
{
  "driverId": 101,
  "deviceId": 1,
  "status": "DRIVING",
  "manualReason": "string",
  "clientEventId": "string"
}
```

**Flutter Current (no DTO, raw in HosNotifier):**
```dart
// hos_provider.dart:68 — no JSON sent
_engine.manualTransition(newStatus, annotation: annotation);
```

**Difference:**
| Field | Flutter | OpenAPI | Match |
|-------|---------|---------|-------|
| driverId | Not tracked | integer (required) | MISSING |
| deviceId | Not tracked | integer (required) | MISSING |
| status | `DutyStatus` enum (offDuty, sleeperBerth, onDutyNotDriving, driving, personalUse) | String enum (OFF_DUTY, SLEEPER_BERTH, ON_DUTY_NOT_DRIVING, DRIVING, PERSONAL_USE) | **NAMING MISMATCH** |
| manualReason | `annotation` (String?) | `manualReason` (String) | FIELD NAME DIFFERENT |
| clientEventId | Not tracked | String | MISSING |

### DutyStatusResponse (OpenAPI vs Flutter)

**OpenAPI Schema:**
```json
{
  "id": 1,
  "driverId": 101,
  "deviceId": 1,
  "positionId": 1,
  "status": "DRIVING",
  "driver": { "id": 101, "name": "...", ... },
  "device": { "id": 1, "name": "...", ... },
  "position": { "id": 1, "latitude": ..., ... },
  "startTime": "2026-01-01T00:00:00Z",
  "endTime": "2026-01-01T12:00:00Z",
  "latitude": 24.7136,
  "longitude": 46.6753,
  "speed": 60.0,
  "engineHours": 3500.0,
  "odometer": 150000.0,
  "source": "GPS",
  "manualReason": "string",
  "createdAt": "2026-01-01T00:00:00Z"
}
```

**Flutter Current (`DutyPeriod`):**
```json
{
  "status": "driving",
  "startTime": "2026-01-01T00:00:00",
  "endTime": "2026-01-01T12:00:00",
  "startOdometer": 150000.0,
  "endOdometer": 150100.0,
  "startLat": 24.7136,
  "startLon": 46.6753,
  "endLat": 24.7200,
  "endLon": 46.6800
}
```

**Key Differences:**
| Field | Flutter `DutyPeriod` | OpenAPI `DutyStatusResponse` | Match |
|-------|---------------------|------------------------------|-------|
| id | Not present | integer | MISSING |
| driverId | Not present | integer | MISSING |
| deviceId | Not present | integer | MISSING |
| positionId | Not present | integer | MISSING |
| status | lowercase string ("driving") | UPPER_CASE enum ("DRIVING") | **NAMING MISMATCH** |
| driver object | Not present | Nested `DriverResponse` | MISSING |
| device object | Not present | Nested `DeviceResponse` | MISSING |
| position object | Not present | Nested `PositionResponse` | MISSING |
| startTime | DateTime | ISO8601 DateTime | COMPATIBLE |
| endTime | DateTime | ISO8601 DateTime | COMPATIBLE |
| latitude | `startLat` / `endLat` (split) | Single `latitude` | **STRUCTURAL DIFFERENT** |
| longitude | `startLon` / `endLon` (split) | Single `longitude` | **STRUCTURAL DIFFERENT** |
| speed | Not present | double | MISSING |
| engineHours | Not present | double | MISSING |
| odometer | `startOdometer` / `endOdometer` (split) | Single `odometer` | **STRUCTURAL DIFFERENT** |
| source | Not present | String | MISSING |
| manualReason | Not present | String | MISSING |
| totalMinutes | Computed from Duration | Integer | **COMPUTED vs STORED** |
| distanceKm | `distanceKm` (computed) | Not in response | EXTRA IN FLUTTER |

### ComplianceSummaryResponse

**OpenAPI Schema:**
```json
{
  "driverId": 101,
  "driver": { ... },
  "complianceScore": 95.5,
  "drivingRemainingMinutes": 660,
  "dutyRemainingMinutes": 780,
  "cycleRemainingMinutes": 4200,
  "activeViolationsCount": 0,
  "status": "COMPLIANT"
}
```

**Flutter Current (`HosLimits`):**
```dart
class HosLimits {
  final int remainingDriveMinutes;    // → drivingRemainingMinutes
  final int remainingShiftMinutes;    // → dutyRemainingMinutes
  final double remainingCycleHours;   // → cycleRemainingMinutes (HOURS vs MINUTES)
  final bool breakRequired;           // → No equivalent
  final int breakDeadlineMinutes;     // → No equivalent
}
```

**Key Differences:**
| Field | Flutter `HosLimits` | OpenAPI `ComplianceSummaryResponse` | Match |
|-------|---------------------|-------------------------------------|-------|
| driverId | Not present | integer | MISSING |
| complianceScore | Not computed | double | MISSING |
| drivingRemainingMinutes | `remainingDriveMinutes` (int) | integer | COMPATIBLE |
| dutyRemainingMinutes | `remainingShiftMinutes` (int) | integer | COMPATIBLE |
| cycleRemainingMinutes | `remainingCycleHours` (double, **HOURS**) | integer (**MINUTES**) | **UNIT MISMATCH** |
| activeViolationsCount | Not computed | integer | MISSING |
| status | Not present | String enum | MISSING |

### ViolationResponse

**OpenAPI Schema:**
```json
{
  "id": 1,
  "driverId": 101,
  "deviceId": 1,
  "periodId": 1,
  "driver": { ... },
  "device": { ... },
  "period": { ... },
  "violationType": "DAILY_DRIVING_EXCEEDED",
  "severity": "HIGH",
  "actualValue": 12.5,
  "allowedLimit": 11.0,
  "referenceRule": "395.3(a)(1)",
  "detectedAt": "2026-01-01T12:00:00Z",
  "status": "ACTIVE",
  "notes": "string"
}
```

**Flutter Current (`HosViolation`):**
```dart
class HosViolation {
  final String type;        // "dailyDrivingExceeded" (camelCase)
  final ViolationLevel level; // ViolationLevel.high (enum)
  final String message;     // Human-readable message
  final String arabicMessage;
  final DateTime timestamp;
  final Map<String, dynamic>? details;
}
```

**Key Differences:**
| Field | Flutter `HosViolation` | OpenAPI `ViolationResponse` | Match |
|-------|------------------------|----------------------------|-------|
| id | Not present | integer | MISSING |
| driverId | Not present | integer | MISSING |
| deviceId | Not present | integer | MISSING |
| periodId | Not present | integer | MISSING |
| driver object | Not present | Nested | MISSING |
| device object | Not present | Nested | MISSING |
| period object | Not present | Nested | MISSING |
| violationType | camelCase string | UPPER_SNAKE_CASE | **NAMING MISMATCH** |
| severity | `ViolationLevel` enum (minor/medium/high/critical) | String (LOW/MEDIUM/HIGH/CRITICAL) | **NAMING MISMATCH** |
| actualValue | Not present | double | MISSING |
| allowedLimit | Not present | double | MISSING |
| referenceRule | Not present | String | MISSING |
| detectedAt | `timestamp` | `detectedAt` | **FIELD NAME DIFFERENT** |
| status | Not present | String enum | MISSING |
| notes | `message` + `arabicMessage` | `notes` | **STRUCTURAL DIFFERENT** |

---

## 10 — DTO REQUIREMENTS

### Required DTOs (None exist currently)

| DTO Name | Source | Destination | OpenAPI Schema | Priority |
|----------|--------|-------------|----------------|----------|
| `CreateDutyStatusRequestDto` | Flutter `HosNotifier.changeStatus()` | `POST /eld/status` | `CreateDutyStatusRequest` | HIGH |
| `DutyStatusResponseDto` | `GET /eld/status/{driverId}` | Flutter `HosNotifier` | `DutyStatusResponse` | HIGH |
| `ComplianceSummaryResponseDto` | `GET /eld/compliance/{driverId}/remaining` | Flutter `HosLimits` | `ComplianceSummaryResponse` | HIGH |
| `ViolationResponseDto` | `GET /eld/violations` | Flutter `HosViolation` list | `ViolationResponse` | HIGH |
| `DiagnosticResponseDto` | `GET /eld/diagnostics/{driverId}` | Flutter `MalfunctionEvent` | `DiagnosticResponse` | HIGH |
| `PeriodResponseDto` | `GET /eld/status/{driverId}/history` | Flutter `DutyPeriod` | `PeriodResponse` | HIGH |
| `DailySummaryDto` | `GET /eld/reports/{driverId}/daily` | Flutter `DailyLog` | `DailySummaryDTO` | MEDIUM |
| `WeeklySummaryDto` | `GET /eld/reports/{driverId}/weekly` | Flutter `RecapData` | `WeeklySummaryDTO` | MEDIUM |
| `DriverResponseDto` | Multiple endpoints | Flutter `User` | `DriverResponse` | MEDIUM |
| `DeviceResponseDto` | Multiple endpoints | Flutter `Vehicle` | `DeviceResponse` | MEDIUM |
| `PositionResponseDto` | Multiple endpoints | Flutter `LocationEntity` | `PositionResponse` | MEDIUM |
| `InspectionDetailsResponseDto` | `GET /eld/inspections/{id}` | Flutter `InspectionDayData` | `InspectionDetailsResponse` | LOW |
| `SignatureResponseDto` | `GET /eld/signatures/{driverId}` | None | `SignatureResponse` | LOW |
| `DocumentResponseDto` | `GET /eld/documents/{driverId}` | None | `DocumentResponse` | LOW |
| `DriverRuleModelDto` | `GET /eld/rules/{driverId}` | `HosConfiguration` | `DriverRuleModel` | LOW |
| `ELDConfigurationDto` | `GET /eld/config` | `HosConfiguration` | `ELDConfiguration` | LOW |

---

## 11 — MAPPER REQUIREMENTS

| Mapper | From | To | Key Transformations |
|--------|------|----|---------------------|
| `DutyStatusMapper` | `DutyStatus` enum (Flutter) | `CreateDutyStatusRequestDto.status` (OpenAPI) | `driving` → `DRIVING`, `offDuty` → `OFF_DUTY` |
| `DutyStatusResponseMapper` | `DutyStatusResponseDto` | `DutyPeriod` / `HosStatusUpdate` | Split lat/lon, compute totalMinutes, handle nested objects |
| `ViolationMapper` | `ViolationResponseDto` | `HosViolation` | `DAILY_DRIVING_EXCEEDED` → `dailyDrivingExceeded`, `HIGH` → `ViolationLevel.high` |
| `DiagnosticMapper` | `DiagnosticResponseDto` | `MalfunctionEvent` | Map diagnosticType → MalfunctionType, severity mapping |
| `ComplianceMapper` | `ComplianceSummaryResponseDto` | `HosLimits` | Convert cycleRemainingMinutes (int) → remainingCycleHours (double), compute complianceScore |
| `PeriodMapper` | `PeriodResponseDto` | `DutyPeriod` | Handle single lat/lon → split start/end, compute duration from totalMinutes |
| `VehicleMapper` | `DeviceResponseDto` | `Vehicle` | Already partially done in `VehicleRemoteDataSourceImpl` |
| `UserMapper` | `DriverResponseDto` | `User` | Not yet needed until driver profile feature |
| `ReportMapper` | `DailySummaryDto` | `DailyLog` | Map periods array, compute totalDrivingHours |
| `SessionMapper` | `DriverSessionModelDto` | None (new feature) | New feature — session management |

---

## 12 — REPOSITORY REQUIREMENTS

### Existing Repositories

| Repository | File | Has Remote? | Has Local? | Backend Ready? |
|-----------|------|-------------|------------|----------------|
| `AuthRepository` | `features/auth/domain/repositories/auth_repository.dart` | YES (Traccar) | YES (SecureStorage) | **YES** |
| `VehicleRepository` | `features/vehicle/domain/repositories/vehicle_repository.dart` | YES (Traccar) | YES (SharedPreferences) | **PARTIAL** |
| `TrackingRepository` | `features/tracking/domain/repositories/tracking_repository.dart` | YES (Native/Traccar) | YES (SharedPreferences) | **YES** |
| `LogRepository` | `features/logs/domain/repositories/log_repository.dart` | **NO** | YES (Hive) | **NO** |
| `SyncRepository` | `features/sync/domain/repositories/sync_repository.dart` | YES (Traccar) | YES (SharedPreferences) | **PARTIAL** |

### Required New Repositories

| Repository | Responsibility | Consumers | Should NOT Know |
|-----------|---------------|-----------|-----------------|
| `HosRepository` | Abstraction for HOS status operations (get/set status, remaining hours, compliance) | `HosNotifier`, `RecapProvider`, UI | Backend URL, API client, DTO details |
| `ComplianceRepository` | Abstraction for compliance evaluation and remaining hours | `HosProvider`, `DashboardProvider` | Local engine implementation details |
| `ViolationRepository` | Abstraction for violation lifecycle (get, resolve, dispute) | `DiagnosticsStateProvider`, UI | Backend API path, HTTP details |
| `DiagnosticsRepository` | Abstraction for diagnostic/malfunction operations | `DiagnosticsStateProvider`, UI | Local engine implementation |
| `ReportRepository` | Abstraction for report generation (daily, weekly, PDF, CSV) | `ReportsProvider`, `RecapProvider` | Report format details |
| `InspectionRepository` | Abstraction for inspection lifecycle | `InspectionProvider` | Backend API path |
| `SignatureRepository` | Abstraction for electronic signatures | New feature | Backend API path |
| `DocumentRepository` | Abstraction for compliance documents | New feature | Backend API path |
| `SessionRepository` | Abstraction for driver session management | New feature | Backend API path |
| `RulesRepository` | Abstraction for driver rule customization | New feature | Backend API path |

---

## 13 — REMOTEDATASOURCE REQUIREMENTS

| RemoteDataSource | Endpoints | Request DTOs | Response DTOs | Errors | Auth |
|-----------------|-----------|-------------|---------------|--------|------|
| `HosRemoteDataSource` | `POST /eld/status`, `GET /eld/status/{driverId}`, `GET /eld/status/{driverId}/history` | `CreateDutyStatusRequestDto` | `DutyStatusResponseDto` | 400, 401, 403, 500 | BasicAuth |
| `ComplianceRemoteDataSource` | `GET /eld/compliance/{driverId}/evaluate`, `GET /eld/compliance/{driverId}/remaining` | None | `ComplianceSummaryResponseDto` | 400, 401, 403, 500 | BasicAuth |
| `ViolationRemoteDataSource` | `GET /eld/violations`, `PUT /eld/violations/{id}/resolve`, `PUT /eld/violations/{id}/dispute` | None | `ViolationResponseDto` | 400, 401, 403, 404, 500 | BasicAuth |
| `DiagnosticsRemoteDataSource` | `GET /eld/diagnostics/{driverId}`, `PUT /eld/diagnostics/{id}/clear` | None | `DiagnosticResponseDto` | 400, 401, 403, 500 | BasicAuth |
| `ReportRemoteDataSource` | `POST /eld/reports/generate`, `GET /eld/reports/{driverId}/daily`, `GET /eld/reports/{driverId}/pdf` | `EldReportRequestDto` | `EldReportResponseDto` | 400, 401, 403, 500 | BasicAuth |
| `InspectionRemoteDataSource` | `POST /eld/inspections`, `GET /eld/inspections/{id}`, `PUT /eld/inspections/{id}/complete` | `StartInspectionRequestDto` | `InspectionDetailsResponseDto` | 400, 401, 403, 404, 500 | BasicAuth |
| `SignatureRemoteDataSource` | `POST /eld/signatures/{driverId}`, `GET /eld/signatures/{driverId}` | `SaveSignatureRequestDto` | `SignatureResponseDto` | 400, 401, 403, 500 | BasicAuth |
| `DocumentRemoteDataSource` | `GET /eld/documents/{driverId}`, `POST /eld/documents/{driverId}` | `UploadDocumentRequestDto` | `DocumentResponseDto` | 400, 401, 403, 404, 500 | BasicAuth |
| `RulesRemoteDataSource` | `GET /eld/rules/{driverId}`, `PUT /eld/rules/driver` | `DriverRuleModelDto` | `DriverRuleModelDto` | 400, 401, 403, 500 | BasicAuth |
| `SessionRemoteDataSource` | `POST /eld/sessions/start`, `POST /eld/sessions/switch`, `GET /eld/sessions/{driverId}` | `StartDriverSessionRequestDto` | `DriverSessionModelDto` | 400, 401, 403, 500 | BasicAuth |
| `ConfigRemoteDataSource` | `GET /eld/config`, `PUT /eld/config` | `UpdateHosConfigRequestDto` | `ELDConfigurationDto` | 400, 401, 403, 500 | BasicAuth |
| `StatsRemoteDataSource` | `GET /eld/stats`, `GET /eld/stats/driver/{driverId}` | None | Fleet/Driver stats | 400, 401, 403, 500 | BasicAuth |

---

## 14 — API CLIENT REQUIREMENTS

### Current State
- `ApiClient` (`core/network/api_client.dart`) — Generic Dio wrapper, handles HTTP methods + error mapping
- `TraccarApiClient` (`core/network/traccar/traccar_api_client.dart`) — Traccar-specific REST calls (session, devices, positions, events)
- **No ELD-specific API client exists**

### Required: `EldApiClient`

```
Responsibility:
  - All /eld/* endpoint calls
  - Request serialization (Domain → JSON)
  - Response deserialization (JSON → DTO)
  - Error handling (HTTP status → Exception)
  - Authentication headers (BasicAuth / BearerAuth)

Must NOT contain:
  - HOS business rules
  - Violation logic
  - UI logic
  - SQLite/Hive logic
  - Local engine logic
```

### Proposed Interface

```dart
abstract class EldApiClient {
  // Duty Status
  Future<Map<String, dynamic>> updateStatus(CreateDutyStatusRequestDto request);
  Future<Map<String, dynamic>> getStatus(int driverId);
  Future<List<Map<String, dynamic>>> getStatusHistory(int driverId);
  
  // Compliance
  Future<Map<String, dynamic>> evaluateCompliance(int driverId);
  Future<Map<String, dynamic>> getRemainingHours(int driverId);
  
  // Violations
  Future<List<Map<String, dynamic>>> getViolations({int? driverId});
  Future<void> resolveViolation(int id);
  Future<void> disputeViolation(int id);
  
  // Diagnostics
  Future<List<Map<String, dynamic>>> getDriverDiagnostics(int driverId);
  Future<void> clearDiagnostic(int id);
  
  // Reports
  Future<Map<String, dynamic>> generateReport(EldReportRequestDto request);
  
  // Inspections
  Future<Map<String, dynamic>> startInspection(StartInspectionRequestDto request);
  Future<Map<String, dynamic>> getInspection(int id);
  Future<void> completeInspection(int id, CompleteInspectionRequestDto request);
  
  // Signatures
  Future<void> saveSignature(int driverId, SaveSignatureRequestDto request);
  Future<List<Map<String, dynamic>>> getSignatures(int driverId);
  
  // Documents
  Future<List<Map<String, dynamic>>> getDocuments(int driverId);
  Future<void> uploadDocument(int driverId, UploadDocumentRequestDto request);
  
  // Rules
  Future<Map<String, dynamic>> getRules(int driverId);
  Future<void> updateRules(DriverRuleModelDto rules);
  
  // Sessions
  Future<Map<String, dynamic>> startSession(StartDriverSessionRequestDto request);
  Future<void> switchRole(int driverId);
  Future<Map<String, dynamic>> getSession(int driverId);
  
  // Config
  Future<Map<String, dynamic>> getConfiguration();
  Future<Map<String, dynamic>> updateConfiguration(UpdateHosConfigRequestDto config);
  
  // Stats
  Future<Map<String, dynamic>> getFleetStats();
  Future<Map<String, dynamic>> getDriverComplianceScore(int driverId);
  
  // Health
  Future<Map<String, dynamic>> checkHealth();
}
```

---

## 15 — ERROR HANDLING REQUIREMENTS

### Current Error Model
```dart
// core/error/failure.dart
abstract class Failure {
  final String message;
  final String? arabicMessage;
  final int? statusCode;
}

// Subtypes: ServerFailure, NetworkFailure, AuthFailure, CacheFailure,
//           PermissionFailure, TrackingFailure, SyncFailure, ValidationFailure
```

### OpenAPI Error Responses
All endpoints return:
- `400` — Bad Request
- `401` — Unauthorized
- `403` — Forbidden
- `500` — Internal Server Error
- `404` — Not Found (some endpoints)

### Gap Analysis

| Error Type | Flutter Has | OpenAPI Requires | Action Needed |
|-----------|-------------|------------------|---------------|
| 400 Bad Request | `ServerFailure` (generic) | Specific field errors | Add `ValidationFailure` with field-level details |
| 401 Unauthorized | `AuthFailure` | Session expired | Already handled |
| 403 Forbidden | `ServerFailure` (403) | Permission denied | Add `ForbiddenFailure` |
| 404 Not Found | Not handled | Resource not found | Add `NotFoundFailure` |
| 500 Server Error | `ServerFailure` | Internal error | Already handled |

---

## 16 — TIME/TIMEZONE REQUIREMENTS

### Current State
- `UtcSyncService` (`core/services/utc_sync_service.dart`) — Calculates drift between local and UTC
- `TraccarMapper._parseUtcDate()` — Forces parsed dates to UTC
- `DutyStatusTracker._now()` — Uses `DateTime.now()` (local time)
- `HosCalculator` — Uses `DateTime.now()` for limit calculations

### OpenAPI Requirements
- All timestamps in OpenAPI use ISO 8601 UTC format (`2026-01-01T12:00:00Z`)
- `fixTime` in `PositionResponse` is UTC
- `startTime`, `endTime`, `detectedAt`, `signedAt` — all UTC

### Gaps

| Component | Current Behavior | Required | Impact |
|-----------|-----------------|----------|--------|
| `DutyStatusTracker._now()` | `DateTime.now()` (local) | UTC for backend sync | **HIGH** — status timestamps must match backend |
| `HosCalculator` | Local time for calculations | UTC consistency | **MEDIUM** — could cause 1-hour drift |
| `HosStateMachine._shiftStartTime` | Local time | UTC for backend | **HIGH** |
| `DutyPeriod.startTime/endTime` | Local time | UTC for backend | **HIGH** — period boundaries must match |
| `HosViolation.timestamp` | Local time | UTC | **MEDIUM** |
| `MalfunctionEvent.timestamp` | `DateTime.now()` | UTC | **MEDIUM** |

---

## 17 — ENUM REQUIREMENTS

### Flutter Enums vs OpenAPI Enums

| Domain | Flutter Enum | OpenAPI Enum | Mapping Required |
|--------|-------------|--------------|------------------|
| Duty Status | `DutyStatus.offDuty` | `OFF_DUTY` | `offDuty` → `OFF_DUTY` |
| Duty Status | `DutyStatus.sleeperBerth` | `SLEEPER_BERTH` | `sleeperBerth` → `SLEEPER_BERTH` |
| Duty Status | `DutyStatus.onDutyNotDriving` | `ON_DUTY_NOT_DRIVING` | `onDutyNotDriving` → `ON_DUTY_NOT_DRIVING` |
| Duty Status | `DutyStatus.driving` | `DRIVING` | `driving` → `DRIVING` |
| Duty Status | `DutyStatus.personalUse` | `PERSONAL_USE` | `personalUse` → `PERSONAL_USE` |
| Violation Type | `HosViolationType.dailyDrivingExceeded` | `DAILY_DRIVING_EXCEEDED` | camelCase → UPPER_SNAKE |
| Violation Level | `ViolationLevel.minor` | `LOW` | **NAME MISMATCH** |
| Violation Level | `ViolationLevel.medium` | `MEDIUM` | COMPATIBLE |
| Violation Level | `ViolationLevel.high` | `HIGH` | COMPATIBLE |
| Violation Level | `ViolationLevel.critical` | `CRITICAL` | COMPATIBLE |
| Malfunction Type | `MalfunctionType.dataGap` | `DATA_GAP` | camelCase → UPPER_SNAKE |
| Malfunction Severity | `MalfunctionSeverity.minor` | `INFO` | **NAME MISMATCH** |
| Malfunction Severity | `MalfunctionSeverity.major` | `WARNING` | **NAME MISMATCH** |
| Malfunction Severity | `MalfunctionSeverity.critical` | `CRITICAL` | COMPATIBLE |
| Transfer Method | `TransferMethod.webService` | `WEB_SERVICE` | camelCase → UPPER_SNAKE |
| Vehicle Condition | `VehicleCondition.safe` | Not in OpenAPI | LOCAL ONLY |
| Inspection Type | `InspectionType.preTrip` | `PRE_TRIP` | camelCase → UPPER_SNAKE |
| Tracking Source | `TrackingEventSource.gps` | `GPS` | COMPATIBLE |

---

## 18 — ID REQUIREMENTS

### Current State
- Flutter uses `String` IDs everywhere (e.g., `DateTime.now().millisecondsSinceEpoch.toString()`)
- OpenAPI uses `int64` (integer) IDs for all entities

### ID Mapping Required

| Entity | Flutter ID Type | OpenAPI ID Type | Conversion Needed |
|--------|----------------|-----------------|-------------------|
| Driver | String (from Traccar user) | int64 | `String` → `int.parse()` |
| Device/Vehicle | String (uniqueId) | int64 | `String` → `int.parse()` |
| Duty Status Record | Not tracked | int64 | NEW |
| Violation | Not tracked | int64 | NEW |
| Diagnostic | Not tracked | int64 | NEW |
| Period | Not tracked | int64 | NEW |
| Inspection | String (mock) | int64 | `String` → `int.parse()` |
| Signature | Not tracked | int64 | NEW |
| Document | Not tracked | int64 | NEW |

---

## 19 — UNIT REQUIREMENTS

| Field | Flutter Current | OpenAPI Expected | Conversion |
|-------|----------------|------------------|------------|
| `remainingCycleHours` | `double` (hours) | `int` (minutes) | `* 60` |
| Speed | `speedMph` (mph) in `EldEvent` | `speedKmh` (km/h) in OpenAPI | `* 1.609` |
| Distance | `distanceKm` (km) | `distanceKm` (km) | COMPATIBLE |
| Odometer | `odometerMiles` (miles) in `EldEvent` | `odometer` (km) in OpenAPI | `* 1.609` |
| Duration | `Duration` (Dart) | `totalMinutes` (int) | `.inMinutes` |
| Engine Hours | `double` (hours) | `double` (hours) | COMPATIBLE |

---

## 20 — OFFLINE REQUIREMENTS

### Current Offline Support
- `SyncEngine` with `OfflineQueue` (SQLite + Memory implementations)
- `SyncItem` with retry logic and exponential backoff
- `TraccarRemoteEventDispatcher` sends to `/api/events`
- `MemoryOfflineQueue` and `SQLiteOfflineQueue` implementations

### What's Missing for Backend Integration

| Feature | Status | Required |
|---------|--------|----------|
| Duty status change queue | Not implemented | `SyncEventType.statusChange` exists but not wired |
| Violation sync queue | Not implemented | Need `SyncEventType.violation` |
| Diagnostic sync queue | Not implemented | Need `SyncEventType.diagnostic` |
| Period sync queue | Not implemented | Need `SyncEventType.period` |
| Conflict resolution | Not implemented | Backend may override local state |
| Last-write-wins | Not implemented | For offline → online merge |

---

## 21 — CACHE REQUIREMENTS

### Current Cache Layers
1. **Hive** — Events, Periods, Diagnostics, Violations, Audit (date-keyed)
2. **SharedPreferences** — Tracking config, settings, sync queue
3. **SecureStorage** — Auth session, password

### Backend Cache Needs

| Data | Current Cache | Backend Cache Needed | Strategy |
|------|--------------|---------------------|----------|
| Duty Status | In-memory only | Cache last known status | SharedPreferences + Backend fallback |
| Compliance Hours | Computed on-demand | Cache from backend | Repository-level cache |
| Violations | Hive (local) | Backend is source of truth | Repository merges local + remote |
| Diagnostics | Hive (local) | Backend is source of truth | Repository merges local + remote |
| Reports | Generated locally | Backend generates | Remote-first, local fallback |
| Config | Hardcoded | Backend is source of truth | Fetch on login, cache locally |

---

## 22 — SYNC REQUIREMENTS

### Current Sync Architecture
```
SyncItem (statusChange, locationUpdate, dvirReport, certifyLog, inspectionReport)
  ↓
SyncRepositoryImpl.enqueue()
  ↓
SyncLocalDataSource (SharedPreferences)
  ↓
processQueue() → TraccarRemoteEventDispatcher → POST /api/events
```

### Required Sync Extensions

| Sync Type | OpenAPI Endpoint | Current Status | Priority |
|-----------|-----------------|----------------|----------|
| Duty Status Change | `POST /eld/status` | `SyncEventType.statusChange` exists, **not wired** | HIGH |
| Period Save | Implicit in status | Not in sync queue | HIGH |
| Violation Detected | `GET /eld/violations` (read) | Not in sync queue | MEDIUM |
| Diagnostic Detected | `GET /eld/diagnostics` (read) | Not in sync queue | MEDIUM |
| Log Certification | `POST /eld/signatures/{driverId}` | `SyncEventType.certifyLog` exists | MEDIUM |
| DVIR Submit | `POST /eld/inspections` | `SyncEventType.dvirReport` exists | LOW |
| Config Fetch | `GET /eld/config` | Not in sync | HIGH (on login) |
| Rules Fetch | `GET /eld/rules/{driverId}` | Not in sync | MEDIUM (on login) |

---

## 23 — RECONCILIATION REQUIREMENTS

### Current State
No reconciliation logic exists. The app assumes local state is authoritative.

### Future Requirements

| Scenario | Local State | Backend State | Resolution |
|----------|-------------|---------------|------------|
| Status changed offline | `driving` | `off_duty` | Backend wins (authoritative) |
| Violation detected offline | Stored in Hive | Not yet received | Send to backend on reconnect |
| Period saved offline | Hive | Not yet received | Send to backend on reconnect |
| Config changed on backend | Local `HosConfiguration` | New config from `GET /eld/config` | Backend wins, update local |
| Rules changed on backend | Local rules | New rules from `GET /eld/rules/{driverId}` | Backend wins, update local |

---

## 24 — TARGET ARCHITECTURE

```
                    ┌─────────────────────────────┐
                    │       PRESENTATION          │
                    │  (Pages, Widgets, Providers) │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │       APPLICATION           │
                    │  (UseCases, Notifiers)       │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │         DOMAIN              │
                    │  (Entities, Repositories)    │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │       REPOSITORIES          │
                    │  (Abstraction Boundary)      │
                    └──────┬───────────────┬──────┘
                           │               │
              ┌────────────▼──┐    ┌───────▼────────────┐
              │ LOCAL ENGINE  │    │  REMOTE DATASOURCE  │
              │ (Existing)    │    │  (New)              │
              │               │    │                     │
              │ HosCalculator │    │ HosRemoteDS         │
              │ HosRulesEngine│    │ ComplianceRemoteDS  │
              │ HosStateMachine│   │ ViolationRemoteDS   │
              │ HosViolations │    │ DiagnosticsRemoteDS │
              │ Diagnostics   │    │ ReportRemoteDS      │
              │ DutyTracker   │    │ InspectionRemoteDS  │
              │ DistanceTracker│   │ SignatureRemoteDS   │
              └───────┬───────┘    │ DocumentRemoteDS    │
                      │            │ RulesRemoteDS       │
                      │            │ SessionRemoteDS     │
              ┌───────▼───────┐    │ ConfigRemoteDS      │
              │ LOCAL STORAGE │    │ StatsRemoteDS       │
              │ Hive/SharedPref│   └──────────┬─────────┘
              └───────────────┘               │
                                    ┌─────────▼─────────┐
                                    │   ELD API CLIENT   │
                                    │  (Dio + Interceptor)│
                                    └─────────┬─────────┘
                                              │
                                    ┌─────────▼─────────┐
                                    │     BACKEND        │
                                    │  (Traccar + ELD)   │
                                    └───────────────────┘
```

### Key Design Principles

1. **Repository is the boundary** — UI/Application never talks to RemoteDataSource directly
2. **Local engines remain untouched** — They continue to work exactly as today
3. **RemoteDataSource is additive** — New layer, no modification to existing code
4. **DTOs are only at the boundary** — Between RemoteDataSource and API Client
5. **Mappers are only at the boundary** — Between DTOs and Domain entities
6. **Backend is optional** — App works fully without backend connection

---

## 25 — RESPONSIBILITY BOUNDARIES

| Layer | Responsibility | Must NOT |
|-------|---------------|----------|
| Presentation | Display data, handle user input | Call repositories directly, contain business logic |
| Application | Orchestrate use cases, manage UI state | Know about API endpoints, HTTP, or SQLite |
| Domain | Define entities, repository interfaces, use cases | Know about Dio, Hive, SharedPreferences |
| Repository | Abstract data source selection (local vs remote) | Contain business rules, UI logic |
| Local Engine | Compute HOS, violations, diagnostics locally | Know about backend, HTTP, API |
| RemoteDataSource | Fetch/send data from/to backend | Contain business logic, know about Hive |
| API Client | HTTP communication, serialization | Know about domain entities, business rules |
| DTO | Data transfer shape matching OpenAPI | Contain business logic |
| Mapper | Transform between DTO ↔ Domain | Contain business logic |

---

## 26 — ISOLATION PLAN

### Local Engine Isolation Strategy

**Goal:** Each local engine should produce a `Domain Result` without knowing about Backend, HTTP, or SQLite.

```
CURRENT:
  HosRulesEngine → state (in-memory) → HosNotifier → UI
  HosViolationsEngine → Hive (direct write) + Stream
  DiagnosticsEngine → Hive (direct write) + Stream
  DutyStatusTracker → LogRepository.savePeriod() → Hive

TARGET:
  HosRulesEngine → HosStatusUpdate (unchanged)
  HosViolationsEngine → Stream<HosViolation> (unchanged, but remove direct DB write)
  DiagnosticsEngine → Stream<DiagnosticsState> (unchanged, but remove direct DB write)
  DutyStatusTracker → Stream<DutyTransition> (unchanged, but remove direct DB write)
```

### Isolation Steps (READ-ONLY suggestions)

1. **HosViolationsEngine** — Remove `_localDb.saveViolation()` call. Instead, emit violations via Stream only. Let the consumer (Repository/Provider) decide persistence.

2. **DiagnosticsEngine** — Remove `_localDb.saveDiagnostic()` call. Instead, emit malfunctions via Stream only.

3. **DutyStatusTracker** — Remove `_logRepository.savePeriod()` call from `_transitionTo()`. Instead, emit `DutyTransition` with full period data. Let the consumer decide persistence.

4. **HosStateMachine** — Add optional persistence callback instead of relying on in-memory state only.

---

## 27 — MIGRATION PLAN

### Phase 0: AUDIT ✅ (Current)
- Understand current architecture
- Map all data flows
- Identify coupling points
- Document OpenAPI contract

### Phase 1: ISOLATE LOCAL ENGINES (READ-ONLY suggestions)
- Remove direct DB writes from engines
- Engines emit via Streams only
- No behavior change

### Phase 2: INTRODUCE DOMAIN INTERFACES
- Create `HosRepository` interface
- Create `ComplianceRepository` interface
- Create `ViolationRepository` interface
- Create `DiagnosticsRepository` interface
- Create `ReportRepository` interface

### Phase 3: INTRODUCE DTOs
- Create all request/response DTOs matching OpenAPI schemas
- Create enum mappers (Flutter enums ↔ OpenAPI enums)

### Phase 4: INTRODUCE REMOTEDATASOURCES
- Create `HosRemoteDataSource`
- Create `ComplianceRemoteDataSource`
- Create `ViolationRemoteDataSource`
- Create `DiagnosticsRemoteDataSource`
- Create `ReportRemoteDataSource`

### Phase 5: CONNECT API CLIENT
- Create `EldApiClient` using existing `ApiClient` (Dio)
- Add to `network_providers.dart`
- Implement all `/eld/*` endpoints

### Phase 6: BACKEND INTEGRATION
- Implement `HosRepositoryImpl` with local + remote strategy
- Wire into providers
- Test offline/online switching

### Phase 7: VALIDATION
- Compare local engine results with backend results
- Verify data consistency
- Test edge cases

### Phase 8: SWITCH AUTHORITY
- Backend becomes source of truth for compliance
- Local engines become fallback/offline

### Phase 9: OPTIONAL LOCAL ENGINE REDUCTION (Only if needed)
- Reduce local computation if backend is always available
- Keep as offline fallback

---

## 28 — MIGRATION READINESS MATRIX

| Component | Current State | Target Layer | Backend Dependency | Isolation Needed | Migration Difficulty | Risk |
|-----------|--------------|--------------|-------------------|-----------------|---------------------|------|
| HosCalculator | Local engine | Local Engine | None | NO | None | LOW |
| HosRulesEngine | Local engine | Local Engine | None | NO | None | LOW |
| HosStateMachine | Local engine | Local Engine | None | PARTIAL | LOW | LOW |
| HosViolationsEngine | Local engine + Hive write | Local Engine | None | YES (remove DB write) | MEDIUM | MEDIUM |
| DiagnosticsEngine | Local engine + Hive write | Local Engine | None | YES (remove DB write) | MEDIUM | MEDIUM |
| DutyStatusTracker | Local engine + Hive write | Local Engine | None | YES (remove DB write) | MEDIUM | MEDIUM |
| DistanceTracker | Local engine | Local Engine | None | NO | None | LOW |
| HosProvider | Presentation | Presentation | None | NO | None | LOW |
| HosConfiguration | Config | Config | Backend (future) | NO | LOW | LOW |
| LogRepository | Local data | Data | None (local only) | NO | None | LOW |
| TrackingRepository | Local + Remote (Traccar) | Data | Traccar | NO | None | LOW |
| VehicleRepository | Local + Remote (Traccar) | Data | Traccar | NO | None | LOW |
| AuthRepository | Remote (Traccar) | Data | Traccar | NO | None | LOW |
| SyncRepository | Local + Remote (Traccar) | Data | Traccar | NO | None | LOW |
| ApiClient | Infrastructure | Infrastructure | None | NO | None | LOW |
| EldApiClient | **MISSING** | Infrastructure | Backend | N/A | HIGH | HIGH |
| HosRemoteDataSource | **MISSING** | Remote Data | Backend | N/A | HIGH | HIGH |
| ComplianceRemoteDataSource | **MISSING** | Remote Data | Backend | N/A | HIGH | HIGH |
| ViolationRemoteDataSource | **MISSING** | Remote Data | Backend | N/A | HIGH | HIGH |
| DiagnosticsRemoteDataSource | **MISSING** | Remote Data | Backend | N/A | HIGH | HIGH |
| ReportRemoteDataSource | **MISSING** | Remote Data | Backend | N/A | HIGH | HIGH |
| DTOs | **MISSING** | Data | None | N/A | HIGH | HIGH |
| Mappers | **1 exists (TraccarMapper)** | Data | None | N/A | HIGH | HIGH |
| HosRepository | **MISSING** | Domain | None | N/A | HIGH | HIGH |

---

## 29 — RISK MATRIX

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Backend response format differs from OpenAPI | MEDIUM | HIGH | Validate with actual backend before implementing DTOs |
| Local engine behavior diverges from backend | HIGH | HIGH | Keep local engines, use backend as validation |
| UTC timezone mismatch causes 1-hour errors | MEDIUM | HIGH | Standardize all timestamps to UTC early |
| ID type mismatch (String vs int64) | HIGH | MEDIUM | Create ID mapping layer |
| Unit mismatch (mph vs km/h, hours vs minutes) | HIGH | MEDIUM | Create unit conversion layer |
| Offline/online state conflict | MEDIUM | HIGH | Design reconciliation strategy before integration |
| Breaking existing app during integration | LOW | CRITICAL | Additive changes only, never modify existing code |
| OpenAPI spec changes | MEDIUM | MEDIUM | DTOs act as buffer, only mapper needs update |

---

## 30 — MUST CHANGE

These changes are **required** to enable backend integration. They are additive and must not break existing behavior.

### 1. Remove Direct DB Writes from Local Engines

**Files Affected:**
- `lib/core/engine/hos_violations_engine.dart:85` — `_localDb.saveViolation(violation.toJson())`
- `lib/core/engine/diagnostics/diagnostics_engine.dart:140` — `_localDb.saveDiagnostic(event.toJson())`
- `lib/core/engine/tracking/duty_status_tracker.dart:145` — `_logRepository.savePeriod(period)`

**Change:** Replace direct persistence with Stream emission. Let the Repository/Provider handle persistence.

**Current:**
```dart
// hos_violations_engine.dart:85
_localDb.saveViolation(violation.toJson()).then((result) { ... });
```

**Target:**
```dart
// Emit via stream, let consumer decide
_violationsController.add(_violations);
// Remove direct DB write
```

### 2. Create Repository Interfaces for HOS Domains

**New Files:**
- `lib/features/hos/domain/repositories/hos_repository.dart`
- `lib/features/compliance/domain/repositories/compliance_repository.dart` (new feature)
- `lib/features/violations/domain/repositories/violation_repository.dart` (new feature)

### 3. Create DTO Layer

**New Files:** (all in `lib/core/network/dto/` or per-feature `data/dto/`)
- `create_duty_status_request_dto.dart`
- `duty_status_response_dto.dart`
- `compliance_summary_response_dto.dart`
- `violation_response_dto.dart`
- `diagnostic_response_dto.dart`
- `period_response_dto.dart`
- `daily_summary_dto.dart`
- `weekly_summary_dto.dart`
- `eld_report_request_dto.dart`
- `eld_report_response_dto.dart`

### 4. Create EldApiClient

**New File:** `lib/core/network/eld/eld_api_client.dart`

### 5. Create RemoteDataSources

**New Files:**
- `lib/features/hos/data/datasources/hos_remote_data_source.dart`
- `lib/features/compliance/data/datasources/compliance_remote_data_source.dart`
- `lib/features/violations/data/datasources/violation_remote_data_source.dart`
- `lib/features/diagnostics/data/datasources/diagnostics_remote_data_source.dart`
- `lib/features/reports/data/datasources/report_remote_data_source.dart`

---

## 31 — SHOULD CHANGE

These are recommended improvements that make integration easier but are not blocking.

### 1. Standardize All Timestamps to UTC

**Files Affected:**
- `lib/core/engine/tracking/duty_status_tracker.dart` — `_now()` returns local time
- `lib/core/engine/hos_state_machine.dart` — `_shiftStartTime` uses local time
- `lib/core/engine/hos_violations_engine.dart` — `DateTime.now()` for timestamps

### 2. Add `driverId` and `deviceId` to Engine Context

**Files Affected:**
- `lib/core/engine/hos_rules_engine.dart` — No driver/device tracking
- `lib/core/engine/hos_state_machine.dart` — No driver/device tracking

### 3. Create Unit Conversion Utilities

**New File:** `lib/core/utils/unit_converter.dart`
- `mphToKmh(double mph)` → `double`
- `kmhToMph(double kmh)` → `double`
- `hoursToMinutes(double hours)` → `int`
- `minutesToHours(int minutes)` → `double`
- `milesToKm(double miles)` → `double`

### 4. Standardize Enum Serialization

**New File:** `lib/core/utils/enum_serializer.dart`
- `DutyStatus` → OpenAPI string mapping
- `HosViolationType` → OpenAPI string mapping
- `ViolationLevel` → OpenAPI string mapping
- `MalfunctionType` → OpenAPI string mapping

---

## 32 — MUST NOT CHANGE

### Absolute Prohibitions

| Item | File(s) | Reason |
|------|---------|--------|
| HosCalculator logic | `core/engine/hos_calculator.dart` | FMCSA rule implementation, must remain identical |
| HosRulesEngine logic | `core/engine/hos_rules_engine.dart` | Alert/violation detection logic |
| HosStateMachine transitions | `core/engine/hos_state_machine.dart` | Duty status state management |
| DutyStatus enum values | `core/engine/hos_models.dart` | All UI depends on these |
| EldEvent structure | `core/engine/hos_models.dart` | All engines depend on this |
| DutyPeriod structure | `core/engine/hos_models.dart` | All persistence depends on this |
| UI pages and widgets | All `presentation/` files | Explicitly out of scope |
| Local database schema | `core/services/local_database_service.dart` | Existing data must remain accessible |
| Existing repository interfaces | All `domain/repositories/` files | Other code depends on them |
| Existing RemoteDataSources | `auth_remote_data_source.dart`, `vehicle_remote_data_source.dart` | Already working with Traccar |
| TraccarMapper | `tracking/data/mappers/traccar_mapper.dart` | Already working |
| Auth flow | `features/auth/` | Already working with Traccar |
| Tracking flow | `features/tracking/` | Already working with Traccar |
| SyncEngine | `features/sync/domain/usecases/sync_engine.dart` | Already working |

---

## 33 — MIGRATION BLOCKERS

### Hard Blockers (Must resolve before integration)

| Blocker | Description | Resolution |
|---------|-------------|------------|
| No `driverId` in local engines | HOS engines don't track which driver is using them | Add driver context to engine initialization |
| No `deviceId` in local engines | No way to associate status changes with a device | Add device context to engine |
| Status timestamps are local time | Backend expects UTC | Standardize to UTC |
| Cycle hours in wrong units | `HosLimits.remainingCycleHours` is double (hours), backend returns int (minutes) | Add conversion in mapper |
| No backend API client for `/eld/*` | Only Traccar REST client exists | Create `EldApiClient` |
| No DTOs | No data transfer objects matching OpenAPI | Create all DTOs |
| Local engines write directly to DB | Can't redirect to backend | Remove direct writes, use Streams |

### Soft Blockers (Can work around)

| Blocker | Description | Workaround |
|---------|-------------|------------|
| OpenAPI IDs are int64, Flutter uses String | ID type mismatch | Create mapping layer |
| Enum naming conventions differ | camelCase vs UPPER_SNAKE | Create enum serializers |
| Speed units differ (mph vs km/h) | `EldEvent.speedMph` vs OpenAPI `speedKmh` | Create conversion utility |
| Odometer units differ (miles vs km) | `EldEvent.odometerMiles` vs OpenAPI `odometer` | Create conversion utility |

---

## 34 — FUTURE BACKEND CONNECTION PROCEDURE

### Step-by-Step Connection Process

**Prerequisites:** All MUST CHANGE items completed.

```
Step 1: Create EldApiClient
  File: lib/core/network/eld/eld_api_client.dart
  Uses: Existing ApiClient (Dio)
  Endpoints: All /eld/* endpoints from OpenAPI

Step 2: Create DTOs
  Files: lib/core/network/dto/*.dart
  Matching: All OpenAPI schemas

Step 3: Create Mappers
  Files: lib/core/network/dto/*_mapper.dart
  Logic: Flutter enum ↔ OpenAPI string, unit conversion

Step 4: Create RemoteDataSources
  Files: lib/features/*/data/datasources/*_remote_data_source.dart
  Each: Calls EldApiClient, returns DTOs

Step 5: Create Repository Interfaces
  Files: lib/features/*/domain/repositories/*_repository.dart
  Each: Abstract class with methods matching backend capabilities

Step 6: Create Repository Implementations
  Files: lib/features/*/data/repositories/*_repository_impl.dart
  Each: Combines LocalEngine + RemoteDataSource
  Strategy: Online → backend first, fallback to local
           Offline → local first, queue for sync

Step 7: Wire into Providers
  Files: lib/features/*/presentation/providers/*_provider.dart
  Change: Watch Repository instead of Engine directly

Step 8: Test
  - Verify local behavior unchanged when backend is offline
  - Verify backend data when online
  - Verify sync queue processes correctly
  - Verify conflict resolution
```

### What Can Be Prepared NOW (Without Backend Running)

| Item | Can Prepare? | Effort |
|------|-------------|--------|
| EldApiClient interface | YES | LOW |
| DTOs (based on OpenAPI) | YES | MEDIUM |
| Mappers (enum mapping) | YES | LOW |
| Repository interfaces | YES | LOW |
| RemoteDataSource interfaces | YES | LOW |
| Unit conversion utilities | YES | LOW |
| UTC timestamp standardization | YES | LOW |
| Remove direct DB writes from engines | YES | MEDIUM |
| Error model extensions | YES | LOW |

### What CANNOT Be Prepared Without Backend

| Item | Reason |
|------|--------|
| Actual API responses | Need to verify with real backend |
| Authentication flow for ELD endpoints | Need to test with real auth |
| SSE stream format | Need to test with real endpoint |
| Binary report formats (PDF, XML) | Need to test with real backend |
| File upload endpoints | Need to test with real backend |
| Error response format | Need to verify with real backend |

---

## 35 — FINAL VERDICT

### Current State Summary

The Golden Feather ELD application has a **well-structured local engine architecture** that correctly implements FMCSA HOS rules. The codebase follows Clean Architecture principles with feature-first organization and Riverpod dependency injection.

**Strengths:**
- 7 local engines fully implementing HOS/Compliance/Diagnostics
- Clean repository interfaces for key features
- Existing Traccar integration proves remote data source pattern works
- `TrackingEventProcessor` already serves as a mapper layer
- `TraccarMapper` proves the mapper pattern is established
- `HosConfiguration` is parameterized and can be driven by backend
- `SyncEngine` with retry logic already exists

**Critical Gaps:**
- **0 DTOs** matching OpenAPI schemas
- **0 ELD API clients** for `/eld/*` endpoints
- **0 RemoteDataSources** for HOS/Compliance/Violations/Diagnostics/Reports
- **0 Repository abstractions** for HOS (UI calls engine directly)
- Local engines write directly to DB (can't redirect to backend)
- No `driverId`/`deviceId` context in engines
- Timestamps are local time, not UTC
- Unit mismatches (mph vs km/h, hours vs minutes)

### The One-Line Answer

> **If we want to run the real backend in one month, we must create: 1 EldApiClient, ~15 DTOs, ~10 Mappers, ~5 RemoteDataSources, ~5 Repository interfaces, and remove 3 direct DB writes from local engines — all without touching any existing UI, engine logic, or business rules.**

### Effort Estimate

| Phase | Effort | Dependencies |
|-------|--------|-------------|
| Remove DB writes from engines | 1-2 days | None |
| Create DTOs + Mappers | 3-5 days | OpenAPI spec (already exists) |
| Create EldApiClient | 2-3 days | Existing ApiClient |
| Create RemoteDataSources | 3-5 days | EldApiClient + DTOs |
| Create Repository interfaces | 1-2 days | None |
| Create Repository implementations | 3-5 days | RemoteDataSources + Local Engines |
| Wire into providers | 2-3 days | Repository implementations |
| Testing + Validation | 3-5 days | All above |
| **TOTAL** | **15-25 days** | |

### What Will NOT Change

- All UI pages and widgets
- All local engine calculation logic
- All existing providers (they will be extended, not replaced)
- All existing repository interfaces
- All existing remote data sources (Traccar)
- All existing persistence layers (Hive, SharedPreferences, SecureStorage)
- The app's ability to work offline without backend

---

*This report was generated as a READ-ONLY forensic audit. No source code was modified.*
