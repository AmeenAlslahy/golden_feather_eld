# Security Remediation Plan & Engineering Roadmap
**Project:** Golden Feather ELD  
**Target Platform:** Flutter Mobile Application (Android / iOS)  
**Standard:** OWASP MASVS v2.0 Remediation Guidelines  
**Status:** Approved Architectural Action Plan  
**Date:** October 2026  

---

## 1. Overview & Remediation Strategy

This document establishes a prioritized, phased engineering strategy to systematically resolve all security vulnerabilities and architectural weaknesses identified during the Golden Feather ELD deep security audit.

Every proposed remediation preserves:
1. **The Clean Architecture structure** of the application.
2. **The Driver App Scope Rule** (no back-office management code).
3. **FMCSA 49 CFR Part 395 compliance behavior**.
4. **Offline synchronization reliability and performance**.

Remediations are organized into five sequential stages prioritized by exploitability, data impact, and regulatory liability:
- **Stage 1:** Critical & High-Risk Operating System and Transport Vulnerabilities.
- **Stage 2:** Session Invalidation, Electronic Signatures, and Offline Clock Integrity.
- **Stage 3:** Network & Platform Hardening (TLS Pinning, Screen Shielding).
- **Stage 4:** Configuration & Logging Hygiene.
- **Stage 5:** Automated Security Verification & Long-Term Governance.

---

## 2. Prioritized Vulnerability Inventory

| Vulnerability ID | Finding Title | Severity | CWE | Remediation Target Component |
| :--- | :--- | :--- | :--- | :--- |
| **SEC-ANDROID-001** | Sensitive GPS Location Leak via Implicit Broadcast | **HIGH** | CWE-927 | `TrackingForegroundService.kt` |
| **SEC-STORAGE-001** | Plaintext Local Storage in Hive & SQLite | **HIGH** | CWE-312 | `LocalDatabaseService.dart`, `sqlite_offline_queue.dart` |
| **SEC-BLE-001** | Insecure & Unauthenticated BLE Connection | **HIGH** | CWE-306 | `BluetoothPlugin.kt` |
| **SEC-STORAGE-002** | Incomplete Cache & Draft Cleanup on Logout | **MEDIUM** | CWE-459 | `AuthRepositoryImpl.dart` |
| **SEC-SIGN-001** | Electronic Signatures Lack Cryptographic Binding | **MEDIUM** | CWE-347 | `certify_log_provider.dart`, `log_local_data_source.dart` |
| **SEC-TIME-001** | Offline Monotonic Time Tampering Vulnerability | **MEDIUM** | CWE-361 | `trusted_time_provider.dart` |
| **SEC-NET-001** | Absence of TLS Certificate Pinning | **MEDIUM** | CWE-295 | `api_client.dart`, `NetworkUploader.kt` |
| **SEC-LOG-001** | Coordinates Logged to Android Logcat | **LOW** | CWE-532 | `TrackingForegroundService.kt` |
| **SEC-ANDROID-002** | Missing `FLAG_SECURE` in Android MainActivity | **LOW** | CWE-200 | `MainActivity.kt` |
| **SEC-CONF-001** | Cleartext `.env` Asset Inclusion | **LOW** | CWE-538 | `pubspec.yaml`, Build configuration |
| **SEC-ANDROID-003** | `BootReceiver` Missing Permission Declaration | **LOW** | CWE-276 | `AndroidManifest.xml` |

---

## 3. Detailed Remediation Roadmap

---

### STAGE 1: Critical & High-Risk Vulnerabilities (Immediate Priority)

