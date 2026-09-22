import 'package:flutter_riverpod/flutter_riverpod.dart';

// **CLEAN ARCH 100%:** Presentation يستورد فقط من composition root — لا من data/repositories مباشرة
import '../../../../app/providers/app_repository_providers.dart';
import '../../../../core/services/live_tracking_data_source.dart';
import '../../../../core/time/time_authority_provider.dart';
import '../../../tracking/domain/entities/connection_status.dart';
import '../../domain/usecases/sync_engine.dart';

// Re-export للتوافق — الواجهة الموحدة من composition root
export '../../data/providers/repository_providers.dart'
    show offlineQueueProvider, syncDispatcherProvider;

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final queue = ref.watch(offlineQueueProvider);
  final dispatcher = ref.watch(syncDispatcherProvider);
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
