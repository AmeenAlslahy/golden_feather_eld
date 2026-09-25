import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';

/// Session store used by the HTTP layer.
///
/// This provider lives outside presentation so network and sync do not import
/// auth pages or auth state notifiers.
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl();
});
