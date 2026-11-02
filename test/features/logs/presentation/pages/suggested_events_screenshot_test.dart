import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/presentation/pages/suggested_events_page.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/logs_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

class _FakeLogsNotifier extends StateNotifier<LogsState>
    implements LogsNotifier {
  _FakeLogsNotifier(super.state);

  @override
  void selectLog(DailyLog log) {
    state = state.copyWith(selectedLog: log);
  }

  @override
  Future<void> loadLogs({bool refresh = false}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DailyLog _makeLog({
  required int id,
  DateTime? date,
  bool requiresAction = false,
  CertificationStatus certificationStatus = CertificationStatus.certified,
}) {
  return DailyLog(
    id: DailyLogId(id),
    date: date ?? DateTime(2026, 10, 24),
    totalDrivingHours: 4.5,
    isFormComplete: true,
    isCertified: certificationStatus == CertificationStatus.certified,
    requiresAction: requiresAction,
    certificationStatus: certificationStatus,
  );
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

  Widget buildHarness({
    required GlobalKey repaintKey,
    required LogsState state,
    required ThemeData theme,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
  }) {
    final notifier = _FakeLogsNotifier(state);

    return RepaintBoundary(
      key: repaintKey,
      child: ProviderScope(
        overrides: [logsProvider.overrideWith((ref) => notifier)],
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
            home: const SuggestedEventsPage(),
          ),
        ),
      ),
    );
  }

  final sampleLogs = [
    _makeLog(
      id: 101,
      date: DateTime(2026, 10, 24),
      certificationStatus: CertificationStatus.reCertificationRequired,
    ),
    _makeLog(
      id: 102,
      date: DateTime(2026, 10, 23),
      requiresAction: true,
      certificationStatus: CertificationStatus.certified,
    ),
  ];

  // 1. Suggested Events — Arabic Light
  testWidgets('Screenshot 1: Suggested Events — Arabic Light', (tester) async {
    final key = GlobalKey();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        state: LogsState(logs: sampleLogs),
        theme: AppTheme.light,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'suggested_events_arabic_light.png',
    );
  });

  // 2. Suggested Events — Arabic Dark
  testWidgets('Screenshot 2: Suggested Events — Arabic Dark', (tester) async {
    final key = GlobalKey();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        state: LogsState(logs: sampleLogs),
        theme: AppTheme.dark,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'suggested_events_arabic_dark.png',
    );
  });

  // 3. Suggested Events — English Light
  testWidgets('Screenshot 3: Suggested Events — English Light', (
    tester,
  ) async {
    final key = GlobalKey();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        state: LogsState(logs: sampleLogs),
        theme: AppTheme.light,
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'suggested_events_english_light.png',
    );
  });

  // 4. Suggested Events — Spanish Light
  testWidgets('Screenshot 4: Suggested Events — Spanish Light', (
    tester,
  ) async {
    final key = GlobalKey();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        state: LogsState(logs: sampleLogs),
        theme: AppTheme.light,
        locale: const Locale('es'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'suggested_events_spanish_light.png',
    );
  });

  // 5. Recertification Required (Contextual Warning Active)
  testWidgets('Screenshot 5: Recertification Required', (tester) async {
    final key = GlobalKey();
    final recertLogs = [
      _makeLog(
        id: 201,
        date: DateTime(2026, 10, 25),
        certificationStatus: CertificationStatus.reCertificationRequired,
      ),
    ];
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        state: LogsState(logs: recertLogs),
        theme: AppTheme.light,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'suggested_events_recertification_required.png',
    );
  });

  // 6. No Recertification Required (Carrier Edits Only)
  testWidgets('Screenshot 6: No Recertification Required', (tester) async {
    final key = GlobalKey();
    final editOnlyLogs = [
      _makeLog(
        id: 301,
        date: DateTime(2026, 10, 24),
        requiresAction: true,
        certificationStatus: CertificationStatus.certified,
      ),
    ];
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        state: LogsState(logs: editOnlyLogs),
        theme: AppTheme.light,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'suggested_events_no_recertification_required.png',
    );
  });

  // 7. Multiple Suggested Events
  testWidgets('Screenshot 7: Multiple Suggested Events', (tester) async {
    final key = GlobalKey();
    final manyLogs = [
      _makeLog(
        id: 401,
        date: DateTime(2026, 10, 25),
        certificationStatus: CertificationStatus.reCertificationRequired,
      ),
      _makeLog(
        id: 402,
        date: DateTime(2026, 10, 24),
        requiresAction: true,
        certificationStatus: CertificationStatus.certified,
      ),
      _makeLog(
        id: 403,
        date: DateTime(2026, 10, 22),
        requiresAction: true,
        certificationStatus: CertificationStatus.reCertificationRequired,
      ),
      _makeLog(
        id: 404,
        date: DateTime(2026, 10, 20),
        requiresAction: true,
        certificationStatus: CertificationStatus.certified,
      ),
    ];
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        state: LogsState(logs: manyLogs),
        theme: AppTheme.light,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'suggested_events_multiple_events.png',
    );
  });

  // 8. Empty State
  testWidgets('Screenshot 8: Empty State', (tester) async {
    final key = GlobalKey();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        state: const LogsState(logs: []),
        theme: AppTheme.light,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'suggested_events_empty_state.png',
    );
  });

  // 9. Loading State
  testWidgets('Screenshot 9: Loading State', (tester) async {
    final key = GlobalKey();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        state: const LogsState(isLoading: true, logs: []),
        theme: AppTheme.light,
        locale: const Locale('ar'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'suggested_events_loading_state.png',
    );
  });

  // 10. Error State
  testWidgets('Screenshot 10: Error State', (tester) async {
    final key = GlobalKey();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        state: const LogsState(
          error:
              'تعذر الاتصال بالخادم. يرجى التحقق من اتصال الشبكة وإعادة المحاولة.',
          logs: [],
        ),
        theme: AppTheme.light,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'suggested_events_error_state.png',
    );
  });

  // 11. 320dp Width (Compact Screen)
  testWidgets('Screenshot 11: 320dp Width', (tester) async {
    final key = GlobalKey();
    tester.view.physicalSize = const Size(640, 1400); // 320 x 700 at 2.0 DPR
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        state: LogsState(logs: sampleLogs),
        theme: AppTheme.light,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'suggested_events_320dp.png',
    );
  });

  // 12. 2.0x Text Scaling (Accessibility)
  testWidgets('Screenshot 12: 2.0x Text Scaling', (tester) async {
    final key = GlobalKey();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key,
        state: LogsState(logs: sampleLogs),
        theme: AppTheme.light,
        locale: const Locale('ar'),
        textScale: 2.0,
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(
      tester: tester,
      key: key,
      filename: 'suggested_events_2_0x_text_scale.png',
    );
  });
}
