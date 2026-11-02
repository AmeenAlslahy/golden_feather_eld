import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/app/di/app_providers.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_auth_backend.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/core/widgets/app_logo.dart';
import 'package:golden_feather_eld/core/widgets/app_text_field.dart';
import 'package:golden_feather_eld/features/auth/domain/repositories/auth_repository.dart';
import 'package:golden_feather_eld/features/auth/presentation/pages/auth_page.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_mode_provider.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/auth/presentation/widgets/forgot_password_form.dart';
import 'package:golden_feather_eld/features/auth/presentation/widgets/login_form.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockRepo extends Mock implements AuthRepository {}

class _MockStorage extends Mock implements LocalStorageService {
  @override
  String get language => 'en';
  @override
  String get serverUrl => 'https://snsoft.cloud';
  @override
  String get backendType => 'eld';
}

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MockRepo repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = _MockRepo();
  });

  Widget createHarness({
    ThemeData? theme,
    Locale locale = const Locale('en'),
    double textScaleFactor = 1.0,
    AuthMode initialMode = AuthMode.login,
    AuthState? authStateOverride,
  }) {
    return ProviderScope(
      overrides: [
        traccarAuthRepositoryProvider.overrideWithValue(repo),
        localStorageProvider.overrideWithValue(_MockStorage()),
        authBackendProvider.overrideWithValue(const MockAuthBackend()),
        authModeProvider.overrideWith((ref) => initialMode),
        if (authStateOverride != null)
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(authStateOverride)),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: const AuthPage(),
        ),
      ),
    );
  }

  group('Auth Page Redesign — Structure & Visual Identity', () {
    testWidgets('displays AppLogo, App Name, and Slogan properly', (tester) async {
      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.text('Golden Feather ELD'), findsOneWidget);
      expect(find.text('Golden Feather - Field Compliance Tracking'), findsOneWidget);
      expect(find.byType(LoginForm), findsOneWidget);
      expect(find.byType(ForgotPasswordForm), findsNothing);
    });

    testWidgets('transitions smoothly between LoginForm and ForgotPasswordForm', (tester) async {
      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      // Go to Forgot Password
      final forgotBtn = find.text('Forgot Password?');
      await tester.ensureVisible(forgotBtn);
      await tester.tap(forgotBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordForm), findsOneWidget);
      expect(find.byType(LoginForm), findsNothing);
      expect(find.text('Reset Password'), findsOneWidget);

      // Return to Login
      final backBtn = find.widgetWithText(AppButton, 'Back to Login');
      await tester.ensureVisible(backBtn);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.byType(LoginForm), findsOneWidget);
      expect(find.byType(ForgotPasswordForm), findsNothing);
    });

    testWidgets('displays validation errors with semantic styling on empty submit', (tester) async {
      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      final loginBtn = find.widgetWithText(AppButton, 'Login');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('renders authentication error banner when state has error', (tester) async {
      const errorState = AuthState(
        status: AuthStatus.error,
        errorMessage: 'invalidCredentials',
      );

      await tester.pumpWidget(createHarness(authStateOverride: errorState));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Invalid username or password'), findsOneWidget);
    });

    testWidgets('renders loading state on AppButton when authenticating', (tester) async {
      const loadingState = AuthState(status: AuthStatus.loading);

      await tester.pumpWidget(createHarness(authStateOverride: loadingState));
      await tester.pump();

      // AppButton exhibits loading indicator and disables user tap
      final buttonFinder = find.byType(AppButton);
      expect(buttonFinder, findsOneWidget);
      expect(find.descendant(of: buttonFinder, matching: find.byType(CircularProgressIndicator)), findsOneWidget);
    });
  });

  group('Auth Page Redesign — Themes & Modes', () {
    testWidgets('renders properly in Light Mode', (tester) async {
      await tester.pumpWidget(createHarness(theme: AppTheme.light));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold, isNotNull);
      expect(find.byType(AppTextField), findsNWidgets(2));
      expect(find.widgetWithText(AppButton, 'Login'), findsOneWidget);
    });

    testWidgets('renders properly in Dark Mode', (tester) async {
      await tester.pumpWidget(createHarness(theme: AppTheme.dark));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold, isNotNull);
      expect(find.byType(AppTextField), findsNWidgets(2));
      expect(find.widgetWithText(AppButton, 'Login'), findsOneWidget);
    });
  });

  group('Auth Page Redesign — Locales & RTL/LTR', () {
    testWidgets('renders Arabic (RTL) correctly without overflow', (tester) async {
      await tester.pumpWidget(createHarness(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.text('تسجيل الدخول'), findsOneWidget);
      expect(find.text('نسيت كلمة المرور؟'), findsOneWidget);
      expect(find.text('Golden Feather ELD'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders Spanish (LTR) correctly without overflow', (tester) async {
      await tester.pumpWidget(createHarness(locale: const Locale('es')));
      await tester.pumpAndSettle();

      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('¿Olvidó la contraseña?'), findsOneWidget);
      expect(find.text('Golden Feather ELD'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Auth Page Redesign — Screen Sizes & Responsiveness', () {
    final screenSizes = [
      ('Small Phone (320dp)', const Size(320, 640)),
      ('Medium Phone (375dp)', const Size(375, 812)),
      ('Large Phone (430dp)', const Size(430, 932)),
    ];

    for (final (label, size) in screenSizes) {
      testWidgets('renders cleanly on $label without overflow', (tester) async {
        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createHarness());
        await tester.pumpAndSettle();

        expect(find.byType(AppLogo), findsOneWidget);
        expect(find.byType(LoginForm), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Auth Page Redesign — Text Scaling', () {
    final scales = [1.0, 1.5, 2.0];

    for (final scale in scales) {
      testWidgets('handles text scaling ${scale}x without RenderFlex overflow', (tester) async {
        tester.view.physicalSize = const Size(375 * 2.0, 812 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createHarness(textScaleFactor: scale));
        await tester.pumpAndSettle();

        expect(find.byType(AppLogo), findsOneWidget);
        expect(find.byType(LoginForm), findsOneWidget);
        expect(find.widgetWithText(AppButton, 'Login'), findsOneWidget);

        // Verification of zero overflow
        expect(tester.takeException(), isNull);
      });
    }
  });
}
