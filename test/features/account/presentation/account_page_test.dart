import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/design_system.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/domain/account/driver_account.dart';
import 'package:golden_feather_eld/features/account/presentation/pages/account_page.dart';
import 'package:golden_feather_eld/features/account/presentation/providers/account_provider.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

const _driverAccount = DriverAccount(
  driverId: 101,
  email: 'driver@example.com',
  phone: '1234567890',
  license: LicenseInfo(state: 'TX', number: 'DL-999', formatted: 'TX, DL-999'),
  carrier: 'Golden Feather Transport',
  mainOfficeAddress: '100 Main St',
  homeTerminalAddress: '200 Terminal Rd',
  timeZone: 'America/New_York',
  language: 'English',
  odometer: 'mi',
  availableLanguages: ['English', 'Spanish', 'Arabic'],
  availableOdometerUnits: ['mi', 'km'],
);

final _testUser = User(
  id: '101',
  username: 'driver101',
  fullName: 'Captain Driver',
  email: 'driver@example.com',
  role: UserRole.fieldWorker,
  createdAt: DateTime(2026, 1, 1),
);

Future<void> _pumpAccountPage(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => _AuthNotifier(AuthState(user: _testUser)),
        ),
        accountProvider.overrideWith(
          (ref) => _FakeAccountNotifier(
            const AccountState(accountData: _driverAccount),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AccountPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'AccountPage displays Driver Name under driverName label (not sortByName)',
    (tester) async {
      await _pumpAccountPage(tester);

      // Verify Driver Name label appears
      expect(find.text('Driver Name'), findsOneWidget);
      // Verify driver's actual name appears
      expect(find.text('Captain Driver'), findsOneWidget);
      // Verify incorrect label 'Sort by name' does NOT appear
      expect(find.text('Sort by name'), findsNothing);
      // Verify other fields
      expect(find.text('driver@example.com'), findsOneWidget);
      expect(find.text('1234567890'), findsOneWidget);
    },
  );

  testWidgets('AccountPage renders without overflow on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpAccountPage(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Captain Driver'), findsOneWidget);
    expect(find.text('Golden Feather Transport'), findsOneWidget);
    expect(find.text('100 Main St'), findsOneWidget);
    expect(find.text('200 Terminal Rd'), findsOneWidget);
    expect(find.text('America/New_York'), findsOneWidget);
  });
}

class _AuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _AuthNotifier(super.state);

  @override
  Future<bool> login({
    required String username,
    required String password,
    String? serverUrl,
  }) async => true;

  @override
  void forceLogout() {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> checkAuthStatus() async {}

  @override
  void clearError() {}
}

class _FakeAccountNotifier extends StateNotifier<AccountState>
    implements AccountNotifier {
  _FakeAccountNotifier(super.state);

  @override
  String? get ownerDriverId => '101';

  @override
  void bindOwner(String? driverId, int? epoch) {}

  @override
  Future<void> fetchMyAccount() async {}

  @override
  void reset() {}

  @override
  Future<bool> updatePreferences({
    required String language,
    required String odometerUnit,
  }) async => true;

  @override
  Future<void> changeLanguage(String newLanguage) async {}

  @override
  Future<void> changeOdometer(String newOdometer) async {}
}
