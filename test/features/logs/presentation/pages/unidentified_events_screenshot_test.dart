import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/backend/contracts/contract_enums.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/backend/contracts/unidentified_events_backend.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/logs/data/repositories/log_repository_impl.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log_page.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/pages/unidentified_events_page.dart';
import 'package:golden_feather_eld/features/logs/presentation/widgets/annotation_dialog.dart';
import 'package:golden_feather_eld/features/vehicle/data/providers/vehicle_repository_providers.dart';
import 'package:golden_feather_eld/features/vehicle/domain/entities/vehicle.dart';
import 'package:golden_feather_eld/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _Logs extends Mock implements LogRepository {}
class _Vehicles extends Mock implements VehicleRepository {}

class _AuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _AuthNotifier(super.state);
  @override
  Future<bool> login({
    required String username,
    required String password,
    String? serverUrl,
  }) async => true;
  @override
  void forceLogout() {}
  @override
  Future<void> logout() async {}
  @override
  Future<void> checkAuthStatus() async {}
  @override
  void clearError() {}
}

class _ScreenshotBackend implements UnidentifiedEventsBackend {
  List<Map<String, dynamic>> rows;
  List<Map<String, dynamic>> rejectedRows;
  AppError? listError;
  Completer<Result<RawJson>>? loadingCompleter;

  _ScreenshotBackend({
    required this.rows,
    List<Map<String, dynamic>>? rejectedRows,
    this.listError,
    this.loadingCompleter,
  }) : rejectedRows = rejectedRows ?? [];

  @override
  Future<Result<RawJson>> list({
    UnidentifiedTab tab = UnidentifiedTab.unclaimed,
    int page = 0,
    int size = 20,
    String sortBy = 'id',
    String sortDirection = 'ASC',
    List<UnidentifiedEventFilter> filters = const [],
  }) async {
    if (loadingCompleter != null) {
      return loadingCompleter!.future;
    }
    if (listError != null) return err(listError!);
    return ok({
      'items': tab == UnidentifiedTab.unclaimed ? rows : rejectedRows,
    });
  }

  @override
  Future<Result<RawJson>> getById({required DutyStatusId id}) async {
    final row = [...rows, ...rejectedRows].firstWhere((r) => r['id'] == id.value);
    return ok(row);
  }

  @override
  Future<Result<RawJson>> summary() async {
    if (listError != null) return err(listError!);
    final all = [...rows, ...rejectedRows];
    final pending = all.where((r) => r['pendingOver8Days'] == true).length;
    return ok({
      'totalUnclaimed': rows.length,
      'totalRejected': rejectedRows.length,
      'pendingOver8DaysCount': pending,
      'complianceAlertActive': pending > 0,
    });
  }

  @override
  Future<Result<void>> claim({
    required DutyStatusId id,
    DriverId? driverId,
    required String annotation,
  }) async => ok(null);

