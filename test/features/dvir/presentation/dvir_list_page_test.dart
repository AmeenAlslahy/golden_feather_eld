import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_dvir_backend.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/services/tracking_config_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/dvir/domain/defect_enums.dart';
import 'package:golden_feather_eld/features/dvir/domain/entities/dvir_defect.dart';
import 'package:golden_feather_eld/features/dvir/presentation/pages/dvir_list_page.dart';
import 'package:golden_feather_eld/features/dvir/presentation/providers/dvir_provider.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:golden_feather_eld/features/vehicle/domain/entities/vehicle.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OnlineNetwork implements NetworkInfo {
  @override
  bool get isConnected => true;
  @override
  Stream<bool> get onConnectionChange => const Stream.empty();
}

class _FakeTrackingStorage extends Mock
    implements TrackingConfigStorageService {
  @override
  String get deviceId => '1001';
}

/// Two live-shaped reports: one open defect, one signed & out of service.
class _TwoReportsDvirBackend extends MockDvirBackend {
  final detailIds = <int>[];
  bool failDetails = false;

  /// Full record: the list summary has no remarks / location; the detail does.
  @override
  Future<Result<RawJson>> getById(DvirId dvirId) async {
    detailIds.add(dvirId.value);
    if (failDetails) {
      return err(const ServerError(code: 'server.internal'));
    }
    return ok({
      'id': dvirId.value,
      'uniqueId': '1001',
      'inspectionType': 'Pre-Trip',
      'inspectionTime': '2026-09-24T06:00:00Z',
      'status': 'Has Defects',
      'hasDefects': true,
      'defectsCount': 1,
      'certified': false,
      'outOfService': false,
      'location': 'Yard gate 3, Reno NV',
      'remarks': 'Replaced before departure',
      'defects': [
        {
          'itemCode': 'TIRES',
          'itemName': 'Tires',
          'category': 'REGULATORY_MINIMUM',
          'safetyAffecting': true,
          'description': 'left front worn',
        },
      ],
    });
  }

  @override
  Future<Result<RawJson>> list({
    DriverId? driverId,
    String? uniqueId,
    DateTime? date,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    return ok({
      'data': [
        {
          'id': 1,
          'uniqueId': '1001',
          'inspectionType': 'Pre-Trip',
          'inspectionTime': '2026-09-24T06:00:00Z',
          'status': 'Has Defects',
          'hasDefects': true,
          'defectsCount': 1,
          'certified': false,
          'outOfService': false,
          'defects': [
            {
              'itemCode': 'TIRES',
              'itemName': 'Tires',
              'category': 'REGULATORY_MINIMUM',
              'safetyAffecting': true,
              'description': 'left front worn',
            },
          ],
        },
        {
          'id': 2,
          'uniqueId': '1001',
          'inspectionType': 'Post-Trip',
          'inspectionTime': '2026-09-23T18:00:00Z',
          'status': 'Has Defects',
          'hasDefects': true,
          'defectsCount': 1,
          'certified': true,
          'signatureData': 'iVBOR',
          'outOfService': true,
          'defects': const [],
        },
      ],
    });
  }

  @override
  Future<Result<RawJson>> getVehicleDefects(String uniqueId) async {
    return ok({
      'data': [
        {
          'id': 99,
          'itemCode': 'TIRES',
          'itemName': 'Tires',
          'category': 'REGULATORY_MINIMUM',
          'safetyAffecting': true,
          'description': 'left front worn',
          'stage': 'OPEN',
          'severity': 'HIGH',
        },
      ],
    });
  }
}

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

void main() {
  late _TwoReportsDvirBackend backend;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = _TwoReportsDvirBackend();
  });

  Future<void> pump(
    WidgetTester tester, {
    bool failDetails = false,
    List<DvirDefect>? activeDefects,
  }) async {
    backend.failDetails = failDetails;
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardDataProvider.overrideWith(
            (ref) => DashboardNotifier()
              ..updateVehicle(
                const Vehicle(
                  id: '1001',
                  uniqueId: '1001',
                  name: 'Truck 1001',
                  year: '2022',
                ),
              ),
          ),
          activeBackendProvider.overrideWithValue(MockAdapter()),
          localStorageProvider.overrideWithValue(_FakeLocalStorage()),
          dvirBackendProvider.overrideWithValue(backend),
          networkInfoProvider.overrideWithValue(_OnlineNetwork()),
          trackingConfigStorageProvider.overrideWithValue(
            _FakeTrackingStorage(),
          ),
          activeVehicleDefectsProvider.overrideWith(
            (ref) async =>
                activeDefects ??
                const [DvirDefect(id: 1, stage: DefectLifecycleStage.open)],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const DvirListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'summary row counts Total / Open / Signed / OOS from the loaded list',
    (tester) async {
      await pump(tester);

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Signed'), findsOneWidget);
      expect(find.text('OOS'), findsOneWidget);

      // total 2; open defects: report 1 (has defects, not certified) = 1;
      // signed: report 2 = 1; out of service: report 2 = 1.
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(3));
    },
  );

  testWidgets('open count uses DefectLifecycleStage, not wire strings', (
    tester,
  ) async {
    await pump(
      tester,
      activeDefects: const [
        DvirDefect(id: 1, stage: DefectLifecycleStage.open),
        DvirDefect(id: 2, stage: DefectLifecycleStage.open),
        DvirDefect(id: 3, stage: DefectLifecycleStage.repaired),
      ],
    );

    // Total 2; active defects override the summary open count (1) with 2.
    expect(find.text('2'), findsNWidgets(2));
    expect(find.text('1'), findsNWidgets(2));
  });

  testWidgets('app bar has a refresh action next to add', (tester) async {
    await pump(tester);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    // Reference layout (screenshot 21): "+" lives in the AppBar, no FAB.
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('opening a card reads the full report from GET /eld/dvir/{id}', (
    tester,
  ) async {
    await pump(tester);

    // Summary card of report 1 → read-only view.
    await tester.tap(find.text('Pre-Trip').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(backend.detailIds, [1]);
    // Detail-only fields are shown; the summary alone had neither.
    expect(find.text('Replaced before departure'), findsOneWidget);
    expect(find.text('Yard gate 3, Reno NV'), findsWidgets);
  });

  testWidgets('detail read failure shows a localized message', (tester) async {
    await pump(tester, failDetails: true);

    await tester.tap(find.text('Pre-Trip').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(
      find.text('The server returned an error. Try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('server.internal'), findsNothing);
  });
}
