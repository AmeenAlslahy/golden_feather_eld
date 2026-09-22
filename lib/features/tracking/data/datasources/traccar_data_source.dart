import 'dart:async';

import '../../../../core/config/app_environment.dart';
import '../../../../core/domain/shared/speed.dart';
// ignore: directives_ordering
import '../../../../core/utils/logger.dart';
import '../../domain/entities/connection_status.dart';
import '../../domain/entities/tracking_event.dart';
import 'native_event_channel_client.dart';
import 'traccar_sdk/traccar_api_client.dart';
import 'traccar_sdk/traccar_native_client.dart';
import 'traccar_sdk/traccar_websocket_client.dart';
import 'tracking_data_source.dart';

/// محوّل (Adapter) يقوم بدمج عملاء Traccar المختلفة (API, WebSocket, Native)
/// لتقديم واجهة TrackingDataSource الموحدة للنظام دون أن يتسرب أي من تفاصيل Traccar للخارج.
class TraccarDataSource implements TrackingDataSource {
  // ignore: unused_field
  final TraccarApiClient _apiClient;
  final TraccarWebSocketClient _webSocketClient;
  final TraccarNativeClient _nativeClient;
  final NativeEventChannelClient _nativeEventClient;
  StreamSubscription? _nativeEventSubscription;

  final StreamController<TrackingEvent> _eventsController =
      StreamController<TrackingEvent>.broadcast();
  final StreamController<ConnectionStatus> _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  StreamSubscription? _wsConnectionSubscription;

  TraccarDataSource({
    required TraccarApiClient apiClient,
    required TraccarWebSocketClient webSocketClient,
    required TraccarNativeClient nativeClient,
    required NativeEventChannelClient nativeEventClient,
  })  : _apiClient = apiClient,
        _webSocketClient = webSocketClient,
        _nativeClient = nativeClient,
        _nativeEventClient = nativeEventClient {
    // ملاحظة: سيتم ربط Stream الخاص بـ WebSocket وتمريره عبر Mapper مستقبلاً هنا

    // نرسل حالة مبدئية "غير متصل" أو "غير مهيأ"
    final baseUrl = AppEnvironmentConfig.apiBaseUrl;
    final isConfigured =
        baseUrl.isNotEmpty && !baseUrl.contains('mock-traccar-server');

    final initialStatus = isConfigured
        ? ConnectionStatus.disconnected
        : ConnectionStatus.unconfigured;

    AppLogger.info(
        'TraccarDataSource: Emitting initial ConnectionStatus.$initialStatus');
    _connectionStatusController.add(initialStatus);

    _wsConnectionSubscription =
        _webSocketClient.connectionStateStream.listen((isConnected) {
      final status = isConnected
          ? ConnectionStatus.connected
          : ConnectionStatus.disconnected;
      AppLogger.info('TraccarDataSource: ConnectionStatus updated to $status');
      _connectionStatusController.add(status);
    });
  }

  @override
  Stream<TrackingEvent> get events => _eventsController.stream;

  @override
  Stream<ConnectionStatus> get connectionStatusStream =>
      _connectionStatusController.stream;

  @override
  Future<void> start() async {
    AppLogger.info('TraccarDataSource: Starting native background tracking');
    // بدء التتبع على مستوى الـ Native Background
    await _nativeClient.startBackgroundTracking();

    // الاستماع للقناة وتمرير الإحداثيات
    _nativeEventClient.startListening();
    _nativeEventSubscription ??=
        _nativeEventClient.locationStream.listen((nativeEvent) {
      final trackingEvent = TrackingEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        deviceId: AppEnvironmentConfig.traccarDeviceId.isNotEmpty
            ? AppEnvironmentConfig.traccarDeviceId
            : 'native_device',
        latitude: nativeEvent.latitude,
        longitude: nativeEvent.longitude,
        speed: Speed.fromMetersPerSecond(nativeEvent.speedMetersPerSecond),
        bearing: nativeEvent.bearingDegrees,
        altitude: nativeEvent.altitudeMeters,
        accuracy: nativeEvent.accuracyMeters,
        timestampUtc: nativeEvent.recordedAt,
        source: TrackingEventSource.gps,
      );
      _eventsController.add(trackingEvent);
    });

    // ملاحظة: الاتصال بـ WebSocket قد يتم هنا أو من خلال إدارة خارجية متخصصة
    // بالاعتماد على توفر الـ serverUrl و token
  }

  @override
  Future<void> stop() async {
    // إيقاف التتبع في الخلفية
    await _nativeClient.stopBackgroundTracking();

    _nativeEventClient.stopListening();
    _nativeEventSubscription?.cancel();
    _nativeEventSubscription = null;

    // فصل الاتصال الحي
    await disconnectWebSocket();
  }

  Future<void> connectWebSocket(String serverUrl, String cookie) async {
    AppLogger.info('TraccarDataSource: Connecting WebSocket to $serverUrl');
    await _webSocketClient.connect(serverUrl, cookie);
  }

  Future<void> disconnectWebSocket() async {
    AppLogger.info('TraccarDataSource: Disconnecting WebSocket');
    await _webSocketClient.disconnect();
  }

  @override
  Future<TrackingEvent?> getLastEvent() async {
    // يمكن هنا استدعاء REST API (مثل _apiClient.getPositions) لجلب آخر موقع مسجل.
    // في مرحلة لاحقة سيتم تطبيق TraccarMapper لتحويل البيانات من Map إلى TrackingEvent.
    return null;
  }

  /// تنظيف الموارد
  void dispose() {
    _wsConnectionSubscription?.cancel();
    _eventsController.close();
    _connectionStatusController.close();
  }
}
