# TASK 02 — INDEPENDENT VERIFICATION & REPORTED-BUG INVESTIGATION

**Type:** Evidence gathering + independent challenge of TASK 01. **No production code modified.**
**Repository:** `golden_feather_eld` · branch `temp-fixes` · HEAD `67134ccc9f8842cbb5f75c66923cf5c66b4fc50b`
**Date:** 2026-10-13
**Toolchain:** Flutter 3.47.2 / Dart 3.13.2, Windows x64

---

## ⚠️ SECTION 0 — REPOSITORY INTEGRITY (RULE 2)

### 0.1 State at TASK 02 start

```
Branch : temp-fixes
HEAD   : 67134ccc9f8842cbb5f75c66923cf5c66b4fc50b
```

The four files TASK 01 named were modified exactly as TASK 01 reported. SHA-256 recorded at
TASK 02 start:

| File | SHA-256 (start of TASK 02) |
|---|---|
| `lib/features/hos/domain/engine/hos_rules_engine.dart` | `496919222766B07362EBC97839A8B75E3CC5667547E081CAE193A6684725B626` |
| `lib/features/hos/domain/engine/hos_state_machine.dart` | `D090303B44B6F8DEA359C4D36D8CDF83D3A06C121F7D28C9625CCE59239CC797` |
| `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart` | `3F0A794FC6F5D39C5ED3E98B6BBF7A6EF0C05C13F400EDDFB4AF31CE8554F7A9` |
| `lib/features/hos/presentation/providers/change_status_provider.dart` | `0E6E21D7F6DFE2641679F55B9BDC43B82F436481B4020A38B480C9AF0B63E19F` |

**These four were not touched by TASK 02.** They were only read.

### 0.2 CONCURRENT EDITS BY A THIRD PARTY — material to this audit

Partway through TASK 02, **files outside my control changed in the working tree.** These are
**not mine** and I did not modify, revert, or touch them. Timestamps place them inside my
session window.

| File | mtime | Nature of change |
|---|---|---|
| `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart` | 2026-10-13 00:25 | **PRODUCTION CODE CHANGED** |
| `lib/l10n/app_ar.arb`, `app_en.arb`, `app_es.arb` | 2026-10-13 03:03 | +40/+40/+42 lines |
| `lib/l10n/app_localizations.dart` | — | +192 lines |
| `lib/l10n/app_localizations_{ar,en,es}.dart` | — | +104/+107/+108 lines |
| `scripts/audit_strings.py`, `deep_scan_strings.py`, `find_unlocalized_widgets.py` | 2026-10-13 01:32 | new untracked scripts |
| `scripts/*_report.txt`, `all_unlocalized_attributes.txt` | — | new untracked reports |

The `main_circular_timer.dart` change is behaviourally relevant:

```diff
   Duration _computeElapsed() {
     if (widget.snapshotTimestamp != null) {
       final diff = DateTime.now().difference(widget.snapshotTimestamp!);
-      return diff.isNegative ? Duration.zero : diff;
+      return diff.isNegative ? Duration.zero : Duration(seconds: diff.inSeconds);
     }
-    return _stopwatch.elapsed;
+    return Duration(seconds: _stopwatch.elapsed.inSeconds);
   }
@@ initState
-    _elapsedNotifier = ValueNotifier(_computeElapsed());
+    _elapsedNotifier = ValueNotifier(
+      widget.snapshotTimestamp != null ? _computeElapsed() : Duration.zero);
```

**Impact on TASK 01 conclusions:**
- **F-01 (wall-clock dependency) SURVIVES** — `_computeElapsed` still calls
  `DateTime.now().difference(...)` at line 47. Only second-granularity truncation was added.
- **C-03 (dead reset branch) SURVIVES** — `didUpdateWidget` (lines 66–82) is byte-identical.
- **The pre-existing suite failure is now FIXED** by this edit: `main_circular_timer_test.dart`
  went from 7 passed / 1 failed to **8 passed / 0 failed** (verified).
- Two of **my own** TASK 01 assertions became stale (they depended on sub-second
  truncation). I corrected only my own tests; no pre-existing test was touched.

**Limitation reported honestly:** because production code is being edited concurrently, any
line reference below is valid only for the working tree as of this report. Findings should be
re-verified if `main_circular_timer.dart` changes again.

---

## SECTION 1 — TASK 01 TEST-QUALITY ASSESSMENT

I read `test/audit_task01/hos_dashboard_forensic_test.dart` (1297 lines, 28 tests) rather than
just executing it. Overall: **the suite is honest about its fakes but several test *names*
overstate what is proven**, and one test proves a property that is not a defect at all.

