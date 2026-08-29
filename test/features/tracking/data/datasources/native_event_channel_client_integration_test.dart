import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/tracking/domain/entities/native_location_event.dart';
import 'package:golden_feather_eld/features/tracking/data/datasources/native_event_channel_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeEventChannelClient', () {
    late NativeEventChannelClient client;
    final String channelName = 'com.goldenfeather.eld/traccar/events';
    late StreamController<dynamic> mockStreamController;

    setUp(() {
      mockStreamController = StreamController<dynamic>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        EventChannel(channelName),
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            mockStreamController.stream.listen((event) {
              events.success(event);
            }, onError: (error) {
              events.error(code: 'ERROR', message: error.toString(), details: null);
            }, onDone: () {
              events.endOfStream();
            });
          },
          onCancel: (arguments) {
            mockStreamController.close();
          },
        ),
      );

      client = NativeEventChannelClient();
    });

    tearDown(() {
      client.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(EventChannel(channelName), null);
    });

    test('Parses valid Android payload successfully', () async {
      final now = DateTime.now().toUtc();
      
      client.startListening();
      
      // Delay to ensure subscription is active before pushing events
      await Future.delayed(Duration.zero);

      final futureEvent = client.locationStream.first;

      mockStreamController.add({
        'latitude': 24.7136,
        'longitude': 46.6753,
        'speed': 15.0,
        'bearing': 90.0,
        'altitude': 100.0,
        'accuracy': 5.0,
        'timestamp': now.millisecondsSinceEpoch,
      });

      final event = await futureEvent;

      expect(event.latitude, 24.7136);
      expect(event.speedMetersPerSecond, 15.0);
      expect(event.source, LocationSource.localNative);
      // Ensure recordedAt uses the provided timestamp
      expect(event.recordedAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('Parses valid iOS payload successfully (using doubles)', () async {
      final now = DateTime.now().toUtc();
      
      client.startListening();
      await Future.delayed(Duration.zero);

      final futureEvent = client.locationStream.first;

      mockStreamController.add({
        'latitude': 24.7136,
        'longitude': 46.6753,
        'speed': 15.5,
        'bearing': 90.5,
        'altitude': 100.5,
        'accuracy': 5.5,
        // iOS might send double or Int timestamp depending on bridge implementation. 
        // Our parsing `(data['timestamp'] as num?)?.toInt()` handles both.
        'timestamp': now.millisecondsSinceEpoch.toDouble(),
      });

      final event = await futureEvent;

      expect(event.speedMetersPerSecond, 15.5);
      expect(event.recordedAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('Handles invalid payloads and produces correct quality status', () async {
      final now = DateTime.now().toUtc();
      
      client.startListening();
      await Future.delayed(Duration.zero);

      final events = <NativeLocationEvent>[];
      final subscription = client.locationStream.listen((event) {
        events.add(event);
      });

      // 1. Send malformed payload (missing latitude) - should be dropped completely
      mockStreamController.add({
        'longitude': 46.6753,
        'timestamp': now.millisecondsSinceEpoch,
      });

      // 2. Send payload with NaN - should be emitted as invalid
      mockStreamController.add({
        'latitude': double.nan,
        'longitude': 46.6753,
        'timestamp': now.millisecondsSinceEpoch,
      });

      // 3. Send valid payload - should be emitted as valid
      mockStreamController.add({
        'latitude': 24.0,
        'longitude': 46.0,
        'speed': 15.0,
        'timestamp': now.millisecondsSinceEpoch,
      });

      // Allow event loop to process
      await Future.delayed(const Duration(milliseconds: 100));

      // We should only receive 2 events (the first was malformed and dropped)
      expect(events.length, 2);
      expect(events[0].qualityStatus, LocationQualityStatus.invalid);
      expect(events[1].qualityStatus, LocationQualityStatus.valid);
      expect(events[1].latitude, 24.0);

      await subscription.cancel();
    });

    test('Allows only a single subscription to the native channel', () {
      client.startListening();
      client.startListening(); // Should not throw or create dual listeners

      expect(mockStreamController.hasListener, true);
    });

    test('Dispose closes the stream', () async {
      client.startListening();
      await Future.delayed(Duration.zero);

      client.dispose();
      await Future.delayed(Duration.zero);
      
      // Creating a new subscription on a closed stream should throw or return done immediately
      var isDone = false;
      client.locationStream.listen(
        (_) {},
        onDone: () {
          isDone = true;
        }
      );
      
      await Future.delayed(Duration.zero);
      expect(isDone, true);
    });
  });
}
