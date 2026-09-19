import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'adapters/flutter_secure_storage_adapter.dart';
import 'ports/key_value_port.dart';
import 'ports/secure_storage_port.dart';

/// Provides the app-wide [SecureStoragePort].
///
/// **Default:** [FlutterSecureStorageAdapter].
/// **Override in tests:** Provide an in-memory fake.
final secureStorageProvider = Provider<SecureStoragePort>((ref) {
  return const FlutterSecureStorageAdapter();
});

/// Provides the app-wide [KeyValuePort].
///
/// **Must be overridden in `main()`** with an instance created by
/// `SharedPreferencesAdapter.create()`. This avoids async-in-sync
/// awkwardness and keeps tests simple.
///
/// **Override in tests:** Provide a fake or a real adapter backed by
/// `SharedPreferences.setMockInitialValues({})`.
final keyValueStorageProvider = Provider<KeyValuePort>((ref) {
  throw UnimplementedError(
    'keyValueStorageProvider must be overridden in main() '
    'with an instance from SharedPreferencesAdapter.create().',
  );
});
