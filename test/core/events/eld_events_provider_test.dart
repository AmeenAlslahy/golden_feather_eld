import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/domain/entities/connection_status.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/core/domain/ports/live_eld_event_source.dart';
import 'package:golden_feather_eld/core/events/eld_events_provider.dart';

class _FakeLiveEldEventSource implements LiveEldEventSource {
  _FakeLiveEldEventSource({
    required this.events,
    required this.connectionStatus,
  });

  @override
  final Stream<EldEvent> events;

  @override
  final Stream<ConnectionStatus> connectionStatus;
}

void main() {
  test('exposes events and connection status through the core port', () async {
    final event = EldEvent(
      timestamp: DateTime.utc(2026, 10, 21, 12),
      speedMph: 12,
    );
    final container = ProviderContainer(
      overrides: [
        liveEldEventSourceProvider.overrideWithValue(
          _FakeLiveEldEventSource(
            events: Stream.value(event),
            connectionStatus: Stream.value(ConnectionStatus.connected),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(eldEventsStreamProvider.future), same(event));
    expect(
      await container.read(eldConnectionStatusProvider.future),
      ConnectionStatus.connected,
    );
  });

  test('default source is empty', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final source = container.read(liveEldEventSourceProvider);

    expect(await source.events.toList(), isEmpty);
    expect(await source.connectionStatus.toList(), isEmpty);
  });
}
