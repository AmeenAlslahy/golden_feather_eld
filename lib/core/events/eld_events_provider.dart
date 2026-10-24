import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/connection_status.dart';
import '../domain/entities/hos_models.dart';
import '../domain/ports/live_eld_event_source.dart';

/// Production composition supplies the tracking implementation by overriding
/// this provider in `AppInitializer`.
///
/// The empty default keeps isolated tests deterministic and prevents core from
/// importing tracking data.
final liveEldEventSourceProvider = Provider<LiveEldEventSource>(
  (ref) => const _EmptyLiveEldEventSource(),
);

/// Domain-level provider exposing the live ELD events stream.
final eldEventsStreamProvider = StreamProvider<EldEvent>((ref) {
  return ref.watch(liveEldEventSourceProvider).events;
});

/// Domain-level provider exposing the live ELD connection status.
final eldConnectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  return ref.watch(liveEldEventSourceProvider).connectionStatus;
});

class _EmptyLiveEldEventSource implements LiveEldEventSource {
  const _EmptyLiveEldEventSource();

  @override
  Stream<EldEvent> get events => const Stream.empty();

  @override
  Stream<ConnectionStatus> get connectionStatus => const Stream.empty();
}
