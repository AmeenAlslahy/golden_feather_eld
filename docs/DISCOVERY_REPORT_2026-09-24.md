# Discovery Report — 2026-09-24

Owner batch: remaining in-scope driver SRS gaps on the existing tree.
Rule: SEARCH → REUSE → EXTEND → CREATE LAST. No parallel pages. No invented API fields.

## Proven facts

| Item | Evidence |
|---|---|
| Live vehicle route | `HomeRoutes` → `SelectVehiclePage` (`lib/features/vehicle/presentation/pages/select_vehicle_page.dart`). |
| `connectSession` called twice | `VehicleRepositoryImpl.selectVehicle` and `EldConnectionPage` CONNECT / CONTINUE DISCONNECTED. |
| VIEW ALL | Unassigned dialog `loadCompanyVehicles()` then same tap path as My Vehicles. |
| Form SAVE `vehicles[]` | SRS 5.13 lists it. OpenAPI `UpdateDailyFormRequest` required/`properties`: `uniqueId`, `coDriverId`, `trailers`, `shippingDocuments`, `notes`. **No `vehicles`.** |
| Packet completeness | `informationPacketProvider` + `parseInformationPacket` exist; `InfoPacketPage` does not watch them. |
| Send logs routing | Backend already accepts `routingCode`. UI does not collect it. |
| Inspection events | `DotInspectionEvent` has `origin`, `notes`, `certificationEvent`. Table does not show them. |
| 24h start | OpenAPI `period24HourStartTime`. Domain cycle/log models do not map it. UI hardcodes `00:00`. |
| Co-driver session | `manageCoDriver` exists on `DriverSessionBackend`. OK on picker only sets local `selectedCoDriver`. |
| Unidentified capture | `UnidentifiedCapture.capture` requires `fromEcm`. Tracking maps GPS `EldEvent` without `fromEcm`. Orchestrator does not call `capture`. Logout stops tracking. |
| About | `AppRoutes.about` exists. `EldMenu.items` omits it. |
| Certify NOT READY | `onPressed: () {}`. |

## Conflicts (do not pick silently)

1. **SRS 5.13 `vehicles[]` vs OpenAPI form.** Stop. Do not invent the field. `uniqueId` is the vehicle key on the wire.
2. **GPS vs ECM.** Do not set `fromEcm: true` on phone GPS. Capture wiring is still correct; it will no-op until ECM events exist.
3. **Screenshot Menu omits About vs SRS 2.2 About.** SRS wins for presence of the existing About route.
4. **Inspection start 400 / send-logs 400.** Server CHECK / Hibernate. Out of app.

## This batch (implement)

1. List tap = local select after motion/id guards. `connectSession` only on connection page.
2. Company list: operate only if `isAssigned`; otherwise unauthorized. Refresh respects browse mode.
3. Certify NOT READY pops.
4. Add About to `EldMenu`.
5. Show event origin / notes / certification; stop inventing `00:00`.
6. Optional routing-code field on Send/Email Logs (existing API param).
7. Packet landing watches `informationPacketProvider` (status only; keep the two original blocks).
8. Picker OK → existing `manageCoDriver` (link/remove). Needs real `uniqueId`.
9. Switch copy: co-driver becomes the driver.
10. Orchestrator: if not authenticated, `UnidentifiedCapture.capture(event)`.

## Not this batch

- Form `vehicles[]` (OpenAPI conflict).
- Mapping `period24HourStartTime` (needs Freezed field + build_runner).
- Keep tracking after logout.
- USB/Bluetooth ELD file generation.
- Carrier portal / Fleet Manager.
- Fake photos / SUCCESS status for known server 400s.

## Tests

- `listedVehicleIsOperable` in `vehicle_selection_test.dart`.
- Certify NOT READY has a non-null `onPressed`.
- Existing vehicle-selection and inspection-transfer tests must still pass.
