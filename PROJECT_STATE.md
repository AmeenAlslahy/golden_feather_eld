# PROJECT_STATE

Last updated: 2026-09-26 (batch 38 — verified: `flutter analyze` No issues found, 628 tests pass + 1 skipped)

## What this app is

Flutter **driver** ELD app only. Carrier / fleet-manager portal is out of scope.

## Sources of truth

- Behavior: PDF SRS v2.0 Rewritten (`/home/user/uploads/13-09-2026 Top_Compliance_ELD_SRS_v2.0_Rewritten.pdf`)
- Wire: `openapi.yaml` in this repo
- Review matrix: `/home/user/SRS_V2_APP_FULL_REVIEW.md`

When SRS and OpenAPI disagree, stop. Do not invent fields.

## Architecture

5 layers, imports down only. See `docs/architecture.md` and `.agents/AGENTS.md`.
Do not add PageV2 / parallel repos / third `coDriverId` / second `connectSession` owner.

## Ownership (this batch)

| Concern | Owner |
|---|---|
| View company fleet | `SelectVehiclePage` browse flag + `listedVehicleIsOperable` |
| Local vehicle select | `VehicleNotifier.selectVehicle` (no API) |
| `POST /eld/hardware/connect` | `EldConnectionPage` only |
| Session co-driver link/remove | `CoDriverRepository.updateSessionCoDriver` → `manageCoDriver` |
| Unidentified local capture | `UnidentifiedCapture.capture`; wired from `trackingOrchestratorProvider` |

## Known server / contract blocks

- Inspection start 400: Hibernate jsonb `photos`. Not an app field miss.
- Send-logs 400: DB CHECK rejects status `SUCCESS`.
- Form `vehicles[]`: not on OpenAPI `UpdateDailyFormRequest`.
- ECM unidentified: GPS events are not `fromEcm`; logout stops tracking.

## Completed batch 36 (2026-09-25) — layout realigned to the 34 reference screenshots (owner: «اجعلها بنفس التخطيط والحجم والتصميم … مع الحفاظ على الاصلاحات»)

Reference map: `docs/DESIGN_REFERENCE_MAP_2026-09-25.md` (screenshot → screen → layout facts). Theme stays gold-primary / black-secondary. All functional fixes kept; only structure/size changed.

- **Information Packet** (shots 2/7): back to exactly two blocks (User Manual, Instructions). Extra "Data Transfer Sheet" / "Malfunction Manual" blocks removed (still reachable inside Instructions). Packet-status line now shows **only when the server says the packet is incomplete** (red); nothing in the normal state.
- **Send Logs** (shot 9): heading + `Comment` field + `Data Transfer Type: Email` + green SEND. Scope caption, routing-code field and transfer-history list removed. **Email Logs** (shot 3): heading + `Recipient Email` (hint `some@email.com`) + SEND; the 4–60 output-file comment is still sent (default), the FMCSA mailbox is no longer prefilled in the field. Channel stays `TransferMethod.email`.
- **Insert DVIR** (shots 15/19): `Time (ET)`, 16 px labels/values, Vehicle|Defects and Trailers|Defects as two underlined cells per row, catalog defects rendered as plain lines (no Card/ListTile) under the grid, SIGN with 28 px side padding. AppBar refresh kept (SRS 7.2 names it explicitly) — flagged as an owner decision below.
- **DVIRs list** (shot 21): FAB removed, "+" is the AppBar action; empty state is a plain grey `No Records` near the top (errors still use `EldRetryView`). Refresh icon kept (SRS 7.2).
- **ELD Connection** (shot 33): only banner, checklist, MAC field, CONNECT, CONTINUE DISCONNECTED. Trailing AppBar action removed (swap icon already goes to vehicle selection). `_ConnectivityPanel` + `_ManualRecordingSection` **moved** to `lib/features/connection/presentation/widgets/eld_diagnostics_section.dart` (`EldConnectivityPanel`, `ManualRecordingSection`) and rendered on **About / Diagnostics** (SRS 3.8) in a new "ELD Connection Status" card. `eld_connection_page.dart` remains the sole `connectSession` caller; `setManualMode` still lives on `EldConnectionNotifier`.
- **Co-driver** (shot 12): full-width dividers between the two sections, 16 px hint text, reference copy "You will become co-driver. Your co-driver will stay driver.", AppBar refresh removed (pull-to-refresh remains). SRS 10.3 linked-state/team badge kept **below** the last divider so the reference layout is untouched.
- **Home / Status** (shot 1): rule-set Chip and limits caption removed from above the ring; `HosIndicatorsCard` is now the full-width "HOURS OF SERVICE" table (grey header, label + limit description, 34 px value). Descriptions derive from server `limits` (`maxDrivingHours: 11` → "11-Hour Driving Limit") with l10n fallbacks; cycle row shows the rule set (`USA 70/8`). `used` indicators are marked "· Used" so a consumed figure is never read as remaining.
- Tests: `info_packet_page_test`, `send_logs_page_test`, `dvir_form_defects_test`, `dvir_list_page_test`, `eld_connection_page_test`, new `eld_diagnostics_section_test`, `about_page_test`, `codriver_page_test`, `hos_indicators_card_test`, `status_dashboard_page_test` updated. 594 pass + 1 skip; analyze clean.

**Owner decisions still open after batch 36**
1. Insert DVIR AppBar refresh icon and DVIRs list refresh icon: SRS 7.2 requires them, screenshots 15/21 do not show them — currently **kept**.
2. Manual recording + connectivity lines now sit on About/Diagnostics (my placement; SRS has no screen for §3.7) — say the word to move them elsewhere.
3. Co-driver confirm dialog and "Roles switched" result dialog (SRS 10.4) kept — not visible in screenshots either way.

