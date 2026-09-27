import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/features/auth/presentation/pages/splash_page.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

/// Records `checkAuthStatus` calls and lands on the state the test chose.
class _AuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _AuthNotifier(this._after) : super(const AuthState());
  final AuthState _after;
  int checks = 0;

  @override
  Future<void> checkAuthStatus() async {
    checks++;
    state = _after;
  }

  @override
  Future<bool> login({
    required String username,
    required String password,
    String? serverUrl,
  }) async =>
      true;

  @override
  void forceLogout() {}

  @override
  Future<void> logout() async {}

  @override
  void clearError() {}
}

/// SRS 4.1 — Splash decides: missing permissions → Permissions page;
/// permissions present → session check → Connection (logged in) or Login.
void main() {
  const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
  // permission_handler: Permission.location = 3, Permission.bluetooth = 21;
  // PermissionStatus.denied = 0, granted = 1.
  late Map<int, int> statuses;

  setUp(() {
    statuses = {3: 1, 21: 1};
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'checkPermissionStatus') {
        return statuses[call.arguments as int] ?? 0;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  final user = User(
    id: '106',
    username: 'driver',
    email: 'd@example.com',
    fullName: 'Test Driver',
    role: UserRole.fieldWorker,
    createdAt: DateTime(2026, 1, 1),
  );

  Future<_AuthNotifier> pump(WidgetTester tester, AuthState after) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final notifier = _AuthNotifier(after);
    final router = GoRouter(routes: [
      GoRoute(
          path: '/', name: 'splash', builder: (_, __) => const SplashPage()),
      GoRoute(
          path: '/permissions',
          name: 'permissions',
          builder: (_, __) => const Scaffold(body: Text('PERMISSIONS PAGE'))),
      GoRoute(
          path: '/login',
          name: 'login',
          builder: (_, __) => const Scaffold(body: Text('LOGIN PAGE'))),
      GoRoute(
          path: '/connection',
          name: 'connection',
          builder: (_, __) => const Scaffold(body: Text('CONNECTION PAGE'))),
    ]);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authStateProvider.overrideWith((ref) => notifier)],
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    return notifier;
  }

  Future<void> passSplashDelay(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the app name and a spinner while deciding',
      (tester) async {
    await pump(tester, const AuthState(status: AuthStatus.unauthenticated));
    expect(find.text('Golden Feather ELD'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await passSplashDelay(tester);
  });

  testWidgets('missing Bluetooth permission → Permissions page, no auth check',
      (tester) async {
    statuses[21] = 0;
    final auth =
        await pump(tester, AuthState(status: AuthStatus.authenticated, user: user));
    await passSplashDelay(tester);
    expect(find.text('PERMISSIONS PAGE'), findsOneWidget);
    expect(auth.checks, 0);
  });

  testWidgets('permissions granted + valid session → Connection',
      (tester) async {
    final auth =
        await pump(tester, AuthState(status: AuthStatus.authenticated, user: user));
    await passSplashDelay(tester);
    expect(find.text('CONNECTION PAGE'), findsOneWidget);
    expect(auth.checks, 1);
  });

  testWidgets('offline session with a stored user still counts as logged in',
      (tester) async {
    await pump(tester, AuthState(status: AuthStatus.offline, user: user));
    await passSplashDelay(tester);
    expect(find.text('CONNECTION PAGE'), findsOneWidget);
  });

  testWidgets('permissions granted + no session → Login', (tester) async {
    final auth =
        await pump(tester, const AuthState(status: AuthStatus.unauthenticated));
    await passSplashDelay(tester);
    expect(find.text('LOGIN PAGE'), findsOneWidget);
    expect(auth.checks, 1);
  });
}
