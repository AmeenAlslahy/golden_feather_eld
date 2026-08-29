import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'traccar_websocket_client.dart';

/// تنفيذ عميل WebSocket الخاص بـ Traccar عبر /api/socket.
/// يدعم إعادة الاتصال التلقائي وبث حالة الاتصال.
class TraccarWebSocketClientImpl implements TraccarWebSocketClient {
  WebSocket? _webSocket;
  String? _serverUrl;
  String? _cookie;

  final StreamController<Map<String, dynamic>> _positionsController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _eventsController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionStateController = StreamController<bool>.broadcast();

  bool _isConnecting = false;
  bool _shouldReconnect = true;
  Timer? _reconnectTimer;

  @override
  Stream<Map<String, dynamic>> get positionsStream => _positionsController.stream;

  @override
  Stream<Map<String, dynamic>> get eventsStream => _eventsController.stream;

  @override
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  @override
  Future<void> connect(String serverUrl, String cookie) async {
    _serverUrl = serverUrl;
    _cookie = cookie;
    _shouldReconnect = true;
    await _connectInternal();
  }

  Future<void> _connectInternal() async {
    if (_isConnecting || _serverUrl == null || _cookie == null) return;
    
    _isConnecting = true;
    try {
      final wsUrl = _serverUrl!.replaceFirst('http', 'ws');
      final uri = Uri.parse('$wsUrl/api/socket');

      _webSocket = await WebSocket.connect(
        uri.toString(),
        headers: {'Cookie': _cookie},
      );
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
                  // الوسم لمنع الإرسال المزدوج
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
              // تجاهل أخطاء فك التشفير إذا كانت الرسالة ليست JSON صالحاً
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

  void _handleDisconnect() {
    _webSocket = null;
    if (_shouldReconnect) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 5), () {
        if (_shouldReconnect && _webSocket == null) {
          _connectInternal();
        }
      });
    }
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
    await _connectInternal();
  }

  void dispose() {
    disconnect();
    _positionsController.close();
    _eventsController.close();
    _connectionStateController.close();
  }
}
