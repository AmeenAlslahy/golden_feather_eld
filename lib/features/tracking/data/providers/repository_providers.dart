import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/local_storage_service.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/native_event_channel_client.dart';
import '../datasources/tracking_local_data_source.dart';
import '../repositories/tracking_repository_impl.dart';
import '../services/tracking_service.dart';

final trackingLocalDataSourceProvider = Provider<TrackingLocalDataSource>((ref) {
  return TrackingLocalDataSourceImpl(ref.watch(localStorageProvider));
});

final nativeEventChannelClientProvider = Provider<NativeEventChannelClient>((ref) {
  return NativeEventChannelClient();
});

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  return TrackingRepositoryImpl(
    service: ref.watch(trackingServiceProvider),
    localDataSource: ref.watch(trackingLocalDataSourceProvider),
    nativeClient: ref.watch(nativeEventChannelClientProvider),
    storage: ref.watch(localStorageProvider),
  );
});
