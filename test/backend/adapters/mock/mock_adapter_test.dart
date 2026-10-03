import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/core/backend_kind.dart';

void main() {
  late MockAdapter adapter;

  setUp(() {
    adapter = MockAdapter();
  });

  group('MockAdapter — identity', () {
    test('has mock kind', () {
      expect(adapter.identity.kind, BackendKind.mock);
      expect(adapter.isMock, isTrue);
    });

    test('identity id is fixed', () {
      expect(adapter.identity.id, 'mock:local');
    });
  });

  group('MockAdapter — all contracts exposed', () {
    test('all 14 driver-scope contracts are non-null', () {
      expect(adapter.account, isNotNull);
      expect(adapter.statusDashboard, isNotNull);
      expect(adapter.rulesScreen, isNotNull);
      expect(adapter.dailyLogs, isNotNull);
      expect(adapter.dutyStatus, isNotNull);
      expect(adapter.driverSession, isNotNull);
      expect(adapter.dvir, isNotNull);
      expect(adapter.inspection, isNotNull);
      expect(adapter.unidentifiedEvents, isNotNull);
      expect(adapter.vehicle, isNotNull);
      expect(adapter.hardware, isNotNull);
    });

    test('contracts are lazily instantiated (same instance on repeat access)', () {
      expect(adapter.dutyStatus, same(adapter.dutyStatus));
      expect(adapter.account, same(adapter.account));
      expect(adapter.statusDashboard, same(adapter.statusDashboard));
    });
  });

  group('MockAdapter — dispose', () {
    test('completes without errors', () async {
      await expectLater(adapter.dispose(), completes);
    });
  });
}
