import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/network/lenient_json_transformer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ISO-001: LenientJsonTransformer & lenientJsonDecode', () {
    late LenientJsonTransformer defaultTransformer;
    late LenientJsonTransformer lowThresholdTransformer;

    setUp(() {
      defaultTransformer = LenientJsonTransformer();
      // Low threshold of 50 bytes to force background isolate execution in tests
      lowThresholdTransformer = LenientJsonTransformer(isolateThresholdBytes: 50);
    });

    ResponseBody createResponseBody(String content, {int statusCode = 200}) {
      final bytes = utf8.encode(content);
      return ResponseBody.fromBytes(
        bytes,
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    ResponseBody createEmptyResponseBody({int statusCode = 204}) {
      return ResponseBody.fromBytes(
        Uint8List(0),
        statusCode,
        headers: {},
      );
    }

    RequestOptions createOptions({ResponseType responseType = ResponseType.json}) {
      return RequestOptions(path: '/test', responseType: responseType);
    }

    test('1. lenientJsonDecode parses valid JSON map correctly', () {
      const input = '{"status":"OK","code":200}';
      final result = lenientJsonDecode(input);
      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map)['status'], 'OK');
      expect(result['code'], 200);
    });

    test('2. lenientJsonDecode parses valid JSON array correctly', () {
      const input = '[{"id":1},{"id":2}]';
      final result = lenientJsonDecode(input);
      expect(result, isA<List<dynamic>>());
      expect((result as List).length, 2);
    });

    test('3. lenientJsonDecode handles malformed JSON fallback without throwing', () {
      const malformed = '<html><body>502 Bad Gateway</body></html>';
      final result = lenientJsonDecode(malformed);
      expect(result, malformed);
    });

    test('4. lenientJsonDecode preserves escaped quotes inside driver remarks', () {
      const input = r'{"remark":"Inspected \"engine\" thoroughly","driverId":42}';
      final result = lenientJsonDecode(input);
      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map)['remark'], 'Inspected "engine" thoroughly');
    });

    test('5. lenientJsonDecode preserves Unicode text (Arabic, Spanish, Accents)', () {
      const input = '{"driverName":"سائق تجريبي أحمد","location":"Estación de servicio"}';
      final result = lenientJsonDecode(input);
      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map)['driverName'], 'سائق تجريبي أحمد');
      expect(result['location'], 'Estación de servicio');
    });

    test('6. transformResponse returns empty map on empty string or whitespace', () async {
      final res1 = await defaultTransformer.transformResponse(
        createOptions(),
        createResponseBody(''),
      );
      expect(res1, equals(<String, dynamic>{}));

      final res2 = await defaultTransformer.transformResponse(
        createOptions(),
        createResponseBody('   \n\t  '),
      );
      expect(res2, equals(<String, dynamic>{}));
    });

    test('7. transformResponse handles HTTP 204 No Content safely', () async {
      final res = await defaultTransformer.transformResponse(
        createOptions(),
        createEmptyResponseBody(statusCode: 204),
      );
      expect(res, equals(<String, dynamic>{}));
    });

    test('8. transformResponse handles small JSON synchronously (<50 KB)', () async {
      const smallJson = '{"vehicleId":"TRUCK-99","status":"DRIVING"}';
      final res = await defaultTransformer.transformResponse(
        createOptions(),
        createResponseBody(smallJson),
      );
      expect(res, isA<Map<String, dynamic>>());
      expect((res as Map)['vehicleId'], 'TRUCK-99');
    });

    test('9. transformResponse handles large payload (>50 KB) via background isolate', () async {
      // Build a multi-event log sync response exceeding 50 KB
      final events = List.generate(
        350,
        (i) => {
          'id': i,
          'type': 'DUTY_STATUS_CHANGE',
          'status': 'DRIVING',
          'timestamp': '2026-10-26T04:00:00.000Z',
          'odometer': 125000.5 + i,
          'engineHours': 3450.2 + (i * 0.1),
          'notes': 'Log record index $i with extended remarks and coordinates',
          'location': 'Rest Area Mile Marker $i, Interstate 80 West',
        },
      );
      final largeJson = jsonEncode({'dailyLogId': 999, 'events': events});
      expect(largeJson.length, greaterThan(50 * 1024));

      final res = await defaultTransformer.transformResponse(
        createOptions(),
        createResponseBody(largeJson),
      );

      expect(res, isA<Map<String, dynamic>>());
      final map = res as Map<String, dynamic>;
      expect(map['dailyLogId'], 999);
      expect((map['events'] as List).length, 350);
    });

    test('10. transformResponse handles low threshold forcing background isolate', () async {
      const jsonContent = '{"forcedIsolate":true,"items":[1,2,3,4,5],"description":"testing compute isolate"}';
      expect(jsonContent.length, greaterThan(50));

      final res = await lowThresholdTransformer.transformResponse(
        createOptions(),
        createResponseBody(jsonContent),
      );

      expect(res, isA<Map<String, dynamic>>());
      expect((res as Map)['forcedIsolate'], isTrue);
      expect(res['items'], [1, 2, 3, 4, 5]);
    });

    test('11. Equivalent results between synchronous and background parsing', () async {
      final sample = {
        'id': 101,
        'title': 'Sync vs Background Equivalence Check',
        'unicode': 'سائق رقم 45 - revisión completada',
        'escaped': 'Quoted "values" and special symbols: \t \n \r / \\',
        'nested': {
          'subId': 'A-1',
          'active': true,
          'scores': [1.5, 2.7, 3.9],
        },
      };
      final sampleString = jsonEncode(sample);

      final syncResult = await defaultTransformer.transformResponse(
        createOptions(),
        createResponseBody(sampleString),
      );

      final isolateResult = await lowThresholdTransformer.transformResponse(
        createOptions(),
        createResponseBody(sampleString),
      );

      expect(syncResult, equals(isolateResult));
      expect(isolateResult, equals(sample));
    });

    test('12. Passes through non-json responseType intact', () async {
      const rawText = 'Plain text response line 1\nline 2';
      final res = await defaultTransformer.transformResponse(
        createOptions(responseType: ResponseType.plain),
        createResponseBody(rawText),
      );
      expect(res, rawText);
    });
  });
}
