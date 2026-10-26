# Security Test Coverage & Automated Assurance Plan
**Project:** Golden Feather ELD  
**Target Platform:** Flutter Mobile Application (Android / iOS)  
**Standard:** OWASP MASVS v2.0 Testing Guide & Clean Architecture Verification  
**Status:** Audit & Test Engineering Roadmap  
**Date:** October 2026  

---

## 1. Executive Summary

A comprehensive audit of the `test/` directory within the Golden Feather ELD repository was performed. The testing suite exhibits commendable coverage for domain calculations (e.g. `hos_calculator_test.dart`), Riverpod state transitions, and offline mutation dispatch fences (`dispatch_ownership_test.dart`, `queue_ownership_storage_test.dart`).

However, **security property testing**—specifically covering storage encryption, logout cache sanitization, session expiration handling, TLS failure responses, BLE data authentication, and screen shielding—is currently absent or reliant on test doubles that stub out security logic.

This document inventories existing security-relevant tests, identifies critical testing gaps, and provides concrete specifications for recommended unit, integration, and manual security tests.

---

## 2. Inventory of Existing Security-Relevant Tests

| Test Suite / File | Target Component | Security Property Evaluated | Limitations / Evaluation |
| :--- | :--- | :--- | :--- |
| [`test/features/sync/dispatch_ownership_test.dart`](file:///d:/Flutter%20projects/golden_feather_eld/test/features/sync/dispatch_ownership_test.dart) | `TraccarRemoteEventDispatcher` | Cross-driver mutation isolation; quarantining events when `ownership.driverId != sessionDriverId`. | **Effective.** Confirms that events belonging to Driver A are not dispatched under Driver B's active session. |
| [`test/features/sync/queue_ownership_storage_test.dart`](file:///d:/Flutter%20projects/golden_feather_eld/test/features/sync/queue_ownership_storage_test.dart) | `SQLiteOfflineQueue` | Storage and retrieval of quarantine records and dead letters. | **Functional Only.** Uses unencrypted in-memory SQLite; does not test encryption at rest or file permissions. |
| [`test/features/auth/presentation/providers/auth_state_provider_test.dart`](file:///d:/Flutter%20projects/golden_feather_eld/test/features/auth/presentation/providers/auth_state_provider_test.dart) | `AuthStateNotifier` | Session epoch transitions, login state updates, force logout triggering. | **Mocks Repository.** Uses `MockAuthRepository`; does not test secure storage read/write failures or keychain deadlocks. |
| [`test/architecture/`](file:///d:/Flutter%20projects/golden_feather_eld/test/architecture/) | Clean Architecture Rules | Prevents illegal dependencies between presentation and data layers. | **Architectural Hygiene.** Prevents architectural regression. |

---

## 3. Security Test Coverage Gaps

```
Security Test Domain              Current Coverage Status
────────────────────────────────────────────────────────────
Storage Encryption (Hive/SQLite)  [░░░░░░░░░░░░░░░░░░░░]   0%  (MISSING)
Logout Cache Invalidation        [░░░░░░░░░░░░░░░░░░░░]   0%  (MISSING)
TLS Certificate Pinning           [░░░░░░░░░░░░░░░░░░░░]   0%  (MISSING)
BLE Peripheral Authentication     [░░░░░░░░░░░░░░░░░░░░]   0%  (MISSING)
Clock Tampering Detection         [████████░░░░░░░░░░░░]  40%  (PARTIAL - Unit tests only)
Electronic Signature Binding      [░░░░░░░░░░░░░░░░░░░░]   0%  (MISSING)
Android IPC Boundary Leakage      [░░░░░░░░░░░░░░░░░░░░]   0%  (MISSING)
Driver Scope Rule Enforcement     [████████████████░░░░]  80%  (STRONG - Architecture tests)
Queue Ownership Quarantine        [████████████████████] 100%  (EXCELLENT - Dedicated tests)
```

### Critical Missing Scenarios:
1. **Cache Leakage Across Driver Sessions:** No automated test asserts that `daily_logs_cache_box` or draft signatures are unavailable to Driver B after Driver A logs out.
2. **Encrypted Storage Verification:** No automated test asserts that raw database files on disk are unreadable without the AES encryption key.
3. **Network Transport Security:** No automated test simulates an untrusted TLS certificate or proxy to ensure Dio rejects the connection.
4. **Android Intent Boundary:** No instrumentation test checks whether `ACTION_LOCATION_UPDATE` can be intercepted by an external package.

---

## 4. Recommended Unit Tests

Create the following unit tests in `test/security/`:

### Test 4.1: Logout Cache Purge Verification (`test/security/logout_sanitization_test.dart`)
```dart
test('Logout must purge user daily logs cache and draft signatures', () async {
  final container = ProviderContainer(...);
  final authNotifier = container.read(authStateProvider.notifier);
  final hiveService = container.read(localDatabaseServiceProvider);

  // Setup: Simulate Driver A logging in and caching data
  await hiveService.dailyLogsCacheBox.put('log_101', 'sensitive_driver_A_log');
  await hiveService.dailyLogsCacheBox.put('sig_draft:101', 'driver_A_signature_draft');

  // Action: Logout
  await authNotifier.logout();

  // Assertion: All user-scoped cache keys must be deleted
  expect(hiveService.dailyLogsCacheBox.get('log_101'), isNull);
  expect(hiveService.dailyLogsCacheBox.get('sig_draft:101'), isNull);
});
```

### Test 4.2: Storage Encryption Validation (`test/security/storage_encryption_test.dart`)
```dart
test('Hive boxes must be encrypted with 256-bit AES cipher', () async {
  final tempDir = await Directory.systemTemp.createTemp();
  final key = Hive.generateSecureKey();
  
  final box = await Hive.openBox<String>(
    'test_box',
    encryptionCipher: HiveAesCipher(key),
    path: tempDir.path,
  );
  await box.put('secret', 'Confidential HOS Record');
  await box.close();

  // Inspect raw bytes on disk
  final file = File('${tempDir.path}/test_box.hive');
  final rawBytes = await file.readAsBytes();
  final rawString = String.fromCharCodes(rawBytes);

  expect(rawString.contains('Confidential HOS Record'), isFalse);
});
```

### Test 4.3: Digital Signature Binding (`test/security/signature_cryptography_test.dart`)
```dart
test('Digital signature verification must fail if log contents are modified', () {
  final keyPair = generateMockECKeyPair();
  final logPayload = '{"logDate":"2026-10-26","driverId":101,"vin":"1ABC..."}';
  final signature = signPayload(keyPair.privateKey, logPayload);

  // Verification succeeds on authentic payload
  expect(verifySignature(keyPair.publicKey, logPayload, signature), isTrue);

  // Verification fails on tampered payload
  final tamperedPayload = '{"logDate":"2026-10-26","driverId":101,"vin":"1ABC...","odometer":99999}';
  expect(verifySignature(keyPair.publicKey, tamperedPayload, signature), isFalse);
});
```

---

## 5. Recommended Integration Tests

### Test 5.1: Cross-Driver Session Transition Isolation (`integration_test/account_switching_test.dart`)
- **Objective:** Verify that on a shared mobile device, switching from Driver A to Driver B immediately updates all presentation providers and prevents stale requests from mutating state.
- **Steps:**
  1. Authenticate Driver A (`driverId = 1`).
  2. Navigate to HOS Log Details; verify Driver A logs load.
  3. Initiate `AuthNotifier.logout()`.
  4. Authenticate Driver B (`driverId = 2`).
  5. Assert that Driver B sees empty or Driver B logs only.
  6. Verify that any in-flight requests from Driver A were cancelled with `OwnerMismatchSignal`.

### Test 5.2: TLS Certificate Validation Rejection (`integration_test/tls_pinning_test.dart`)
- **Objective:** Verify that the HTTP networking client rejects self-signed or invalid certificates.
- **Steps:**
  1. Configure `ApiClient` against a local test server presenting a self-signed SSL certificate.
  2. Attempt `GET /api/session`.
  3. Assert that a `HandshakeException` or `DioExceptionType.badResponse` occurs and that zero request bytes or cookies are transmitted.

---

## 6. Required Manual Security Tests

| Test ID | Procedure | Expected Security Behavior |
| :--- | :--- | :--- |
| **MST-01** | **Broadcast Intent Interception:** Deploy an unprivileged test Android app listening for `ACTION_LOCATION_UPDATE`. Drive 1 mile. | Test app receives zero location updates. Updates remain confined to Golden Feather ELD. |
| **MST-02** | **Recent Apps Task Switcher Masking:** Open the Golden Feather ELD app, navigate to certified log details, and press the Android App Overview / Recents button. | Screen thumbnail appears blank or shows a solid privacy mask due to `FLAG_SECURE`. |
| **MST-03** | **Offline Clock Tampering:** Turn on Airplane Mode. Force-stop the app. Move the device system clock back by 3 hours. Launch the app and attempt to record a duty status transition. | The app indicates that trusted time is unavailable and refuses to create a certified log event until clock drift is resolved. |
| **MST-04** | **BLE Telemetry Injection:** Run a script using a BLE dongle transmitting false NMEA/J1939 strings on characteristic `0000ffe1-...`. | App rejects the connection or ignores telemetry until cryptographic mutual pairing is completed. |
