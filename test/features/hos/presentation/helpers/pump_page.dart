import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/core/backend_adapter.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier()
      : super(
          AuthState(
            status: AuthStatus.authenticated,
            user: User(
              id: '106',
              username: 'driver106',
              email: 'driver106@test.com',
              fullName: 'Driver 106',
              role: UserRole.fieldWorker,
              createdAt: DateTime(2026),
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Pumps a widget wrapped in the required scaffolding:
/// - `ProviderScope` with MockAdapter by default (overridable).
/// - `MaterialApp` with localization delegates.
///
/// **Default locale:** `en` for predictable string assertions.
Future<void> pumpPage(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
}) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeBackendProvider.overrideWithValue(MockAdapter()),
        authStateProvider.overrideWith((ref) => _FakeAuthNotifier()),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: child),
      ),
    ),
  );
}

/// Exposes a helper to override the backend with any adapter.
Override overrideBackend(BackendAdapter adapter) =>
    activeBackendProvider.overrideWithValue(adapter);