## Completed batch 35 (2026-09-25) — last three owner items (owner: «اضفه»)
- **Verified:** `flutter analyze` No issues found; `flutter test` 592 pass + 1 skipped.
- `instructions_page.dart`: `InstructionsSection {all, inspection, sendLogs, malfunction}` — single-section sheets with their own titles (`Key('instructions_<section>')`). `info_packet_page.dart`: two extra blocks "Data Transfer Instruction Sheet" / "Malfunction Manual (395.34)" opening those sheets (`packet_transfer_sheet`, `packet_malfunction_manual`). Rows 639/640. `info_packet_page_test` extended.
- `inspection_events_table.dart`: header `Time ET` (server field `timeEt`). Row 709.
- Dead second operate path removed: `VehicleRepository.selectVehicle` + impl + `hardwareBackend` ctor arg deleted; `ConnectionNotifier.connect` is the only `connectSession` caller. Rows 927/932 (were stale). `select_vehicle_page_test` updated.
- Review matrix addendum د35; remaining جزئي/ناقص: 102, none owner-decision.

## Completed batch 34 (2026-09-25) — owner-design rows implemented per SRS text (owner: «اضفه»)
- **Verified:** `flutter analyze` No issues found; `flutter test` 592 pass + 1 skipped.
- `home_page.dart`: server `operationalAlerts.toolIcon` / `warningTriangleIcon` wired to AppBar (`home_tool_alert`, `home_warning_triangle` → connection screen); GPS-off keeps the tool icon. Rows 114/115.
- `inspection_duty_graph.dart`: four FMCSA rows (OFF/SB/D/ON); PC on OFF row, YM on ON row, drawn in `infoBlue` with PC/YM tag. `log_graph.dart`: PC/YM overlay + tag. Rows 301/700.
- `dvir_list_page.dart`: `FloatingActionButton` (`dvir_insert_fab`) → Insert DVIR (SRS 7.2); AppBar "+" kept. Rows 391/521. `dvir_form_page.dart`: defect chips → cards (name, note, critical icon, remove; `dvir_defect_cards`). Row 413.
- `inspection_events_table.dart`: headers `Odometer` / `Engine Hours`; `Code: <eventCode>` in details line. Rows 710/712/713.
- `send_logs_page.dart`: email mode pre-fills `fmcsaeldsub@dot.gov` (`kFmcsaEldEmail`) + visible Comment (4–60, default `kDefaultEmailComment`); send-mode type text "Telematics — Email + Web Services". Rows 736/752/754.
- `eld_connection_page.dart`: five-item checklist always visible. Row 930.
- `codriver_page.dart`: back arrow when `canPop`, else drawer; post-SWITCH "Roles switched" dialog before `go('/home')`. Rows 1048/1081.
- Tests updated: `dvir_list_page_test`, `dvir_form_defects_test`, `send_logs_page_test`, `codriver_page_test`.
- Review matrix: 18 rows closed/reclassified; addendum د34. Remaining جزئي/ناقص: 107.

## Completed batch 33 (2026-09-25) — sixth verification pass
- `suggested_events_page.dart`: explains carrier edits (§395.30) are reviewed on the Certify tab; buttons Logs + Unidentified Events. Row 802.
- 19 rows reclassified with evidence to «مكتمل على التطبيق» / «مكتمل بالبناء» (141, 142, 180, 323, 347, 348, 744, 789, 803, 813, 822, 891, 949, 1161, 1261, 1262, 1273, 1288, 1300). Addendum د33.

## Completed batch 32 (2026-09-25) — fifth verification pass
- **Verified:** `flutter analyze` No issues found; `flutter test` 592 pass + 1 skipped.
- `dvir_form_page.dart`: AppBar refresh action (`Key('dvir_form_refresh')`) per SRS 7.2 (close + title + refresh) — invalidates `dvirCatalogProvider`, calls `DvirNotifier.refresh()`, reloads open report when editing. Review row 404 closed. New widget test in `dvir_form_defects_test.dart`.
- `send_logs_page.dart`: scope caption under "Send 8 Logs" (SRS 8.7: current 24-hour period + previous 7 consecutive days), `Key('send_logs_scope_caption')`. Review row 734 closed; `send_logs_page_test.dart` asserts it.
- Review matrix addendum د32: 145 rows remain جزئي/ناقص, all in the six non-app-closable categories of د31.

## Completed batch 31 (2026-09-25) — fourth verification pass + consolidated final list
- **Verified:** `flutter analyze` No issues found; `flutter test` 591 pass + 1 skipped (no regressions).
- `certify_tab.dart`: signature pad placeholder ("Image not available") is hidden as soon as the driver starts drawing (`onDrawStart` + listener; placeholder only when `isEmpty`). Closes review row 467.
- `home_page.dart`: dashboard header fallback now `<driverName> - <driverId>` (SRS §5.1 "Name - ID"), vehicle name is shown in the vehicle card, not the header. Closes review row 113.
- Review matrix: rows 96, 113, 467, 471, 490, 519, 1209, 1229-1237, 1421 re-audited; addendum د31 = definitive consolidated list of every remaining جزئي/ناقص row grouped in 6 categories (no API contract / ECM hardware / owner design / SRS contradiction / needs live-data proof / outside driver app).
- Result: no further rows are closable app-side without new server contract or an owner decision (only pending owner item: Send Logs comment field 4–60 chars / preset recipient).

