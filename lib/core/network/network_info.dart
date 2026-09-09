import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Stream<bool> get onConnectionChange;
  bool get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;
  bool _currentStatus = true;
  final _controller = StreamController<bool>.broadcast();

  NetworkInfoImpl() : _connectivity = Connectivity() {
    _connectivity.onConnectivityChanged.listen((result) {
      _currentStatus = !result.contains(ConnectivityResult.none);
      _controller.add(_currentStatus);
    });
  }

  @override
  Stream<bool> get onConnectionChange => _controller.stream;

  @override
  bool get isConnected => _currentStatus;

  void dispose() => _controller.close();
}
