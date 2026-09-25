import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/native_location_event.dart';

import 'tracking_providers.dart';

// A stream provider that exposes ONLY valid/stale/suspicious native locations to the UI.
// This is intentionally isolated from HOS, Diagnostics, and Distance engines.
final nativeLocationUiStreamProvider =
    StreamProvider<NativeLocationEvent>((ref) {
  final client = ref.watch(nativeEventChannelClientProvider);

  // We start listening when the UI watches this stream.
  // Note: For a real background service, the startListening might need to be
  // tied to the actual tracking service start/stop commands. But for now,
  // listening to the event channel is safe if the native side is broadcasting.
  client.startListening();

  return client.locationStream;
});

enum NativeLocationUiState {
  noNativeLocationReceived,
  receivingNativeLocation,
  lastLocalLocationStale,
  nativeLocationUnavailable,
  permissionDenied,
  locationServiceDisabled
}

final nativeLocationUiStateProvider = Provider<NativeLocationUiState>((ref) {
  final locationAsyncValue = ref.watch(nativeLocationUiStreamProvider);

  return locationAsyncValue.when(
    data: (location) {
      if (location.qualityStatus == LocationQualityStatus.stale) {
        return NativeLocationUiState.lastLocalLocationStale;
      }
      return NativeLocationUiState.receivingNativeLocation;
    },
    error: (_, __) => NativeLocationUiState
        .nativeLocationUnavailable, // Or permission denied depending on error
    loading: () => NativeLocationUiState.noNativeLocationReceived,
  );
});
