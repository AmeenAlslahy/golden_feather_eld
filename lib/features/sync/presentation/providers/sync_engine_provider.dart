import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/sync_engine.dart';
import '../../data/repositories/memory_offline_queue.dart';
import '../../data/repositories/sqlite_offline_queue.dart';
import '../../domain/repositories/offline_queue.dart';
import 'package:golden_feather_eld/features/tracking/data/datasources/live_tracking_data_source.dart';
import '../../../tracking/domain/entities/connection_status.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/pending_event.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../data/repositories/traccar_remote_event_dispatcher.dart';
import '../../../../core/di/auth_local_data_source_provider.dart';
import '../../../../core/time/time_authority_provider.dart';
import '../../../../core/network/core_providers.dart';

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

  // SRS 6.8 — also flush the queue when *network* connectivity returns,
  // not only when the vehicle link reconnects.
  final networkSubscription =
      ref.watch(networkInfoProvider).onConnectionChange.listen((online) {
    if (online) engine.triggerSync();
  });

  ref.onDispose(() {
    subscription.cancel();
    networkSubscription.cancel();
  });

  return engine;
});