#### Task 1.1: Seal Android Location Broadcast (SEC-ANDROID-001)
- **Target File:** [`android/app/src/main/kotlin/com/goldenfeather/eld/TrackingForegroundService.kt`](file:///d:/Flutter%20projects/golden_feather_eld/android/app/src/main/kotlin/com/goldenfeather/eld/TrackingForegroundService.kt#L181-L183)
- **Required Fix:**
  Replace the implicit broadcast with an explicit intent restricted to the application's package name:
  ```kotlin
  // In TrackingForegroundService.kt:
  val intent = Intent("com.goldenfeather.eld.ACTION_LOCATION_UPDATE").apply {
      setPackage(packageName)
      putExtra("location", location)
  }
  sendBroadcast(intent)
  ```
- **Implementation Risks:** Low. Any internal receivers registered by the app will continue receiving updates; external eavesdropping applications will be immediately blocked.
- **Required Regression Tests:** Verify that foreground and background location tracking continue to update the Flutter UI and Traccar ingestion client.
- **Validation Criteria:** Deploy a secondary test application registering a receiver for `com.goldenfeather.eld.ACTION_LOCATION_UPDATE` and assert that zero broadcast intents are intercepted.

#### Task 1.2: Implement Local Storage Encryption for Hive & SQLite (SEC-STORAGE-001)
- **Target Files:**
  - [`lib/core/services/local_database_service.dart`](file:///d:/Flutter%20projects/golden_feather_eld/lib/core/services/local_database_service.dart#L10-L40)
  - [`lib/features/sync/data/repositories/sqlite_offline_queue.dart`](file:///d:/Flutter%20projects/golden_feather_eld/lib/features/sync/data/repositories/sqlite_offline_queue.dart#L110-L145)
- **Required Fix:**
  1. Retrieve or generate a 256-bit AES encryption key stored securely in `FlutterSecureStorage` (backed by Android Keystore / iOS Keychain).
  2. Pass `HiveAesCipher(encryptionKey)` when opening Hive boxes:
     ```dart
     final key = await secureStorageService.getOrCreateDbKey();
     final cipher = HiveAesCipher(key);
     await Hive.openBox<String>(StorageConstants.eventsBox, encryptionCipher: cipher);
     await Hive.openBox<String>(StorageConstants.dailyLogsCacheBox, encryptionCipher: cipher);
     ```
  3. Migrate `sqlite_offline_queue.dart` to use `sqflite_sqlcipher` or introduce database encryption password parameters.
- **Implementation Risks:** Medium-High. Existing unencrypted local databases on driver devices must be safely migrated or decrypted before re-encrypting to avoid data loss.
- **Required Regression Tests:** Test fresh install, upgrade from unencrypted schema, and verify that offline sync mutations survive app restarts.
- **Validation Criteria:** Inspect the database files via ADB shell on a test device; assert that file headers and payloads do not contain plaintext strings.

#### Task 1.3: Establish Authenticated & Bonded BLE Connection (SEC-BLE-001)
- **Target File:** [`android/app/src/main/kotlin/com/goldenfeather/eld/BluetoothPlugin.kt`](file:///d:/Flutter%20projects/golden_feather_eld/android/app/src/main/kotlin/com/goldenfeather/eld/BluetoothPlugin.kt#L125-L135)
- **Required Fix:**
  1. Check device bond state before establishing GATT connection. If unbonded, initiate `device.createBond()` and await pairing completion.
  2. Require encrypted GATT characteristics (`BluetoothGattCharacteristic.PERMISSION_READ_ENCRYPTED`).
  3. Implement an application-level challenge-response handshake upon connection before accepting odometer, engine hour, or speed telemetry.
- **Implementation Risks:** High. Requires alignment with the physical ELD hardware firmware and manufacturer specification.
- **Required Regression Tests:** Connect to physical and simulated ELD hardware, test reconnection after signal loss, test pairing rejection when invalid PIN/credentials are entered.
- **Validation Criteria:** Attempt connecting with a simulated BLE peripheral; verify that telemetry is rejected unless the cryptographic handshake succeeds.

---

### STAGE 2: High-Risk Authentication, Signatures & Integrity (Priority 2)

#### Task 2.1: Implement Complete Cache & State Invalidation on Logout (SEC-STORAGE-002)
- **Target File:** [`lib/features/auth/data/repositories/auth_repository_impl.dart`](file:///d:/Flutter%20projects/golden_feather_eld/lib/features/auth/data/repositories/auth_repository_impl.dart#L102-L105)
- **Required Fix:**
  Update `_clearLocalData()` to clear all user-scoped data stores:
  ```dart
  Future<void> _clearLocalData() async {
    await _localDataSource.clearSession();
    await _localDataSource.clearUser();
    // Purge cached daily logs, draft signatures, and driver-specific offline caches
    await _localDatabaseService.clearUserCaches();
    await _offlineQueue.purgeDriverDeferredEvents();
  }
  ```
- **Implementation Risks:** Low. Ensures that when Driver A logs out, Driver B cannot view Driver A's cached daily logs, draft signatures, or pending mutations.
- **Required Regression Tests:** Log in as Driver A, view logs, create a draft signature, log out, log in as Driver B, and verify that no prior driver data is displayed.
- **Validation Criteria:** Check Hive box contents and UI providers after logout; confirm complete absence of stale data.

#### Task 2.2: Cryptographically Bind Electronic Signatures (SEC-SIGN-001)
- **Target Files:**
  - [`lib/features/logs/presentation/providers/certify_log_provider.dart`](file:///d:/Flutter%20projects/golden_feather_eld/lib/features/logs/presentation/providers/certify_log_provider.dart#L280)
  - [`lib/features/logs/data/datasources/log_local_data_source.dart`](file:///d:/Flutter%20projects/golden_feather_eld/lib/features/logs/data/datasources/log_local_data_source.dart#L60)
- **Required Fix:**
  1. Generate an ECDSA (P-256) key pair for the authenticated driver in Android Keystore / iOS Keychain.
  2. Before submitting certification, calculate the canonical SHA-256 digest of the daily log:
     `digest = SHA256(driverId + logDate + vin + events_hash + timestamp)`.
  3. Sign the digest with the private key.
  4. Submit `{ certified: true, signatureImage: "<base64>", digitalSignature: "<hex>", publicKey: "<hex>" }` to the server.
- **Implementation Risks:** Medium. Requires backend API coordination to verify the digital signature in addition to saving the visual bitmap.
- **Required Regression Tests:** Unit test signature generation, verification, and rejection of tampered log digests.
- **Validation Criteria:** Alter a single byte of the log data; verify that the digital signature verification fails.

#### Task 2.3: Harden Monotonic Time Restoration Against Clock Tampering (SEC-TIME-001)
- **Target File:** [`lib/core/time/trusted_time_provider.dart`](file:///d:/Flutter%20projects/golden_feather_eld/lib/core/time/trusted_time_provider.dart#L78-L80)
- **Required Fix:**
  Instead of relying on `DateTime.now()` to compute offline elapsed duration, query the hardware monotonic clock (`SystemClock.elapsedRealtime()` on Android) via a platform channel to measure elapsed duration across sleep/wake states. If the device was rebooted while offline and no trusted server anchor exists, mark the state as `TrustedTimeState.unavailable` rather than trusting the altered wall clock.
- **Implementation Risks:** Low.
- **Required Regression Tests:** Test device reboot while offline, app restart with altered system time, and recovery when network is restored.
- **Validation Criteria:** Alter device time by -4 hours offline; verify that the provider refuses to issue a trusted UTC timestamp until verified by GPS or network.

---

### STAGE 3: Network & Platform Hardening (Priority 3)

#### Task 3.1: Implement TLS Certificate Pinning (SEC-NET-001)
- **Target Files:**
  - [`lib/core/network/api_client.dart`](file:///d:/Flutter%20projects/golden_feather_eld/lib/core/network/api_client.dart#L46-L55)
  - [`android/app/src/main/res/xml/network_security_config.xml`](file:///d:/Flutter%20projects/golden_feather_eld/android/app/src/main/res/xml/network_security_config.xml)
- **Required Fix:**
  Configure public key hashes (SPKI pins) for `snsoft.cloud`:
  ```xml
  <network-security-config>
      <domain-config>
          <domain includeSubdomains="true">snsoft.cloud</domain>
          <pin-set expiration="2027-10-01">
              <pin digest="SHA-256">AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=</pin>
              <!-- Backup Pin -->
              <pin digest="SHA-256">BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=</pin>
          </pin-set>
      </domain-config>
  </network-security-config>
  ```
- **Implementation Risks:** High operational risk if certificates are rotated without updating backup pins. A robust pin expiration and backup pin strategy is essential.
- **Required Regression Tests:** Connect via standard network, test proxy interception failure with Burp Suite / OWASP ZAP.
- **Validation Criteria:** Intercept traffic with an untrusted root CA; confirm that connections are rejected with a TLS handshake error.

#### Task 3.2: Enable `FLAG_SECURE` in Android MainActivity (SEC-ANDROID-002)
- **Target File:** [`android/app/src/main/kotlin/com/goldenfeather/eld/MainActivity.kt`](file:///d:/Flutter%20projects/golden_feather_eld/android/app/src/main/kotlin/com/goldenfeather/eld/MainActivity.kt)
- **Required Fix:**
  Add `FLAG_SECURE` in `onCreate`:
  ```kotlin
  import android.os.Bundle
  import android.view.WindowManager

  class MainActivity: FlutterActivity() {
      override fun onCreate(savedInstanceState: Bundle?) {
          super.onCreate(savedInstanceState)
          window.setFlags(
              WindowManager.LayoutParams.FLAG_SECURE,
              WindowManager.LayoutParams.FLAG_SECURE
          )
      }
  }
  ```
- **Implementation Risks:** None. Prevents screenshots and masks the Recent Apps task switcher thumbnail.
- **Validation Criteria:** Attempt taking a screenshot on Android; verify that the OS blocks the capture with "Can't take screenshot due to security policy."

---

### STAGE 4: Configuration & Logging Hygiene (Priority 4)

#### Task 4.1: Remove Coordinates from Android Logcat (SEC-LOG-001)
- **Target File:** [`android/app/src/main/kotlin/com/goldenfeather/eld/TrackingForegroundService.kt:180`](file:///d:/Flutter%20projects/golden_feather_eld/android/app/src/main/kotlin/com/goldenfeather/eld/TrackingForegroundService.kt#L180)
- **Required Fix:**
  Remove or guard location logging with `if (BuildConfig.DEBUG)`:
  ```kotlin
  if (BuildConfig.DEBUG) {
      Log.d("TRACKING_SVC", "Location received (redacted)")
  }
  ```

#### Task 4.2: Remove `.env` Asset & Transition to Compile-Time Defines (SEC-CONF-001)
- **Target Files:** [`pubspec.yaml:108`](file:///d:/Flutter%20projects/golden_feather_eld/pubspec.yaml#L108), `.env`
- **Required Fix:**
  Remove `- .env` from the `assets` list in `pubspec.yaml`. Pass configuration values during build time using `--dart-define-from-file=config.json` or `--dart-define=API_BASE_URL=...`.

#### Task 4.3: Declare Missing Boot Permission (SEC-ANDROID-003)
- **Target File:** [`android/app/src/main/AndroidManifest.xml`](file:///d:/Flutter%20projects/golden_feather_eld/android/app/src/main/AndroidManifest.xml)
- **Required Fix:**
  Add `<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />` to the manifest.

---

## 4. Verification & Sign-Off Matrix

| Stage | Verification Activity | Owner | Pass Criteria |
| :--- | :--- | :--- | :--- |
| **Stage 1** | Native Broadcast & BLE Verification | Mobile Security Lead | 0 leaked intents; BLE handshake enforced. |
| **Stage 2** | Logout Sanitization & Signature Cryptography | Flutter Lead | No cross-driver cache retention; valid digital signatures. |
| **Stage 3** | TLS Interception & Screen Masking | SecOps / QA | Proxy interception rejected; screenshot blocked. |
| **Stage 4** | Build Audit & Asset Inspection | DevOps / CI | Clean logcat; `.env` excluded from APK assets. |
