import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_status_dashboard_backend.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';

void main() {
  late MockStatusDashboardBackend backend;

  setUp(() {
    backend = MockStatusDashboardBackend();
  });

  group('MockStatusDashboardBackend.getDashboard', () {
    test('returns fixture with default status', () async {
      final result = await backend.getDashboard();

      result.tap(onSuccess: (data) {
        expect(data['currentDutyStatus'], 'ON_DUTY');
        expect(data['driver'], isNotNull);
        expect(data['hosIndicators'], isNotNull);
        expect(data['remainingCircle'], isNotNull);
      });
    });

    test('accepts optional driverId', () async {
      final result = await backend.getDashboard(
        driverId: const DriverId(101),
      );
      expect(result.isSuccess, isTrue);
    });
  });

  group('MockStatusDashboardBackend.updateDutyStatus', () {
    test('changes current duty status', () async {
      final result = await backend.updateDutyStatus(
        dutyStatus: 'DRIVING',
        notes: 'Trip started',
      );

      result.tap(onSuccess: (data) {
        expect(data['currentDutyStatus'], 'DRIVING');
      });
    });

    test('subsequent getDashboard reflects new status', () async {
      await backend.updateDutyStatus(dutyStatus: 'OFF_DUTY');

      final result = await backend.getDashboard();

      result.tap(onSuccess: (data) {
        expect(data['currentDutyStatus'], 'OFF_DUTY');
      });
    });
  });

  group('MockStatusDashboardBackend.getWeeklyRecap', () {
    test('returns 7 days', () async {
      final result = await backend.getWeeklyRecap();

      result.tap(onSuccess: (data) {
        expect(data['days'], hasLength(7));
        expect(data['cycleRule'], 'USA 70/8');
      });
    });
  });
}
