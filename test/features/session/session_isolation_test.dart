import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/backend/contracts/account_backend.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/domain/account/driver_account.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/account/presentation/providers/account_provider.dart';
import 'package:golden_feather_eld/features/auth/domain/repositories/auth_repository.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_providers.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/codriver/domain/current_codriver.dart';
import 'package:golden_feather_eld/features/codriver/domain/entities/codriver.dart';
import 'package:golden_feather_eld/features/codriver/domain/repositories/codriver_repository.dart';
import 'package:golden_feather_eld/features/codriver/data/providers/codriver_repository_providers.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:golden_feather_eld/features/vehicle/data/providers/vehicle_repository_providers.dart';
import 'package:golden_feather_eld/features/vehicle/domain/entities/vehicle.dart';
import 'package:golden_feather_eld/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:golden_feather_eld/features/vehicle/presentation/providers/vehicle_provider.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────

User _user(String id, String name, String email) => User(
  id: id,
  fullName: name,
  email: email,
  username: email,
  role: UserRole.fieldWorker,
  createdAt: DateTime.utc(2026, 1, 1),
);

final _userA = _user('101', 'Driver A', 'driverA@demo.com');
final _userB = _user('202', 'Driver B', 'driverB@demo.com');

class FakeAuthRepository implements AuthRepository {
  User? current;

  @override
  Future<Either<Failure, User>> login({
    required dynamic identifier,
    required dynamic password,
  }) async {
    final id = identifier is String
        ? identifier
        : (identifier as dynamic).value as String;
    if (id == 'driverA@demo.com') {
      current = _userA;
      return Right(_userA);
    }
    if (id == 'driverB@demo.com') {
      current = _userB;
      return Right(_userB);
    }
    return const Left(ServerFailure(message: 'Unauthorized'));
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    current = null;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, User>> checkAndRestoreSession() async {
    final u = current;
    return u == null
        ? const Left(ServerFailure(message: 'No session'))
        : Right(u);
  }

  @override
  Future<Either<Failure, User>> getCurrentSession() async {
    final u = current;
    return u == null
        ? const Left(ServerFailure(message: 'No session'))
        : Right(u);
  }
}

Vehicle _vehicle(String id, String name) => Vehicle(
  id: id,
  uniqueId: 'UID-$id',
  name: name,
  year: '2022',
  activeForCurrentDriver: true,
);

/// Captures the fleet at call start, then optionally waits on [gate].
/// This models a slow server response ordered behind a newer request.
class GatedVehicleRepository implements VehicleRepository {
  GatedVehicleRepository(this.fleetHook);

  List<Vehicle> Function() fleetHook;
  Completer<void>? gate;
  bool gateFirstCallOnly = false;
  int calls = 0;

  @override
  Future<Either<Failure, List<Vehicle>>> getVehicles() async {
    calls++;
    final captured = fleetHook();
    if (gate != null && (!gateFirstCallOnly || calls == 1)) {
      await gate!.future;
    }
    return Right(captured);
  }

  @override
  Future<Either<Failure, List<Vehicle>>> getCompanyVehicles() async =>
      Right(fleetHook());

  @override
  Future<Either<Failure, Vehicle?>> getSelectedVehicle() async =>
      const Right(null);
}

class FakeCoDriverRepository implements CoDriverRepository {
  @override
  Future<Either<Failure, List<CoDriver>>> getAvailableDrivers() async =>
      const Right([]);
  @override
  Future<Either<Failure, CurrentCoDriverRead>> getCurrentCoDriver() async =>
      const Right(CurrentCoDriverRead());
  @override
  Future<Either<Failure, bool>> switchPrimary({
    required int coDriverId,
    String? reason,
  }) async => const Right(true);
}

DriverAccount _account(int id, String email) => DriverAccount(
  driverId: id,
  email: email,
  phone: '000',
  license: const LicenseInfo(state: 'ST', number: 'N', formatted: 'ST-N'),
  carrier: 'carrier',
  mainOfficeAddress: 'office',
  homeTerminalAddress: 'terminal',
  timeZone: 'UTC',
  language: 'en',
  odometer: 'mi',
);

class FakeAccountBackend implements AccountBackend {
  @override
  Future<Result<DriverAccount>> getMyAccount({DriverId? driverId}) async {
    final id = driverId?.value ?? 0;
    if (id == 101) return ok(_account(101, 'driverA@demo.com'));
    if (id == 202) return ok(_account(202, 'driverB@demo.com'));
    return ok(_account(id, 'unknown@demo.com'));
  }

