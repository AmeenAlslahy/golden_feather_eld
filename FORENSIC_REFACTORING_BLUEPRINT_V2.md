# FORENSIC REFACTORING BLUEPRINT V2 - GOLDEN FEATHER ELD

## 1. Executive Summary
This document serves as the Reconstructed Refactoring Blueprint for the Golden Feather ELD application. It is based strictly on the **actual current codebase state** rather than relying solely on historical reports. The objective is to define a minimal-risk, evidence-driven refactoring path that corrects architectural boundaries without compromising existing behavior, particularly concerning offline capabilities, HOS tracking, and native integrations.

## 2. Current Repository State
The current codebase exhibits a mix of newly applied fixes and persistent architectural issues. A forensic sweep confirms that while some issues have been partially addressed, others remain deeply embedded.

| Component | Status | Note |
|-----------|--------|------|
| HOS Engine | Active | Core calculation logic in `domain/engine`. Exposes UI side-effects via `hosStatusProvider`. |
| Auth Layer | Active | `AuthRemoteDataSourceImpl` uses `rawDioProvider` directly. |
| Networking | Fragmented | Mixture of `ApiClient` and raw `Dio`. |
| Storage | Active | Managed by `LocalStorageService` and specialized stores (`AuthSessionStore`). |

## 3. Previously Reported Findings — Current Status

| Previous Finding | Current Code Status | Evidence | Still Requires Refactor? |
|-----------------|---------------------|----------|-------------------------|
| Router tracking listener | STILL VALID | `lib/app.dart:23` listens to `hosStatusProvider` and triggers SnackBars. | YES (UI Leakage) |
| Auth raw Dio | STILL VALID | `AuthRemoteDataSourceImpl` uses `rawDioProvider`. | YES |
| HOS speed rule coupling | STILL VALID | `HosRulesEngine` directly handles speed thresholds logic. | YES |
| Core -> Feature Dependency | STILL VALID | `remote_config_service.dart` imports feature providers. | YES |

## 4. Already Resolved Issues
- **Missing Imports:** `remote_config_service.dart`, `file_sharing_service.dart`, and `app.dart` have been corrected and compile successfully.

## 5. Remaining Confirmed Issues
- **Core to Feature Leakage:** Multiple files in `lib/core/services/` and `lib/core/network/` import and depend directly on feature layers (e.g., `tracking_service.dart`, `auth_interceptor.dart`).
- **Domain Contamination & UI Side Effects:** `hosStatusProvider` orchestrates global UI side effects directly in `app.dart`.
- **Infrastructure Bypass:** `traccarAuthRemoteDataSourceProvider` bypasses standard `ApiClient` configuration in favor of raw `Dio` injections.

## 6. Newly Discovered Issues
- **Provider Over-responsibility:** `hos_provider.dart` handles both state management and direct tracking service synchronization.
- **Dependency Inversion Violation:** `network_providers.dart` depends on concrete implementations of Traccar clients rather than abstract definitions.

## 7. Current Actual Architecture
```text
Core
 ├─ Network (Depends on Features)
 ├─ Services (Depends on Features)
 └─ Widgets

Features
 ├─ Auth (Uses Raw Dio)
 ├─ HOS (Exposes UI side effects to App)
 └─ Tracking (Coupled with HOS)
```

## 8. Architectural Root Causes
- **Convenience Over Design:** Core services were built to directly read feature states (e.g., `remote_config_service` reading `trackingServiceProvider`) instead of using event streams or abstracted repositories.
- **Global Listeners:** The need for automatic tracking updates led to placing listeners at the highest widget level (`app.dart`), creating tight coupling.

## 9. Target Architecture
```text
Core
 ├─ Network (Independent, Abstracted)
 ├─ Services (Independent)
 └─ Widgets

Features
 ├─ Auth (Uses standard ApiClient)
 ├─ HOS (Pure domain, decoupled from UI side-effects)
 └─ Tracking (Independent, orchestrates via domain events)
```

## 10. Refactoring Principles
- **Correct the boundaries, not rebuild the application.**
- Behavior Preservation > Architectural Beauty.
- Current Code > Old Reports.
- Minimal Safe Change > Large Redesign.

## 11. Finding → Phase Mapping
1. **Core -> Feature Leakage** → Phase 1
2. **Auth Raw Dio Bypass** → Phase 2
3. **Global UI Side Effects (Router/App)** → Phase 3

## 12. Refactoring Dependency Graph
`Phase 1 (Core Decoupling)` -> `Phase 2 (Auth Abstraction)` -> `Phase 3 (UI Side Effect Isolation)`

## 13. Phase Plan
- **Phase 1:** Core Network & Services Decoupling
- **Phase 2:** Auth Layer Network Standardization
- **Phase 3:** HOS & Tracking UI Side-effect Isolation

