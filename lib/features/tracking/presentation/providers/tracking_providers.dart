import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../data/datasources/native_event_channel_client.dart';
import '../../data/datasources/tracking_local_data_source.dart';
import '../../data/repositories/tracking_repository_impl.dart';
import '../../data/services/tracking_service.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../../domain/usecases/tracking_event_processor.dart';

/// مزود حالة خدمة الـ GPS
final gpsStatusProvider =
    StreamProvider.autoDispose<ServiceStatus>((ref) async* {
  bool isEnabled = await Geolocator.isLocationServiceEnabled();
  yield isEnabled ? ServiceStatus.enabled : ServiceStatus.disabled;
  yield* Geolocator.getServiceStatusStream();
});

/// مزود مصدر البيانات المحلي
final trackingLocalDataSourceProvider =
    Provider<TrackingLocalDataSource>((ref) {
  final storage = ref.watch(localStorageProvider);
  return TrackingLocalDataSourceImpl(storage);
});

/// مزود خدمة التتبع
final trackingServiceFullProvider = Provider<TrackingService>((ref) {
  final storage = ref.watch(localStorageProvider);
  final tracker = ref.watch(traccarNativeClientProvider);
  return TrackingService(storage: storage, tracker: tracker);
});

/// مزود العميل الأصلي
final nativeEventChannelClientProvider =
    Provider<NativeEventChannelClient>((ref) {
  final client = NativeEventChannelClient();
  ref.onDispose(() => client.dispose());
  return client;
});

/// مزود مستودع التتبع
final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  final service = ref.watch(trackingServiceFullProvider);
  final localDataSource = ref.watch(trackingLocalDataSourceProvider);
  final nativeClient = ref.watch(nativeEventChannelClientProvider);
  final storage = ref.watch(localStorageProvider);
  return TrackingRepositoryImpl(
    service: service,
    localDataSource: localDataSource,
    nativeClient: nativeClient,
    storage: storage,
  );
});

// مزود المعالج
final trackingEventProcessorProvider = Provider<TrackingEventProcessor>((ref) {
  // للوصول إلى AppEnvironmentConfig نعتمد على الاستيراد المناسب، ولكن يمكننا تبسيطها:
  // إذا كان لدينا TraccarDataSource جاهز نستخدمه، وإلا نرسل null ليستخدم Mock.
  // ملاحظة: لقد قمنا بربطه بالفعل داخل live_tracking_data_source.dart
  // لذلك لا نحتاج trackingDataSourceProvider هنا.

  final processor = TrackingEventProcessor();
  if (AppEnvironmentConfig.current == AppEnvironment.mock) {
    processor.startProcessing();
  }

  ref.onDispose(() {
    processor.dispose();
  });

  return processor;
});
