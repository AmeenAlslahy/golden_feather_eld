/// Composition root — مصنع TraccarDataSource المعزول.
///
/// **CLEAN ARCH 100%:** كل بناء DataSource يبقى هنا، لا في Presentation.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/core_providers.dart';
import '../../../../core/network/traccar/traccar_api_client_impl.dart';
import '../../../../core/network/traccar/traccar_websocket_client_impl.dart';
import '../datasources/traccar_data_source.dart';
import '../datasources/traccar_sdk/traccar_native_client_impl.dart';
import 'repository_providers.dart';

/// مصنع TraccarDataSource — الواجهة الوحيدة لبنائه.
final traccarDataSourceProvider = Provider<TraccarDataSource>((ref) {
  final dataSource = TraccarDataSource(
    apiClient: TraccarApiClientImpl(apiClient: ref.watch(apiClientProvider)),
    webSocketClient: TraccarWebSocketClientImpl(),
    nativeClient: TraccarNativeClientImpl(),
    nativeEventClient: ref.watch(nativeEventChannelClientProvider),
  );
  ref.onDispose(() => dataSource.dispose());
  return dataSource;
});
