import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_hardware_backend.dart';
import 'package:golden_feather_eld/backend/contracts/hardware_backend.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/connection/presentation/providers/hardware_status_provider.dart';
import 'package:golden_feather_eld/features/connection/presentation/widgets/eld_diagnostics_section.dart';
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

/// Records the manual-mode call the section makes; everything else is the mock.
class _RecordingHardware extends MockHardwareBackend {
  final calls = <String>[];

  @override
  Future<Result<RawJson>> setManualMode({
    required bool enable,
    required String reason,
    DriverId? driverId,
  }) async {
    calls.add('manual-mode:$enable:$reason');
    return ok(<String, dynamic>{
      'connectionStatus': enable ? 'MALFUNCTION' : 'CONNECTED',
      'manualModeActive': enable,
    });
  }
}

/// SRS 3.7 / 3.8 — the §395.34 manual-recording block and the server
/// connectivity lines live on About / Diagnostics (moved off the connection
/// screen to match the reference layout).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(
    WidgetTester tester,
    ConnectivityStatus status, {
    HardwareBackend? hardware,
    HardwareReadiness? readiness,
    Object? readinessError,
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
          hardwareReadinessProvider.overrideWith((ref) async {
            if (readinessError != null) throw readinessError;
            return readiness ?? const HardwareReadiness(ready: true);
          }),
          if (hardware != null)
            hardwareBackendProvider.overrideWithValue(hardware),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  EldConnectivityPanel(),
                  EldReadinessPanel(),
                  ManualRecordingSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('MALFUNCTION shows §395.34 steps and the manual recording action',
      (tester) async {
    await pump(
      tester,
      const ConnectivityStatus(
        connectionStatus: 'MALFUNCTION',
        lastHeartbeat: '2026-09-24T06:00:00Z',
      ),
    );

    expect(find.text('Malfunction'), findsOneWidget);
    expect(find.text('Last valid data: 2026-09-24T06:00:00Z'), findsOneWidget);
    expect(find.text('If the ELD malfunctions (§395.34)'), findsOneWidget);
    expect(find.textContaining('within 24 hours'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'START MANUAL RECORDING'), findsOneWidget);
  });

  testWidgets('manual recording: empty reason refused, reason sent to manual-mode',
      (tester) async {
    final hardware = _RecordingHardware();
    await pump(
      tester,
      const ConnectivityStatus(connectionStatus: 'MALFUNCTION'),
      hardware: hardware,
    );

    final start = find.widgetWithText(AppButton, 'START MANUAL RECORDING');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(find.text('Manual recording reason'), findsOneWidget);

    // Empty reason → refused locally; nothing hits the server.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a reason for manual recording.'), findsOneWidget);
    expect(hardware.calls, isEmpty);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // With a reason → POST manual-mode with enable=true and that reason.
    await tester.tap(start);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Lost connection to the ELD');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(hardware.calls, ['manual-mode:true:Lost connection to the ELD']);
    expect(find.text('Manual recording start was recorded on the server.'),
        findsOneWidget);
  });

  testWidgets('CONNECTED keeps the manual recording section hidden', (tester) async {
    await pump(tester, const ConnectivityStatus(connectionStatus: 'CONNECTED'));

    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('If the ELD malfunctions (§395.34)'), findsNothing);
    expect(find.widgetWithText(AppButton, 'START MANUAL RECORDING'), findsNothing);
  });

  testWidgets(
      'manual mode active: END replaces START, is offered even when CONNECTED, '
      'and ends via manual-mode enable=false with the reason', (tester) async {
    final hardware = _RecordingHardware();
    await pump(
      tester,
      const ConnectivityStatus(
        connectionStatus: 'CONNECTED',
        manualModeActive: true,
        manualModeReason: 'no connection',
      ),
      hardware: hardware,
    );

    expect(find.widgetWithText(AppButton, 'START MANUAL RECORDING'), findsNothing);
    expect(find.textContaining('Manual recording is active'), findsOneWidget);
    expect(find.textContaining('no connection'), findsOneWidget);

    final end = find.widgetWithText(AppButton, 'END MANUAL RECORDING');
    expect(end, findsOneWidget);
    await tester.ensureVisible(end);
    await tester.tap(end);
    await tester.pumpAndSettle();
    expect(find.text('Reason for ending manual recording'), findsOneWidget);

    // Empty reason → refused locally (server 400s without a reason).
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(hardware.calls, isEmpty);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(end);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'ELD connection restored');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(hardware.calls, ['manual-mode:false:ELD connection restored']);
    expect(find.text('Manual recording ended; electronic recording resumed.'),
        findsOneWidget);
  });

  testWidgets('server manualRecordingAllowed=false: no START, explanation shown',
      (tester) async {
    await pump(
      tester,
      const ConnectivityStatus(
        connectionStatus: 'UNAVAILABLE',
        manualRecordingAllowed: false,
      ),
    );
    expect(find.widgetWithText(AppButton, 'START MANUAL RECORDING'), findsNothing);
    expect(find.widgetWithText(AppButton, 'END MANUAL RECORDING'), findsNothing);
    expect(
      find.text('The server does not allow manual recording for this vehicle.'),
      findsOneWidget,
    );
  });

  testWidgets('readiness: checklist ✓/✗, server reasons and action verbatim',
      (tester) async {
    await pump(
      tester,
      const ConnectivityStatus(connectionStatus: 'UNAVAILABLE'),
      readiness: const HardwareReadiness(
        ready: false,
        checklist: {
          'device_paired': true,
          'connection_active': false,
          'engine_telemetry': false,
          'brand_new_check': true,
        },
        rejectionReasons: ['No GPS or live data received from the ELD yet.'],
        recommendedAction: 'End manual mode after the device reconnects.',
      ),
    );

    expect(find.text('Pre-operation readiness'), findsOneWidget);
    expect(find.text('Not ready for operation'), findsOneWidget);
    expect(find.text('Device paired'), findsOneWidget);
    expect(find.text('Connection active'), findsOneWidget);
    expect(find.text('Engine telemetry (ECM)'), findsOneWidget);
    // Unknown server keys are still listed, never hidden.
    expect(find.text('brand new check'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    expect(find.byIcon(Icons.cancel), findsNWidgets(2));
    expect(find.text('• No GPS or live data received from the ELD yet.'),
        findsOneWidget);
    expect(
      find.text('Recommended action: End manual mode after the device reconnects.'),
      findsOneWidget,
    );
  });

  testWidgets('readiness: ready → success line',
      (tester) async {
    await pump(
      tester,
      const ConnectivityStatus(connectionStatus: 'CONNECTED'),
      readiness: const HardwareReadiness(ready: true, checklist: {'device_paired': true}),
    );
    expect(find.text('Ready for operation'), findsOneWidget);
  });

  testWidgets('readiness read failure → user message, never a raw dump',
      (tester) async {
    await pump(
      tester,
      const ConnectivityStatus(connectionStatus: 'CONNECTED'),
      readinessError: const FormatException('readiness body is not an object'),
    );
    expect(find.textContaining('FormatException'), findsNothing);
    expect(find.textContaining('readiness body'), findsNothing);
    expect(find.text('Ready for operation'), findsNothing);
    expect(find.text('Not ready for operation'), findsNothing);
  });
}
