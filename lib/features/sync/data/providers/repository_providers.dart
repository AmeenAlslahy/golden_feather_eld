import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/network/core_providers.dart';
import '../../domain/repositories/offline_queue.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../domain/usecases/sync_engine.dart';
import '../datasources/sync_local_data_source.dart';
import '../repositories/memory_offline_queue.dart';
import '../repositories/sync_repository_impl.dart';
import '../repositories/traccar_remote_event_dispatcher.dart';

final syncLocalDataSourceProvider = Provider<SyncLocalDataSource>((ref) {
  return SyncLocalDataSourceImpl();
});

final offlineQueueProvider = Provider<OfflineQueue>((ref) {
  return MemoryOfflineQueue();
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepositoryImpl(
    localDataSource: ref.watch(syncLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
    dispatcher: ref.watch(syncDispatcherProvider),
  );
});

final syncDispatcherProvider = Provider<RemoteEventDispatcher>((ref) {
  return TraccarRemoteEventDispatcher(
    ref.watch(dutyStatusBackendProvider),
    ref.watch(authLocalDataSourceProvider),
  );
});
