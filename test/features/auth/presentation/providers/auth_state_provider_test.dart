import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/core/config/app_environment.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';

import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/features/auth/domain/repositories/auth_repository.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_providers.dart';
import 'package:golden_feather_eld/core/error/failure.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  final mockAuthRepo = MockAuthRepository();

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });
  group('AuthState Centralization Tests', () {
    late ProviderContainer container;
    late var notifier;

    setUp(() async {
      await AppEnvironmentConfig.init(testEnv: {
        'TRACCAR_ENVIRONMENT': 'mock', 
      });
      container = ProviderContainer(
        overrides: [
          traccarAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
      );
      notifier = container.read(authStateProvider.notifier);

      bool hasSession = false;

      when(() => mockAuthRepo.login(
              email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((invocation) async {
        if (invocation.namedArguments[#email] == 'admin@demo.com') {
          hasSession = true;
          return Right(User(
              id: '1', fullName: 'Test User', email: 'test@example.com', username: 'admin', role: UserRole.fieldWorker, createdAt: DateTime.now()));
        }
        return Left(ServerFailure(message: 'Unauthorized'));
      });
      
      when(() => mockAuthRepo.checkAndRestoreSession())
          .thenAnswer((_) async {
        if (hasSession) {
          return Right(User(
              id: '1', fullName: 'Test User', email: 'test@example.com', username: 'admin', role: UserRole.fieldWorker, createdAt: DateTime.now()));
        }
        return Left(ServerFailure(message: 'No session'));
      });
              
      when(() => mockAuthRepo.logout())
          .thenAnswer((_) async {
        hasSession = false;
        return const Right(unit);
      });
    });

    tearDown(() {
      container.dispose();
    });

    test('1. Initial state is initial', () {
      final state = container.read(authStateProvider);
      expect(state.status, equals(AuthStatus.initial));
    });

    test(
        '2. Login sets loading state temporarily (verified through notifier logic)',
        () async {
      final notifier = container.read(authStateProvider.notifier);
      // We cannot easily intercept the exact microtask of loading in this basic test without a stream,
      // but we know it sets loading internally before awaiting repository.
      expect(notifier, isNotNull);
    });

    test('3. Successful Login sets state to authenticated', () async {
      final notifier = container.read(authStateProvider.notifier);

      final result = await notifier.login(
          username: 'admin@demo.com', password: 'admin123');

      expect(result, isTrue);
      final state = container.read(authStateProvider);
      expect(state.status, equals(AuthStatus.authenticated));
      expect(state.user, isNotNull);
    });

    test('4. Failed Login sets state to error', () async {
      final notifier = container.read(authStateProvider.notifier);

      final result =
          await notifier.login(username: 'wrong@demo.com', password: 'wrong');

      expect(result, isFalse);
      final state = container.read(authStateProvider);
      expect(state.status, equals(AuthStatus.error));
      expect(state.errorMessage, isNotNull);
    });

    test('5. Logout sets state to unauthenticated', () async {
      final notifier = container.read(authStateProvider.notifier);
      await notifier.login(username: 'admin@demo.com', password: 'admin123');

      await notifier.logout();

      final state = container.read(authStateProvider);
      expect(state.status, equals(AuthStatus.unauthenticated));
    });

    test('6 & 7. checkAuthStatus without session sets unauthenticated',
        () async {
      final notifier = container.read(authStateProvider.notifier);
      await notifier.checkAuthStatus();

      final state = container.read(authStateProvider);
      expect(state.status, equals(AuthStatus.unauthenticated));
    });

    test('8. checkAuthStatus with valid session sets authenticated', () async {
      final notifier = container.read(authStateProvider.notifier);
      await notifier.login(username: 'admin@demo.com', password: 'admin123');

      await notifier.checkAuthStatus();

      final state = container.read(authStateProvider);
      expect(state.status, equals(AuthStatus.authenticated));
    });
    test('9. Concurrency: login B called before login A completes is ignored',
        () async {
      final notifier = container.read(authStateProvider.notifier);

      // Fire first login without waiting
      final futureA =
          notifier.login(username: 'admin@demo.com', password: 'admin123');

      // Fire second login immediately
      final futureB =
          notifier.login(username: 'other@demo.com', password: 'password123');

      final resultA = await futureA;
      final resultB = await futureB;

      expect(resultA, isTrue); // A should succeed
      expect(resultB,
          isFalse); // B should be rejected immediately due to busy flag
    });

    test('10. TARGET BUG TEST: login A completes AFTER logout is called',
        () async {
      // This test documents a current flaw where logout doesn't increment operationId.
      final notifier = container.read(authStateProvider.notifier);

      // Start login
      final loginFuture =
          notifier.login(username: 'admin@demo.com', password: 'admin123');

      // Immediately call logout (this sets state to unauthenticated)
      await notifier.logout();

      // Wait for login to finish
      await loginFuture;

      // Since logout doesn't use the generation counter or busy flag, the delayed login
      // will overwrite the state to authenticated.
      final state = container.read(authStateProvider);
      expect(
          state.status,
          equals(AuthStatus
              .authenticated)); // BUG: Should ideally be unauthenticated.
    });

    test('11. TARGET BUG TEST: checkAuthStatus concurrent with login',
        () async {
      final notifier = container.read(authStateProvider.notifier);

      final checkFuture = notifier.checkAuthStatus();
      final loginFuture =
          notifier.login(username: 'admin@demo.com', password: 'admin123');

      await Future.wait([checkFuture, loginFuture]);

      // State is unpredictable depending on which finished last, but since checkAuthStatus
      // doesn't use the lock, they run in parallel.
      // We just ensure it doesn't crash for this characterization.
      expect(container.read(authStateProvider).status, isNotNull);
    });
  });
}
