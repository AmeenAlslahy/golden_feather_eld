import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/sub/eld_inspection_backend.dart';
import 'package:golden_feather_eld/backend/http/api_client.dart';
import 'package:golden_feather_eld/backend/http/api_response.dart';
import 'package:golden_feather_eld/core/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  group('EldInspectionBackend', () {
    late MockApiClient mockApiClient;
    late EldInspectionBackend backend;

    setUp(() {
      mockApiClient = MockApiClient();
      backend = EldInspectionBackend(mockApiClient);
    });

    test('getScreen calls API and returns screen', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            parser: any(named: 'parser'),
          )).thenAnswer((_) async => ok(const ApiResponse<Map<String, dynamic>>(
            statusCode: 200,
            isSuccess: true,
            data: {'screenTitle': 'Test DOT'},
          )));

      final result = await backend.getScreen(driverId: const DriverId(101));
      
      result.fold(
        (l) => fail('Expected right'),
        (r) {
          expect(r.screenTitle, 'Test DOT');
        },
      );
      
      verify(() => mockApiClient.get<Map<String, dynamic>>(
            '/eld/dot-inspection',
            queryParameters: {'driverId': 101},
            parser: any(named: 'parser'),
          )).called(1);
    });

    test('getCycle calls API and returns list', () async {
      when(() => mockApiClient.get<List<dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            parser: any(named: 'parser'),
          )).thenAnswer((_) async => ok(const ApiResponse<List<dynamic>>(
            statusCode: 200,
            isSuccess: true,
            data: [{'displayLocation': 'Riyadh'}],
          )));

      final result = await backend.getCycle(driverId: const DriverId(101), days: 8);
      
      result.fold(
        (l) => fail('Expected right'),
        (r) {
          expect(r.length, 1);
          expect(r.first.displayLocation, 'Riyadh');
        },
      );
    });
    
    test('getLogs calls API and returns log', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            parser: any(named: 'parser'),
          )).thenAnswer((_) async => ok(const ApiResponse<Map<String, dynamic>>(
            statusCode: 200,
            isSuccess: true,
            data: {'displayLocation': 'Dammam'},
          )));

      final result = await backend.getLogs(driverId: const DriverId(101));
      
      result.fold(
        (l) => fail('Expected right'),
        (r) {
          expect(r.displayLocation, 'Dammam');
        },
      );
    });
  });
}