## Completed batch 30 (2026-09-25) — third verification pass (rows 700–1290 vs. contract)

- Send/Email Logs transfer history rows show period (`startDate – endDate`) and `recordCount` (`TransferAuditRow.period/recordCount`).
- Unidentified Events: both tabs fetched in parallel → real TOTAL/UNCLAIMED/REJECTED counters (`UnidentifiedListState.unclaimedCount/rejectedCount`); card shows `allocationStatus` chip and `ELD: <uniqueId>`.
- Select Vehicle: SRS-literal copy — dialog title `No Vehicles Assigned`; 403 → `You are not authorized to operate this vehicle.`; 404/503 → `Vehicle unavailable.`
- Review rows 779, 823, 889, 944, 946, 947, 1216–1218, 1228, 1233 updated; addendum د30.

## Completed batch 29 (2026-09-25) — second verification pass, contract-backed gaps closed

- Status dashboard shows `regulatoryConstraints.limits` under the rule-set chip.
- Events tab: per-status hour totals row under the graph (PC→OFF, YM→ON); event start date shown when it differs from the log day (`LogEventTile.logDate`).
- Inspection header: driver license number/state and co-driver name/id now come from the log record (`driver`/`coDriver` = `DriverResponse`), account/live co-driver only as fallback; diagnostic/malfunction indicators list the active codes instead of a bare "Yes". `DotInspectionLog` gained `driverLicenseNumber/driverLicenseState/coDriverName/coDriverId` (freezed regenerated).
- Review rows 123, 302, 304, 520, 670, 671, 674, 675, 684, 685 updated; addendum د29.

## Completed batch 28 (2026-09-25) — full re-verification of partial/missing review rows

- Review file rows re-checked against the tree; 12 stale rows updated (already done in batches 21–27).
- Fixed: Events tab pencil hidden for automatic driving / server-locked events (§395.30(b), `events_tab_test.dart`); inspection header odometer/distance in miles with `mi`; "Unassigned Vehicles" prompt only when no `isAssigned` vehicle exists (SRS 9.1); Unidentified Events filters (SRS 11.2): date (local), current vehicle (`uniqueId` server param), status (tabs) + removable chips.
- Remaining partial/missing rows are classified in review addendum د28: no OpenAPI contract / needs ECM hardware / reference-design decision / SRS contradiction (team accounts) / needs live server data / outside driver app.

## Completed batch 27 (2026-09-25) — logs events, logout tracking, offline §6.8, dead-code purge

Owner answers: Today badge stays; `requiresAction` badge removed; events per log id via graph-grid; tracking continues after logout (Unidentified Driver); dead files + tests deleted; held items closed by judgment; offline/local storage IS required (§6.8).

- **Logs 5.2:** `LogEventModel.fromJson` maps the `GraphGridEvent` wire shape (`DRIVING`→`D`, `durationMinutes`, `odometerKm`→mi, `origin`). `LogsNotifier.selectLog` loads that day's events via `LogRepository.getEvents(logId, date)` → `GET /eld/daily-logs/{id}/graph-grid`; `isLoadingEvents` / `eventsError` + retry; Events tab rewritten on the server data. Logs list: single row with flexible gaps (no 360dp overflow).
- **Logout:** `TrackingOrchestrator` no longer stops tracking on `unauthenticated` (SRS §1 / §395.32). Locked by `test/app/orchestrators/tracking_orchestrator_test.dart`.
- **Offline §6.8:** `LogLocalDataSource.cacheDailyLogs/getCachedDailyLogs/cacheLogEvents/getCachedLogEvents` (Hive `daily_logs_cache_box`); `LogRepositoryImpl.getDailyLogs` serves the last snapshot offline (first page only) and `getEvents` merges snapshot + locally recorded events; cache writes are best-effort. `SyncEngine` now also flushes on `NetworkInfo.onConnectionChange == true` (not only on vehicle-link reconnect). Test: `test/features/logs/data/log_repository_offline_test.dart`.
- **Inspection:** `period24HourStartTime` (`InspectionLogDisplayResponse`, `LocalTime`) mapped to `DotInspectionLog.period24HourStartTime` and shown in the header table instead of `—`.
- **Permissions:** location tile now requires *Always* (background) — needed for post-logout unidentified tracking; battery-optimization duplicate path (`battery_optimization_service.dart`, dialog, `showBatteryDialog` state) removed — the Permissions page already handles `ignoreBatteryOptimizations`.
- **Time:** `NativeLocationQualityValidator` takes `nowUtc` from `TimeAuthority` (provider wiring) instead of the device clock.
- **Config:** `AppEnvironmentConfig.osmAndPort` (5055) is the single source for the tracking port.
- **Dead-code purge (analyzer + reference scan):** removed unused backend contracts/adapters (compliance, driver_rules, fleet_dashboard, health, log_transfer, reports, rules_engine, stats) and their providers/endpoints; account + inspection repository chains; `diagnostics_engine`, `distance_tracker`, `hos_violations_engine`, `distance_calculator`, `hos_local_data_source`, `TraccarMapper`, `time_extensions`, `key_value_port`; unused methods in `utc_sync_service`, `local_database_service` (+2 Hive boxes), `app_theme_provider.toggleTheme`, `login_form_provider.toggleAdvanced`, `traccar_data_source.connectWebSocket`, `hos_calculator.calculateConsecutiveDays`; `EldColorTokens` extension (badge reads `EldColors` directly). Backend adapter now exposes 14 driver-scope contracts.
- **Generated code:** `build_runner` re-run → freezed/json files regenerated (formatting-only diffs except `dot_inspection.freezed.dart`).
- Still held / not closable app-side: `HosStateMachine` persistence (display-only, server is truth), `AppButton` palette & InstructionsPage colors (reference design), server-side 400s, READY_CHECK items, `vehicles[]`, GPS-as-ECM, signed ELD file.

