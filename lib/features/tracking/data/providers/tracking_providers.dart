import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/local_storage_service.dart';
import '../../../../core/time/time_authority_provider.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/native_event_channel_client.dart';
import '../datasources/tracking_local_data_source.dart';
import '../services/tracking_service.dart';
import '../repositories/tracking_repository_impl.dart';

// --- DI: طبقة البيانات هي من تركّب مصادرها ومستودعها (المرحلة 3b) ---

/// مزود مصدر البيانات المحلي
final trackingLocalDataSourceProvider = Provider<TrackingLocalDataSource>((
  ref,
) {
  final storage = ref.watch(localStorageProvider);
  return TrackingLocalDataSourceImpl(storage);
});

/// مزود خدمة التتبع الكامل.
///
/// يعيد استخدام [trackingServiceProvider] نفسه بدل إنشاء نسخة ثانية.
/// كانت النسختان تعنيان: خدمة يهيّئها `AppInitializer` عند الإقلاع
/// (وتستخدمها الإشعارات والإجراءات السريعة)، وخدمة أخرى ينشئها المستودع
/// وتهيّئ الـ SDK الأصلي مرة أخرى عند أول `startTracking` — أي `configure`
/// مزدوج وتهيئة مزدوجة بلا داعٍ.
final trackingServiceFullProvider = Provider<TrackingService>((ref) {
  return ref.watch(trackingServiceProvider);
});

/// مزود العميل الأصلي
final nativeEventChannelClientProvider = Provider<NativeEventChannelClient>((
  ref,
) {
  final time = ref.watch(timeAuthorityProvider);
  final client = NativeEventChannelClient(
    validator: NativeLocationQualityValidator(nowUtc: time.nowUtc),
  );
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
