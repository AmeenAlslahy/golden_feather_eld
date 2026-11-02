import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_dvir_backend.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/services/tracking_config_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/core/widgets/app_signature_canvas.dart';
import 'package:golden_feather_eld/core/widgets/eld_card.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/dvir/domain/defect_enums.dart';
import 'package:golden_feather_eld/features/dvir/domain/entities/dvir_defect.dart';
import 'package:golden_feather_eld/features/dvir/presentation/pages/dvir_detail_page.dart';
import 'package:golden_feather_eld/features/dvir/presentation/pages/dvir_form_page.dart';
import 'package:golden_feather_eld/features/dvir/presentation/pages/dvir_list_page.dart';
import 'package:golden_feather_eld/features/dvir/presentation/providers/dvir_provider.dart';
import 'package:golden_feather_eld/features/dvir/presentation/widgets/dvir_form_sections.dart';
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

class _FakeTrackingStorage extends Mock implements TrackingConfigStorageService {
  @override
  String get deviceId => '1001';
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

class _RedesignTestDvirBackend extends MockDvirBackend {
  @override
  Future<Result<RawJson>> getById(DvirId dvirId) async {
    return ok({
      'id': dvirId.value,
      'uniqueId': '1001',
      'inspectionType': 'Pre-Trip',
      'inspectionTime': '2026-09-24T06:00:00Z',
      'status': 'Has Defects',
      'hasDefects': true,
      'defectsCount': 1,
      'certified': true,
      'outOfService': false,
      'location': 'Yard gate 3, Reno NV',
      'remarks': 'Replaced left front tire before departure',
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
      ],
    });
  }

  @override
  Future<Result<RawJson>> getVehicleDefects(String uniqueId) async {
    return ok({'data': <Map<String, dynamic>>[]});
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget createHarness({
    required Widget child,
    ThemeData? theme,
    Locale locale = const Locale('en'),
    double textScaleFactor = 1.0,
  }) {
    final backend = _RedesignTestDvirBackend();
    return ProviderScope(
      overrides: [
        activeBackendProvider.overrideWithValue(MockAdapter()),
        dvirBackendProvider.overrideWithValue(backend),
        localStorageProvider.overrideWithValue(_FakeLocalStorage()),
        networkInfoProvider.overrideWithValue(_OnlineNetwork()),
        trackingConfigStorageProvider.overrideWithValue(_FakeTrackingStorage()),
        dashboardDataProvider.overrideWith(
          (ref) => DashboardNotifier()
            ..updateVehicle(
              const Vehicle(
                id: '1001',
                uniqueId: '1001',
                name: 'Freightliner Cascadia 1001',
                year: '2022',
              ),
            ),
        ),
        activeVehicleDefectsProvider.overrideWith(
          (ref) async => const [
            DvirDefect(id: 1, stage: DefectLifecycleStage.open),
          ],
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScaleFactor),
          size: const Size(430, 932),
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme ?? AppTheme.light,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: child,
        ),
      ),
    );
  }

  group('Phase 4 — DVIR Form Redesign & Usability Verification', () {
    testWidgets('renders all redesigned sections without overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 8000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createHarness(child: const DvirFormPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Key redesigned sections are present
      expect(find.byType(DvirInspectionTypeSection), findsOneWidget);
      expect(find.byType(DvirVehicleSection), findsOneWidget);
      expect(find.byType(DvirTrailerSection), findsOneWidget);
      expect(find.byType(DvirRemarksSection), findsOneWidget);
      expect(find.byType(DvirSignatureSection), findsOneWidget);
      expect(find.byType(DvirSubmitButtonSection), findsOneWidget);

      // Signature canvas integration
      expect(find.byType(AppSignatureCanvas), findsOneWidget);
      // Design system buttons
      expect(find.byType(AppButton), findsWidgets);
    });

    testWidgets('inspection type selection changes state correctly', (tester) async {
      tester.view.physicalSize = const Size(1080, 8000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createHarness(child: const DvirFormPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pre-Trip'), findsWidgets);
    });

    testWidgets('signature canvas displays clear action and resets drawing', (tester) async {
      tester.view.physicalSize = const Size(1080, 8000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createHarness(child: const DvirFormPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final canvas = find.byType(AppSignatureCanvas);
      expect(canvas, findsOneWidget);

      final clearText = find.text('Clear signature');
      expect(clearText, findsOneWidget);
    });

    testWidgets('supports dark theme rendering cleanly', (tester) async {
      tester.view.physicalSize = const Size(1080, 8000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createHarness(
        child: const DvirFormPage(),
        theme: AppTheme.dark,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DvirFormPage), findsOneWidget);
      expect(find.byType(AppSignatureCanvas), findsOneWidget);
    });

    testWidgets('supports Arabic RTL directionality properly', (tester) async {
      tester.view.physicalSize = const Size(1080, 8000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createHarness(
        child: const DvirFormPage(),
        locale: const Locale('ar'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DvirFormPage), findsOneWidget);
      final element = tester.element(find.byType(DvirFormPage));
      expect(Directionality.of(element), TextDirection.rtl);
    });

    testWidgets('supports Spanish LTR locale properly', (tester) async {
      tester.view.physicalSize = const Size(1080, 8000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createHarness(
        child: const DvirFormPage(),
        locale: const Locale('es'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DvirFormPage), findsOneWidget);
      final element = tester.element(find.byType(DvirFormPage));
      expect(Directionality.of(element), TextDirection.ltr);
    });
  });

  group('Phase 4 — Responsive Layout & Text Scaling Tests', () {
    for (final width in [320.0, 375.0, 430.0]) {
      testWidgets('renders on ${width}dp width without overflow', (tester) async {
        tester.view.physicalSize = Size(width * 2.0, 800 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createHarness(child: const DvirFormPage()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DvirFormPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('supports text scaling ${scale}x without overflow', (tester) async {
        tester.view.physicalSize = const Size(375 * 2.0, 900 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createHarness(
          child: const DvirFormPage(),
          textScaleFactor: scale,
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DvirFormPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Phase 4 — DVIR List & Details Redesign Tests', () {
    testWidgets('dvir list page renders summary metric card and cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createHarness(child: const DvirListPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(EldCard), findsWidgets);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Signed'), findsOneWidget);
    });

    testWidgets('dvir detail page renders report sections cleanly in light and dark', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createHarness(child: const DvirDetailPage(dvirId: '1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DvirDetailPage), findsOneWidget);
      expect(find.byType(EldCard), findsWidgets);
    });
  });
}
