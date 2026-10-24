import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:golden_feather_eld/features/auth/data/datasources/auth_local_data_source.dart'; // ignore_architecture

/// Session store used by the HTTP layer.
///
/// This provider lives outside presentation so network and sync do not import
/// auth pages or auth state notifiers.
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl();
});
