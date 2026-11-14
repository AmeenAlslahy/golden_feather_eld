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
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/services/tracking_config_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/dvir/domain/defect_enums.dart';
import 'package:golden_feather_eld/features/dvir/domain/entities/dvir_defect.dart';
import 'package:golden_feather_eld/features/dvir/domain/entities/dvir_report.dart';
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

class _ScreenshotDvirBackend extends MockDvirBackend {
  @override
  Future<Result<RawJson>> getById(DvirId dvirId) async {
    return ok({
      'id': dvirId.value,
      'uniqueId': '1001',
      'inspectionType': 'Pre-Trip',
      'inspectionTime': '2026-10-30T07:30:00Z',
      'status': 'Has Defects',
      'hasDefects': true,
      'defectsCount': 2,
      'certified': true,
      'outOfService': false,
      'location': 'Phoenix Terminal, Bay 4',
      'odometer': 142500.0,
      'companyName': 'Golden Feather Transport Inc.',
      'remarks':
          'Left front tire worn; scheduled for replacement at next stop.',
      'defects': [
        {
          'itemCode': 'TIRES',
          'itemName': 'Tires & Wheels',
          'category': 'REGULATORY_MINIMUM',
          'safetyAffecting': true,
          'description': 'Left front steer tire tread below 4/32 inch',
        },
        {
          'itemCode': 'LIGHTS',
          'itemName': 'Headlights / Stop Lights',
          'category': 'REGULATORY_MINIMUM',
          'safetyAffecting': false,
          'description': 'Right marker lamp dim',
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
          'inspectionTime': '2026-10-30T07:30:00Z',
          'status': 'Has Defects',
          'hasDefects': true,
          'defectsCount': 2,
          'certified': true,
          'outOfService': false,
          'defects': [
            {
              'itemCode': 'TIRES',
              'itemName': 'Tires & Wheels',
              'category': 'REGULATORY_MINIMUM',
              'safetyAffecting': true,
              'description': 'Left front steer tire tread below 4/32 inch',
            },
          ],
        },
        {
          'id': 2,
          'uniqueId': '1001',
          'inspectionType': 'Post-Trip',
          'inspectionTime': '2026-10-29T19:15:00Z',
          'status': 'Vehicle Condition Satisfactory',
          'hasDefects': false,
          'defectsCount': 0,
          'certified': true,
          'outOfService': false,
          'defects': const [],
        },
        {
          'id': 3,
          'uniqueId': '1001',
          'inspectionType': 'Pre-Trip',
          'inspectionTime': '2026-10-28T06:00:00Z',
          'status': 'Has Defects',
          'hasDefects': true,
          'defectsCount': 1,
          'certified': false,
          'outOfService': true,
          'defects': const [],
        },
      ],
    });
  }

