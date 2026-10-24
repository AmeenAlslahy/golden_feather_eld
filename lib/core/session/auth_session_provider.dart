import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_session.dart';
import 'auth_session_reader.dart';

/// Production composition overrides this with the auth feature's data source.
///
/// The no-session default keeps isolated tests deterministic and prevents core
/// from importing auth data.
final authSessionReaderProvider = Provider<AuthSessionReader>(
  (ref) => const _NoSessionReader(),
);

class _NoSessionReader implements AuthSessionReader {
  const _NoSessionReader();

  @override
  Future<AuthSession?> getSession() async => null;

  @override
  int get credentialGeneration => 0;
}
