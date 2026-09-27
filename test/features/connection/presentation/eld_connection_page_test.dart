import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_hardware_backend.dart';
import 'package:golden_feather_eld/backend/contracts/hardware_backend.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/services/bluetooth_service.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/features/connection/presentation/pages/eld_connection_page.dart';
import 'package:golden_feather_eld/features/connection/presentation/providers/hardware_status_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocalStorage extends Mock implements LocalStorageService {
  @override
  String get backendType => 'mock';
  @override
  String get serverUrl => 'https://example.com';
  @override
  String get language => 'en';
  @override
  String? get selectedVehicleId => null;
}

/// Bluetooth link succeeds; the server then refuses the session.
class _ServerRefusesHardware extends MockHardwareBackend {
  @override
  Future<Result<RawJson>> connectSession({
    String? uniqueId,
    bool disconnected = false,
  }) async =>
      err(const ServerError(
        code: 'server',
        statusCode: 503,
        context: {'raw': 'DioException [bad response] Hibernate'},
      ));
}

class _Bluetooth extends Mock implements BluetoothService {}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(
    WidgetTester tester,
    ConnectivityStatus status, {
    HardwareBackend? hardware,
    BluetoothService? bluetooth,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          localStorageProvider.overrideWithValue(_FakeLocalStorage()),
          hardwareStatusProvider.overrideWith((ref) async => status),
          if (hardware != null)
            hardwareBackendProvider.overrideWithValue(hardware),
          if (bluetooth != null)
            bluetoothServiceProvider.overrideWithValue(bluetooth),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const EldConnectionPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('reference layout: checklist, MAC field, two buttons — nothing else',
      (tester) async {
    await pump(
      tester,
      const ConnectivityStatus(
        connectionStatus: 'MALFUNCTION',
        lastHeartbeat: '2026-09-24T06:00:00Z',
        eldIdentifier: 'AA:BB:CC:DD:EE:FF',
      ),
    );

    // Screenshot 33: no status lines and no §395.34 block on this screen
    // (they live on About / Diagnostics).
    expect(find.text('Malfunction'), findsNothing);
    expect(find.textContaining('Last valid data'), findsNothing);
    expect(find.text('If the ELD malfunctions (§395.34)'), findsNothing);
    expect(find.widgetWithText(AppButton, 'START MANUAL RECORDING'), findsNothing);
    expect(find.byKey(const Key('connection_checklist_title')), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'CONNECT'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'CONTINUE DISCONNECTED'), findsOneWidget);
    expect(find.byType(AppButton), findsNWidgets(2));
    // Only the swap icon in the AppBar (leading) — no trailing action.
    expect(find.byIcon(Icons.compare_arrows), findsOneWidget);
    expect(find.byIcon(Icons.airport_shuttle_outlined), findsNothing);

    // MAC-shaped eldIdentifier prefills the empty MAC field.
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller?.text, 'AA:BB:CC:DD:EE:FF');
  });

  testWidgets('a non-MAC identifier is never pushed into the MAC field', (tester) async {
    await pump(
      tester,
      const ConnectivityStatus(
        connectionStatus: 'CONNECTED',
        eldIdentifier: 'ELD-PRO-1001',
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('connection failure names the targeted MAC and never a raw dump',
      (tester) async {
    // 1) The Bluetooth link itself fails.
    final bt = _Bluetooth();
    when(() => bt.connect(any()))
        .thenThrow(BluetoothException('CONNECT_FAILED', 'GATT error 133'));
    await pump(
      tester,
      const ConnectivityStatus(connectionStatus: 'DISCONNECTED'),
      bluetooth: bt,
    );
    await tester.enterText(find.byType(TextField).first, '44:A4:00:11:22:33');
    final connect = find.widgetWithText(AppButton, 'CONNECT');
    await tester.ensureVisible(connect);
    await tester.tap(connect);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.textContaining('Unable to connect to ELD with MAC 44:A4:00:11:22:33.'),
      findsOneWidget,
    );
    expect(find.textContaining('Bluetooth'), findsWidgets);
    expect(find.textContaining('GATT'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
  });

  testWidgets('server refusal after the Bluetooth link: MAC + sanitized reason',
      (tester) async {
    final bt = _Bluetooth();
    when(() => bt.connect(any())).thenAnswer((_) async {});
    await pump(
      tester,
      const ConnectivityStatus(connectionStatus: 'DISCONNECTED'),
      hardware: _ServerRefusesHardware(),
      bluetooth: bt,
    );
    await tester.enterText(find.byType(TextField).first, '44A4');
    final connect = find.widgetWithText(AppButton, 'CONNECT');
    await tester.ensureVisible(connect);
    await tester.tap(connect);
    await tester.pumpAndSettle();

    final banner = tester.widget<Text>(
      find.textContaining('Unable to connect to ELD with MAC 44A4.'),
    );
    expect(banner.data, isNot(contains('Dio')));
    expect(banner.data, isNot(contains('Hibernate')));
    // English UI → English reason (the notifier no longer hardcodes Arabic).
    expect(banner.data, contains('Try again'));
    expect(banner.data, isNot(contains('تعذر')));
  });

  testWidgets('CONNECT with empty MAC shows required error, no attempt',
      (tester) async {
    final bt = _Bluetooth();
    when(() => bt.connect(any())).thenAnswer((_) async {});
    await pump(
      tester,
      const ConnectivityStatus(connectionStatus: 'DISCONNECTED'),
      bluetooth: bt,
    );
    final connect = find.widgetWithText(AppButton, 'CONNECT');
    await tester.ensureVisible(connect);
    await tester.tap(connect);
    await tester.pumpAndSettle();

    expect(find.text('MAC address is required.'), findsOneWidget);
    verifyNever(() => bt.connect(any()));
    // Typing clears the error (autovalidate on user interaction).
    await tester.enterText(find.byType(TextField).first, '44A4');
    await tester.pumpAndSettle();
    expect(find.text('MAC address is required.'), findsNothing);
  });
}
