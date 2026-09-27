import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'adapters/flutter_secure_storage_adapter.dart';
import 'ports/secure_storage_port.dart';

/// Provides the app-wide [SecureStoragePort].
///
/// **Default:** [FlutterSecureStorageAdapter].
/// **Override in tests:** Provide an in-memory fake.
final secureStorageProvider = Provider<SecureStoragePort>((ref) {
  return const FlutterSecureStorageAdapter();
});
