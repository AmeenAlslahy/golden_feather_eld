import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/network/core_providers.dart';
import '../../../sync/data/providers/sync_providers.dart';
import '../../domain/repositories/log_repository.dart';
import '../datasources/log_local_data_source.dart';
import '../repositories/log_repository_impl.dart';

// --- DI: طبقة البيانات هي من تركّب مستودعها (المرحلة 3b) ---

final logRepositoryProvider = Provider<LogRepository>((ref) {
  return LogRepositoryImpl(
    localDataSource: ref.watch(logLocalDataSourceProvider),
    dailyLogsBackend: ref.watch(dailyLogsBackendProvider),
    dutyStatusBackend: ref.watch(dutyStatusBackendProvider),
    networkInfo: ref.watch(networkInfoProvider),
    offlineQueue: ref.watch(offlineQueueProvider),
  );
});
