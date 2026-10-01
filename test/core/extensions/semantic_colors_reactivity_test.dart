import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/extensions/context_extensions.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:golden_feather_eld/core/theme/app_colors.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/features/account/presentation/pages/instructions_page.dart';

/// برهان التجاوب: الألوان الدلالية المحسومة (context.textPrimary …)
/// يجب أن تتبع تبديل الثيم الفاتح/الداكن **أثناء التشغيل وفي نفس الشجرة** —
/// لأن كل قراءة تسجل اعتماداً على الـ Theme داخل build().
///
/// ملاحظة قياس: بعد تبديل themeMode يحتاج MaterialApp أكثر من إطاراً
/// لينشر الثيم الجديد — لذلك pumpAndSettle إلزامي قبل التأكيد.
void main() {
  testWidgets('semantic colors follow a runtime light->dark->light flip',
      (tester) async {
    Color? band;
    Color? textPrimary;
    ThemeMode mode = ThemeMode.light;

    late StateSetter setMode;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          setMode = setState;
          return MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            home: Builder(
              builder: (context) {
                band = context.inspectionBand;
                textPrimary = context.textPrimary;
                return const Scaffold();
              },
            ),
          );
        },
      ),
    );

    // الفاتح
    expect(band, AppColors.inspectionBand);
    expect(textPrimary, AppColors.textPrimary);

    // تبديل حي إلى الداكن — نفس الشجرة، نفس العناصر
    setMode(() => mode = ThemeMode.dark);
    await tester.pumpAndSettle();

    expect(band, AppColors.inspectionBandDark);
    expect(textPrimary, AppColors.darkTextPrimary);

    // وعودة حية إلى الفاتح
    setMode(() => mode = ThemeMode.light);
    await tester.pumpAndSettle();

    expect(band, AppColors.inspectionBand);
    expect(textPrimary, AppColors.textPrimary);
  });

  testWidgets('InstructionsPage bands resolve per mode on the real page',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // ListView تبني الأبناء كسولاً — نتحقق من كل قسم عند ظهوره بالتمرير.
    Set<Color> containerColors() => tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => (c.decoration is BoxDecoration)
            ? (c.decoration as BoxDecoration).color
            : null)
        .whereType<Color>()
        .toSet();

    Future<void> scrollThrough() async {
      await tester.pumpAndSettle();
      for (var i = 0; i < 8; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    Widget page(ThemeMode mode) => MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const InstructionsPage(),
        );

    // الفاتح — أعلى الصفحة (شريط وضع التفتيش)
    await tester.pumpWidget(page(ThemeMode.light));
    await tester.pumpAndSettle();
    expect(containerColors(), contains(AppColors.inspectionBand));

    // الداكن — أعلى الصفحة: شريط التفتيش بدرجته الداكنة (لا الفاتحة)
    await tester.pumpWidget(page(ThemeMode.dark));
    await tester.pumpAndSettle();
    final darkTop = containerColors();
    expect(darkTop, contains(AppColors.inspectionBandDark));
    expect(darkTop, isNot(contains(AppColors.inspectionBand)));

    // الداكن — أسفل الصفحة بعد التمرير: خلفية دليل الأعطال الداكنة (لا الفاتحة)
    await scrollThrough();
    final darkBottom = containerColors();
    expect(darkBottom, contains(AppColors.manualBandDark));
    expect(darkBottom, isNot(contains(AppColors.manualBand)));
  });
}
