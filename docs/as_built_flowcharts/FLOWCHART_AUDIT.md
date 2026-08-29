# FLOWCHART AUDIT LOG
سجل التدقيق البرمجي (Reachability & Orphan Analysis)

يقوم هذا السجل بتوثيق الأجزاء غير المكتملة، المقلدة (Mocks)، أو المعزولة (Orphans) التي تم اكتشافها خلال عملية التتبع العكسي للتطبيق، لضمان أن المخططات الانسيابية تمثل فقط ما هو مُنفذ ومُتصل فعلياً.

---

## 1. Orphaned Executions (أكواد معزولة / غير مستدعاة)

| Component | Code Symbol | Issue Description | Impact on Flowchart |
|---|---|---|---|
| **HOS Rules Engine** | `HosRulesEngine.processEvent(EldEvent event)` | The method is fully defined and contains complex logic for automatic duty status transitions based on speed (`_shouldAutoTransitionToDriving`). However, a deep codebase search reveals this method is **never invoked**. The `LiveTrackingDataSource` streams `EldEvent` objects to `DutyStatusTracker`, but does not feed them into the `HosRulesEngine`. The UI instead calls `manualTransition` via `HosNotifier.changeStatus()`. | The automatic speed-based transition in HOS Engine has been marked as an **ORPHAN** flow and visualized with a broken red line in `09_hos_logic.mmd`. |

---

## 2. Mock Implementations (تنفيذ وهمي / مقلد)

| Component | Code Symbol | Issue Description | Impact on Flowchart |
|---|---|---|---|
| **Vehicle Connection** | `_EldConnectionPageState._attemptConnection()` | The Bluetooth/Connection page UI simulates a connection delay using `Future.delayed(const Duration(seconds: 2))` instead of initiating a real Bluetooth/OBDII handshake process in the frontend. | The connection step in the master flow is tagged as **MOCK**, pointing to the simulated delay. |
| **Authentication Repository** | `AuthRepositoryImpl.register()` | Contains a mock implementation: `await Future.delayed(const Duration(seconds: 1)); return const Right(true);`. | The user registration flow is excluded from the deep execution flowcharts as it lacks backend integration. |
| **Authentication Repository** | `AuthRepositoryImpl.forgotPassword()` | Contains a mock implementation similar to register. | The forgot password flow is excluded from the deep execution flowcharts. |

---

## 3. Disconnected Data Flows (تدفقات بيانات منفصلة)

| Component | Architecture Finding | Description |
|---|---|---|
| **HOS State vs Tracking State** | `DutyStatusTracker` vs `HosRulesEngine` | There are two parallel systems managing Duty Status. `DutyStatusTracker` listens to the tracking stream and saves to `LogRepository`. `HosRulesEngine` manages the FMCSA limits and alerts via `HosStateMachine` but relies entirely on manual user input (`HosNotifier.changeStatus()`). They are not currently synchronized automatically. |