  @override
  Future<Result<RawJson>> getVehicleDefects(
    String uniqueId, {
    int? deviceId,
  }) async {
    return ok({
      'data': [
        {
          'id': 101,
          'itemCode': 'TIRES',
          'itemName': 'Tires & Wheels',
          'category': 'REGULATORY_MINIMUM',
          'safetyAffecting': true,
          'description': 'Left front steer tire tread below 4/32 inch',
          'stage': 'OPEN',
          'severity': 'HIGH',
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
      final file = File('build/screenshots/$filename');
      await file.writeAsBytes(bytes);

      const artifactDir =
          r'C:\Users\Owner\.gemini\antigravity-ide\brain\5a94c5e4-5889-4e0e-a640-28bea96b9f8a';
      final artDir = Directory(artifactDir);
      if (artDir.existsSync()) {
        await File('$artifactDir/$filename').writeAsBytes(bytes);
      }
    });
  }

  Widget buildHarness({
    required GlobalKey repaintKey,
    required Widget child,
    required ThemeData theme,
    Locale locale = const Locale('en'),
  }) {
    final backend = _ScreenshotDvirBackend();
    return RepaintBoundary(
      key: repaintKey,
      child: ProviderScope(
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          dvirBackendProvider.overrideWithValue(backend),
          localStorageProvider.overrideWithValue(_FakeLocalStorage()),
          networkInfoProvider.overrideWithValue(_OnlineNetwork()),
          trackingConfigStorageProvider.overrideWithValue(
            _FakeTrackingStorage(),
          ),
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
              DvirDefect(
                id: 101,
                itemCode: 'TIRES',
                itemName: 'Tires & Wheels',
                stage: DefectLifecycleStage.open,
                severity: DefectSeverity.high,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: child,
        ),
      ),
    );
  }

  testWidgets('Capture 11 DVIR screens for Phase 4 visual verification', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. New Inspection — Light
    final key1 = GlobalKey();
    await tester.pumpWidget(
      buildHarness(
        repaintKey: key1,
        child: const DvirFormPage(),
        theme: AppTheme.light,
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key1,
      filename: 'dvir_new_inspection_light.png',
    );

    // 2. New Inspection — Dark
    final key2 = GlobalKey();
    await tester.pumpWidget(
      buildHarness(
        repaintKey: key2,
        child: const DvirFormPage(),
        theme: AppTheme.dark,
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key2,
      filename: 'dvir_new_inspection_dark.png',
    );

    // 3. New Inspection — Arabic RTL
    final key3 = GlobalKey();
    await tester.pumpWidget(
      buildHarness(
        repaintKey: key3,
        child: const DvirFormPage(),
        theme: AppTheme.dark,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key3,
      filename: 'dvir_new_inspection_arabic_rtl.png',
    );

    // 4. New Inspection — Spanish LTR
    final key4 = GlobalKey();
    await tester.pumpWidget(
      buildHarness(
        repaintKey: key4,
        child: const DvirFormPage(),
        theme: AppTheme.light,
        locale: const Locale('es'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key4,
      filename: 'dvir_new_inspection_spanish_ltr.png',
    );

    // 5. New Inspection — Validation Errors
    final key5 = GlobalKey();
    await tester.pumpWidget(
      buildHarness(
        repaintKey: key5,
        child: const DvirFormPage(),
        theme: AppTheme.light,
      ),
    );
    await tester.pumpAndSettle();
    // Scroll down to submit button and trigger validation
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    final submitSection = find.byType(DvirSubmitButtonSection);
    final submitBtn = find.descendant(
      of: submitSection,
      matching: find.byType(AppButton),
    );
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();
    // Scroll slightly up so inputs with errors are visible
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key5,
      filename: 'dvir_new_inspection_validation_errors.png',
    );

    // 6. New Inspection — Defects Selected
    const draftWithDefects = DvirReport(
      id: 'draft-101',
      type: InspectionType.preTrip,
      driverName: 'Driver #1001',
      vehicleId: '1001',
      deviceId: 1001,
      trailerId: 'TR-8820',
      odometer: 142500.0,
      notes: 'Brake pads worn, air line slow leak',
      condition: VehicleCondition.needsRepair,
      conditionStatus: DvirConditionStatus.hasDefects,
      isSubmitted: false,
      location: 'Phoenix Terminal, Bay 4',
      companyName: 'Golden Feather Transport Inc.',
      vehicleDefects: 'Service Brakes, Air Lines',
      trailerDefects: 'Tires, Brake Connections',
      hasDefects: true,
      defectsCount: 4,
      certified: false,
      outOfService: false,
    );
    final key6 = GlobalKey();
    await tester.pumpWidget(
      buildHarness(
        repaintKey: key6,
        child: const DvirFormPage(existingReport: draftWithDefects),
        theme: AppTheme.dark,
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key6,
      filename: 'dvir_new_inspection_defects_selected.png',
    );

    // 7. New Inspection — Signature Section
    final key7 = GlobalKey();
    await tester.pumpWidget(
      buildHarness(
        repaintKey: key7,
        child: const DvirFormPage(),
        theme: AppTheme.light,
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key7,
      filename: 'dvir_new_inspection_signature_section.png',
    );

    // 8. DVIR List — Light
    final key8 = GlobalKey();
    await tester.pumpWidget(
      buildHarness(
        repaintKey: key8,
        child: const DvirListPage(),
        theme: AppTheme.light,
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key8,
      filename: 'dvir_list_light.png',
    );

    // 9. DVIR List — Dark
    final key9 = GlobalKey();
    await tester.pumpWidget(
      buildHarness(
        repaintKey: key9,
        child: const DvirListPage(),
        theme: AppTheme.dark,
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key9,
      filename: 'dvir_list_dark.png',
    );

    // 10. DVIR Details — Light
    final key10 = GlobalKey();
    await tester.pumpWidget(
      buildHarness(
        repaintKey: key10,
        child: const DvirDetailPage(dvirId: '1'),
        theme: AppTheme.light,
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key10,
      filename: 'dvir_details_light.png',
    );

    // 11. DVIR Details — Dark
    final key11 = GlobalKey();
    await tester.pumpWidget(
      buildHarness(
        repaintKey: key11,
        child: const DvirDetailPage(dvirId: '1'),
        theme: AppTheme.dark,
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key11,
      filename: 'dvir_details_dark.png',
    );
  });
}
