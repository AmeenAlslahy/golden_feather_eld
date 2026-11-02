import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_dvir_backend.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/design_system.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/services/tracking_config_storage_service.dart';
import 'package:golden_feather_eld/features/dvir/presentation/pages/dvir_form_page.dart';
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

/// Development-only Component Showcase View
class ComponentShowcaseView extends StatelessWidget {
  const ComponentShowcaseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GoldenAppBar(
        titleText: 'Design System 2.0 Showcase',
        variant: GoldenAppBarVariant.brand,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Section: Buttons
          Text('BUTTON STATES', style: context.styles.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          AppButton.primary(
            label: 'Primary Enabled',
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.xs),
          const AppButton.primary(
            label: 'Primary Disabled',
            onPressed: null,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton.primary(
            label: 'Primary Loading',
            isLoading: true,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton.secondary(
            label: 'Secondary Outlined',
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton.tertiary(
            label: 'Tertiary Subtle',
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: AppButton.destructive(
                  label: 'Destructive',
                  isCompact: true,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton.success(
                  label: 'Success',
                  isCompact: true,
                  onPressed: () {},
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          // Section: Input Fields
          Text('INPUT FIELD STATES', style: context.styles.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          const AppTextField(
            label: 'Normal Field',
            hint: 'Enter vehicle number',
          ),
          const SizedBox(height: AppSpacing.sm),
          const AppTextField(
            label: 'Required Field',
            hint: 'Mandatory field value',
            isRequired: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          const AppTextField(
            label: 'Error Field',
            hint: 'Invalid entry',
            errorText: 'Value must not be negative',
          ),
          const SizedBox(height: AppSpacing.sm),
          const AppTextField(
            label: 'Disabled Field',
            hint: 'Non-editable system parameter',
            enabled: false,
          ),
          const SizedBox(height: AppSpacing.sm),
          const AppTextField(
            label: 'Read-only Field',
            hint: 'Carrier DOT #482910',
            readOnly: true,
          ),

          const SizedBox(height: AppSpacing.lg),
          // Section: Badges & Pills
          Text('BADGES & STATUS PILLS', style: context.styles.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          const Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatusBadge(label: 'Satisfactory', type: AppStatusBadgeType.success),
              AppStatusBadge(label: 'Defects Found', type: AppStatusBadgeType.error),
              AppStatusBadge(label: 'Review Required', type: AppStatusBadgeType.warning),
              AppStatusBadge(label: 'Pre-Trip', type: AppStatusBadgeType.info),
              AppStatusBadge(label: 'Draft', type: AppStatusBadgeType.neutral),
            ],
          ),
        ],
      ),
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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
    required Widget child,
    required ThemeData theme,
    Locale locale = const Locale('en'),
    TextDirection textDirection = TextDirection.ltr,
  }) {
    return RepaintBoundary(
      key: repaintKey,
      child: ProviderScope(
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          dvirBackendProvider.overrideWithValue(const MockDvirBackend()),
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
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Directionality(
            textDirection: textDirection,
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets('Generate Phase 4.1 Screenshots for Visual Verification', (tester) async {
    tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Component Showcase — Light
    final key1 = GlobalKey();
    await tester.pumpWidget(buildHarness(
      repaintKey: key1,
      child: const ComponentShowcaseView(),
      theme: AppTheme.light,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await captureScreen(tester: tester, key: key1, filename: 'component_showcase_light.png');

    // 2. Component Showcase — Dark
    final key2 = GlobalKey();
    await tester.pumpWidget(buildHarness(
      repaintKey: key2,
      child: const ComponentShowcaseView(),
      theme: AppTheme.dark,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await captureScreen(tester: tester, key: key2, filename: 'component_showcase_dark.png');

    // 3. GoldenAppBar — Brand Light
    final key3 = GlobalKey();
    await tester.pumpWidget(buildHarness(
      repaintKey: key3,
      child: const Scaffold(
        appBar: GoldenAppBar(
          titleText: 'DVIR Inspection Reports',
          variant: GoldenAppBarVariant.brand,
        ),
        body: Center(child: Text('Brand Light Surface Content')),
      ),
      theme: AppTheme.light,
    ));
    await tester.pumpAndSettle();
    await captureScreen(tester: tester, key: key3, filename: 'golden_app_bar_brand_light.png');

    // 4. GoldenAppBar — Brand Dark
    final key4 = GlobalKey();
    await tester.pumpWidget(buildHarness(
      repaintKey: key4,
      child: const Scaffold(
        appBar: GoldenAppBar(
          titleText: 'DVIR Inspection Reports',
          variant: GoldenAppBarVariant.brand,
        ),
        body: Center(child: Text('Brand Dark Surface Content')),
      ),
      theme: AppTheme.dark,
    ));
    await tester.pumpAndSettle();
    await captureScreen(tester: tester, key: key4, filename: 'golden_app_bar_brand_dark.png');

    // 5. GoldenAppBar — Standard Light
    final key5 = GlobalKey();
    await tester.pumpWidget(buildHarness(
      repaintKey: key5,
      child: const Scaffold(
        appBar: GoldenAppBar(
          titleText: 'Report Details #84910',
          variant: GoldenAppBarVariant.standard,
        ),
        body: Center(child: Text('Standard Neutral Surface Content')),
      ),
      theme: AppTheme.light,
    ));
    await tester.pumpAndSettle();
    await captureScreen(tester: tester, key: key5, filename: 'golden_app_bar_standard_light.png');

    // 6. GoldenAppBar — Arabic RTL
    final key6 = GlobalKey();
    await tester.pumpWidget(buildHarness(
      repaintKey: key6,
      child: const Scaffold(
        appBar: GoldenAppBar(
          titleText: 'فحص المركبة اليومي (DVIR)',
          variant: GoldenAppBarVariant.brand,
        ),
        body: Center(child: Text('محتوى الواجهة باللغة العربية')),
      ),
      theme: AppTheme.light,
      locale: const Locale('ar'),
      textDirection: TextDirection.rtl,
    ));
    await tester.pumpAndSettle();
    await captureScreen(tester: tester, key: key6, filename: 'golden_app_bar_arabic_rtl.png');

    // 7. Buttons — Enabled / Disabled / Loading
    final key7 = GlobalKey();
    await tester.pumpWidget(buildHarness(
      repaintKey: key7,
      child: Scaffold(
        appBar: const GoldenAppBar(
          titleText: 'Button Interactive States',
          variant: GoldenAppBarVariant.brand,
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppButton.primary(label: 'Enabled Action', onPressed: () {}),
              const SizedBox(height: AppSpacing.sm),
              const AppButton.primary(label: 'Disabled Action', onPressed: null),
              const SizedBox(height: AppSpacing.sm),
              AppButton.primary(label: 'Loading Action', isLoading: true, onPressed: () {}),
              const SizedBox(height: AppSpacing.sm),
              AppButton.secondary(label: 'Secondary Action', onPressed: () {}),
              const SizedBox(height: AppSpacing.sm),
              AppButton.destructive(label: 'Destructive Action', onPressed: () {}),
            ],
          ),
        ),
      ),
      theme: AppTheme.light,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await captureScreen(tester: tester, key: key7, filename: 'buttons_states.png');

    // 8. Inputs — Normal / Focused / Error / Required
    final key8 = GlobalKey();
    await tester.pumpWidget(buildHarness(
      repaintKey: key8,
      child: const Scaffold(
        appBar: GoldenAppBar(
          titleText: 'Input Field States',
          variant: GoldenAppBarVariant.brand,
        ),
        body: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppTextField(label: 'Normal Field', hint: 'Type anything here'),
              SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Required Field', hint: 'Cannot be empty', isRequired: true),
              SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Error Field', hint: 'Invalid entry', errorText: 'Invalid odometer reading'),
              SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Disabled Field', hint: 'Locked value', enabled: false),
              SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Read-only Field', hint: 'Read-only value', readOnly: true),
            ],
          ),
        ),
      ),
      theme: AppTheme.light,
    ));
    await tester.pumpAndSettle();
    await captureScreen(tester: tester, key: key8, filename: 'inputs_states.png');

    // 9. DVIR Form — Light
    final key9 = GlobalKey();
    await tester.pumpWidget(buildHarness(
      repaintKey: key9,
      child: const DvirFormPage(),
      theme: AppTheme.light,
    ));
    await tester.pumpAndSettle();
    await captureScreen(tester: tester, key: key9, filename: 'dvir_form_light.png');

    // 10. DVIR Form — Dark
    final key10 = GlobalKey();
    await tester.pumpWidget(buildHarness(
      repaintKey: key10,
      child: const DvirFormPage(),
      theme: AppTheme.dark,
    ));
    await tester.pumpAndSettle();
    await captureScreen(tester: tester, key: key10, filename: 'dvir_form_dark.png');

    // 11. DVIR Signature Actions
    final key11 = GlobalKey();
    await tester.pumpWidget(buildHarness(
      repaintKey: key11,
      child: const DvirFormPage(),
      theme: AppTheme.light,
    ));
    await tester.pumpAndSettle();
    // Scroll down to signature section
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await captureScreen(tester: tester, key: key11, filename: 'dvir_signature_actions.png');

    // 12. DVIR Validation Errors
    final key12 = GlobalKey();
    await tester.pumpWidget(buildHarness(
      repaintKey: key12,
      child: const DvirFormPage(),
      theme: AppTheme.light,
    ));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    // Tap the sign/submit button to trigger validation errors
    final submitButton = find.descendant(
      of: find.byType(DvirSubmitButtonSection),
      matching: find.byType(AppButton),
    );
    if (submitButton.evaluate().isNotEmpty) {
      await tester.tap(submitButton);
    }
    await tester.pumpAndSettle();
    await captureScreen(tester: tester, key: key12, filename: 'dvir_validation_errors.png');
  });
}
