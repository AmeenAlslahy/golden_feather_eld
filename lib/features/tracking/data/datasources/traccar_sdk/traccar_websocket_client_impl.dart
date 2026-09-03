import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'traccar_websocket_client.dart';

/// تنفيذ عميل WebSocket الخاص بـ Traccar عبر /api/socket.
/// يدعم إعادة الاتصال التلقائي مع تراجع أسي وبث حالة الاتصال.
class TraccarWebSocketClientImpl implements TraccarWebSocketClient {
  WebSocket? _webSocket;
  String? _serverUrl;
  String? _cookie;

  final StreamController<Map<String, dynamic>> _positionsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _eventsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();

  bool _isConnecting = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  @override
  Stream<Map<String, dynamic>> get positionsStream =>
      _positionsController.stream;

  @override
  Stream<Map<String, dynamic>> get eventsStream => _eventsController.stream;

  @override
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  @override
  Future<void> connect(String serverUrl, String cookie) async {
    _serverUrl = serverUrl;
    _cookie = cookie;
    _shouldReconnect = true;
    _reconnectAttempts = 0; // إعادة ضبط المحاولات عند الاتصال الأولي
    await _connectInternal();
  }

  Future<void> _connectInternal() async {
    if (_isConnecting || _serverUrl == null || _cookie == null) return;

    _isConnecting = true;
    try {
      // استخدام Uri لاستبدال scheme بشكل آمن
      final uri = Uri.parse(_serverUrl!);
      final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
      final wsUri = uri.replace(scheme: wsScheme, path: '/api/socket');
      final wsUrl = wsUri.toString();

      _webSocket = await WebSocket.connect(
        wsUrl,
        headers: {'Cookie': _cookie},
      );

      // إعادة ضبط محاولات إعادة الاتصال عند النجاح
      _reconnectAttempts = 0;
      _connectionStateController.add(true);

      _webSocket!.listen(
        (data) {
          if (data is String) {
            try {
              final Map<String, dynamic> decoded = jsonDecode(data);

              if (decoded.containsKey('positions')) {
                final positions = decoded['positions'] as List;
                for (var pos in positions) {
                  final mapPos = pos as Map<String, dynamic>;
                  mapPos['source'] = 'remoteTraccar';
                  _positionsController.add(mapPos);
                }
              }

              if (decoded.containsKey('events')) {
                final events = decoded['events'] as List;
                for (var event in events) {
                  _eventsController.add(event as Map<String, dynamic>);
                }
              }
            } catch (e) {
              // تجاهل أخطاء فك التشفير
            }
          }
        },
        onDone: () {
          _connectionStateController.add(false);
          _handleDisconnect();
        },
        onError: (error) {
          _connectionStateController.add(false);
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      _connectionStateController.add(false);
      _handleDisconnect();
    } finally {
      _isConnecting = false;
    }
  }

  /// معالجة الانفصال مع تراجع أسي
  void _handleDisconnect() {
    _webSocket = null;
    if (_shouldReconnect) {
      _reconnectTimer?.cancel();
      final delay = _calculateBackoffDelay();
      _reconnectTimer = Timer(Duration(seconds: delay), () {
        if (_shouldReconnect && _webSocket == null) {
          _connectInternal();
        }
      });
    }
  }

  /// حساب تأخير إعادة الاتصال باستخدام التراجع الأسي (2^attempts) بحد أقصى 60 ثانية
  int _calculateBackoffDelay() {
    // 2^attempts
    int delay = 1 << _reconnectAttempts; // يساوي pow(2, attempts)
    if (delay > 60) delay = 60;
    _reconnectAttempts++;
    return delay;
  }

  @override
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    await _webSocket?.close();
    _webSocket = null;
    _connectionStateController.add(false);
  }

  @override
  Future<void> reconnect() async {
    await disconnect();
    _shouldReconnect = true;
    _reconnectAttempts = 0; // إعادة ضبط المحاولات عند إعادة الاتصال اليدوي
    await _connectInternal();
  }

  void dispose() {
    disconnect();
    _positionsController.close();
    _eventsController.close();
    _connectionStateController.close();
  }
}