## Completed this batch (2026-09-24)

- Discovery: `docs/DISCOVERY_REPORT_2026-09-24.md`
- Vehicle list no longer calls `connectSession`; connection page remains the owner
- VIEW ALL / company list: `listedVehicleIsOperable` (assigned only)
- Certify NOT READY pops
- About added to driver menu (existing `/about`)
- Inspection events show origin / notes / certification; header no longer invents `00:00`
- Send/Email Logs collect optional `routingCode` (existing OpenAPI field)
- Information Packet watches `informationPacketProvider` for completeness
- Co-driver OK → `manageCoDriver` link/remove
- Switch copy: co-driver becomes the driver
- Unidentified capture wired from tracking events when logged out (`fromEcm` still required)
- Form SAVE uses operable `uniqueId` only (not numeric list id)
- DVIR card opens existing `DvirFormPage`
- Inspection exit requires driver account password (PIN remains start lock only)
- Instructions no longer tell the officer to leave with the back arrow
- Logs list marks Today
- Certify tab accept/reject `pendingCarrierEdits` via existing respond API
- Automatic driving (`automatedDriving` / `editable: false`) cannot be shortened or status-changed; no pencil
- Re-certification banner is bilingual
- Suggested Events explains the live contract and opens Unidentified Events (no fake API)
- Reassign driving to linked co-driver uses existing `reassign-driving` + annotation
- Mixed AR/EN copy reduced on certify, edit-log, unidentified
- Logs list Today comes from server `today`; `requiresAction` is shown
- Connection MAC prefills only when hardware status `eldIdentifier` is MAC-shaped
- DVIR list: Total / Open / Signed / OOS counts from loaded reports (`dvir_list_summary.dart`) + refresh button
- DOT inspection start view consumes live `GET /eld/dot-inspection` (guidance, hand-over notice, compliance statement, `canStartInspection`) with local fallback
- Connection panel shows `lastHeartbeat` as last valid data time
- Manual recording mode (§395.34): connection page shows malfunction steps + START MANUAL RECORDING → existing `POST /eld/hardware/manual-mode` with reason (`manual_mode_test.dart`); mock returns ok
- About: hardware-alerts error goes through `anyErrorUserMessage` (no raw `$err`)
- Rules: read-only `ruleSource` row (Federal / State / Fleet / Exception) from live `DriverRulesScreenResponse`
- DOT inspection start view honours server `canSendLogs` / `canEmailLogs` / `canViewInformationPacket` (disabled + note); mapper treats an absent flag as allowed
- DVIR §396.11 catalog: `dvir_catalog.dart` (parser + `DvirDefectSelection.toWire`), `dvirCatalogProvider` on existing `getDefectsCatalog`, "+ Add Defects" chips row under the existing defect text fields, catalog dialog auto-opens when Has Defects is chosen with nothing recorded, picks sent in `defects[]` on `POST /eld/dvir`; server defects with `itemCode` shown as chips on saved reports; mock catalog returns the 11 regulatory items
- DVIR previous-inspection review dialog lists the previous report's recorded defects (catalog picks, free text, or `defectsSummary`) and repair status/mechanic/notes before the driver signs; DVIR status modal and submit-path messages are bilingual (wire values unchanged)
- **Verification (Flutter 3.41.9 / Dart 3.11.5, matching pubspec.lock):** `flutter analyze` 0 errors / 0 warnings (17 infos); `flutter test` 532 passed, 0 failed
- Compile fixes from earlier batches: auth_page bracket balance after gear removal; `_respondToEdit` restored in certify_tab; non-const `DateTime.fromMillisecondsSinceEpoch`; `vehicle_selection.dart` import path; `Result` extension import in inspection_provider; const SnackBar with runtime text in edit_log_page; 27 unused imports removed
- Runtime fix: `NetworkInfoImpl` starts optimistic and reads `checkConnectivity()` at once — the earlier `false` default made every repository return NetworkFailure on cold start until Connectivity emitted
- `parseTransferAudit`: a bare `status` key is an envelope, not a transfer row
- Stale tests aligned with deliberate behaviour: PC is off-duty; event ids are UUIDs (no same-millisecond collision); unidentified driving not decided locally; widget tests use `AppTheme.light` (AppStyles extension); AGREE without signature shows the fill-form message
- CI: `verify.yml` Flutter pin raised 3.24.0 → 3.41.9 to match `pubspec.lock`
- Widget tests for batches 5–10: `dvir_list_page_test.dart` (summary row + refresh), `dot_inspection_page_test.dart` (server copy + explicit-false capabilities disable actions), `eld_connection_page_test.dart` (§395.34 section on MALFUNCTION, hidden on CONNECTED, MAC prefill only for MAC-shaped id)
- Found by those tests: `_DvirCard._infoRow` overflowed on long values (now wraps); `MockVehicleBackend` threw synchronously and crashed any vehicle-listing page under the mock backend (now empty envelopes)
- Radio pickers migrated to `RadioGroup` (codriver page, edit-log status list, co-driver picker, vehicle picker); `pubspec.yaml` environment now states `flutter: >=3.32.0` / `sdk: >=3.8.0` explicitly (the lockfile already required it) — analyzer: **No issues found**
- `dvir_form_defects_test.dart`: Add Defects opens the live catalog, a pick adds a chip and flips status to Has Defects, CANCEL leaves the report untouched
- Owner decisions (2026-09-24): **HosPage deleted** together with `feature_flags.dart` / `featureFlagsProvider` and the dead `StatusDashboard` wrapper in `home_page.dart` (`StatusDashboardPage` is the only status screen); **local GPS-based Unidentified capture removed** (`UnidentifiedCapture`, `unidentifiedCaptureProvider`, orchestrator listener, `trackingEventsStreamProvider`, `localOnly` rows) — the Unidentified list is server-only; no commit made (owner handles git)
- New widget tests: `logs_list_page_test.dart` (Today/Action badges, Form/Certify chips, No Records, sanitized failure + retry), `certify_tab_test.dart` carrier-proposed edit card → ACCEPT via `respondToCarrierEdit` → readiness re-fetched, `rules_page_test.dart` (read-only info rows incl. Rule Source + fleet-fixed settings; editable dropdowns/switch → SAVE payload)
- Layout defects found by those tests and fixed: logs row header (`Flexible` date) and status row (`Wrap`), shared `EldInfoRow` label now `Flexible`, rules dropdowns `isExpanded` + ellipsis
- Batch 16 widget tests: `unidentified_events_page_test.dart` (server rows + counters, no device-local rows, ASSUME/NOT MINE require annotation and call claim/reject with server `statusId` + signed-in driver, server refusal shown), `codriver_page_test.dart` (link via `updateSessionCoDriver`, SWITCH disabled with nobody selected, refused when motion unknown with no server call, stopped → confirm → `switchPrimary` → `/home`, server refusal shown), `eld_connection_page_test.dart` +1 (manual-mode: empty reason refused locally, reason POSTed with `enable=true`)
- Real defect found by those tests and fixed in two places: a `TextEditingController` was disposed right after `showDialog` returned, while the dialog's exit animation still used it (debug-mode crash) — unidentified annotate dialog (controller now owned by the page state) and §395.34 manual-mode prompt (extracted `_ManualModeReasonDialog` StatefulWidget that owns its controller)
- Batch 17 widget tests: `change_status_page_test.dart` (Driving tile locked; PC/YM hidden unless server `personalConveyanceEnabled`/`yardMoveEnabled`; PC/YM require annotation then `changeStatus(personalUse, annotation)` / `onDutyNotDriving … isYardMoves=true`; moving → all non-current tiles disabled, UPDATE sends nothing; refusal code keeps the page), `select_vehicle_page_test.dart` (stopped tap → select + `/connection` without calling the repo's `selectVehicle`; unknown motion refused; no assigned vehicle → Unassigned dialog, VIEW ALL loads company fleet as view-only: unassigned → 'Not authorized', in-use → 'in use', assigned-to-me → selectable; empty list → No vehicles available + retry)
- Copy defect fixed: Select Vehicle success snackbar claimed 'The server accepted the connection…' although the list tap only selects locally (session is opened on the Connection page) → now 'Selected {name}. Connect to the ELD to operate it. Hours were not copied.' (AR equivalent)
- Batch 18 widget tests: `send_logs_page_test.dart` (comment 4–60 enforced before any request; valid comment + routing code → `sendLogs` and the server's own outcome text replaces the form; email mode validates the address then hits `emailLogs`; server `FAILED` status is a refusal not a success screen; transport error never leaks Dio/Hibernate text; transfer history rows from `getTransfers`), `about_page_test.dart` (app version/package/device id, server & GPS tiles, hardware alerts list, ELD engine / hardware versions from the server or N/A, and sanitized failures)
- Defect found by the About test and fixed: hardware-status error branch still rendered `Text('Error: $err')` (raw exception) → now `anyErrorUserMessage` like the alerts branch
- Widget tests (batch 19): `info_packet_page_test.dart` (4 — completeness text from `GET /eld/inspection/information-packet` for the current driver, missing-items sentence, sanitized server failure keeps the manual/instructions reachable, navigation to User Manual / Instructions), `recap_page_test.dart` (3 — 7-day table + Total/Hours Worked Today/Available Today/Tomorrow in decimal hours, Arabic locale has no English row titles, sanitized retry re-queries), `settings_page_test.dart` (5 — language switch persists + re-renders Arabic, theme persisted, server URL empty refused / trimmed value saved with `eld` backend, flattened fleet settings rows, sanitized retry)
- Defects found by batch-19 tests and fixed: Recap hard-coded 'Total' / 'Last 7 Days' / 'Hours Worked Today' / 'Hours Available Today' in English while the arb keys already existed (mixed AR/EN) → now `context.loc.*`; User Manual header (`_buildHeader`, fixed `height: 250`) overflowed by 41 px at 360 dp → `minHeight: 250` + `IntrinsicHeight`
- Open copy question (not changed): the in-app User Manual / Instructions text still says "TOP COMPLIANCE ELD" (user_manual_page.dart L144, instructions_page.dart L81/L156/L220) while `appName` is "Golden Feather ELD" — user decides
- Batch 20 (SRS gap closure, app-side only): Select Vehicle rows carry `Assigned to you` / `In use` / `View only` badges (+ `statusReason`) and dim before the tap (`listedVehicleIsOperable`); connection failure banner = `Unable to connect to ELD with MAC <target>.` + sanitized reason in the *current* locale (`EldConnectionState.error` holds the `AppError`; notifier no longer hardcodes `isArabic: true`); Co-driver page: AppBar refresh + pull-to-refresh (`CoDriverNotifier.reload`) and `Team driving active/inactive` badge from `teamDrivingActive`; Unidentified `DRIVING 24H` = rolling 24-hour window on `endTime`/`startTime`; after ASSUME/NOT MINE success → `logsProvider.loadLogs(refresh)`, invalidate `statusDashboardProvider` + `recapProvider`, snackbar pointing to the daily log for re-certification; product name in User Manual / Instructions → `Golden Feather ELD` (was TOP COMPLIANCE ELD)
- Tests batch 20: eld_connection_page (+2: Bluetooth failure names MAC, server refusal MAC + sanitized English reason), codriver_page (+1: team badge + refresh re-reads link), select_vehicle_page (badges asserted), unidentified_events_page (fixture moved to relative timestamps; >24h driving row excluded; logs re-read verified via `logRepositoryProvider` stub)
- `SRS_V2_APP_FULL_REVIEW.md` re-synced: 46 stale rows updated in place (tagged د#), per-page summary rewritten to the current tree, addendum for batch 20. Counts now: مكتمل 361 / جزئي 158 / ناقص 31 — most remaining جزئي/ناقص rows are server/contract-bound and say so
- Remaining app-side functional item: 7.12 — wire `loadDvirDetails` (`GET /eld/dvir/{id}`) when a DVIR card is opened (currently opens `DvirFormPage(existingReport:)` from the list item)
- Batch 21 — 7.12 closed: `DvirFormPage` shows the list report immediately, then calls `loadDvirDetails` post-frame and swaps in the detailed report via `ref.listen(currentReport)`
- Batch 21 — Trailers / Shipping Documents defect fixed: both pages edited private orphan `StateNotifier` lists with fake defaults (`1402`, `BOL-2024-001`) that the Form SAVE never read (`_dailyFormPayload` reads `dashboard.trailerId/shippingDocuments`, which nothing set → always `[]`). Now one source of truth: `DashboardNotifier.updateTrailers/updateShippingDocuments` store the comma-joined form value; pages derive their lists from `dashboardDataProvider`; `_dailyFormPayload` splits and validates every entry into `trailers[]` / `shippingDocuments[]`. Rules live once in `lib/features/logs/domain/daily_form_rules.dart` (`splitFormList`, `joinFormList`, `trailerNumberError`, `shippingDocumentError`). Page strings bilingual (`context.loc.trailers/shippingDocuments`, AR fallbacks for hint/empty/DELETE)
- Batch 21 — copy/error hygiene: `translateErrorKey` default branch no longer leaks raw codes (`network.*` → no-internet text, other codes → generic via `anyErrorUserMessage`); login "Forgot Password?" label uses `loc.forgotPassword`; Form SAVE failure snackbar uses `anyErrorUserMessage` instead of `error.code`
- Tests batch 21: auth_page_test (5), dvir_list_page_test (+1 details load), trailers_page_test (6: rules, Trailers page, Shipping page, FormTab SAVE payload carries every trailer/document, SAVE failure sanitized). Remaining hygiene only: Splash widget test
- App-side functional backlog: **0**. User-held 8 and out-of-scope ~15 unchanged (see `SRS_V2_APP_FULL_REVIEW.md` addendum د21)
- Batch 22 — Splash: `splash_page.dart` now checks `mounted` after the permission awaits and after `checkAuthStatus` (previously navigated on a possibly-disposed context behind `// ignore` comments); single `goNamed(isLoggedIn ? 'connection' : 'login')`. Test `test/features/auth/presentation/splash_page_test.dart` (5) mocks the `flutter.baseflow.com/permissions/methods` channel (location=3, bluetooth=21; granted=1) and a `GoRouter` with stub pages: spinner+name; missing permission → Permissions without auth check; granted+authenticated → Connection; offline+user → Connection; unauthenticated → Login
- Hygiene backlog: **0** (Login, Splash, Trailers/Shipping all covered)
- Batch 23 — raw-error / mixed-copy sweep (grep of `Text(...error/.code/$e)` across lib): `inspection_preview_page` `Text('Error: $e')` → `EldRetryView` + `anyErrorUserMessage` + retry (`ref.invalidate(dotInspectionScreenProvider)`); `CertifyLogNotifier` now takes `isArabic` from `localeProvider` and maps every `Failure` via `anyErrorUserMessage` (was surfacing repository-fixed English `An unexpected error occurred` / `No internet connection` in Arabic UI); signature/interrupted/session-missing messages bilingual; `LogRepositoryImpl` offline guards return `NetworkFailure()` (3×) so the no-internet sentence is chosen. Test `certify_tab_errors_test.dart` (2). Repositories still carry `error.code` in `Failure.message` for logs — fine, UI sanitizes at display.
- User-held 8 items: asked again (2026-09-24, ask_user skipped) — still held, untouched.
- Batch 24 (user log 2026-09-24 23:49 + new design directives):
  - **Crash on Start Inspection fixed:** `dot_inspection_page.dart` PIN dialog and driver-exit dialog disposed their `TextEditingController`s right after `await showDialog` → "used after being disposed" during the exit animation, cascading into the 99827px overflow / `_dependents.isEmpty` / wrong-build-scope errors in the log. Both are now `StatefulWidget` dialogs (`_InspectionPinDialog`, `_DriverExitDialog`) that own and dispose their controllers; content wrapped in `SingleChildScrollView` for the keyboard. Test added (dot_inspection_page_test +1: validation + cancel with `takeException() == null`).
  - **Identity: gold primary / black secondary.** `AppColors.eldAppBar` and `primaryBlue` now resolve to `primaryGold` (single source; drawer header, Information Packet / Instructions / User Manual app bars follow). `colorScheme.secondary = AppColors.secondary` (black), `onSecondary = gold`. AppBar theme gold, `centerTitle: true`. New `snackBarTheme` (black, floating, rounded, gold action).
  - **One Scaffold background for every page:** removed page-level `backgroundColor:` overrides (info_packet, send_logs, dvir_form, codriver, instructions, user_manual) so all use `scaffoldBackgroundColor` (#FAFAFA) with white cards/`border` — comment in `app_theme.dart` says not to set it per page.
  - **Error/success colours:** `EldRetryView(isError:)` — failures in `styles.error`, empty states neutral (logs noRecords, dvir/vehicle/settings empty). DOT inspection error texts → `styles.error`/`styles.warning`; Unidentified banner → error style. New `lib/core/widgets/app_feedback.dart` (`AppFeedback.success/error/info`) replaces hand-built SnackBars in account, codriver, connection, dvir_form, change_status_page/sheet, edit_log, unidentified, settings, trailers, shipping — success green, failure error colour, info theme black.
  - **Perf on device / weak network:** removed the duplicate Dio `LogInterceptor(requestBody/responseBody: true)` (double logging; printed the login body); `RequestLogger` only in `kDebugMode`; `AppLogger` `methodCount: 0` (no `StackTrace.current` per HTTP line). New `lib/core/utils/provider_cache.dart` `cacheFor(ref, duration)` on `rulesScreenProvider` (5 min), `informationPacketProvider` (5 min), `hardwareStatusProvider` (30 s) — re-opening those pages shows data instantly; retry/pull-to-refresh still `invalidate`. Timeouts unchanged (30 s).
  - Still not done (needs owner decision): the 8 held items.
- Batch 25 (user log 2026-09-25 — the pasted log is the pre-batch-24 build: the 23:49 `TextEditingController used after being disposed` crash and the 00:17 `Duplicate GlobalKeys … Overlay Theater` cascade share the dialog-dispose root cause fixed in batch 24):
  - **Inspection exit = local PIN check (SRS 7.5).** `_DriverExitDialog` no longer asks for the login password and no longer calls `POST /api/session` (log showed `401` on `{email, password: 1234}` — the inspection PIN was being compared against the account password). It now calls the existing `InspectionNotifier.exitWithPin(pin)` (REUSE), so exit works offline at the roadside and the login password is never re-sent. Bilingual errors in `styles.error` ("Enter the inspection PIN." / "Incorrect PIN."). Removed the now-unused auth/backend/storage imports from `dot_inspection_page.dart`. `exitAfterDriverVerified()` is left in the notifier (unused) — remove in a hygiene pass if wanted.
  - **Connect requires a MAC.** `eld_connection_page.dart`: MAC `AppTextField` wrapped in a `Form` (`autovalidateMode: onUserInteraction`); `_attemptConnection` validates first, so an empty MAC shows "MAC address is required." / «عنوان MAC مطلوب.» and no Bluetooth/server attempt is made. Rule lives in `connectivity_status.dart` (`isMacAddress`, `macAddressError`) — one source shared with the prefill. Format is **not** rejected (device labels are not always colon-separated).
  - **My vehicles empty — server data, not app.** `GET /eld/company-vehicles/my-vehicles` (openapi: optional `driverId`; "المركبات المخصصة مباشرة للسائق وفق Traccar") returned `data: []` for driver 106 while `GET /eld/hardware/status` reports `ELD-PRO-1006`. Hardware status is the *connected ELD*, not a Traccar driver→device assignment; the app must not derive Select/Operate from it (View≠Select≠Operate). Fix is on the server/Traccar side: link driver 106 to device 1006.
  - Tests: +1 `dot_inspection_page_test` (exit dialog: empty → required, wrong → refused, right → unlocked, `verifyZeroInteractions(backend)`); +1 `eld_connection_page_test` (empty MAC → required error, `verifyNever(bt.connect)`, typing clears it). 605 pass.
- Batch 26 (external UI/UX + architecture review, triaged in `docs/EXTERNAL_REVIEW_TRIAGE_2026-09-25.md` — many findings were from a pre-batch-24 snapshot):
  - Fixed: VIN `substring` RangeError (`_vinTail`, + widget test); `certify_tab` SignatureController built once; `NOT READY` → `loc.notReady`; Unidentified stat labels bilingual; hard-coded blue `0xFF1565C0` ×3 → `primaryGold`; `AppStatusBadge.info` → `infoText`; `EldCard` clip; `_rowOf` standard-code switch first; `_mapToEldEvent` m/s→mph (+ processor test corrected); Settings URL http/https validation (+ test); `RetryPolicy` comment (linear, locked by test); `AppColors` usage doc.
  - Deleted dead code: `ChangeStatusSheet` (0 callers → single change-status path), `widgets/main_circular_timer.dart` duplicate, `countdown_wheel.dart`, `trackingEventProcessorProvider` (null data source, unreferenced).
  - Reverted after test evidence: Send-mode transfer channel stays `EMAIL` (openapi default; screen shows "Email").
  - Held/decisions (see triage §C/§E): HosStateMachine persistence, DiagnosticsEngine delete, sync unification, TraccarMapper delete/wire, Permissions Always-only, port 5055 config, TimeAuthority in native validator, AppButton palette.

## Do not do

- Invent API fields to silence 400s.
- Treat GPS as ECM.
- Grant operate on unassigned company fleet.
- Restyle Information Packet / Send Logs / manuals / account / DVIR insert (the catalog row is an addition under the existing defect fields, not a layout change).

## Batch 37 — manual-mode END + hardware readiness (owner decisions 2026-09-25)

Owner decided: (ب) manual recording stays on About / Diagnostics but **only when degraded or manual mode is active**; G1 + G2 now; PM/backend question 13 added.

| Change | Where | Notes |
|---|---|---|
| `ConnectivityStatus` gains `manualModeActive` / `manualModeReason` / `manualRecordingAllowed` | `features/connection/domain/connectivity_status.dart` | absent → null (never assumed active) |
| `HardwareReadiness` + `parseHardwareReadiness` | `features/connection/domain/hardware_readiness.dart` | `GET /eld/hardware/readiness`; checklist order kept; missing `ready` → not ready |
| `hardwareReadinessProvider` | `features/connection/presentation/providers/hardware_status_provider.dart` | same 30 s cache policy as status; uses existing `HardwareBackend.getReadiness` |
| `EldReadinessPanel` (G2) | `features/connection/presentation/widgets/eld_diagnostics_section.dart` | ✓/✗ per server key (known keys labelled AR/EN, unknown keys shown as-is), `rejectionReasons` + `recommendedAction` verbatim (server text is authoritative — Arabic-only strings are a backend defect, see questions doc) |
| `ManualRecordingSection` END toggle (G1) | same file | visible when degraded **or** `manualModeActive`; END → reason dialog → `setManualMode(enable:false)` (server requires reason both ways); `manualRecordingAllowed:false` → no START, explanation in error colour; invalidates status + readiness after success |
| About card: refresh icon + readiness panel | `features/about/presentation/pages/about_page.dart` | retry for both server reads |
| Mock `getReadiness` returns a PreOperationReadinessResponse-shaped body | `backend/adapters/mock/sub/mock_hardware_backend.dart` | was `UnimplementedError` |
| Tests | `test/features/connection/hardware_readiness_test.dart` (4), `eld_diagnostics_section_test.dart` (+5) | 603 pass + 1 skip |

Not done on purpose: no `sendTelemetry` caller; `connectSession` call site unchanged; no §7.14 malfunction list (no API); Manual RODS ↔ `manualMode` naming left as-is pending question 13.

## Batch 37b — re-test vs Swagger 05.4 / 07 / 08 (live bodies 2026-09-25)

`test/backend/live_contract_2026_09_25_test.dart` (12 tests): every path, `action` wire value and body key the app sends matches the Swagger sections; parsers accept the exact live bodies (co-driver none `{coDriverId:0,teamDrivingActive:false,message}`, catalog item `code/name/nameAr/statutoryMandatory/criticalSafety`, DOT screen flags, cycle `[]`).

Findings (no code change needed): app never used `GET /eld/drivers` — picker source is Traccar `GET /drivers` (correct: `manageCoDriver` needs an id to act on, it is not a list). Unused-but-available: `GET /eld/daily-logs/{id}/team` (team status + `hosRecordsIsolated`), `GET /eld/dvir/pre-trip/{uniqueId}` (backend method exists, previous-DVIR review currently uses the vehicle-scoped list). DVIR insert sends `inspectionType:'Pre-Trip'` fixed; `latitude/longitude/photos/passengerCarrying` not sent (optional; no fake values). POST start / send-logs still server-side 500/400 (jsonb photos / CHECK status) — unchanged.

## PARKED — device-connection track (owner directive 2026-09-26)

«تجاهل مرحلة الاتصال بالجهاز واعتمد ما هو جاهز حتى يتم تزويدنا بالمعلومات من الإدارة.»
Until PM/backend answer `docs/QUESTIONS_FOR_PM_AND_BACKEND_2026-09-25.md` (Q1–Q13): **do not** touch `attemptConnection` / BLE step / `connectSession` call site, `sendTelemetry`, `TraccarPlugin.kt` role, SRS §3.2 wording, or the Manual RODS ↔ `manualMode` naming. What already ships (connection page, About readiness/manual toggle, CONTINUE DISCONNECTED) stays as-is. Work continues only on server-ready, non-hardware paths.

## Batch 38 — server-ready paths adopted (2026-09-26)

| Change | Where | Notes |
|---|---|---|
| §396.13 previous-DVIR source = `GET /eld/dvir/pre-trip/{uniqueId}` | `DvirRepository.getPreviousDvir` (+impl), `DvirState.previousDvir/previousToReview`, `DvirNotifier.loadPreviousDvir`, `dvir_form_page.dart` | Live "No Records" body → nothing to review; DVIR body → report; unreadable/failed → **falls back to the vehicle-scoped list** (previous behaviour). Banner + pre-sign review now share one source (`previousToReview`), so an already-reviewed report no longer shows the banner. Form calls the lookup once on open for new reports. |
| SRS 5.8 HOS isolation line on Co-Driver page | `EldEndpoints.teamStatus`, `DailyLogsBackend.getTeamStatus` (+eld/mock), `features/codriver/domain/team_status.dart`, `providers/team_status_provider.dart`, `_HosIsolationLine` in `codriver_page.dart` | Today's log id via `list(driverId, today, limit 1)` → `/team`; no log today → nothing shown; `hosRecordsIsolated` null → nothing shown (never assumed); `complianceNote` verbatim (server text); read failure → muted one-liner. |
| Mock backends | `mock_dvir_backend.getPreviousDvir`, `mock_daily_logs_backend.getTeamStatus` | were `UnimplementedError`; now live-shaped bodies |
| Tests | `test/features/dvir/previous_dvir_source_test.dart` (7), `test/features/codriver/team_status_test.dart` (4), `codriver_page_test.dart` (+2) | 628 pass + 1 skip |

