import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/local_storage_service.dart';
import '../../domain/tracking_source_mode.dart';

/// Synchronous UI state for the selected transport, persisted in local storage.
///
/// The initial value is `bleDevice` to preserve the historical ELD connection
/// flow (MAC address + BLE link). Drivers who only want phone tracking switch to
/// `phoneGps` once and the choice survives restarts.
class TrackingSourceModeNotifier extends StateNotifier<TrackingSourceMode> {
  TrackingSourceModeNotifier(this._ref) : super(TrackingSourceMode.bleDevice) {
    _hydrate();
  }

  final Ref _ref;

  Future<void> _hydrate() async {
    try {
      final storage = _ref.read(localStorageProvider);
      final mode = TrackingSourceMode.fromWire(storage.trackingSourceMode);
      if (mounted) state = mode;
    } catch (_) {
      // Local storage not ready / test double without the getter: keep default.
    }
  }

  Future<void> setMode(TrackingSourceMode mode) async {
    if (state == mode) return;
    state = mode;
    try {
      await _ref.read(localStorageProvider).setTrackingSourceMode(mode.name);
    } catch (_) {}
  }

  /// Remembers the device the driver picked so auto-reconnect can find it after
  /// a process restart.
  Future<void> setBleDevice({required String macAddress, String? name}) async {
    try {
      await _ref
          .read(localStorageProvider)
          .setBleDevice(macAddress: macAddress, name: name);
    } catch (_) {}
  }
}

final trackingSourceModeProvider =
    StateNotifierProvider<TrackingSourceModeNotifier, TrackingSourceMode>((
      ref,
    ) {
      return TrackingSourceModeNotifier(ref);
    });
