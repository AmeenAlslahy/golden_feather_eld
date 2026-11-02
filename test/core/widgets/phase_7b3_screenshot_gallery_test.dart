import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/design_system.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

void main() {
  const artifactDir = r'C:\Users\Owner\.gemini\antigravity-ide\brain\5a94c5e4-5889-4e0e-a640-28bea96b9f8a';

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
      final arialFile = File(r'C:\Windows\Fonts\arial.ttf');
      if (arialFile.existsSync()) {
        robotoLoader.addFont(Future.value(ByteData.view(arialFile.readAsBytesSync().buffer)));
      }
      final arialBd = File(r'C:\Windows\Fonts\arialbd.ttf');
      if (arialBd.existsSync()) {
        robotoLoader.addFont(Future.value(ByteData.view(arialBd.readAsBytesSync().buffer)));
      }
      await robotoLoader.load();
    } catch (_) {}

    try {
      final arialFile = File(r'C:\Windows\Fonts\arial.ttf');
      if (arialFile.existsSync()) {
        final arialLoader = FontLoader('Arial');
        arialLoader.addFont(Future.value(ByteData.view(arialFile.readAsBytesSync().buffer)));
        await arialLoader.load();
      }
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

  Future<void> saveScreenshot({
    required WidgetTester tester,
    required GlobalKey key,
    required String filename,
  }) async {
    await tester.binding.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Save to build/screenshots/phase_7b3/
      final outDir = Directory('build/screenshots/phase_7b3');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      final file = File('build/screenshots/phase_7b3/$filename');
      await file.writeAsBytes(bytes);

      // Also copy to brain artifact directory for markdown embedding
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
    double screenWidth = 375,
    double screenHeight = 1900,
    double textScale = 1.0,
    Locale locale = const Locale('en'),
    TextDirection textDirection = TextDirection.ltr,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final effectiveTheme = theme.copyWith(
      textTheme: theme.textTheme.apply(
        fontFamily: 'Arial',
        fontFamilyFallback: const ['Roboto', 'Arial'],
      ),
    );

    return RepaintBoundary(
      key: repaintKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: effectiveTheme,
        darkTheme: AppTheme.dark.copyWith(
          textTheme: AppTheme.dark.textTheme.apply(
            fontFamily: 'Arial',
            fontFamilyFallback: const ['Roboto', 'Arial'],
          ),
        ),
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: Directionality(
          textDirection: textDirection,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(screenWidth, screenHeight),
              textScaler: TextScaler.linear(textScale),
            ),
            child: Scaffold(
              body: SizedBox(
                width: screenWidth,
                height: screenHeight,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFullGalleryView({
    required BuildContext context,
    required bool isArabic,
    required GoldenAppBarVariant appBarVariant,
  }) {
    final buttonPrimary = isArabic ? 'زر أساسي مفعّل' : 'Primary Action';
    final buttonDisabled = isArabic ? 'زر معطّل' : 'Disabled Action';
    final buttonLoading = isArabic ? 'جاري التحميل...' : 'Loading Action';
    final buttonSecondary = isArabic ? 'زر ثانوي مؤطر' : 'Secondary Outlined';
    final buttonDestructive = isArabic ? 'حذف السجل (حرج)' : 'Delete Record';
    final buttonSuccess = isArabic ? 'اعتماد الفحص (ناجح)' : 'Certify Inspection';

    final fieldNormal = isArabic ? 'اسم السائق' : 'Driver Name';
    final fieldHint = isArabic ? 'أدخل الاسم الثلاثي' : 'Enter full legal name';
    final fieldError = isArabic ? 'قراءة عداد المسافات' : 'Odometer Reading';
    final fieldErrorMessage = isArabic ? 'القيمة لا يمكن أن تقل عن السابقة' : 'Value cannot decrease';
    final fieldMultiline = isArabic ? 'ملاحظات فحص المركبة' : 'Vehicle Inspection Notes';
    final fieldMultilineVal = isArabic
        ? 'تم فحص المكابح، ومستوى الزيت ضمن الحدود المسموح بها، وضغط الإطارات مطابق للمواصفات.'
        : 'Checked service brakes, coupling equipment, tires, horn, and emergency equipment.';

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── 1. Header ──
        GoldenAppBar(
          titleText: isArabic ? 'معرض المكونات المشتركة' : 'Design System 2.0 Gallery',
          variant: appBarVariant,
        ),
        const SizedBox(height: AppSpacing.md),

        // ── 2. AppButton Section ──
        AppSection(
          title: isArabic ? 'حالات الأزرار' : 'AppButton States',
          subtitle: isArabic ? 'الأنماط والحالات التفاعلية' : 'Role variants and interaction states',
          child: Column(
            children: [
              AppButton.primary(label: buttonPrimary, onPressed: () {}),
              const SizedBox(height: AppSpacing.xs),
              AppButton.primary(label: buttonDisabled, onPressed: null),
              const SizedBox(height: AppSpacing.xs),
              AppButton.primary(label: buttonLoading, isLoading: true, onPressed: () {}),
              const SizedBox(height: AppSpacing.xs),
              AppButton.secondary(label: buttonSecondary, onPressed: () {}),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: AppButton.destructive(
                      label: buttonDestructive,
                      isCompact: true,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: AppButton.success(
                      label: buttonSuccess,
                      isCompact: true,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── 3. AppTextField Section ──
        AppSection(
          title: isArabic ? 'حقول الإدخال' : 'AppTextField States',
          child: Column(
            children: [
              AppTextField(
                label: fieldNormal,
                hint: fieldHint,
                controller: TextEditingController(text: isArabic ? 'أحمد محمد' : 'John Doe'),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: fieldError,
                controller: TextEditingController(text: '94,200 mi'),
                errorText: fieldErrorMessage,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: isArabic ? 'رمز الشركة DOT (معطل)' : 'Carrier DOT (Disabled)',
                controller: TextEditingController(text: 'USDOT #3910294'),
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: fieldMultiline,
                controller: TextEditingController(text: fieldMultilineVal),
                maxLines: 3,
              ),
            ],
          ),
        ),

        // ── 4. EldCard & AppKeyValueRow Section ──
        AppSection(
          title: isArabic ? 'البطاقات القياسية والمدمجة' : 'EldCard & Key-Value Rows',
          child: Column(
            children: [
              EldCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'بيانات الشاحنة' : 'Assigned Vehicle',
                      style: context.styles.cardTitle,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppKeyValueRow(
                      label: isArabic ? 'رقم الشاحنة' : 'Truck Unit',
                      value: 'Freightliner #1042',
                    ),
                    const Divider(),
                    AppKeyValueRow(
                      label: isArabic ? 'رقم لوحة المركبة' : 'License Plate',
                      value: 'TX-9842-ELD',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              EldCard.compact(
                child: AppKeyValueRow.compact(
                  label: isArabic ? 'ساعات القيادة المتبقية' : 'Driving Remaining',
                  value: '07:42 hrs',
                ),
              ),
            ],
          ),
        ),

        // ── 5. AppSelectionTile Section ──
        AppSection(
          title: isArabic ? 'بطاقات التحديد' : 'AppSelectionTile States',
          child: Column(
            children: [
              AppSelectionTile(
                title: isArabic ? 'شاحنة النقل الرئيسية' : 'Primary Sleeper Cab',
                subtitle: 'VIN: 1FUJGLDR9CL984102',
                selected: true,
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.xs),
              AppSelectionTile(
                title: isArabic ? 'شاحنة احتياطية (معطلة)' : 'Backup Unit (Out of Service)',
                subtitle: isArabic ? 'غير مصرح للقيادة' : 'Not permitted for driving',
                enabled: false,
                onTap: () {},
              ),
            ],
          ),
        ),

        // ── 6. AppStatusBadge & AppStatusPill Section ──
        AppSection(
          title: isArabic ? 'الشارات الدلالية' : 'Badges & Status Pills',
          child: const Column(
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  AppStatusBadge(label: 'On Duty', type: AppStatusBadgeType.success),
                  AppStatusBadge(label: 'Violation', type: AppStatusBadgeType.error),
                  AppStatusBadge(label: 'Warning', type: AppStatusBadgeType.warning),
                  AppStatusBadge(label: 'Info State', type: AppStatusBadgeType.info),
                  AppStatusBadge(label: 'Off Duty', type: AppStatusBadgeType.neutral),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  AppStatusPill.success(label: 'Connected'),
                  AppStatusPill.error(label: 'Disconnected'),
                  AppStatusPill.warning(label: 'Sync Pending'),
                  AppStatusPill.info(label: 'GPS Active'),
                  AppStatusPill.neutral(label: 'Standby'),
                ],
              ),
            ],
          ),
        ),

        // ── 7. AppLoadingState & EldRetryView Section ──
        AppSection(
          title: isArabic ? 'حالات التحميل والخطأ والفراغ' : 'Loading, Error & Empty Views',
          child: Column(
            children: [
              const AppLoadingState(
                message: 'Connecting to ELD device...',
                isCompact: true,
              ),
              const SizedBox(height: AppSpacing.xs),
              EldRetryView.error(
                message: isArabic ? 'تعذر الاتصال ببروتوكول البلوتوث' : 'Bluetooth handshake failed',
                onRetry: () {},
              ),
              const SizedBox(height: AppSpacing.xs),
              EldRetryView.empty(
                title: isArabic ? 'لا توجد أحداث غير محددة' : 'No Unidentified Events',
                message: isArabic ? 'جميع السجلات مقترنة بالسائق الحالي' : 'All logs are assigned to active driver',
              ),
            ],
          ),
        ),
      ],
    );
  }

  testWidgets('Phase 7B.3 — Generate Visual Evidence Screenshots', (tester) async {
    // 1. Light Mode Gallery, English, 375dp, 1.0x
    final key1 = GlobalKey();
    tester.view.physicalSize = const Size(375 * 2.0, 2050 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHarness(
        repaintKey: key1,
        screenWidth: 375,
        screenHeight: 2050,
        textScale: 1.0,
        theme: AppTheme.light,
        locale: const Locale('en'),
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) => buildFullGalleryView(
            context: context,
            isArabic: false,
            appBarVariant: GoldenAppBarVariant.brand,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await saveScreenshot(tester: tester, key: key1, filename: 'gallery_light_en_375.png');

    // 2. Dark Mode Gallery, Arabic RTL, 375dp, 1.0x
    final key2 = GlobalKey();
    await tester.pumpWidget(
      buildHarness(
        repaintKey: key2,
        screenWidth: 375,
        screenHeight: 2050,
        textScale: 1.0,
        theme: AppTheme.dark,
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        child: Builder(
          builder: (context) => buildFullGalleryView(
            context: context,
            isArabic: true,
            appBarVariant: GoldenAppBarVariant.standard,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await saveScreenshot(tester: tester, key: key2, filename: 'gallery_dark_ar_375.png');

    // 3. Narrow Arabic RTL, 320dp, 1.0x
    final key3 = GlobalKey();
    tester.view.physicalSize = const Size(320 * 2.0, 2150 * 2.0);
    await tester.pumpWidget(
      buildHarness(
        repaintKey: key3,
        screenWidth: 320,
        screenHeight: 2150,
        textScale: 1.0,
        theme: AppTheme.light,
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        child: Builder(
          builder: (context) => buildFullGalleryView(
            context: context,
            isArabic: true,
            appBarVariant: GoldenAppBarVariant.brand,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await saveScreenshot(tester: tester, key: key3, filename: 'gallery_narrow_ar_320.png');

    // 4. Large Text Scale 2.0x, 375dp
    final key4 = GlobalKey();
    tester.view.physicalSize = const Size(375 * 2.0, 3100 * 2.0);
    await tester.pumpWidget(
      buildHarness(
        repaintKey: key4,
        screenWidth: 375,
        screenHeight: 3100,
        textScale: 2.0,
        theme: AppTheme.light,
        locale: const Locale('en'),
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) => buildFullGalleryView(
            context: context,
            isArabic: false,
            appBarVariant: GoldenAppBarVariant.brand,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await saveScreenshot(tester: tester, key: key4, filename: 'gallery_large_text_2x.png');

    // 5. AppDialog Normal Text Scale (1.0x)
    final key5 = GlobalKey();
    tester.view.physicalSize = const Size(375 * 2.0, 450 * 2.0);
    await tester.pumpWidget(
      buildHarness(
        repaintKey: key5,
        screenWidth: 375,
        screenHeight: 450,
        textScale: 1.0,
        theme: AppTheme.light,
        locale: const Locale('en'),
        textDirection: TextDirection.ltr,
        child: Center(
          child: AppDialog.confirmation(
            title: 'Confirm Duty Status Change',
            contentText: 'Are you sure you want to transition to ON DUTY driving status?',
            primaryActionLabel: 'Confirm Change',
            secondaryActionLabel: 'Cancel',
            onPrimaryAction: () {},
            onSecondaryAction: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await saveScreenshot(tester: tester, key: key5, filename: 'dialog_normal_text.png');

    // 6. AppDialog Large Text Scale (2.0x)
    final key6 = GlobalKey();
    tester.view.physicalSize = const Size(375 * 2.0, 700 * 2.0);
    await tester.pumpWidget(
      buildHarness(
        repaintKey: key6,
        screenWidth: 375,
        screenHeight: 700,
        textScale: 2.0,
        theme: AppTheme.light,
        locale: const Locale('en'),
        textDirection: TextDirection.ltr,
        child: Center(
          child: AppDialog.confirmation(
            title: 'Confirm Duty Status Change',
            contentText: 'Are you sure you want to transition to ON DUTY driving status?',
            primaryActionLabel: 'Confirm Change',
            secondaryActionLabel: 'Cancel',
            onPrimaryAction: () {},
            onSecondaryAction: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await saveScreenshot(tester: tester, key: key6, filename: 'dialog_large_text_2x.png');
  });
}