## 14. Detailed Phase Specifications

### PHASE 1: Core Network & Services Decoupling
**Validated Findings:** Core services depend on feature providers.
**Current State:** `remote_config_service.dart` and network providers import `features/`.
**Target State:** Core relies on abstractions or dependency injection without explicit feature imports.
**Exact Files To Modify:** 
- `lib/core/services/remote_config_service.dart`
- `lib/core/network/network_providers.dart`
**Behavioral Invariants:** Configuration fetching behaves identically.
**Safe Gate:** `flutter analyze` passes, no runtime DI errors.

### PHASE 2: Auth Layer Network Standardization
**Validated Findings:** Auth uses raw Dio.
**Current State:** `AuthRemoteDataSourceImpl` uses `rawDioProvider`.
**Target State:** Auth uses `ApiClient` or a dedicated abstracted network client without raw Dio exposure.
**Exact Files To Modify:** 
- `lib/features/auth/data/datasources/auth_remote_data_source.dart`
- `lib/features/auth/presentation/providers/auth_providers.dart`
**Behavioral Invariants:** Login/Register/Logout logic handles tokens exactly the same.
**Safe Gate:** Login flow succeeds, tokens are preserved.

### PHASE 3: HOS & Tracking UI Side-effect Isolation
**Validated Findings:** `app.dart` listens to `hosStatusProvider` to show SnackBars.
**Current State:** UI logic leaked into global app widget.
**Target State:** A dedicated side-effect handler or event bus manages notifications.
**Exact Files To Modify:** 
- `lib/app.dart`
- `lib/features/hos/presentation/providers/hos_provider.dart`
**Behavioral Invariants:** User still sees Snackbar when tracking starts automatically.
**Safe Gate:** Duty status transitions trigger UI correctly without global app rebuilds.

## 15. File Impact Matrix
| File | Phase | Risk Level |
|------|-------|------------|
| `lib/core/services/remote_config_service.dart` | Phase 1 | Low |
| `lib/features/auth/data/datasources/auth_remote_data_source.dart` | Phase 2 | High |
| `lib/app.dart` | Phase 3 | Medium |

## 16. Protected Components
- **SyncEngine:** Proven robust, do not touch unless proven necessary.
- **Native Tracking Bridges:** Complex JNI/Swift logic, leave unchanged.
- **hos_calculator.dart:** Core FMCSA math, do not modify.

## 17. Behavioral Invariants
- Same input → Same result for HOS calculations.
- Existing tokens must remain valid after auth refactor.
- App startup time must not degrade.

## 18. Migration Strategy
No physical data migration required for these phases as storage keys are not being modified. Ensure `AuthSessionStore` logic remains untouched during Phase 2.

## 19. Risk Register
| Risk | Phase | Trigger | Impact | Mitigation | Rollback |
|------|-------|---------|--------|------------|----------|
| Auth Failure | 2 | Dio swap | Critical | 100% unit test coverage | Git revert Auth |
| DI Resolution Error | 1 | Provider change | High | App crash on launch | Git revert Core |

## 20. Rollback Strategy
Each phase must be committed individually. If a Safe Gate fails, execute `git reset --hard HEAD~1`.

## 21. Validation Strategy
- **Static Validation:** `flutter analyze` with 0 warnings.
- **Integration Tests:** Verify full login -> HOS status -> Tracking flow.
- **Manual Verification:** Check Snackbars and auth state retention across restarts.

## 22. Safe Gate Matrix
- **Phase 1:** Build passes.
- **Phase 2:** Login succeeds on staging server.
- **Phase 3:** HOS transition triggers visual Snackbar.

## 23. Scope Control Matrix
| Phase | Mandatory | Optional | Forbidden |
|-------|-----------|----------|-----------|
| 1 | YES | N/A | Feature Logic Changes |
| 2 | YES | N/A | Token parsing changes |
| 3 | YES | Event Bus refactor | Modifying HOS math |

## 24. Deferred / Future Refactors
- Traccar client unification.
- Deep storage consolidation.

## 25. Unknowns / Blockers
- None identified at this stage for the proposed phases.

## 26. Definition of Done
- [x] No confirmed Core → Feature dependency.
- [x] Auth uses standardized networking abstractions.
- [x] Domain logic has no explicit UI semantics in `app.dart`.
- [x] HOS and Tracking behavior remains unchanged.

## 27. Final Recommended Execution Order
1. Execute Phase 1 (Core).
2. Validate Core.
3. Execute Phase 2 (Auth).
4. Validate Auth.
5. Execute Phase 3 (UI Isolation).
6. Final System Validation.
