import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/session/session_epoch.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';

void main() {
  group('driverSessionHeaderProvider Clean Architecture Tests', () {
    test('returns empty string when user is unauthenticated', () {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => _FakeAuthNotifier(
              const AuthState(status: AuthStatus.unauthenticated),
            ),
          ),
          dashboardDataProvider.overrideWith(
            (ref) => _TestDashboardNotifier(DashboardData.empty),
          ),
        ],
      );
      addTearDown(container.dispose);

      final header = container.read(driverSessionHeaderProvider);
      expect(header, isEmpty);
    });

    test(r'returns "$driverName - $driverId" when vehicle is not selected', () {
      final user = User(
        id: '101',
        username: 'driver1',
        email: 'alshamiibrahimpro@gmail.com',
        fullName: 'إبراهيم الشامي',
        role: UserRole.fieldWorker,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => _FakeAuthNotifier(
              AuthState(
                status: AuthStatus.authenticated,
                user: user,
                sessionEpoch: 1,
              ),
            ),
          ),
          activeDriverIdProvider.overrideWith((ref) => (SessionEpoch.current, 101)),
          dashboardDataProvider.overrideWith(
            (ref) => _TestDashboardNotifier(
              DashboardData.empty.copyWith(driverName: 'إبراهيم الشامي'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final header = container.read(driverSessionHeaderProvider);
      expect(header, 'إبراهيم الشامي - 101');
    });

    test('returns only driverName without appending unverified Traccar userId when activeDriverId is null', () {
      final user = User(
        id: '2',
        username: 'driver1',
        email: 'alshamiibrahimpro@gmail.com',
        fullName: 'إبراهيم الشامي',
        role: UserRole.fieldWorker,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => _FakeAuthNotifier(
              AuthState(
                status: AuthStatus.authenticated,
                user: user,
                sessionEpoch: 1,
              ),
            ),
          ),
          activeDriverIdProvider.overrideWith((ref) => null),
          dashboardDataProvider.overrideWith(
            (ref) => _TestDashboardNotifier(
              DashboardData.empty.copyWith(driverName: 'إبراهيم الشامي'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final header = container.read(driverSessionHeaderProvider);
      expect(header, 'إبراهيم الشامي');
      expect(header.contains('- 2'), isFalse);
    });

    test(r'returns "$driverName - $vehicleName" when vehicle is selected', () {
      final user = User(
        id: '101',
        username: 'driver1',
        email: 'alshamiibrahimpro@gmail.com',
        fullName: 'إبراهيم الشامي',
        role: UserRole.fieldWorker,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => _FakeAuthNotifier(
              AuthState(
                status: AuthStatus.authenticated,
                user: user,
                sessionEpoch: 1,
              ),
            ),
          ),
          activeDriverIdProvider.overrideWith((ref) => (SessionEpoch.current, 101)),
          dashboardDataProvider.overrideWith(
            (ref) => _TestDashboardNotifier(
              DashboardData.empty.copyWith(
                driverName: 'إبراهيم الشامي',
                vehicleId: 'truck_77',
                vehicleDisplayName: 'Freightliner Cascadia',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final header = container.read(driverSessionHeaderProvider);
      expect(header, 'إبراهيم الشامي - Freightliner Cascadia');
    });

    test('immutable driver anchor: does NOT leak unauthenticated dummy names', () {
      final user = User(
        id: '101',
        username: 'driver1',
        email: 'alshamiibrahimpro@gmail.com',
        fullName: 'إبراهيم الشامي',
        role: UserRole.fieldWorker,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => _FakeAuthNotifier(
              AuthState(
                status: AuthStatus.authenticated,
                user: user,
                sessionEpoch: 1,
              ),
            ),
          ),
          activeDriverIdProvider.overrideWith((ref) => (SessionEpoch.current, 101)),
          dashboardDataProvider.overrideWith(
            (ref) => _TestDashboardNotifier(
              DashboardData.empty.copyWith(driverName: 'إبراهيم الشامي'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final header = container.read(driverSessionHeaderProvider);
      // Confirms Adam Nassem is NEVER leaked
      expect(header.contains('Adam Nassem'), isFalse);
      expect(header.contains('إبراهيم الشامي'), isTrue);
    });
  });
}

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestDashboardNotifier extends StateNotifier<DashboardData>
    implements DashboardNotifier {
  _TestDashboardNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
