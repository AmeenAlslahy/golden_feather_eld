import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/backend/providers/backend_network_providers.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/session/session_epoch.dart';
import 'package:golden_feather_eld/features/auth/domain/repositories/auth_repository.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_providers.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';

User _user(String id, String name) => User(
      id: id,
      fullName: name,
      email: '$id@demo.com',
      username: id,
      role: UserRole.fieldWorker,
      createdAt: DateTime.utc(2026, 1, 1),
    );

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, User>> login({
    required dynamic identifier,
    required dynamic password,
  }) async {
    final id = identifier is String
        ? identifier
        : (identifier as dynamic).value as String;
    if (id == 'driverB@demo.com') return Right(_user('202', 'Driver B'));
    return const Left(ServerFailure(message: 'Unauthorized'));
  }

  @override
  Future<Either<Failure, Unit>> logout() async => const Right(unit);

  @override
  Future<Either<Failure, User>> checkAndRestoreSession() async =>
      const Left(ServerFailure(message: 'No session'));

  @override
  Future<Either<Failure, User>> getCurrentSession() async =>
      const Left(ServerFailure(message: 'No session'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P0 session epoch + late 401 (TEST-04 family)', () {
    late ProviderContainer container;

    setUp(() {
      SessionEpoch.resetForTests();
      container = ProviderContainer(
        overrides: [
          traccarAuthRepositoryProvider
              .overrideWithValue(_FakeAuthRepository()),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('TEST-04a: successful login establishes a new epoch', () async {
      final before = SessionEpoch.current;
      final okLogin = await container
          .read(authStateProvider.notifier)
          .login(username: 'driverB@demo.com', password: 'password123');
      expect(okLogin, isTrue);
      expect(SessionEpoch.current, before + 1);
      expect(container.read(authStateProvider).sessionEpoch,
          SessionEpoch.current);
      expect(container.read(sessionEpochProvider), SessionEpoch.current);
    });

    test('TEST-04b: failed login never bumps the epoch', () async {
      final before = SessionEpoch.current;
      final okLogin = await container
          .read(authStateProvider.notifier)
          .login(username: 'nobody@demo.com', password: 'password123');
      expect(okLogin, isFalse);
      expect(SessionEpoch.current, before);
    });

    test(
        'TEST-04: stale 401 from a previous epoch must not logout the new session',
        () async {
      await container
          .read(authStateProvider.notifier)
          .login(username: 'driverB@demo.com', password: 'password123');
      expect(container.read(authStateProvider).isAuthenticated, isTrue);
      final current = SessionEpoch.current;

      // Late 401 carrying the previous generation (request created under A).
      container.read(unauthenticatedEventProvider).add(current - 1);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(container.read(authStateProvider).isAuthenticated, isTrue,
          reason: 'stale 401 must be ignored');

      // A 401 from the current generation still revokes the session.
      container.read(unauthenticatedEventProvider).add(current);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(container.read(authStateProvider).isAuthenticated, isFalse);
    });

    test('logout drops user identity immediately at transition start',
        () async {
      await container
          .read(authStateProvider.notifier)
          .login(username: 'driverB@demo.com', password: 'password123');
      final epochAtLogin = SessionEpoch.current;

      await container.read(authStateProvider.notifier).logout();
      final state = container.read(authStateProvider);
      expect(state.user, isNull);
      expect(state.isAuthenticated, isFalse);
      expect(state.sessionEpoch, greaterThan(epochAtLogin));
      expect(state.transitioning, isFalse);
    });
  });
}