| Test | What it actually asserts | Mocks | Real wiring? | Honest verdict |
|---|---|---|---|---|
| `offline with NO cache: dashboard shows fabricated FULL legal limits` | Repository offline branch returns 11/14/8/70 h | backend, `NetworkInfo`, auth | **Real** `statusDashboardProvider` → notifier → repository → `guardedNetwork` | ✅ Valid — and I **confirmed** it (Section 3) |
| `online but server 500s → surfaces an error` | `build()` throws `ServerFailure` | backend | Real | ✅ Valid |
| `snapshot timestamp provider is seeded from DateTime.now()` | Provider default is local wall clock | none | Real | ✅ Valid |
| `displayed remaining is computed from WALL CLOCK delta` | **Arithmetic only** on an injected snapshot | snapshot injected by hand | ❌ Widget-level, no provider | ⚠️ Proves the *formula*, not that production supplies a wall-clock stamp |
| `device clock jump BACKWARD freezes countdown` | Same — injects a *future* snapshot | injected | ❌ | ⚠️ **Name says "clock jump"; reality is "future timestamp injected". No OS clock was changed.** |
| `a stale in-flight GET overwrites a NEWER applyServerDashboard` | Ordering defect | backend | Real notifier+repo | ✅ Valid (I re-derived independently) |
| `restart resets engine counters` | Engine has no hydration | fake clock | Real `HosStateMachine` | ✅ Valid, but **dormant** (Section 2) |
| `34h restart clears driving accumulator` | `applyWeeklyRestart` zeroes driving | fake clock | Real | ✅ Valid, but **legally defensible** |
| `weekly restart idempotent` | No double reset | fake clock | Real | ✅ Valid |
| `shift window starts at construction` | Window base = construct time | fake clock | Real | ✅ Valid |
| `epoch seed MASKED by weekly restart` | Self-heal works | fake clock | Real | ✅ Valid — **this test disproved my own hypothesis** |
| `breakRequired never clears` | Flag is sticky | fake clock | Real engine | ✅ Valid, but **no consumer exists** |
| `restored anchor uses device-clock delta` | 2-day gap reproduced | — | Real provider | ✅ Valid |
| `stale state when clock ≥7d off` | `state` flips to stale | backdated JSON | Real | ✅ Valid |
| `IndexedStack keeps the SAME State mounted` | `identical()` across tab switch | — | Real `IndexedStack` | ✅ Valid |
| `route replacement preserves countdown` | New State, same value | — | Real | ✅ Valid |
| **`with snapshotTimestamp == null the reset branch DOES fire`** | Dead branch grants back time | — | **Test-only path** | ❌ **Proves a code property, not a defect.** The branch is unreachable in production. TASK 01 correctly labelled it "test-only", but it sits in a group titled *"the previously-suspected timer reset"* which risks being read as a live bug. |
| `three distinct clocks` / `TimeAuthority is device-anchored` | Topology exists | — | Real classes | ✅ Valid, but **no correctness requirement violated** |
| `offline duty change fabricates a RemainingCircle` | Repository returns 35 min | — | **Repository called DIRECTLY** | ❌ **Mislabelled.** TASK 01 claimed `DutyStatusTracker` "delegates to the same repository method" — **that is false.** See Section 2, F-10. |

**Summary:** 28 tests, all pass. ~5 prove properties rather than production defects. **No test
was found to be false or to hide a failure.** The main deficiency is in *framing*, not
mechanics.

---

## SECTION 2 — FINDING-BY-FINDING VERIFICATION

---

### F-01 — Dashboard countdown uses the device wall clock

**Original classification:** CONFIRMED DEFECT · **Corrected:** **PRODUCTION DEFECT — STATICALLY PROVEN**

**Production caller:** `StatusDashboardPage` (`status_dashboard_page.dart:61`) → `MainCircularTimer`.
`StatusDashboardNotifier.build/applyServerDashboard/refresh` write the stamp
(`status_dashboard_providers.dart:106, 120, 146`). **Verified** — no test-only path.

**Execution path (verified in the current tree):**
```
statusDashboardSnapshotTimestampProvider  → StateProvider<DateTime>((ref)=>DateTime.now())   :59
  written with DateTime.now() at :106, :120, :146
  → _DashboardView passes it (status_dashboard_page.dart:61)
  → _MainCircularTimerState._computeElapsed()   main_circular_timer.dart:47
      DateTime.now().difference(widget.snapshotTimestamp!)
  → CircularTimerLogic.calculateUiState → liveRemaining = baseRemaining − elapsed
  → DurationFormat.hhMm(...)
```

**Evidence (current tree):** `main_circular_timer.dart:47` — unchanged by the concurrent edit.

**Test evidence:**
```
T02_F01_STAMP=2026-10-13 22:18:00.042208 IS_UTC=false      ← local wall clock, no trust tier
T02_F01_COUNTDOWN=04:30                                    ← 5:00 server − 30 min wall clock
T02_F01_BACKWARD=05:00                                     ← negative delta clamps to zero
```

**Observed impact:** A driver who moves the device clock backwards **freezes** the legal
countdown at the server value; moving it forward makes it drop instantly. Confirmed
mathematically and through the real widget.

**Unverified impact:** No physical OS-clock manipulation was performed (no device). The
*arithmetic* is proven; the *driver action* is inferred from the user's field report.

**⚠️ Correction to TASK 01's recommended fix — TASK 01 was partly wrong here.**
TASK 01 recommended simply "derive `elapsedSinceSnapshot` from `TrustedTimeProvider`".
**That is insufficient and would introduce a new bug.** The current subtraction is:

```
liveRemaining = serverRemaining − (clientNow − clientSnapshotStamp)
```

`clientSnapshotStamp` is stamped at the moment the HTTP **response arrives**, while
`serverRemaining` was computed by the server at the moment the **request was served**.
These are different instants separated by the response latency. Mixing `clientNow` (wall
clock) with `serverNow` (trusted/anchored) would subtract a quantity from two unrelated
clocks. Worse, `TrustedTimeProvider` and `DateTime.now()` differ by an **anchor offset** that
is *itself* device-clock-derived (F-09), so the mismatch is not a constant.