  @override
  Future<Result<void>> reject({
    required DutyStatusId id,
    DriverId? driverId,
    required String rejectionReason,
  }) async => ok(null);
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
        robotoLoader.addFont(Future.value(ByteData.view(regularFile.readAsBytesSync().buffer)));
      }
      final mediumFile = File('assets/fonts/google_fonts/Roboto-Medium.ttf');
      if (mediumFile.existsSync()) {
        robotoLoader.addFont(Future.value(ByteData.view(mediumFile.readAsBytesSync().buffer)));
      }
      final boldFile = File('assets/fonts/google_fonts/Roboto-Bold.ttf');
      if (boldFile.existsSync()) {
        robotoLoader.addFont(Future.value(ByteData.view(boldFile.readAsBytesSync().buffer)));
      }
      await robotoLoader.load();
    } catch (_) {}

    try {
      final iconFile = File(r'D:\Flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf');
      if (iconFile.existsSync()) {
        final iconLoader = FontLoader('MaterialIcons');
        iconLoader.addFont(Future.value(ByteData.view(iconFile.readAsBytesSync().buffer)));
        await iconLoader.load();
      }
    } catch (_) {}
  });

  final now = DateTime.now().toUtc();
  String iso(Duration ago) => now.subtract(ago).toIso8601String();

  List<Map<String, dynamic>> makeNormalRows() => [
    {
      'id': 501,
      'deviceId': 4,
      'vehicleName': 'Freightliner 101',
      'vehicleVin': '1M8GDM9A_TRK_01',
      'startTime': iso(const Duration(hours: 3)),
      'endTime': iso(const Duration(hours: 2, minutes: 15)),
      'durationMinutes': 45,
      'durationFormatted': '45m',
      'latitude': 34.0522,
      'longitude': -118.2437,
      'locationDescription': 'I-80 Mile 142, Salt Lake City, UT',
      'odometerMiles': 124500.5,
      'engineHours': 3240.2,
      'status': 'UNCLAIMED',
      'allocationType': 'UNASSIGNED',
      'annotation': 'Terminal yard repositioning',
      'pendingOver8Days': false,
    },
    {
      'id': 502,
      'deviceId': 5,
      'vehicleName': 'Volvo VNL 760',
      'vehicleVin': '4V4NC9EH_TRK_02',
      'startTime': iso(const Duration(days: 9)),
      'endTime': iso(const Duration(days: 9, hours: -1)),
      'durationMinutes': 60,
      'durationFormatted': '1h 00m',
      'latitude': 33.4484,
      'longitude': -112.0740,
      'locationDescription': 'Phoenix Logistics Hub, Bay 12',
      'odometerMiles': 89430.0,
      'engineHours': 2105.8,
      'status': 'UNCLAIMED',
      'allocationType': 'UNASSIGNED',
      'annotation': '',
      'pendingOver8Days': true,
    },
    {
      'id': 503,
      'deviceId': 4,
      'vehicleName': 'Kenworth T680',
      'vehicleVin': '1NKDX4EX_TRK_03',
      'startTime': iso(const Duration(hours: 28)),
      'endTime': iso(const Duration(hours: 27)),
      'durationMinutes': 60,
      'durationFormatted': '1h 00m',
      'latitude': 39.7392,
      'longitude': -104.9903,
      'locationDescription': 'Denver Distribution Center, Gate 3',
      'odometerMiles': 215400.2,
      'engineHours': 5420.0,
      'status': 'UNCLAIMED',
      'allocationType': 'UNASSIGNED',
      'annotation': '',
      'pendingOver8Days': false,
    },
  ];

  Future<void> captureScreen({
    required WidgetTester tester,
    required GlobalKey key,
    required String filename,
  }) async {
    await tester.binding.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final outDir = Directory('build/screenshots');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      final file = File('build/screenshots/$filename');
      await file.writeAsBytes(bytes);

      const artifactDir = r'C:\Users\Owner\.gemini\antigravity-ide\brain\5a94c5e4-5889-4e0e-a640-28bea96b9f8a';
      final artDir = Directory(artifactDir);
      if (artDir.existsSync()) {
        await File('$artifactDir/$filename').writeAsBytes(bytes);
      }
    });
  }

  Widget buildHarness({
    required GlobalKey repaintKey,
    required _ScreenshotBackend backend,
    required ThemeData theme,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    Widget? homeWidget,
  }) {
    final logs = _Logs();
    final vehicles = _Vehicles();
    const truck = Vehicle(
      id: 'TRK-1',
      uniqueId: 'imei-1',
      deviceId: 4,
      name: 'Freightliner 101',
      year: '2024',
      vin: '1M8GDM9A_TRK_01',
      isAssigned: true,
      activeForCurrentDriver: true,
    );
    when(() => logs.getDailyLogs(
      driverId: any(named: 'driverId'),
      page: any(named: 'page'),
      size: any(named: 'size'),
    )).thenAnswer((_) async => const Right(DailyLogPage.empty));
    when(() => vehicles.getSelectedVehicle()).thenAnswer((_) async => const Right(truck));
    when(() => vehicles.getVehicles()).thenAnswer((_) async => const Right([truck]));

    return RepaintBoundary(
      key: repaintKey,
      child: ProviderScope(
        overrides: [
          unidentifiedEventsBackendProvider.overrideWithValue(backend),
          currentDriverIdProvider.overrideWithValue(106),
          authStateProvider.overrideWith(
            (ref) => _AuthNotifier(
              AuthState(
                status: AuthStatus.authenticated,
                user: User(
                  id: '106',
                  username: 'driver106',
                  email: 'driver@eld.com',
                  fullName: 'Driver 106',
                  role: UserRole.fieldWorker,
                  createdAt: DateTime(2026),
                ),
              ),
            ),
          ),
          logRepositoryProvider.overrideWithValue(logs),
          vehicleRepositoryProvider.overrideWithValue(vehicles),
        ],
        child: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScale),
            size: const Size(390, 844),
          ),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: homeWidget ?? const UnidentifiedEventsPage(),
          ),
        ),
      ),
    );
  }

  // 1. Arabic Light — Multiple Events
  testWidgets('Screenshot 1: Arabic Light — Multiple Events', (tester) async {
    final key = GlobalKey();
    final backend = _ScreenshotBackend(rows: makeNormalRows());
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        backend: backend,
        theme: AppTheme.light,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'unidentified_events_arabic_light_multiple.png',
    );
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'unidentified_events_arabic_light.png',
    );
  });

  // 2. Arabic Dark — Multiple Events
  testWidgets('Screenshot 2: Arabic Dark — Multiple Events', (tester) async {
    final key = GlobalKey();
    final backend = _ScreenshotBackend(rows: makeNormalRows());
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        backend: backend,
        theme: AppTheme.dark,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'unidentified_events_arabic_dark_multiple.png',
    );
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'unidentified_events_arabic_dark.png',
    );
  });

  // 3. Long Vehicle Name (wrap up to 2 lines, numbers visible)
  testWidgets('Screenshot 3: Long Vehicle Name', (tester) async {
    final key = GlobalKey();
    final rows = [
      {
        'id': 701,
        'deviceId': 4,
        'vehicleName':
            'Heavy Duty Freightliner Cascadia 2026 Fleet Special Edition #9988-X',
        'vehicleVin': '1M8GDM9A_TRK_01',
        'startTime': iso(const Duration(hours: 3)),
        'endTime': iso(const Duration(hours: 1)),
        'durationMinutes': 120,
        'durationFormatted': '2h 00m',
        'locationDescription':
            'Interstate 80 Eastbound Milepost 284, Near Continental Divide Rest Stop, Wyoming',
        'odometerMiles': 152840.5,
        'engineHours': 4150.2,
        'status': 'UNCLAIMED',
        'allocationType': 'UNASSIGNED',
        'annotation':
            'Highway speed transit without authenticated driver token detected',
        'pendingOver8Days': false,
      },
    ];
    final backend = _ScreenshotBackend(rows: rows);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        backend: backend,
        theme: AppTheme.light,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'unidentified_events_long_vehicle_name.png',
    );
  });

  // 4. Full VIN (Dedicated LTR full-width row, monospace font)
  testWidgets('Screenshot 4: Full VIN', (tester) async {
    final key = GlobalKey();
    final rows = [
      {
        'id': 801,
        'deviceId': 9,
        'vehicleName': 'Freightliner Cascadia 126',
        'vehicleVin': '1FT8W3BT9NEC12345',
        'startTime': iso(const Duration(hours: 5)),
        'endTime': iso(const Duration(hours: 4)),
        'durationMinutes': 60,
        'durationFormatted': '1h 00m',
        'locationDescription': 'Chicago Yard Bay 4, IL',
        'odometerMiles': 78940.0,
        'engineHours': 1890.0,
        'status': 'UNCLAIMED',
        'allocationType': 'UNASSIGNED',
        'pendingOver8Days': false,
      },
    ];
    final backend = _ScreenshotBackend(rows: rows);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        backend: backend,
        theme: AppTheme.light,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'unidentified_events_full_vin.png',
    );
  });

  // 5. Time Range (Separate Date, LTR Time Range, Isolated Timezone Chip, Duration Chip)
  testWidgets('Screenshot 5: Time Range', (tester) async {
    final key = GlobalKey();
    final rows = [
      {
        'id': 501,
        'deviceId': 4,
        'vehicleName': 'Peterbilt 579',
        'vehicleVin': '1XP4D49X5KD123456',
        'startTime': '2026-10-30T09:05:00Z',
        'endTime': '2026-10-30T10:45:00Z',
        'durationMinutes': 100,
        'durationFormatted': '1h 40m',
        'locationDescription': 'Salt Lake City Hub, UT',
        'odometerMiles': 145200.0,
        'engineHours': 3820.5,
        'status': 'UNCLAIMED',
        'allocationType': 'UNASSIGNED',
        'pendingOver8Days': false,
      },
    ];
    final backend = _ScreenshotBackend(rows: rows);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        backend: backend,
        theme: AppTheme.light,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'unidentified_events_time_range.png',
    );
  });

  // 6. Event Crossing Midnight (Start Date → End Date)
  testWidgets('Screenshot 6: Event Crossing Midnight', (tester) async {
    final key = GlobalKey();
    final rows = [
      {
        'id': 601,
        'deviceId': 7,
        'vehicleName': 'Volvo VNL 860',
        'vehicleVin': '4V4NC9EH7KN234567',
        'startTime': '2026-10-30T22:30:00Z',
        'endTime': '2026-10-31T03:15:00Z',
        'durationMinutes': 285,
        'durationFormatted': '4h 45m',
        'locationDescription': 'Overnight Cross-Border Corridor, El Paso, TX',
        'odometerMiles': 198420.0,
        'engineHours': 4910.0,
        'status': 'UNCLAIMED',
        'allocationType': 'UNASSIGNED',
        'annotation': 'Shift handover during midnight border transit',
        'pendingOver8Days': false,
      },
    ];
    final backend = _ScreenshotBackend(rows: rows);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        backend: backend,
        theme: AppTheme.light,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'unidentified_events_midnight_crossing.png',
    );
  });

  // 7. 320dp Width (Compact Screen Layout)
  testWidgets('Screenshot 7: 320dp Width', (tester) async {
    final key = GlobalKey();
    final backend = _ScreenshotBackend(rows: makeNormalRows());
    tester.view.physicalSize = const Size(640, 1400); // 320 x 700 at 2.0 ratio
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        backend: backend,
        theme: AppTheme.light,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'unidentified_events_320dp.png',
    );
  });

  // 8. 2.0x Text Scaling (Accessibility)
  testWidgets('Screenshot 8: 2.0x Text Scaling', (tester) async {
    final key = GlobalKey();
    final backend = _ScreenshotBackend(rows: makeNormalRows());
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        backend: backend,
        theme: AppTheme.light,
        locale: const Locale('ar'),
        textScale: 2.0,
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'unidentified_events_2_0x_text_scale.png',
    );
  });

  // 9. Summary Grid (2×2 Responsive Statistics Grid)
  testWidgets('Screenshot 9: Summary Grid', (tester) async {
    final key = GlobalKey();
    final backend = _ScreenshotBackend(rows: makeNormalRows());
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        backend: backend,
        theme: AppTheme.light,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'unidentified_events_summary_grid.png',
    );
  });

  // 10. Claim/Reject Actions
  testWidgets('Screenshot 10: Claim/Reject Actions', (tester) async {
    final key = GlobalKey();
    final backend = _ScreenshotBackend(rows: makeNormalRows());
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        backend: backend,
        theme: AppTheme.light,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'unidentified_events_claim_reject_actions.png',
    );
  });

  // Supporting: English Light
  testWidgets('Screenshot: English Light', (tester) async {
    final key = GlobalKey();
    final backend = _ScreenshotBackend(rows: makeNormalRows());
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        backend: backend,
        theme: AppTheme.light,
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'unidentified_events_english_light.png',
    );
  });

  // Supporting: Spanish Light
  testWidgets('Screenshot: Spanish Light', (tester) async {
    final key = GlobalKey();
    final backend = _ScreenshotBackend(rows: makeNormalRows());
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        backend: backend,
        theme: AppTheme.light,
        locale: const Locale('es'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'unidentified_events_spanish_light.png',
    );
  });

  // Supporting: Empty State
  testWidgets('Screenshot: Empty State', (tester) async {
    final key = GlobalKey();
    final backend = _ScreenshotBackend(rows: const []);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        backend: backend,
        theme: AppTheme.light,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'unidentified_events_empty_state.png',
    );
  });

  // Supporting: Loading State
  testWidgets('Screenshot: Loading State', (tester) async {
    final key = GlobalKey();
    final completer = Completer<Result<RawJson>>();
    final backend = _ScreenshotBackend(
      rows: const [],
      loadingCompleter: completer,
    );
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        backend: backend,
        theme: AppTheme.light,
        locale: const Locale('ar'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'unidentified_events_loading_state.png',
    );
    completer.complete(ok({'items': []}));
    await tester.pumpAndSettle();
  });

  // Supporting: Error State
  testWidgets('Screenshot: Error State', (tester) async {
    final key = GlobalKey();
    final backend = _ScreenshotBackend(
      rows: const [],
      listError: const ServerError(
        code: 'UNIDENTIFIED_EVENTS_FETCH_FAILED',
        l10nKey: 'unidentifiedEventsFetchFailed',
        context: {
          'message':
              'Network connection timed out while querying unassigned events from server.',
        },
      ),
    );
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        backend: backend,
        theme: AppTheme.light,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'unidentified_events_error_state.png',
    );
  });

  // Supporting: Annotation Dialog
  testWidgets('Screenshot: Annotation Dialog', (tester) async {
    final key = GlobalKey();
    final backend = _ScreenshotBackend(rows: makeNormalRows());
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        backend: backend,
        theme: AppTheme.light,
        locale: const Locale('ar'),
        homeWidget: const Scaffold(
          body: Center(
            child: AnnotationDialog(
              title: 'تأكيد قيادة المركبة',
              hint: 'الملاحظة مطلوبة لتسجيل الحدث كوقت قيادة.',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'unidentified_events_annotation_dialog.png',
    );
  });
}

