import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/sub/eld_dvir_backend.dart';
import 'package:golden_feather_eld/backend/http/eld_endpoints.dart';
import 'package:golden_feather_eld/core/network/api_client.dart';
import 'package:golden_feather_eld/core/network/api_config.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// تثبيت العقد الحي لـ §396.13 (GET /eld/dvir/previous):
/// الخادم يقرأ deviceId **رقمية من داخل فلتر `filters` المعياري** —
/// البارامترات المسطحة تُتجاهل ويعيد 400
/// ("Device ID (deviceId) is required in filters").
void main() {
  late Dio dio;
  late DioAdapter adapter;
  late EldDvirBackend backend;
  final List<Map<String, dynamic>> capturedQueries = <Map<String, dynamic>>[];

  setUp(() {
    dio = Dio();
    adapter = DioAdapter(dio: dio);
    capturedQueries.clear();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedQueries.add(
            Map<String, dynamic>.from(options.queryParameters),
          );
          handler.next(options);
        },
      ),
    );
    backend = EldDvirBackend(
      ApiClient(
        config: const ApiConfig(baseUrl: 'https://api.example.com/api'),
        dio: dio,
      ),
    );
  });

  test(
    'numeric deviceId → standard filters contract with latest-first page',
    () async {
      const expectedQuery = <String, dynamic>{
        'filters': '[{"key":"deviceId","operator":"EQ","value":503}]',
        'sortBy': 'id',
        'sortDirection': 'DESC',
        'page': 0,
        'size': 1,
      };
      adapter.onGet(
        EldEndpoints.dvirPreviousReport,
        (server) => server.reply(200, {
          'success': true,
          'data': [
            {
              'id': 42,
              'uniqueId': 'ELD-PB-103',
              'inspectionType': 'Pre-Trip',
              'status': 'Has Defects',
            },
          ],
          'pagination': {'page': 0, 'size': 1, 'totalElements': 1540},
        }),
        queryParameters: expectedQuery,
      );

      final result = await backend.getPreviousDvir('ELD-PB-103', deviceId: 503);

      // المطابقة الصارمة أعلاه نفسها تثبت الاستعلام؛ والالتقاط يثبت القيم.
      expect(capturedQueries.last, expectedQuery);

      // تطبيع الصفحة: أول عنصر من data يصير جسم الرد للمستودع.
      final body = result.fold((error) {
        // ignore: avoid_print
        print('DIAG error code=${error.code} ctx=${error.context}');
        return null;
      }, (data) => data);
      expect(body?['id'], 42);
    },
  );

  test('empty page normalizes to the no-previous body', () async {
    adapter.onGet(
      EldEndpoints.dvirPreviousReport,
      (server) => server.reply(200, {
        'success': true,
        'data': <dynamic>[],
        'pagination': {'page': 0, 'size': 1, 'totalElements': 0},
      }),
      queryParameters: {
        'filters': '[{"key":"deviceId","operator":"EQ","value":503}]',
        'sortBy': 'id',
        'sortDirection': 'DESC',
        'page': 0,
        'size': 1,
      },
    );

    final result = await backend.getPreviousDvir('ELD-PB-103', deviceId: 503);
    final body = result.fold((error) => null, (data) => data);
    expect(body?['hasPreviousDvir'], isFalse);
  });

  test(
    'missing numeric deviceId keeps the legacy flat shape (no invention)',
    () async {
      adapter.onGet(
        EldEndpoints.dvirPreviousReport,
        (server) => server.reply(200, {
          'success': true,
          'data': {'id': 7},
        }),
        queryParameters: {'uniqueId': 'ELD-PB-103', 'deviceId': 'ELD-PB-103'},
      );

      final result = await backend.getPreviousDvir('ELD-PB-103');

      final query = capturedQueries.last;
      expect(query['uniqueId'], 'ELD-PB-103');
      expect(query['deviceId'], 'ELD-PB-103');
      expect(query.containsKey('filters'), isFalse);
      // شكل قديم ببيانات مفردة: يعامل ككائن DVIR كما هو.
      final body = result.fold((error) => null, (data) => data);
      expect(body?['id'], 7);
    },
  );
}