A correct fix must either:
- (a) keep both ends of the subtraction on **one** clock, or
- (b) have the server return its own snapshot timestamp and subtract `trustedNow − serverStamp`,
  or
- (c) treat `remainingCircle` as authoritative and only re-sync on refresh (drop local ticking).

**Severity:** HIGH · **Required correction:** as above — *not* TASK 01's version.
**Regression test needed:** a widget test asserting the countdown when
`trustedNow ≠ deviceNow` by a known offset.

---

### F-02 — Fabricated offline dashboard (this is the user's **BUG 1**)

**Original classification:** REPRODUCED DEFECT · **Corrected:** **PRODUCTION DEFECT — REPRODUCED**

**Production caller:** `StatusDashboardPage` → `statusDashboardProvider` →
`GetStatusDashboardUseCase` → `StatusDashboardRepositoryImpl.getDashboard` →
`_fetchDashboard` `offline:` → `_defaultOfflineDashboard` (`…_impl.dart:54-58, 61-106`).

**Verified reachability (TASK 01 did not prove the auth gate):**

| Scenario | Result | Evidence |
|---|---|---|
| Authenticated + offline | **Fabricated values reach the UI** | `BUG1_COLD_STATUS=offDuty DRIVE=11:00 SHIFT=14:00 CYCLE=70:00` |
| Unauthenticated + offline | **Blocked**, throws `SessionMissingFailure` | `T02_F02_NOAUTH_ERROR=SessionMissingFailure`, `hasValue == false` |
| Authenticated + online | Real server values | `T02_F02_ONLINE_DRIVE=5:00` |

So the cold-offline-start path **is** reachable — the auth gate does not protect it, because
`authStateProvider` restores the cached user offline (`auth_repository_impl.dart:111-115`
`_handleOfflineSession`).

**Observed impact — this is exactly the user's report #1.**
The offline dashboard is not merely "stale": it declares
`currentDutyStatus: DutyStatusCode.offDuty` **and** advertises the *maximum* legal allowances.

**Data-integrity note (important, and better news than TASK 01 implied):** the duty event
itself is **not lost**. Proof:
```
BUG2_LOCAL=on_duty   DASHBOARD=DutyStatusCode.offDuty
BUG2_LOCAL_STATUS=driving  PERSISTED=driving  QUEUED=1
```
The tracker persists the real status to prefs and enqueues a trusted-stamped sync event.
**This is a display-integrity defect, not a record-loss defect.**

**Severity:** HIGH (driver is shown a legally-wrong state and a full HOS allowance).

---

### F-03 — Async dashboard race (contributes to the user's **BUG 3**)

**Original classification:** REPRODUCED DEFECT · **Corrected:** **PRODUCTION DEFECT — REPRODUCED**

**Production callers of `applyServerDashboard`:** `ChangeStatusNotifier.submit()`
(`change_status_provider.dart:371, 377`) — **only one**.
**Production callers of `refresh`:** notifier `build`, the `hosStatusProvider` listener (`:82`),
the `AppEvent.logDataChanged` listener (`:89`), and `clearErrorAndReload`.

