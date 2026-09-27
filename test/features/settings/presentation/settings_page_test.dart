import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/contracts/config_backend.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/backend/core/backend_adapter.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/localization/locale_provider.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/core/widgets/eld_info_row.dart';
import 'package:golden_feather_eld/core/widgets/eld_retry_view.dart';
import 'package:golden_feather_eld/features/settings/presentation/pages/settings_page.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Storage extends Mock implements LocalStorageService {}

class _Adapter extends Mock implements BackendAdapter {}

class _Config extends Mock implements ConfigBackend {}

/// Settings — interface language, theme, server URL and the read-only fleet
/// settings returned by `GET /eld/config/settings`.
void main() {
  late _Storage storage;
  late _Config config;

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
    config = _Config();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = _Adapter();
    when(() => adapter.config).thenReturn(config);
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

  RawJson fleetJson() => {
        'hos': {'cycle': 'USA 70/8', 'restart': 34},
        'exemptions': ['PC', 'YM'],
        'ignored': null,
      };

  testWidgets('shows language/theme/server URL and flattened fleet settings',
      (tester) async {
    when(() => config.getSettings()).thenAnswer((_) async => ok(fleetJson()));
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

    await tester.scrollUntilVisible(find.text('Fleet settings'), 200,
        scrollable: find.byType(Scrollable).first);
    final rows = tester
        .widgetList<EldInfoRow>(find.byType(EldInfoRow))
        .map((r) => (r.label, r.value))
        .toList();
    expect(
      rows,
      containsAll([
        ('hos.cycle', 'USA 70/8'),
        ('hos.restart', '34'),
        ('exemptions', 'PC, YM'),
      ]),
    );
    expect(rows.any((r) => r.$1 == 'ignored'), isFalse);
  });

  testWidgets('switching to Arabic persists and re-renders the page in Arabic',
      (tester) async {
    when(() => config.getSettings()).thenAnswer((_) async => ok(fleetJson()));
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
    when(() => config.getSettings()).thenAnswer((_) async => ok(fleetJson()));
    await pump(tester);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    verify(() => storage.setTheme('dark')).called(1);
  });

  testWidgets('server URL: empty is refused, valid is saved with eld backend',
      (tester) async {
    when(() => config.getSettings()).thenAnswer((_) async => ok(fleetJson()));
    await pump(tester);

    final field = find.byType(TextField).first;
    final save = find.widgetWithText(AppButton, 'Save');

    await tester.enterText(field, '   ');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    expect(find.text('Enter the server URL.'), findsOneWidget);
    verifyNever(() => storage.setServerUrl(any()));
    // Let the refusal snackbar expire so the next one is not queued behind it.
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

    await tester.enterText(find.byType(TextField).first, ' https://eld.example.com ');
    await tester.tap(save);
    await tester.pumpAndSettle();
    verify(() => storage.setServerUrl('https://eld.example.com')).called(1);
    verify(() => storage.setBackendType('eld')).called(1);
    expect(find.text('Server URL saved.'), findsOneWidget);
  });

  testWidgets('fleet settings failure → sanitized retry, retry re-queries',
      (tester) async {
    var calls = 0;
    when(() => config.getSettings()).thenAnswer((_) async {
      calls++;
      return calls == 1
          ? err(const ServerError(
              code: 'server',
              context: {'raw': 'DioException [bad response] Hibernate'},
              statusCode: 500,
            ))
          : ok(fleetJson());
    });
    await pump(tester);

    await tester.scrollUntilVisible(find.byType(EldRetryView), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('Dio'), findsNothing);
    expect(find.textContaining('Hibernate'), findsNothing);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(calls, 2);
    expect(find.byType(EldRetryView), findsNothing);
    expect(find.byType(EldInfoRow), findsWidgets);
  });
}
