git add lib/core/storage/ lib/domain/config/ lib/features/settings/ `
        lib/backend/providers/backend_providers.dart `
        test/core/storage/ test/domain/config/ test/features/settings/

$commitMsg = @"
feat(settings): storage ports + server config (T4.0a)

T4.0a — Storage abstraction + Server Config model/UI.

**Added:**
- lib/core/storage/ports/secure_storage_port.dart.
- lib/core/storage/ports/key_value_port.dart.
- lib/core/storage/adapters/flutter_secure_storage_adapter.dart.
- lib/core/storage/adapters/shared_preferences_adapter.dart.
- lib/core/storage/storage_providers.dart.
- lib/domain/config/server_config.dart (Freezed + BackendType).
- lib/features/settings/presentation/providers/server_config_providers.dart.
- lib/features/settings/presentation/pages/server_config_page.dart.
- tests: 4 files, 20+ tests.

**Changed:**
- lib/backend/providers/backend_providers.dart:
  - reads serverConfigProvider but still returns MockAdapter.
  - EldEngineAdapter activation deferred to T4.0b.

**Not changed:**
- Legacy LocalStorageService / LocalDatabaseService.
- Any feature.
- Router.

Refs: T4.0a, ADR-007
"@

git commit -m $commitMsg
