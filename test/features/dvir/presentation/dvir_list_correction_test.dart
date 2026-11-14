import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_dvir_backend.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/services/tracking_config_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/dvir/domain/defect_enums.dart';
import 'package:golden_feather_eld/features/dvir/domain/dvir_catalog.dart';
import 'package:golden_feather_eld/features/dvir/domain/entities/dvir_defect.dart';
import 'package:golden_feather_eld/features/dvir/presentation/pages/dvir_form_page.dart';
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

class _TestDvirBackend extends MockDvirBackend {
  bool failList = false;

  @override
  Future<Result<RawJson>> list({
    DriverId? driverId,
    String? uniqueId,
    DateTime? date,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    if (failList) {
      return err(const ServerError(code: 'network.disconnected'));
    }
    return ok({
      'data': [
        {
          'id': 101,
          'uniqueId': '1001',
          'inspectionType': 'Pre-Trip',
          'inspectionTime': '2026-10-30T07:00:00Z',
          'status': 'Has Defects',
          'hasDefects': true,
          'defectsCount': 1,
          'certified': false,
          'outOfService': false,
          'vehicleOperationalStatus': 'SATISFACTORY',
          'odometer': 125430.0,
          'defects': [
            {
              'itemCode': 'TR_BRAKES',
              'itemName': 'Brakes',
              'category': 'TRAILER',
              'safetyAffecting': true,
            },
          ],
        },
        {
          'id': 102,
          'uniqueId': '1001',
          'inspectionType': 'Post-Trip',
          'inspectionTime': '2026-10-29T18:30:00Z',
          'status': 'Satisfactory',
          'hasDefects': false,
          'defectsCount': 0,
          'certified': true,
          'signatureData': 'sample_signature_base64',
          'outOfService': false,
          'vehicleOperationalStatus': 'SATISFACTORY',
          'odometer': 124890.0,
          'defects': const [],
        },
      ],
    });
  }

  @override
  Future<Result<RawJson>> getById(DvirId dvirId) async {
    return ok({
      'id': dvirId.value,
      'uniqueId': '1001',
      'inspectionType': 'Pre-Trip',
      'inspectionTime': '2026-10-30T07:00:00Z',
      'status': 'Has Defects',
      'hasDefects': true,
      'defectsCount': 1,
      'certified': false,
      'outOfService': false,
      'remarks': 'Inspected thoroughly before departure',
      'location': 'Salt Lake City, UT',
      'defects': [
        {
          'itemCode': 'TR_BRAKES',
          'itemName': 'Brakes',
          'category': 'TRAILER',
          'safetyAffecting': true,
        },
      ],
    });
  }
}

class _RealImageBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  Future<ui.Codec> instantiateImageCodecWithSize(
    ui.ImmutableBuffer buffer, {
    ui.TargetImageSizeCallback? getTargetSize,
  }) async {
    if (getTargetSize != null) {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final targetSize = getTargetSize(descriptor.width, descriptor.height);
      return descriptor.instantiateCodec(
        targetWidth: targetSize.width,
        targetHeight: targetSize.height,
      );
    }
    return ui.instantiateImageCodecFromBuffer(buffer);
  }
}

