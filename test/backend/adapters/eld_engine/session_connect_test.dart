import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/session_connect.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/core/network/api_response.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';

ApiResponse<RawJson> parsed(
  Object? rawBody, {
  int statusCode = 200,
  RawJson Function(dynamic)? parser,
}) {
  return ApiResponse.fromBody<RawJson>(
    statusCode: statusCode,
    rawBody: rawBody,
    parser: parser ?? EldSessionConnect.parsePermissiveBody,
  );
}

void main() {
  group('EldSessionConnect.payload', () {
    test('always carries the manual-mode flags', () {
      expect(EldSessionConnect.payload(), {
        'manualMode': false,
        'manualModeEnabled': true,
      });
    });

    test('includes only the optional ids that were supplied', () {
      expect(
        EldSessionConnect.payload(
          uniqueId: '44A4',
          disconnected: true,
          driverId: const DriverId(101),
          coDriverId: const DriverId(202),
        ),
        {
          'driverId': 101,
          'coDriverId': 202,
          'deviceId': '44A4',
          'manualMode': true,
          'manualModeEnabled': true,
        },
      );
    });
  });

  group('EldSessionConnect response parsers', () {
    test('permissive parser accepts any Map', () {
      final source = <dynamic, dynamic>{'id': 7};

      expect(EldSessionConnect.parsePermissiveBody(source), {'id': 7});
    });

    test('typed parser keeps only Map<String, dynamic>', () {
      final typed = <String, dynamic>{'id': 7};

      expect(EldSessionConnect.parseTypedMapBody(typed), same(typed));
      expect(
        EldSessionConnect.parseTypedMapBody(<dynamic, dynamic>{'id': 7}),
        isEmpty,
      );
      expect(EldSessionConnect.parseTypedMapBody('ok'), isEmpty);
    });

    test('both parsers use an empty map for null', () {
      expect(EldSessionConnect.parsePermissiveBody(null), isEmpty);
      expect(EldSessionConnect.parseTypedMapBody(null), isEmpty);
    });
  });

  group('EldSessionConnect.failureMarkerOf', () {
    test('detects boolean and string false markers', () {
      expect(
        EldSessionConnect.failureMarkerOf({'success': false}),
        'success_false',
      );
      expect(
        EldSessionConnect.failureMarkerOf({'status': 'FALSE'}),
        'status_false',
      );
    });

    test('ignores bodies without an explicit rejection', () {
      expect(EldSessionConnect.failureMarkerOf({'success': true}), isNull);
      expect(EldSessionConnect.failureMarkerOf({'status': 'ok'}), isNull);
      expect(EldSessionConnect.failureMarkerOf('not a map'), isNull);
    });
  });

  group('EldSessionConnect.confirmedPayload', () {
    test('returns non-empty envelope data', () {
      final response = parsed({
        'success': true,
        'data': {'id': 7},
      });

      expect(EldSessionConnect.confirmedPayload(response), {'id': 7});
    });

    test('returns a non-empty direct body', () {
      expect(EldSessionConnect.confirmedPayload(parsed({'id': 7})), {'id': 7});
    });

    test('rejects empty, missing, and non-object data', () {
      expect(
        EldSessionConnect.confirmedPayload(
          parsed({'success': true, 'data': <String, dynamic>{}}),
        ),
        isNull,
      );
      expect(
        EldSessionConnect.confirmedPayload(
          parsed({'success': true, 'message': 'accepted'}),
        ),
        isNull,
      );
      expect(
        EldSessionConnect.confirmedPayload(
          parsed({'success': true, 'data': 'ok'}),
        ),
        isNull,
      );
      expect(
        EldSessionConnect.confirmedPayload(parsed(<String, dynamic>{})),
        isNull,
      );
    });
  });

  group('EldSessionConnect.requestIdOf', () {
    test('prefers a trimmed raw-body requestId', () {
      final response = parsed({
        'success': true,
        'data': {'id': 7},
        'requestId': '  req-raw  ',
      });

      expect(EldSessionConnect.requestIdOf(response), 'req-raw');
    });

    test('falls back to the envelope requestId', () {
      final response = parsed({
        'success': true,
        'data': {'id': 7},
        'requestId': 'req-envelope',
      });

      expect(EldSessionConnect.requestIdOf(response), 'req-envelope');
    });

    test('returns null when absent', () {
      expect(
        EldSessionConnect.requestIdOf(
          parsed({
            'success': true,
            'data': {'id': 7},
          }),
        ),
        isNull,
      );
    });

    test('a blank raw requestId defers to the envelope value', () {
      // The raw reader trims and rejects blanks, then the envelope value is
      // used as-is (ApiResponse does not trim). This is the legacy behavior.
      expect(
        EldSessionConnect.requestIdOf(
          parsed({
            'success': true,
            'data': {'id': 7},
            'requestId': '   ',
          }),
        ),
        '   ',
      );
    });
  });

  group('EldSessionConnect.dataOrEmpty', () {
    test('maps a missing payload to an empty map', () {
      final response = parsed({'success': true, 'message': 'accepted'});

      expect(EldSessionConnect.dataOrEmpty(response), isEmpty);
    });
  });
}