  @override
  Future<Result<DriverAccount>> updatePreferences({
    required String language,
    required String odometerUnit,
  }) async => ok(_account(0, 'unknown@demo.com'));
}

class FakeNetworkInfo implements NetworkInfo {
  @override
  bool get isConnected => true;
  @override
  Stream<bool> get onConnectionChange => const Stream.empty();
}

ProviderContainer _container({
  required FakeAuthRepository auth,
  required GatedVehicleRepository vehicles,
}) {
  return ProviderContainer(
    overrides: [
      traccarAuthRepositoryProvider.overrideWithValue(auth),
      vehicleRepositoryProvider.overrideWithValue(vehicles),
      coDriverRepositoryProvider.overrideWithValue(FakeCoDriverRepository()),
      accountBackendProvider.overrideWithValue(FakeAccountBackend()),
      networkInfoProvider.overrideWithValue(FakeNetworkInfo()),
    ],
  );
}

Future<void> _waitFor(bool Function() cond, String what) async {
  final end = DateTime.now().add(const Duration(seconds: 5));
  while (!cond()) {
    if (DateTime.now().isAfter(end)) {
      throw TimeoutException('Timed out waiting for: $what');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Future<void> _loginAs(ProviderContainer c, String email) async {
  final okLogin = await c
      .read(authStateProvider.notifier)
      .login(username: email, password: 'password123');
  expect(okLogin, isTrue, reason: 'login $email must succeed');
}

// ─── Tests ────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P0 session isolation characterization', () {
    test(
      'TEST-01: Login A → Logout → Login B must not show A dashboard/account data',
      () async {
        final auth = FakeAuthRepository();
        final vehicles = GatedVehicleRepository(
          () => [_vehicle('VH-A', 'Truck A')],
        );
        final c = _container(auth: auth, vehicles: vehicles);
        addTearDown(c.dispose);

        await _loginAs(c, 'driverA@demo.com');
        // H-D1: first read after login triggers the single owner-tagged load.
        c.read(vehicleProvider);
        await _waitFor(
          () => c.read(vehicleProvider).isInitialized,
          'A vehicles loaded',
        );
        await c.read(accountProvider.notifier).fetchMyAccount();

        expect(c.read(dashboardDataProvider).vehicleId, 'VH-A');
        expect(c.read(accountProvider).accountData?.driverId, 101);

        await c.read(authStateProvider.notifier).logout();

        // No refresh: B must never see A's header/account.
        expect(
          c.read(dashboardDataProvider).vehicleId,
          isNot('VH-A'),
          reason: 'dashboard must not retain A vehicle after logout',
        );
        expect(
          c.read(accountProvider).accountData?.driverId,
          isNot(101),
          reason: 'account must not retain A after logout',
        );

        vehicles.fleetHook = () => [_vehicle('VH-B', 'Truck B')];
        await _loginAs(c, 'driverB@demo.com');
        await _waitFor(
          () =>
              c.read(vehicleProvider).isInitialized &&
              c.read(vehicleProvider).selectedVehicle?.id == 'VH-B',
          'B vehicles loaded',
        );
        await c.read(accountProvider.notifier).fetchMyAccount();

        expect(c.read(dashboardDataProvider).vehicleId, 'VH-B');
        expect(c.read(accountProvider).accountData?.driverId, 202);
      },
    );

    test(
      'TEST-02: VehicleProvider must reinitialize for a new owner',
      () async {
        final auth = FakeAuthRepository();
        final vehicles = GatedVehicleRepository(
          () => [_vehicle('VH-A', 'Truck A')],
        );
        final c = _container(auth: auth, vehicles: vehicles);
        addTearDown(c.dispose);

        await _loginAs(c, 'driverA@demo.com');
        c.read(vehicleProvider);
        await _waitFor(
          () => c.read(vehicleProvider).isInitialized,
          'A vehicles loaded',
        );
        expect(c.read(vehicleProvider).selectedVehicle?.id, 'VH-A');

        await c.read(authStateProvider.notifier).logout();
        vehicles.fleetHook = () => [_vehicle('VH-B', 'Truck B')];
        await _loginAs(c, 'driverB@demo.com');

        await _waitFor(
          () => c.read(vehicleProvider).selectedVehicle?.id == 'VH-B',
          'vehicle state reflects owner B without manual refresh',
        );
        expect(c.read(vehicleProvider).selectedVehicle?.id, 'VH-B');
      },
    );

    test(
      'TEST-03: slow GET from A completed after B login must be ignored',
      () async {
        final auth = FakeAuthRepository();
        final vehicles =
            GatedVehicleRepository(() => [_vehicle('VH-A', 'Truck A')])
              ..gateFirstCallOnly = true
              ..gate = Completer<void>();
        final c = _container(auth: auth, vehicles: vehicles);
        addTearDown(c.dispose);

        await _loginAs(c, 'driverA@demo.com');
        // H-D1: first read after login triggers the single owner-tagged
        // load — call#1 captures A fleet and parks on gate, staying in
        // flight across logout/login below.
        c.read(vehicleProvider);
        await _waitFor(() => vehicles.calls == 1, 'slow A request started');

        await c.read(authStateProvider.notifier).logout();
        vehicles.fleetHook = () => [_vehicle('VH-B', 'Truck B')];
        await _loginAs(c, 'driverB@demo.com');

        vehicles.gate!.complete(); // stale A response lands now
        await _waitFor(() => c.read(vehicleProvider).isInitialized, 'settled');
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(
          c.read(vehicleProvider).selectedVehicle?.id,
          isNot('VH-A'),
          reason: 'stale A response must not overwrite B state',
        );
        expect(c.read(vehicleProvider).selectedVehicle?.id, 'VH-B');
      },
    );

    test(
      'REQ-01: vehicle reads are on demand; owner change costs one request',
      () async {
        final auth = FakeAuthRepository();
        final vehicles = GatedVehicleRepository(
          () => [_vehicle('VH-A', 'Truck A')],
        );
        final c = _container(auth: auth, vehicles: vehicles);
        addTearDown(c.dispose);

        // Listen-only (tracking_orchestrator pattern) must not fire HTTP.
        c.listen(vehicleProvider, (_, __) {});
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(
          vehicles.calls,
          0,
          reason: 'no cold-start request before any page needs data',
        );

        // Page-driven explicit load → exactly one request; repeat reads latch.
        await c.read(vehicleProvider.notifier).loadVehicles();
        expect(vehicles.calls, 1);
        c.read(vehicleProvider);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(vehicles.calls, 1, reason: 'latch must prevent refetch');

        // Login A → exactly one owner reload.
        await _loginAs(c, 'driverA@demo.com');
        await _waitFor(() => vehicles.calls == 2, 'owner A reload');
        expect(vehicles.calls, 2);

        // Logout → reset only, zero requests.
        await c.read(authStateProvider.notifier).logout();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(vehicles.calls, 2, reason: 'reset must not trigger API');

        // Login B → exactly one owner reload with B fleet.
        vehicles.fleetHook = () => [_vehicle('VH-B', 'Truck B')];
        await _loginAs(c, 'driverB@demo.com');
        await _waitFor(() => vehicles.calls == 3, 'owner B reload');
        await _waitFor(
          () => c.read(vehicleProvider).selectedVehicle?.id == 'VH-B',
          'B fleet applied',
        );
        expect(vehicles.calls, 3);
      },
    );

    test('H-D1-A: provider created after login loads exactly once', () async {
      final auth = FakeAuthRepository();
      final vehicles = GatedVehicleRepository(
        () => [_vehicle('VH-A', 'Truck A')],
      );
      final c = _container(auth: auth, vehicles: vehicles);
      addTearDown(c.dispose);

      // Login first; vehicleProvider is created only afterwards
      // (e.g., direct DVIR-first-open path).
      await _loginAs(c, 'driverA@demo.com');
      expect(vehicles.calls, 0);

      c.read(vehicleProvider);
      await _waitFor(
        () => c.read(vehicleProvider).isInitialized,
        'A vehicles loaded',
      );
      expect(c.read(vehicleProvider).selectedVehicle?.id, 'VH-A');
      expect(
        vehicles.calls,
        1,
        reason: 'exactly one owner-tagged initial load, no double fetch',
      );
      expect(c.read(vehicleProvider.notifier).ownerDriverId, isNotNull);
    });

    test('H-D1-B: provider created without auth sends zero requests', () async {
      final auth = FakeAuthRepository();
      final vehicles = GatedVehicleRepository(
        () => [_vehicle('VH-A', 'Truck A')],
      );
      final c = _container(auth: auth, vehicles: vehicles);
      addTearDown(c.dispose);

      c.read(vehicleProvider);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(c.read(vehicleProvider).isInitialized, isFalse);
      expect(
        vehicles.calls,
        0,
        reason: 'unauthenticated creation must stay silent',
      );
    });
  });
}
