import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEvent {
  logDataChanged,
}

class AppEventBus {
  final _controller = StreamController<AppEvent>.broadcast();
  Stream<AppEvent> get stream => _controller.stream;
  void fire(AppEvent event) => _controller.add(event);
}

final appEventBusProvider = Provider<AppEventBus>((ref) {
  final bus = AppEventBus();
  ref.onDispose(bus._controller.close);
  return bus;
});
