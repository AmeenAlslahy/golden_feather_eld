import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/contracts/account_backend.dart';
import 'package:golden_feather_eld/backend/core/backend_adapter.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/localization/locale_provider.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/features/settings/presentation/pages/settings_page.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';

class _Storage extends Mock implements LocalStorageService {}

class _Adapter extends Mock implements BackendAdapter {}

class _Account extends Mock implements AccountBackend {}
/// Settings — interface language, theme and server URL. The read-only
/// fleet settings card was removed by product decision, so there is no
/// `GET /eld/config/settings` coverage here anymore.
void main() {
  late _Storage storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = _Storage();
    when(() => storage.language).thenReturn('en');
    when(() => storage.theme).thenReturn('system');
    when(() => storage.serverUrl).thenReturn('https://snsoft.cloud');
    when(() => storage.setLanguage(any())).thenAnswer((_) async {});
    when(() => storage.setTheme(any())).thenAnswer((_) async {});
    when(() => storage.setServerUrl(any())).thenAnswer((_) async {});
    when(() => storage.setBackendType(any())).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = _Adapter();
    final account = _Account();
    when(() => account.getMyAccount()).thenAnswer((_) async => const Left(UnknownError(code: 'test')));
    when(() => adapter.account).thenReturn(account);
    when(() => adapter.isMock).thenReturn(true);



      await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          activeBackendProvider.overrideWithValue(adapter),
                  ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: AppTheme.light,
            locale: ref.watch(localeProvider),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const SettingsPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('shows language, theme and server URL', (tester) async {
    await pump(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Interface language'), findsOneWidget);
    expect(find.text('Arabic'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Server URL'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'https://snsoft.cloud',
    );
  });

  testWidgets('switching to Arabic persists and re-renders the page in Arabic',
      (tester) async {
    await pump(tester);

    await tester.tap(find.text('Arabic'));
    await tester.pumpAndSettle();

    verify(() => storage.setLanguage('ar')).called(1);
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
    expect(find.text('لغة الواجهة'), findsOneWidget);
    expect(find.text('Interface language'), findsNothing);
  });

  testWidgets('theme choice is persisted', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    verify(() => storage.setTheme('dark')).called(1);
  });

  testWidgets('server URL: empty is refused, valid is saved with eld backend',
      (tester) async {
    await pump(tester);

    final field = find.byType(TextField).first;
    final save = find.widgetWithText(AppButton, 'Save');

    await tester.enterText(field, '   ');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    expect(find.text('Enter the server URL.'), findsOneWidget);
    verifyNever(() => storage.setServerUrl(any()));
    // Let the AppFeedback overlay expire so the next one is not stacked.
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Not an http(s) URL → refused before anything is persisted.
    await tester.enterText(find.byType(TextField).first, 'javascript:alert(1)');
    await tester.tap(save);
    await tester.pump();
    expect(find.textContaining('Invalid URL'), findsOneWidget);
    verifyNever(() => storage.setServerUrl(any()));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextField).first, ' https://eld.example.com ');
    await tester.tap(save);
    await tester.pump();
    await tester.pumpAndSettle();
    verify(() => storage.setServerUrl('https://eld.example.com')).called(1);
    verify(() => storage.setBackendType('eld')).called(1);
    expect(find.text('Server URL saved.'), findsOneWidget);
    // Pump past the AppFeedback auto-dismiss timer (3s) so no pending
    // timer is left when the widget tree is disposed.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
