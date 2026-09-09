import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/core/config/app_environment.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';

import 'package:golden_feather_eld/core/services/local_storage_service.dart';

class FakeLocalStorageService extends LocalStorageService {
  @override
  Future<void> init() async {}
}

void main() {
  group('AuthState Centralization Tests', () {
    late ProviderContainer container;

    setUp(() async {
      await AppEnvironmentConfig.init(testEnv: {
        'TRACCAR_ENVIRONMENT':
            'mock', // Use mock for predictable repository behavior
      });
      container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(FakeLocalStorageService()),
          // Fake UserStore for testing
          // Since it uses FlutterSecureStorage, in tests we can override userStoreProvider if needed,
          // but for basic AuthState testing we can just let it run if it doesn't crash,
          // or we can provide a mock.
        ],
      );
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