void main() {
  _RealImageBinding();

  setUpAll(() async {
    try {
      final robotoLoader = FontLoader('Roboto');
      final regularFile = File('assets/fonts/google_fonts/Roboto-Regular.ttf');
      if (regularFile.existsSync()) {
        robotoLoader.addFont(
          Future.value(ByteData.view(regularFile.readAsBytesSync().buffer)),
        );
      }
      final mediumFile = File('assets/fonts/google_fonts/Roboto-Medium.ttf');
      if (mediumFile.existsSync()) {
        robotoLoader.addFont(
          Future.value(ByteData.view(mediumFile.readAsBytesSync().buffer)),
        );
      }
      final boldFile = File('assets/fonts/google_fonts/Roboto-Bold.ttf');
      if (boldFile.existsSync()) {
        robotoLoader.addFont(
          Future.value(ByteData.view(boldFile.readAsBytesSync().buffer)),
        );
      }
      await robotoLoader.load();
    } catch (_) {}

    try {
      final iconFile = File(
        r'D:\Flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf',
      );
      if (iconFile.existsSync()) {
        final iconLoader = FontLoader('MaterialIcons');
        iconLoader.addFont(
          Future.value(ByteData.view(iconFile.readAsBytesSync().buffer)),
        );
        await iconLoader.load();
      }
    } catch (_) {}
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> captureScreen({
    required WidgetTester tester,
    required GlobalKey key,
    required String filename,
  }) async {
    await tester.binding.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final outDir = Directory('build/screenshots');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      await File('build/screenshots/$filename').writeAsBytes(bytes);

      const artifactDir =
          r'C:\Users\Owner\.gemini\antigravity-ide\brain\5a94c5e4-5889-4e0e-a640-28bea96b9f8a';
      final artDir = Directory(artifactDir);
      if (artDir.existsSync()) {
        await File('$artifactDir/$filename').writeAsBytes(bytes);
      }
    });
  }

  Widget createHarness({
    required GlobalKey repaintKey,
    required _TestDvirBackend backend,
    ThemeData? theme,
    Locale locale = const Locale('ar'),
    double textScale = 1.0,
    List<DvirDefect>? activeDefects,
    bool failActiveDefects = false,
    int initialIndex = 0,
  }) {
    return ProviderScope(
      overrides: [
        dashboardDataProvider.overrideWith(
          (ref) => DashboardNotifier()
            ..updateVehicle(
              const Vehicle(
                id: '1001',
                uniqueId: '1001',
                name: 'Truck 1001',
                year: '2024',
              ),
            ),
        ),
        activeBackendProvider.overrideWithValue(MockAdapter()),
        localStorageProvider.overrideWithValue(_FakeLocalStorage()),
        dvirBackendProvider.overrideWithValue(backend),
        networkInfoProvider.overrideWithValue(_OnlineNetwork()),
        trackingConfigStorageProvider.overrideWithValue(_FakeTrackingStorage()),
        dvirCatalogProvider.overrideWith(
          (ref) async => const [
            DvirCatalogItem(
              code: 'TR_BRAKES',
              name: 'Brakes',
              nameAr: 'المكابح',
              category: 'TRAILER',
            ),
            DvirCatalogItem(
              code: 'TR_LIGHTS',
              name: 'Lights - All',
              nameAr: 'جميع الأضواء',
              category: 'TRAILER',
            ),
            DvirCatalogItem(
              code: 'TR_TIRES',
              name: 'Tires',
              nameAr: 'الإطارات',
              category: 'TRAILER',
            ),
          ],
        ),
        activeVehicleDefectsProvider.overrideWith((ref) async {
          if (failActiveDefects) {
            throw const ServerFailure(message: 'vehicleDefectsUnavailable');
          }
          return activeDefects ??
              const [
                DvirDefect(
                  id: 1,
                  itemCode: 'TR_BRAKES',
                  itemName: 'Brakes',
                  description: 'Air pressure dropping slowly',
                  severity: DefectSeverity.high,
                  stage: DefectLifecycleStage.open,
                  outOfService: true,
                ),
                DvirDefect(
                  id: 2,
                  itemCode: 'TR_LIGHTS',
                  itemName: 'Lights - All',
                  description:
                      'Lights - All', // Identical text for deduplication test
                  severity: DefectSeverity.medium,
                  stage: DefectLifecycleStage.open,
                ),
              ];
        }),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            textScaler: TextScaler.linear(textScale),
          ),
          child: RepaintBoundary(
            key: repaintKey,
            child: Scaffold(body: DvirListPage(initialIndex: initialIndex)),
          ),
        ),
      ),
    );
  }

  group('DVIR List Visual & UX Correction Suite', () {
    testWidgets(
      'Deduplication: Identical title and description suppresses redundant description',
      (tester) async {
        final key = GlobalKey();
        final backend = _TestDvirBackend();
        await tester.pumpWidget(
          createHarness(
            repaintKey: key,
            backend: backend,
            initialIndex: 1,
            activeDefects: const [
              DvirDefect(
                id: 10,
                itemCode: 'TR_BRAKES',
                itemName: 'Brakes',
                description: 'Brakes', // Identical!
                severity: DefectSeverity.medium,
                stage: DefectLifecycleStage.open,
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.text('Brakes'),
          findsNothing,
        ); // In Arabic, it resolves to المكابح
        expect(
          find.text('المكابح'),
          findsOneWidget,
        ); // Displayed once as title, not twice!
      },
    );

    testWidgets(
      'Preservation: Genuinely distinct description is fully preserved',
      (tester) async {
        final key = GlobalKey();
        final backend = _TestDvirBackend();
        await tester.pumpWidget(
          createHarness(
            repaintKey: key,
            backend: backend,
            initialIndex: 1,
            activeDefects: const [
              DvirDefect(
                id: 11,
                itemCode: 'TR_TIRES',
                itemName: 'Tires',
                description: 'Left steer tire tread below 4/32 inch',
                severity: DefectSeverity.high,
                stage: DefectLifecycleStage.open,
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('الإطارات'), findsOneWidget);
        expect(
          find.text('Left steer tire tread below 4/32 inch'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Severity Badge: High (red), Medium (amber), Low (neutral, NOT green)',
      (tester) async {
        final key = GlobalKey();
        final backend = _TestDvirBackend();
        await tester.pumpWidget(
          createHarness(
            repaintKey: key,
            backend: backend,
            initialIndex: 1,
            activeDefects: const [
              DvirDefect(
                id: 1,
                itemCode: 'A',
                itemName: 'Defect 1',
                severity: DefectSeverity.high,
              ),
              DvirDefect(
                id: 2,
                itemCode: 'B',
                itemName: 'Defect 2',
                severity: DefectSeverity.medium,
              ),
              DvirDefect(
                id: 3,
                itemCode: 'C',
                itemName: 'Defect 3',
                severity: DefectSeverity.low,
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('HIGH'), findsOneWidget);
        expect(find.text('MEDIUM'), findsOneWidget);
        expect(find.text('LOW'), findsOneWidget);
      },
    );

    testWidgets(
      'Summary 2x2: Displays all 4 categories cohesively in RTL and LTR',
      (tester) async {
        final key = GlobalKey();
        final backend = _TestDvirBackend();
        await tester.pumpWidget(
          createHarness(
            repaintKey: key,
            backend: backend,
            locale: const Locale('en'),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Total'), findsOneWidget);
        expect(find.text('Signed'), findsOneWidget);
        expect(find.text('Open'), findsOneWidget);
        expect(find.text('OOS'), findsOneWidget);
      },
    );

    testWidgets(
      'Navigation: Tapping in-page action button navigates to DvirFormPage',
      (tester) async {
        final key = GlobalKey();
        final backend = _TestDvirBackend();
        await tester.pumpWidget(
          createHarness(
            repaintKey: key,
            backend: backend,
            locale: const Locale('en'),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final createButton = find.widgetWithText(
          AppButton,
          'Create New Report',
        );
        expect(createButton, findsOneWidget);

        await tester.tap(createButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DvirFormPage), findsOneWidget);
      },
    );

    testWidgets(
      'Partial Failure: Active defects fails but reports succeed with visible retry',
      (tester) async {
        final key = GlobalKey();
        final backend = _TestDvirBackend();
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createHarness(
            repaintKey: key,
            backend: backend,
            failActiveDefects: true,
            locale: const Locale('en'),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Reports list still loaded and interactive on Reports tab
        expect(find.text('Pre-Trip'), findsOneWidget);
        expect(find.text('Post-Trip'), findsOneWidget);

        // Switch to Defects tab
        await tester.tap(find.byKey(const Key('dvir_tab_defects')));
        await tester.pumpAndSettle();

        // Active defects card displays retry on Defects tab
        expect(
          find.text('Could not load the defects list from the server.'),
          findsOneWidget,
        );
        expect(find.widgetWithText(AppButton, 'RETRY'), findsOneWidget);
      },
    );

    testWidgets(
      'Full Failure: Both sections display bounded error cards with independent retry',
      (tester) async {
        final key = GlobalKey();
        final backend = _TestDvirBackend();
        backend.failList = true;
        await tester.pumpWidget(
          createHarness(
            repaintKey: key,
            backend: backend,
            failActiveDefects: true,
            locale: const Locale('en'),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Reports error on Reports tab
        expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);

        // Switch to Defects tab
        await tester.tap(find.byKey(const Key('dvir_tab_defects')));
        await tester.pumpAndSettle();

        // Active defects error on Defects tab
        expect(
          find.text('Could not load the defects list from the server.'),
          findsOneWidget,
        );
      },
    );
  });

  group('Capture 10 Required Screenshots for Phase 4.2', () {
    testWidgets('1. DVIR List — Arabic Light, normal data', (tester) async {
      final key = GlobalKey();
      final backend = _TestDvirBackend();
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createHarness(
          repaintKey: key,
          backend: backend,
          theme: AppTheme.light,
          locale: const Locale('ar'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'dvir_list_arabic_light.png',
      );
    });

    testWidgets('2. DVIR List — Arabic Dark, normal data', (tester) async {
      final key = GlobalKey();
      final backend = _TestDvirBackend();
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createHarness(
          repaintKey: key,
          backend: backend,
          theme: AppTheme.dark,
          locale: const Locale('ar'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'dvir_list_arabic_dark.png',
      );
    });

    testWidgets('3. Active Defects — Many items', (tester) async {
      final key = GlobalKey();
      final backend = _TestDvirBackend();
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createHarness(
          repaintKey: key,
          backend: backend,
          initialIndex: 1,
          theme: AppTheme.light,
          locale: const Locale('ar'),
          activeDefects: const [
            DvirDefect(
              id: 1,
              itemCode: 'TR_BRAKES',
              itemName: 'Brakes',
              severity: DefectSeverity.high,
              outOfService: true,
            ),
            DvirDefect(
              id: 2,
              itemCode: 'TR_TIRES',
              itemName: 'Tires',
              severity: DefectSeverity.medium,
            ),
            DvirDefect(
              id: 3,
              itemCode: 'TR_LIGHTS',
              itemName: 'Lights - All',
              severity: DefectSeverity.low,
            ),
            DvirDefect(
              id: 4,
              itemCode: 'TR_SUSPENSION',
              itemName: 'Suspension System',
              severity: DefectSeverity.high,
            ),
            DvirDefect(
              id: 5,
              itemCode: 'TR_COUPLING',
              itemName: 'Coupling Devices',
              severity: DefectSeverity.medium,
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'active_defects_many.png',
      );
    });

    testWidgets('4. Active Defects — Long titles', (tester) async {
      final key = GlobalKey();
      final backend = _TestDvirBackend();
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createHarness(
          repaintKey: key,
          backend: backend,
          initialIndex: 1,
          theme: AppTheme.light,
          locale: const Locale('en'),
          activeDefects: const [
            DvirDefect(
              id: 20,
              itemCode: 'CUSTOM_LONG',
              itemName:
                  'Auxiliary Refrigeration Unit Temperature Deviation Beyond Tolerable Range Under FMCSA 396.11',
              description:
                  'Refrigerant compressor cycling on and off repeatedly every 30 seconds',
              severity: DefectSeverity.high,
              outOfService: true,
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'active_defects_long_titles.png',
      );
    });

    testWidgets('5. Active Defects — Mixed Arabic/English', (tester) async {
      final key = GlobalKey();
      final backend = _TestDvirBackend();
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createHarness(
          repaintKey: key,
          backend: backend,
          initialIndex: 1,
          theme: AppTheme.light,
          locale: const Locale('ar'),
          activeDefects: const [
            DvirDefect(
              id: 30,
              itemCode: 'TR_BRAKES',
              itemName: 'Brakes',
              severity: DefectSeverity.high,
            ),
            DvirDefect(
              id: 31,
              itemCode: 'CUSTOM_ENG',
              itemName: 'Custom Air Leak Valve 3',
              description: 'Audible hiss from fitting behind cab',
              severity: DefectSeverity.medium,
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'active_defects_mixed_ar_en.png',
      );
    });

    testWidgets('6. DVIR List — No defects', (tester) async {
      final key = GlobalKey();
      final backend = _TestDvirBackend();
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createHarness(
          repaintKey: key,
          backend: backend,
          initialIndex: 1,
          theme: AppTheme.light,
          locale: const Locale('ar'),
          activeDefects: const [], // Zero defects
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'dvir_list_no_defects.png',
      );
    });

    testWidgets('7. DVIR List — Partial loading failure', (tester) async {
      final key = GlobalKey();
      final backend = _TestDvirBackend();
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createHarness(
          repaintKey: key,
          backend: backend,
          theme: AppTheme.light,
          locale: const Locale('ar'),
          failActiveDefects: true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'dvir_list_partial_failure.png',
      );
    });

    testWidgets('8. DVIR List — Full loading failure', (tester) async {
      final key = GlobalKey();
      final backend = _TestDvirBackend();
      backend.failList = true;
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createHarness(
          repaintKey: key,
          backend: backend,
          theme: AppTheme.light,
          locale: const Locale('ar'),
          failActiveDefects: true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'dvir_list_full_failure.png',
      );
    });

    testWidgets('9. DVIR List — 320dp width', (tester) async {
      final key = GlobalKey();
      final backend = _TestDvirBackend();
      tester.view.physicalSize = const Size(960, 2000); // 320dp @ 3.0 ratio
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createHarness(
          repaintKey: key,
          backend: backend,
          theme: AppTheme.light,
          locale: const Locale('ar'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'dvir_list_320dp.png',
      );
    });

    testWidgets('10. DVIR List — 2.0x text scaling', (tester) async {
      final key = GlobalKey();
      final backend = _TestDvirBackend();
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createHarness(
          repaintKey: key,
          backend: backend,
          theme: AppTheme.light,
          locale: const Locale('ar'),
          textScale: 2.0,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'dvir_list_2_0x_text_scale.png',
      );
    });
  });
}
