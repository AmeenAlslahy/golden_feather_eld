import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_auth_backend.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/di/app_providers.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/features/auth/domain/repositories/auth_repository.dart';
import 'package:golden_feather_eld/features/auth/presentation/pages/auth_page.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo extends Mock implements AuthRepository {}

class _Storage extends Mock implements LocalStorageService {
  @override
  String get language => 'en';
  @override
  String get serverUrl => 'https://snsoft.cloud';
  @override
  String get backendType => 'eld';
}

/// Records the password-reset request the form sends.
class _ResetAuthBackend extends MockAuthBackend {
  final calls = <String>[];
  AppError? nextError;

  @override
  Future<Result<void>> requestPasswordReset({
    required String email,
    required String serverUrl,
  }) async {
    calls.add('$email@$serverUrl');
    if (nextError != null) return err(nextError!);
    return ok(null);
  }
}

/// SRS 1.1 — login form validation, credentials → session, refusals shown
/// as plain localized text (never a backend code), password recovery works.
void main() {
  late _Repo repo;
  late _ResetAuthBackend authBackend;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = _Repo();
    authBackend = _ResetAuthBackend();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          traccarAuthRepositoryProvider.overrideWithValue(repo),
          localStorageProvider.overrideWithValue(_Storage()),
          authBackendProvider.overrideWithValue(authBackend),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const AuthPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Finder loginButton() => find.widgetWithText(AppButton, 'Login');

  testWidgets('empty fields are refused locally; nothing is sent', (tester) async {
    await pump(tester);

    await tester.ensureVisible(loginButton());
    await tester.tap(loginButton());
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    verifyNever(() => repo.login(
          identifier: any(named: 'identifier'),
          password: any(named: 'password'),
        ));
  });

  testWidgets('valid credentials → repository login with trimmed identifier → authenticated',
      (tester) async {
    when(() => repo.login(
          identifier: any(named: 'identifier'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => Right(User(
          id: '106',
          username: 'driver106',
          email: 'driver106@example.com',
          fullName: 'Driver One Zero Six',
          role: UserRole.fieldWorker,
          createdAt: DateTime(2026, 1, 1),
        )));
    await pump(tester);

    await tester.enterText(find.byType(TextFormField).at(0), '  driver106  ');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret');
    await tester.ensureVisible(loginButton());
    await tester.tap(loginButton());
    await tester.pumpAndSettle();

    final captured = verify(() => repo.login(
          identifier: captureAny(named: 'identifier'),
          password: captureAny(named: 'password'),
        )).captured;
    expect(captured, ['driver106', 'secret']);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AuthPage)),
    );
    expect(container.read(currentDriverIdProvider), 106);
  });

  testWidgets('wrong password → localized refusal; backend code never shown',
      (tester) async {
    var calls = 0;
    when(() => repo.login(
          identifier: any(named: 'identifier'),
          password: any(named: 'password'),
        )).thenAnswer((_) async {
      calls++;
      return calls == 1
          ? const Left(InvalidCredentialsFailure())
          : const Left(ServerFailure(message: 'network.connectionFailed'));
    });
    await pump(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'driver106');
    await tester.enterText(find.byType(TextFormField).at(1), 'nope');
    await tester.ensureVisible(loginButton());
    await tester.tap(loginButton());
    await tester.pumpAndSettle();
    expect(find.text('Invalid username or password'), findsOneWidget);

    // Server unreachable: the raw code is not what the driver reads.
    await tester.tap(loginButton());
    await tester.pumpAndSettle();
    expect(find.text('network.connectionFailed'), findsNothing);
    expect(find.text('No internet connection. Check the network and try again.'),
        findsOneWidget);
  });

  testWidgets('Forgot Password → validates email → sends reset → back to login',
      (tester) async {
    await pump(tester);

    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset Password'), findsOneWidget);

    final send = find.widgetWithText(AppButton, 'Send');
    await tester.enterText(find.byType(TextField).first, 'not-an-email');
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email.'), findsOneWidget);
    expect(authBackend.calls, isEmpty);

    await tester.enterText(find.byType(TextField).first, 'driver106@example.com');
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(authBackend.calls, ['driver106@example.com@https://snsoft.cloud']);
    expect(
      find.text('If the email is registered, reset instructions will be sent.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Back to Login'));
    await tester.pumpAndSettle();
    expect(loginButton(), findsOneWidget);
  });

  testWidgets('reset not offered by the server → plain guidance, no dump',
      (tester) async {
    authBackend.nextError = const NotFoundError(
      code: 'not_found',
      context: {'raw': 'DioException 404 /api/password/reset'},
    );
    await pump(tester);

    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'driver106@example.com');
    await tester.tap(find.widgetWithText(AppButton, 'Send'));
    await tester.pumpAndSettle();

    expect(
      find.text('Reset is not available on this server. Contact your fleet manager.'),
      findsOneWidget,
    );
    expect(find.textContaining('Dio'), findsNothing);
  });
}
