import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/eld_info_row.dart';
import 'package:golden_feather_eld/features/about/presentation/pages/about_page.dart';
import 'package:golden_feather_eld/features/connection/domain/entities/hardware_alert.dart';
import 'package:golden_feather_eld/features/connection/presentation/providers/hardware_alerts_provider.dart';
import 'package:golden_feather_eld/features/connection/presentation/providers/hardware_status_provider.dart';
import 'package:golden_feather_eld/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _Storage extends Mock implements LocalStorageService {
  @override
  String get deviceId => '1001';
}

class _Alerts extends HardwareAlertsNotifier {
  _Alerts(this._alerts);
  final List<HardwareAlert> _alerts;
  @override
  Future<List<HardwareAlert>> build() async => _alerts;
}

class _FailingAlerts extends HardwareAlertsNotifier {
  @override
  Future<List<HardwareAlert>> build() async =>
      throw Exception('DioException [bad response] extension Hibernate');
}

/// SRS 3.6 / 3.8 / 7.14 — About / Diagnostics: app + device identity,
/// server / GPS / hardware alerts, and ELD engine / hardware versions with
/// "N/A" when the server does not provide them — never a raw exception.
void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Golden Feather ELD',
      packageName: 'com.goldenfeather.eld',
      version: '2.4.0',
      buildNumber: '87',
      buildSignature: '',
    );
  });

  List<String> rows(WidgetTester tester) => tester
      .widgetList<EldInfoRow>(find.byType(EldInfoRow, skipOffstage: false))
      .map((w) => '${w.label}=${w.value}')
      .toList();

  Future<void> pump(
    WidgetTester tester, {
    required List<Override> overrides,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(_Storage()),
          isConnectedProvider.overrideWith((ref) => Stream.value(true)),
          gpsStatusProvider.overrideWith((ref) => Stream.value(ServiceStatus.enabled)),
          ...overrides,
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const AboutPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// The ListView is lazy: collect rows from the top, then scroll the
  /// technical card in and collect again.
  Future<List<String>> allRows(WidgetTester tester) async {
    final top = rows(tester);
    await tester.scrollUntilVisible(find.text('Technical Info'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 100));
    return {...top, ...rows(tester)}.toList();
  }

  testWidgets('shows versions from the server and app/device identity', (tester) async {
    await pump(tester, overrides: [
      hardwareAlertsProvider.overrideWith(() => _Alerts(const [])),
      hardwareStatusProvider.overrideWith((ref) async => const ConnectivityStatus(
            connectionStatus: 'CONNECTED',
            engineVersion: '5.2.1',
            deviceVersion: 'HW-3.0',
            lastHeartbeat: '2026-09-24T06:00:00Z',
          )),
    ]);
    expect(find.text('About'), findsOneWidget);
    // Server tile + the ELD connectivity panel (SRS 3.8) both read Connected.
    expect(find.text('Connected'), findsWidgets);
    expect(find.text('Enabled'), findsOneWidget);
    expect(find.text('No active alerts'), findsOneWidget);
    final r = await allRows(tester);
    expect(r, contains('Version=2.4.0 (87)'));
    expect(r, contains('Package=com.goldenfeather.eld'));
    expect(r, contains('Device ID=1001'));
    expect(r, contains('ELD Engine Version=5.2.1'));
    expect(r, contains('Hardware Version=HW-3.0'));
    expect(r, contains('Last Data Received=2026-09-24T06:00:00Z'));
  });

  testWidgets('missing versions are N/A and alerts are listed', (tester) async {
    await pump(tester, overrides: [
      hardwareAlertsProvider.overrideWith(() => _Alerts([
            HardwareAlert(
              id: 'a1',
              type: 'MALFUNCTION',
              message: 'Power compliance malfunction',
              timestamp: DateTime(2026, 9, 24),
            ),
          ])),
      hardwareStatusProvider.overrideWith(
          (ref) async => const ConnectivityStatus(connectionStatus: 'CONNECTED')),
    ]);
    expect(find.text('Active alerts'), findsOneWidget);
    expect(find.text('• Power compliance malfunction'), findsOneWidget);
    final r = await allRows(tester);
    expect(r, contains('ELD Engine Version=N/A'));
    expect(r, contains('Hardware Version=N/A'));
    expect(r, contains('Last Data Received=N/A'));
  });

  testWidgets('failures are sanitized — no raw exception text', (tester) async {
    await pump(tester, overrides: [
      hardwareAlertsProvider.overrideWith(_FailingAlerts.new),
      hardwareStatusProvider.overrideWith(
          (ref) async => throw Exception('DioException Hibernate extension')),
    ]);
    await tester.scrollUntilVisible(find.text('Technical Info'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Dio'), findsNothing);
    expect(find.textContaining('Hibernate'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.textContaining('Error:'), findsNothing);
    expect(
      find.text('The request could not be completed. Check the network and try again.'),
      findsWidgets,
    );
  });
}
