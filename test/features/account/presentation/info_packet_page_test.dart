import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_inspection_backend.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/backend/core/backend_adapter.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/account/presentation/pages/info_packet_page.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/sync/data/providers/sync_providers.dart';
import 'package:golden_feather_eld/features/sync/domain/usecases/sync_engine.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _Storage extends Mock implements LocalStorageService {
  @override
  String get language => 'en';
}

class _Adapter extends Mock implements BackendAdapter {}

class _Backend extends MockInspectionBackend {
  _Backend(this.answer);
  final Result<RawJson> answer;
  DriverId? askedFor;

  @override
  Future<Result<RawJson>> getInformationPacket({DriverId? driverId}) async {
    askedFor = driverId;
    return answer;
  }
}

class _MockNetworkInfo extends Mock implements NetworkInfo {
  @override
  bool get isConnected => true;
}

class _MockSyncEngine extends Mock implements SyncEngine {}

/// SRS 8.2 — Information Packet: completeness comes from the server's
/// `GET /eld/dot-inspection/information-packet` (never assumed), and the
/// manual / instructions are reachable from this screen.
void main() {
  Future<void> pump(WidgetTester tester, _Backend backend) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = _Adapter();
    when(() => adapter.inspection).thenReturn(backend);
    when(() => adapter.isMock).thenReturn(true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeBackendProvider.overrideWithValue(adapter),
          localStorageProvider.overrideWithValue(_Storage()),
          currentDriverIdProvider.overrideWithValue(106),
          networkInfoProvider.overrideWithValue(_MockNetworkInfo()),
          syncEngineProvider.overrideWithValue(_MockSyncEngine()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const InfoPacketPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('complete packet per server → no status line, two blocks only',
      (tester) async {
    final backend = _Backend(ok({
      'complete': true,
      'items': [
        {'title': 'User manual', 'available': true, 'mandatory': true},
        {'title': 'Instruction sheet', 'available': true, 'mandatory': true},
        {'title': 'Malfunction sheet', 'available': true, 'mandatory': true},
        {'title': 'Blank RODS (8 days)', 'available': true, 'mandatory': true},
      ],
    }));
    await pump(tester, backend);

    expect(backend.askedFor, const DriverId(106));
    expect(find.text('Info Packet'), findsOneWidget);
    // Reference layout: nothing between the AppBar and the User Manual block.
    expect(find.textContaining('packet'), findsNothing);
    expect(find.text('User Manual'), findsOneWidget);
    expect(find.text('Instructions'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'VIEW USER MANUAL'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'VIEW INSTRUCTIONS'), findsOneWidget);
    // Reference layout (screenshots 2/7): exactly two blocks, two buttons.
    expect(find.byType(AppButton), findsNWidgets(2));
    expect(find.text('Data Transfer Instruction Sheet'), findsNothing);
    expect(find.text('Malfunction Manual (395.34)'), findsNothing);
  });

  testWidgets('server says complete but a mandatory item is missing → incomplete',
      (tester) async {
    final backend = _Backend(ok({
      'complete': true,
      'missingItems': ['Malfunction sheet'],
      'items': [
        {'title': 'User manual', 'available': true, 'mandatory': true},
        {'title': 'Blank RODS (8 days)', 'available': false, 'mandatory': true},
      ],
    }));
    await pump(tester, backend);

    expect(
      find.text('Packet incomplete: Malfunction sheet, Blank RODS (8 days)'),
      findsOneWidget,
    );
  });

  testWidgets('server failure hides the status line without raw text', (tester) async {
    final backend = _Backend(err(const ServerError(
      code: 'HTTP_500',
      context: {'raw': 'DioException Hibernate'},
    )));
    await pump(tester, backend);

    expect(find.textContaining('Dio'), findsNothing);
    expect(find.textContaining('packet is'), findsNothing);
    // The manual and instructions are still reachable offline.
    expect(find.widgetWithText(AppButton, 'VIEW USER MANUAL'), findsOneWidget);
  });

  testWidgets('VIEW USER MANUAL and VIEW INSTRUCTIONS open their pages',
      (tester) async {
    final backend = _Backend(ok({'complete': true}));
    await pump(tester, backend);

    await tester.tap(find.widgetWithText(AppButton, 'VIEW USER MANUAL'));
    await tester.pumpAndSettle();
    expect(find.text('ELD User Manual'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    final instructions = find.widgetWithText(AppButton, 'VIEW INSTRUCTIONS');
    await tester.ensureVisible(instructions);
    await tester.tap(instructions);
    await tester.pumpAndSettle();
    expect(find.text('Instructions'), findsOneWidget);
  });
}
