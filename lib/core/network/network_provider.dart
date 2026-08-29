import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Provider to check if the device is currently connected to the internet
final networkStatusProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  
  // Emit initial state
  final initialResult = await connectivity.checkConnectivity();
  yield !initialResult.contains(ConnectivityResult.none);
  
  // Listen for changes
  await for (final result in connectivity.onConnectivityChanged) {
    yield !result.contains(ConnectivityResult.none);
  }
});