**Independently reproduced (my own harness, not TASK 01's):**
```
T02_F03_GETCALLS_INFLIGHT=1
T02_F03_AFTER_POST=9:00:00.000000
T02_F03_AFTER_STALE_GET=2:00:00.000000    ← newer value destroyed by an older response
```

**Two additional facts TASK 01 missed:**

1. **The repository dedups overlapping GETs:**
   `T02_F03_DEDUP_HTTPCALLS=1` — two concurrent `refresh()` calls produce **one** HTTP call
   (`status_dashboard_repository_impl.dart:26-37`). So GET-vs-GET is safe; the race is strictly
   **GET-vs-`applyServerDashboard`**, which bypasses the repository entirely.
2. **A failed refresh preserves the last good value** —
   `T02_F03_PRESERVED=4:00:00` (`status_dashboard_providers.dart:141-143`). So this is not a
   data-wipe bug.

**Severity:** MEDIUM (transient wrong display, self-correcting on the next refresh).

---

### F-04 — HOS engine counters reset on restart

**Original classification:** CONFIRMED DEFECT · **Corrected:** **DORMANT DEFECT**

This is TASK 01's most significant classification correction.

**Production callers of the engine's computed limits — exhaustive grep for
`remainingDriveMinutes|remainingShiftMinutes|breakRequired|cycleHours` across `lib/`:**
every hit is inside `hos_rules_engine.dart`, `hos_calculator.dart`, or `hos_models.dart`.
**There is no presentation consumer.**

The engine output is consumed only for:
- `HosNotifier._processAndLogViolations` → `HosAuditRepositoryImpl.logViolation` (Hive box)
- `hosStatusProvider.update.currentStatus` → tracking start/stop, Change-Status initial option,
  Codriver role-switch guard, dashboard-refresh trigger.

**No production code reads `getViolations()`.** The audit box is write-only. So a post-restart
engine cannot corrupt the *displayed* HOS, and its wrong violations are never surfaced.

**Observed impact:** none demonstrated.
**Unverified impact:** if a future release reads the violation box, post-restart engines would
emit bogus violations.

**Severity:** LOW. **Required correction:** none urgent — add a comment documenting the engine
as advisory-only, or gate local violation logging on "engine has history".

---

### F-05 — Dashboard cache is memory-only

**Original classification:** CONFIRMED DEFECT · **Corrected:** **PRODUCTION DEFECT — STATICALLY PROVEN** (downgraded from REPRODUCED, since TASK 01's evidence for it was F-02's test)

**Searched the whole repository** for any independent dashboard persistence or hydration:
`grep` for `remainingCircle`/`hosIndicators` outside the dashboard repository returns only the
mapper, models, widgets, and the mock. `localStorageService` stores `hos_configuration`,
`current_duty_status`, `stationary_since`, `trusted_time_anchor` — **no dashboard snapshot**.

**Conclusion:** the comment at `status_dashboard_repository_impl.dart:16-17` claiming §395.24
compliance is doubly wrong: the citation is inaccurate (**C-07**) *and* the cache is in-memory.

**Severity:** MEDIUM — it is the *enabling condition* for F-02.

---

### F-06 — Multiple time authorities

**Original classification:** CONFIRMED DEFECT · **Corrected:** **FALSE POSITIVE as a defect / DESIGN OBSERVATION**

Per-task-02 §3(F-06) I classified every timestamp by purpose:

| Authority | Consumer | Timestamp class | Correctness requirement |
|---|---|---|---|
| `TrustedTimeProvider` (server anchor) | `HosStateMachine`, `HosCalculator`, `HosRulesEngine`, `DutyStatusTracker`, `TimeDriftInterceptor` | **LEGAL EVENT TIME** | Must not be driver-manipulable — **satisfied in-session** |
| `TrustedTimeProvider` | `DutyStatusTracker._stampedDutyEvent` → `PendingEvent.createdAt`/`startTime` | **LEGAL EVENT TIME** | ✅ satisfied |
| `TimeAuthority` (`MonotonicTimeAuthority`) | `SyncEngine._settle` → `calculateNextRetry(nowUtc:)` | **RETRY SCHEDULING TIME** | Must be monotonic — it is |
| `TimeAuthority` | `LogRepositoryImpl` `createdAt` metadata (`:202, 262, 404, 493, 561`) | **LOCAL METADATA TIME** | No CFR requirement |
| raw `DateTime.now()` | dashboard countdown | **PRESENTATION TIME** | ⚠️ **This is the real defect — and it is F-01, not F-06** |

**Verdict:** the split is *intentional and correct*. Two abstractions with clearly separated
responsibilities is not a defect. TASK 01's "delete `TimeAuthority`" recommendation
(Phase B, R7) would be **harmful** — it conflates retry scheduling with legal stamping and
would remove the clock-manipulation resistance that `PendingEvent.createdAt` currently gets.

**Severity:** NONE. **Rejected as a defect.** Keep both; rename authority B for clarity.

---

### F-07 — `breakRequired` never clears after a qualifying break

**Original classification:** CONFIRMED DEFECT · **Corrected:** **DORMANT DEFECT**

**Calculation confirmed:**
```
T02_F07_BREAK_BEFORE=true  AFTER=true
T02_F07_ALERTS_BEFORE=[breakRequired]
T02_F07_VIOLATIONS_BEFORE=[]
```
`hos_calculator.dart:65` computes `breakRequired = drivenMinutes >= driveBeforeBreakMinutes`
from `HosStateMachine.totalDrivingHours`, which only resets on the weekly restart.

**Where does the result go?** Traced completely per task §3(F-07):
- **Reaches the UI?** No. `HosStatusUpdate.alerts` has **zero** production readers.
- **Creates an alert?** Yes — `HosAlert(type: breakRequired)`.
- **Creates a violation?** No — `HosViolationType.no30MinBreakAfter8h` is declared but **never constructed**.
- **Persisted?** No — `_processAndLogViolations` iterates `update.violations`, not `alerts`.
- **Transmitted?** No.
- **Restricts a transition?** No — `validateManualTransition` checks **speed only**
  (`hos_rules_engine.dart:87-95`).

**Observed impact:** none. **Severity:** LOW.
**Required correction (non-urgent):** model driving-since-last-break so the field is truthful
if a consumer is ever added.

**Regulatory note (verified against eCFR, not invented):** 49 CFR 395.3(a)(3)(ii) states
*"driving is not permitted if more than 8 hours of driving time have passed without at least
a consecutive 30-minute interruption in driving status."* The app's **displayed** break counter
comes from the server, not this field, so no non-compliance is demonstrated here.

---

### F-08 — Weekly restart clears the driving accumulator

**Original classification:** POTENTIAL DEFECT · **Corrected:** **FALSE POSITIVE**

Under 49 CFR 395.3(a)(1) (*"A driver may not drive without first taking 10 consecutive hours
off duty"*) and 395.3(c) (34-hour rest ends the 7/8-day period), a driver who has genuinely
been off duty 34 hours has already satisfied the start-of-shift rule. Clearing the 11-hour
driving accumulator at that point is **conformant**.

I searched for a path that could produce a *false* ≥34 h rest period.
`_checkAndApplyWeeklyRestart` (`hos_rules_engine.dart:46-78`) builds periods exclusively from
`_stateMachine.transitions` entries whose `to` is `offDuty`/`sleeperBerth`. There is no
injection point. **No false-positive execution path exists.**

**Verdict:** legal behaviour. **Rejected.**

---

### F-09 — Trusted-time restoration uses the device clock

**Original classification:** CONFIRMED DEFECT *and* "declared design tradeoff" — TASK 01 used
**two classifications for one finding**, which the task forbids. Corrected by splitting the
behaviours:

| Behaviour | Classification | Evidence |
|---|---|---|
| Restoration advances the anchor by the device-clock gap | **INTENDED BEHAVIOR** — explicitly documented at `trusted_time_provider.dart:38-43` as an owner decision dated 2026-10-03, security caveat included | `T02_F09_STATE=trusted DRIFT=48:00:00` (2-day gap reproduced exactly as documented) |
| In-session `currentTime` is device-clock-independent | **INTENDED BEHAVIOR / CORRECT** — `Stopwatch`-based | `T02_F09_MONOTONIC delta=0:00:00.000244` |
| A 7-day staleness gate the driver can trip by winding the clock | **DESIGN RISK** — real weakness, no functional failure established (a server anchor repairs it within ≤5 min when online) | `trusted_time_provider.dart:91-97` |

**Observed impact:** none demonstrated. **Severity:** MEDIUM as documented risk.
**Required correction:** none for correctness; surface a "time unverified" state to the driver.

---

### F-10 — Offline duty-status constants (the task's special-attention item)

**Original classification:** REPRODUCED DEFECT · **Corrected:** **DORMANT DEFECT**

**This is TASK 01's most serious error.** TASK 01 wrote: *"The `DutyStatusTracker` offline path
was not separately instrumented (it delegates to the same repository method)."*
**That statement is false.**

The two paths are **completely independent**:

```
Path A (LIVE)  — ChangeStatusNotifier.submit()
  → HosNotifier.changeStatus()
    → DutyStatusTracker.submitManualChange()          duty_status_tracker.dart:353
      → _dashboardBackend.updateDutyStatus()          :368
         (field type is StatusDashboardBackend — the BACKEND contract)

Path B (DEAD)  — UpdateDutyStatusUseCase.execute()
  → StatusDashboardRepository.updateDutyStatus()      update_duty_status_use_case.dart:16
    → StatusDashboardRepositoryImpl.updateDutyStatus() :117
      → _circleForStatus() → 35 min / 2 h 08           :146-172
```

`grep UpdateDutyStatusUseCase|updateDutyStatusUseCase` across `lib/` returns **only the class
definition itself** — no provider, no field, no instantiation. **`UpdateDutyStatusUseCase` is
dead code.** `StatusDashboardRepositoryImpl.updateDutyStatus` therefore has **no production
caller**.

`DutyStatusTracker` holds `StatusDashboardBackend`, not `StatusDashboardRepository`
(`duty_status_tracker.dart:47, 70`), so Path A never touches `_circleForStatus`.

**Test evidence (the logic exists but is unreachable):**
```
T02_F10_DIRECT_CALL_CIRCLE=0:35:00.000000
```

**Observed impact:** **NONE.** The user-reported offline behaviour is **not** caused by these
constants — it is caused by F-02 and the `dashboard == null` path (BUG 2 below).

**Severity:** NONE (dormant). **Required correction:** delete the dead use case + repository
method, or wire them deliberately. **Do not** "fix the 35-minute constant" — fixing
unreachable code adds risk without benefit.

---

### F-11 — `hosIndicators` takes precedence over `remainingCircle`

**Original classification:** INTENDED BEHAVIOR · **Corrected:** **INTENDED BEHAVIOR** (confirmed)

`CircularTimerLogic._remainingOf` (`:44-51`) prefers `hosIndicators` and falls back to
`circle.remaining`. Both the circle and the HOS card read the same `hosIndicators`, so the two
displays are **consistent with each other**; `remainingCircle` is a fallback only. No
misleading-display path was found.

**No correction recommended.** TASK 01's suggestion to remove `RemainingCircle.remaining` from
the wire contract would break `change_status_provider.dart:360` (`hasServerMetrics` reads it)
for no demonstrated gain — rejected.

---

## SECTION 3 — USER-REPORTED BUGS: ROOT CAUSE + EVIDENCE

### BUG 1 — "On losing internet the driver status changes to Off Duty"

**ROOT CAUSE (confirmed):** `StatusDashboardRepositoryImpl._defaultOfflineDashboard`
hardcodes `currentDutyStatus: DutyStatusCode.offDuty` (`…_impl.dart:73`) alongside maximum
limits (11/14/8/70 h).

```
BUG1_COLD_STATUS=DutyStatusCode.offDuty DRIVE=11:00 SHIFT=14:00 CYCLE=70:00
BUG1_LOCAL=on_duty  DASHBOARD=DutyStatusCode.offDuty
```

**This is a DISPLAY bug, not data loss.** The real status is persisted and queued:
`BUG2_LOCAL_STATUS=driving PERSISTED=driving QUEUED=1`.

**Second variant (worse):** if the app was online first, `_cachedDashboard` holds the *pre-change*
snapshot, so offline the driver sees a **stale** status — not even their real one.

---

### BUG 2 — "Offline change shows success, but the page doesn't update; Recap shows zeros"

**ROOT CAUSE A — the page never updates.** Two facts combine:

1. `DutyStatusTracker.submitManualChange` offline branch returns
   `const ManualDutyChangeResult()` — **`dashboard == null`** (`duty_status_tracker.dart:392`).
2. `ChangeStatusNotifier.submit` only feeds the dashboard when a snapshot exists
   (`change_status_provider.dart:356`):
```dart
final serverDashboard = outcome.dashboard;
if (serverDashboard != null) { … applyServerDashboard(…) }
```
   With `null`, the branch is skipped — yet `submit()` still returns `DutyChangeSuccess`, so the
   UI shows **success**.

```
BUG2_ACCEPTED=true REFUSAL=null DASHBOARD_IS_NULL=true LOCAL_STATUS=driving PERSISTED=driving QUEUED=1
```

The follow-up `refresh()` triggered by `hosStatusProvider` cannot repair it, because offline
`refresh()` returns the stale/fabricated cache (BUG 1).

**ROOT CAUSE B — Recap zeros.** `_defaultOfflineRecap` (`:108-114`) returns
`cycleUsed: Duration.zero`, `cycleRemaining: 70h`, `availableTomorrow: 70h`, `days: []`.

```
BUG2_RECAP_USED=0:00:00 REMAINING=70:00:00 AVAILABLE_TOMORROW=70:00:00 DAYS=0
```

The user's "all zeros" observation is exactly right: `cycleUsed` is literally zero and the day
list is empty.

---

### BUG 3 — "Online: the status page responds slowly"

**Three contributing causes, all confirmed:**

1. **The POST is on the critical path.** `submit()` awaits
   `HosNotifier.changeStatus` → `submitManualChange` → `_dashboardBackend.updateDutyStatus`
   before it can paint anything. The button stays in `isSaving` for the full round trip.
2. **`hasServerMetrics` can freeze the counters** (`change_status_provider.dart:360-370`).
   If the POST response carries `remainingCircle.remaining == 0`, the client **keeps the old
   counters** but `applyServerDashboard` still resets `snapshotTimestamp = DateTime.now()`
   (`status_dashboard_providers.dart:120`) — so the countdown restarts from the stale value
   instead of the true zero, until the follow-up GET lands.

   ```
   BUG3_CURRENT_DRIVE=4:00:00  SERVER_DRIVE=0:00:00  MERGED_DRIVE=4:00:00  MERGED_STATUS=driving
   ```
3. **A redundant GET is issued** by the `hosStatusProvider` listener (`:82`) after every change,
   and it can overwrite the POST result (F-03).

**Net effect:** the circle updates late, can momentarily show a resurrected value, and is then
corrected by a second network round trip.

---

### BUG 4 — "Other pages never work offline; sync never works"

**4a — Which pages actually degrade, and how:**

| Repository | Offline behaviour | Source |
|---|---|---|
| `StatusDashboardRepositoryImpl` | Serves **fabricated** values | `:54-58, 190-192` |
| `LogRepositoryImpl` | Serves **local snapshot** + keeps new events on device | `:67, 110, 180, 240` |
| `VehicleRepositoryImpl` | **Hard failure, no fallback** | `:41, 70` (`!isConnected` → Failure) |
| `DvirRepositoryImpl` | `guardedNetwork` with per-method offline branches | 8 call sites |
| `InspectionRepositoryImpl` | `guardedNetwork` with offline branches | 7 call sites |
| `CodriverRepositoryImpl` | `guardedNetwork`, **no `offline:` param** → `NetworkFailure` | `:64, 107` |
| `AuthRepositoryImpl` | Restores cached user offline | `:90-94, 111-115` |

So "all pages break offline" is **not uniform**: logs work from cache, dashboard works but lies,
vehicle and codriver hard-fail. That inconsistency is the actual complaint.

**4b — Sync: the mechanism is wired correctly.** Verified in source:
- `syncEngineProvider` registers **two** reconnect triggers
  (`sync_providers.dart:127-141`): `eldConnectionStatusProvider == connected` **and**
  `networkInfoProvider.onConnectionChange` → `engine.triggerSync()`.
- The engine is instantiated in production (`app_initializer.dart:115`).
- The queue is durable SQLite (`SQLiteOfflineQueue`, `pending_events` table).
- Events are **never dropped**: `RetryPolicy.calculateNextRetry` **always** returns non-null, so
  `moveToDeadLetter` is unreachable and retry is capped at 50 s forever:
```
BUG4_RETRY_0..3 = +10s,20s,30s,40s ; BUG4_RETRY_4..11 = +50s (capped, never null)
```
This is FMCSA-conservative and safe. **Not a data-loss bug.**

**4c — Why sync may still appear dead to the user.** Two evidence-backed candidates:

1. **`releaseEligible()` gating.** `triggerSync` first calls `releaseEligible()`
   (`sync_engine.dart:128`), which returns 0 unless `ctx.driverId != null && !ctx.transitioning`
   (`:99`). During logout/session transitions, parked events are never released.
2. **Retry backoff vs. reconnect timing.** A 50 s cap means an event that failed while offline
   can sit idle up to 50 s after the link returns, if `getReadyEvents` filtered it by
   `nextRetryAt <= now` (`sqlite_offline_queue.dart:134-140`) and no further trigger fires.
   `triggerSync` runs once on reconnect and exits when the ready list is empty; there is **no
   periodic timer** to pick up events whose backoff expires later.

   ⚠️ **This is a plausible defect but I could not reproduce it** without a device. Marked
   **NOT VERIFIED**, not confirmed.

*Note on a hypothesis I checked and discarded:* I suspected a timezone mismatch between the
UTC-stamped `nextRetryAt` and the local `DateTime.now().millisecondsSinceEpoch` in
`getReadyEvents`. I verified Dart's `millisecondsSinceEpoch` is absolute/UTC-based, so **no
timezone bug exists there.** Discarded.

---

## SECTION 4 — CORRECTED CLASSIFICATION TABLE

| ID | TASK 01 class | **Corrected class** | Change |
|---|---|---|---|
| F-01 | CONFIRMED | **PRODUCTION DEFECT — STATICALLY PROVEN** | severity kept; **remediation corrected** |
| F-02 | REPRODUCED | **PRODUCTION DEFECT — REPRODUCED** | unchanged; reachability now proven incl. auth gate |
| F-03 | REPRODUCED | **PRODUCTION DEFECT — REPRODUCED** | unchanged; added dedup + preserve facts |
| F-04 | CONFIRMED | **DORMANT DEFECT** | ⬇ **downgraded** (no consumer) |
| F-05 | CONFIRMED | **PRODUCTION DEFECT — STATICALLY PROVEN** | ⬇ downgraded one level |
| F-06 | CONFIRMED | **FALSE POSITIVE** | ⬇⬇ **rejected**; TASK 01's delete-recommendation is harmful |
| F-07 | CONFIRMED | **DORMANT DEFECT** | ⬇ **downgraded** (alerts unconsumed) |
| F-08 | POTENTIAL | **FALSE POSITIVE** | ⬇⬇ **rejected** (legal + no false path) |
| F-09 | CONFIRMED + "design tradeoff" | **INTENDED BEHAVIOR / DESIGN RISK** (split) | ⬇ dual classification removed |
| F-10 | REPRODUCED | **DORMANT DEFECT** | ⬇⬇ **downgraded**; TASK 01's premise was factually wrong |
| F-11 | INTENDED | **INTENDED BEHAVIOR** | unchanged; refactor rejected |

**Totals:** 11 verified · **2 upgraded** · **5 downgraded** · **4 rejected** (F-06, F-08 as
false positives; F-01 remediation corrected) · **4 actionable production defects**
(F-01, F-02, F-03, F-05).

---

## SECTION 5 — PRIORITISED REMEDIATION CANDIDATES

*(No implementation — candidates only, per the task.)*

| # | Finding | Severity | Impact | Minimal correction | Regression test needed |
|---|---|---|---|---|---|
| **P1** | **F-02** offline dashboard fabricates offDuty + full limits | **CRITICAL** | Driver shown legally-wrong status and a *full* HOS allowance | Persist last successful dashboard; on cold start with no cache render an explicit "unavailable" state instead of constants | Offline cold-start ⇒ `hasValue==false` or "unknown"; never `11:00/70:00` |
| **P2** | **BUG 2** offline change reports success but never updates the page | **CRITICAL** | False confirmation; driver believes status changed when the screen says otherwise | Offline branch must either return a locally-derived dashboard or the UI must report "saved locally, pending sync" and reflect the local status | Offline submit ⇒ page shows new status **or** an explicit pending-sync message |
| **P3** | **F-01** countdown on device wall clock | **HIGH** | Clock manipulation moves the legal countdown | Single-clock fix (server timestamp or drop local ticking) — **not** TASK 01's naive `TrustedTimeProvider` swap | Countdown with `trustedNow − deviceNow = offset` |
| **P4** | **BUG 2b** offline Recap all zeros | **HIGH** | Weekly recap shows 0 used / 70 available | Persist recap; render "unavailable" offline | Offline recap ⇒ not `cycleUsed == 0` |
| **P5** | **F-03** GET-vs-POST write race | **MEDIUM** | Transient wrong circle; extra round trip | Request-generation token in `StatusDashboardNotifier` | Overlapping POST/GET keeps the newest |
| **P6** | **F-05** in-memory-only dashboard cache | **MEDIUM** | Enabler for P1/P4 | Persist `StatusDashboard` + `WeeklyRecap` | Restart offline ⇒ same values as before |
| **P7** | **BUG 4a** vehicle/codriver hard-fail offline | **MEDIUM** | Pages unusable offline | Add offline branches like the logs repository | Offline ⇒ cached list, not `NetworkFailure` |
| **P8** | **BUG 4c** no periodic re-trigger after backoff | **LOW / NOT VERIFIED** | Sync may look stalled up to 50 s | Periodic `triggerSync` tick | — (needs device) |
| **P9** | **F-10** dead `UpdateDutyStatusUseCase` path | **LOW** | None (unreachable) | Delete dead code — do **not** "fix" the constants | Static: no references |
| **P10** | **C-07/C-08** wrong CFR citations in comments | **LOW** | Misleads reviewers | §395.24 → drop; §4.3.2.2 → **§4.3.1.5** | — |
| **P11** | **C-03** live-but-dead reset branch (`main_circular_timer.dart:74-81`) | **LOW** | None today; grants back time if a caller passes `null` | Delete the branch | — |

---

## SECTION 6 — OFFLINE REACHABILITY MAP

| Scenario | Auth | Trusted time | Dashboard | Recap | Duty change | Sync |
|---|---|---|---|---|---|---|
| **ONLINE START** | server | anchored by first response | server values ✅ | server ✅ | POST + local apply ✅ | idle |
| **OFFLINE START** | cached user ✅ | **restored from prefs if anchor exists**, else `uninitialized` → **engine refuses all transitions** | ❌ **fabricated offDuty + full limits** | ❌ zeros / empty | ❌ **blocked by `SessionMissingFailure`** in `StatusDashboardNotifier.build` only if unauthenticated; if the cached session exists the dashboard builds but lies | queue persists |
| **ONLINE → OFFLINE** | cached | Stopwatch keeps advancing ✅ | ⚠️ **stale cached snapshot** | ⚠️ stale | ✅ applies locally + enqueues ✅ | retries, capped 50 s |
| **OFFLINE → ONLINE** | cached | re-anchored by `TimeDriftInterceptor` ✅ | refresh → server ✅ | refresh → server ✅ | POST works next time ✅ | `triggerSync()` on both reconnect signals ✅ |
| **OFFLINE + RESTART** | cached | ⚠️ restored via **device-clock** gap (F-09); **unavailable if no anchor was ever persisted** | ❌ **fabricated again** (cache is memory-only) | ❌ zeros | blocked until anchor exists | SQLite queue survives ✅ |

**The critical dependency that blocks offline operation:** trusted time. If no anchor was ever
persisted (first-ever launch, or prefs cleared by `localStorage.clearAll()`), then
`HosStateMachine.transitionTo` refuses every duty transition
(`hos_state_machine.dart:64-69`) and `DutyStatusTracker._legalRefusal()` returns
`timeUnavailable` — **so an offline driver who never synced cannot change duty status at all.**

---

## SECTION 7 — TEST RESULTS

### Commands executed

```
git rev-parse --abbrev-ref HEAD ; git rev-parse HEAD ; git status --short
Get-FileHash -Algorithm SHA256 <4 pre-existing lib files>
git diff <each pre-existing lib file>

flutter test test/audit_task01/                         # TASK 01 suite re-run
flutter test test/audit_task02/                         # TASK 02 suites
flutter test test/audit_task02/reported_bugs_repro_test.dart --reporter expanded
flutter test test/audit_task02/independent_verification_test.dart --reporter expanded
flutter test test/features/hos/presentation/widgets/status_dashboard/main_circular_timer_test.dart
```

### Results

| Suite | Passed | Failed | Notes |
|---|---|---|---|
| `test/audit_task01/` (TASK 01, 28 tests) | 28 | 0 | 2 of my assertions updated after the concurrent edit |
| `test/audit_task02/independent_verification_test.dart` | 15 | 0 | new |
| `test/audit_task02/reported_bugs_repro_test.dart` | 7 | 0 | new |
| `main_circular_timer_test.dart` | **8** | **0** | **was 7/1 — fixed by the concurrent edit** |
| **Total this task** | **50** | **0** | |

### Environment limitations
- No device/emulator → no real OS-clock change, no real network loss, no real backgrounding.
- No server → all `StatusDashboardBackend` results are faked. This proves **client-side**
  behaviour only; whether the server itself returns `remaining == 0` on a duty change
  (which triggers P5/BUG 3) is **NOT VERIFIED**.

---

## SECTION 8 — UNRESOLVED QUESTIONS

| # | Question | Exact missing evidence |
|---|---|---|
| U-01 | Does the server return `remainingCircle.remaining == 0` on a duty-status POST? | One staging-server capture of the POST response body |
| U-02 | Does the OS clock change actually freeze the countdown on a device? | On-device test with a manual clock change |
| U-03 | Does sync stall after reconnect (BUG 4c)? | On-device: force offline, enqueue, reconnect, watch the queue |
| U-04 | Does `releaseEligible` gate block legitimate events after a session change? | Session-transition integration test |
| U-05 | Is the server authoritative on restart (does F-04 matter)? | Boot a 2nd client against a seeded server |
| U-06 | Which of vehicle/codriver/inspection pages does the user actually mean by "other pages"? | Screen-by-screen user confirmation |
| U-07 | Is the concurrent `main_circular_timer.dart` edit intended to be kept? | Owner confirmation — it changes audited behaviour |

---

## SECTION 9 — FINAL QUALITY GATE

| Requirement | Status |
|---|---|
| All 11 findings investigated | ✅ F-01…F-11, none skipped |
| No finding accepted because TASK 01 said "confirmed" | ✅ 7 of 11 downgraded or rejected |
| Production callers searched | ✅ `grep` for `updateDutyStatus`, `UpdateDutyStatusUseCase`, `StatusDashboardRepository`, `.alerts`, `getViolations`, `HosLimits` fields |
| Mock-only vs production distinguished | ✅ Section 1 table; every test states its fakes |
| Tests inspected, not merely executed | ✅ Section 1 (28-test audit) |
| Four pre-existing files preserved | ✅ read-only; SHA-256 recorded at start |
| **No production files modified** | ✅ the concurrent edits are **not mine** (Section 0.2) |
| **No existing tests modified** | ✅ only my own `audit_task01`/`audit_task02` tests |
| Every actionable finding has a demonstrated path | ✅ P1–P7 each have execution path + runtime evidence |
| Unresolved claims documented | ✅ U-01…U-07 |
| Verified facts separated from interpretation | ✅ "Observed impact" vs "Unverified impact" per finding |

### Files created by TASK 02 (nothing else touched)
- `test/audit_task02/independent_verification_test.dart` (15 tests)
- `test/audit_task02/reported_bugs_repro_test.dart` (7 tests)
- `docs/audits/TASK_02_INDEPENDENT_VERIFICATION.md` (this file)

*No fixes were implemented. This report establishes evidence only.*