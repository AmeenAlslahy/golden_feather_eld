import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/di/auth_local_data_source_provider.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/live_tracking_data_source.dart';
import '../../../../core/time/time_authority_provider.dart';
import '../../../tracking/domain/entities/connection_status.dart';
import '../../data/repositories/memory_offline_queue.dart';
import '../../data/repositories/sqlite_offline_queue.dart';
import '../../data/repositories/traccar_remote_event_dispatcher.dart';
import '../../domain/entities/pending_event.dart';
import '../../domain/repositories/offline_queue.dart';
import '../../domain/usecases/sync_engine.dart';

class MockRemoteEventDispatcher implements RemoteEventDispatcher {
  @override
  Future<Either<Failure, bool>> dispatch(PendingEvent event) async {
    // محاكاة إرسال للـ Backend (Traccar أو غيره)
    await Future.delayed(const Duration(milliseconds: 500));
    return const Right(true);
  }
}

class FailClosedRemoteEventDispatcher implements RemoteEventDispatcher {
  @override
  Future<Either<Failure, bool>> dispatch(PendingEvent event) async {
    // حماية (Fail-closed): نمنع فقدان البيانات بحظر الحذف الوهمي في الإنتاج
    return const Left(ServerFailure(
      message: 'Production dispatcher not implemented yet. Event retained.',
    ));
  }
}

final offlineQueueProvider = Provider<OfflineQueue>((ref) {
  if (AppEnvironmentConfig.current == AppEnvironment.mock) {
    return MemoryOfflineQueue();
  }
  return SQLiteOfflineQueue();
});

final remoteEventDispatcherProvider = Provider<RemoteEventDispatcher>((ref) {
  final env = AppEnvironmentConfig.current;

  if (env == AppEnvironment.mock) {
    return MockRemoteEventDispatcher();
  }

  final dutyStatusBackend = ref.watch(dutyStatusBackendProvider);
  final localDataSource = ref.watch(authLocalDataSourceProvider);
  return TraccarRemoteEventDispatcher(dutyStatusBackend, localDataSource);
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final queue = ref.watch(offlineQueueProvider);
  final dispatcher = ref.watch(remoteEventDispatcherProvider);
  final timeAuthority = ref.watch(timeAuthorityProvider);

  final engine = SyncEngine(
    queue: queue,
    dispatcher: dispatcher,
    timeAuthority: timeAuthority,
  );

  // استماع لحالة الاتصال من نظام التتبع
  final liveTracking = ref.watch(liveTrackingDataSourceProvider);

  final subscription = liveTracking.connectionStatus.listen((status) {
    if (status == ConnectionStatus.connected) {
      // عند عودة الاتصال، نقوم بمحاولة المزامنة
      engine.triggerSync();
    }
  });

  ref.onDispose(() {
    subscription.cancel();
  });

  return engine;
});
