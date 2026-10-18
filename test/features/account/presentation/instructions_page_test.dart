import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/features/account/presentation/pages/instructions_page.dart';
import 'package:golden_feather_eld/features/account/presentation/widgets/instructions/inspection_mode_section.dart';
import 'package:golden_feather_eld/features/account/presentation/widgets/instructions/malfunction_manual_section.dart';
import 'package:golden_feather_eld/features/account/presentation/widgets/instructions/send_logs_section.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

void main() {
  final overlay = find.byKey(const Key('instructions_zoom_overlay'));
  final openSendLogs = find.byKey(const Key('instructions_open_sendLogs'));

  Future<void> pumpPage(
    WidgetTester tester, {
    InstructionsSection section = InstructionsSection.all,
    Size physicalSize = const Size(1080, 2340),
  }) async {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InstructionsPage(section: section),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppLocalizations locOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(InstructionsPage)))!;

  Future<void> openZoom(WidgetTester tester, Finder open) async {
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(overlay, findsOneWidget);
  }

  testWidgets('كامل: يعرض المقاطع الثلاثة بعنوان التعليمات', (tester) async {
    await pumpPage(tester);

    expect(find.byType(InspectionModeSection), findsOneWidget);
    expect(find.byType(SendLogsSection), findsOneWidget);
    expect(find.text(locOf(tester).instructions), findsOneWidget);

    // المقطع الثالث كسول خارج نافذة البناء — يُبنى بعد التمرير إليه.
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.byType(MalfunctionManualSection), findsOneWidget);
  });

  testWidgets('وضع مقطع واحد: يعرض المقطع المطلوب فقط بعنوانه',
      (tester) async {
    await pumpPage(tester, section: InstructionsSection.inspection);
    expect(find.byType(InspectionModeSection), findsOneWidget);
    expect(find.byType(SendLogsSection), findsNothing);
    expect(find.byType(MalfunctionManualSection), findsNothing);
    expect(find.text(locOf(tester).inspectionMode), findsOneWidget);

    await pumpPage(tester, section: InstructionsSection.sendLogs);
    expect(find.byType(SendLogsSection), findsOneWidget);
    expect(find.byType(InspectionModeSection), findsNothing);
    expect(find.text(locOf(tester).dataTransferInstructionSheet), findsOneWidget);

    await pumpPage(tester, section: InstructionsSection.malfunction);
    expect(find.byType(MalfunctionManualSection), findsOneWidget);
    expect(find.byType(SendLogsSection), findsNothing);
    expect(find.text(locOf(tester).malfunctionManual39534), findsOneWidget);
  });

  testWidgets('فتح مقطع يعرض طبقة التكبير بتكبير فعلي', (tester) async {
    await pumpPage(tester, section: InstructionsSection.sendLogs);
    await openZoom(tester, openSendLogs);

    expect(find.byType(SendLogsSection), findsNWidgets(2));
    final viewer =
        tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      moreOrLessEquals(1.3, epsilon: 0.01),
    );
  });

  testWidgets('لمس المحتوى لا يغلق الطبقة ولمس الفراغ أسفلها يغلقها',
      (tester) async {
    // شاشة أطول من الورقة المكبَّرة حتى يوجد فراغ فعلي أسفلها.
    await pumpPage(
      tester,
      section: InstructionsSection.inspection,
      physicalSize: const Size(1080, 3600),
    );
    await openZoom(tester, find.byKey(const Key('instructions_open_inspection')));

    final contentRect =
        tester.getRect(find.byType(InspectionModeSection).last);
    await tester.tapAt(contentRect.center);
    await tester.pumpAndSettle();
    expect(overlay, findsOneWidget);

    final rect = tester.getRect(overlay);
    expect(contentRect.bottom, lessThan(rect.bottom - 40));
    await tester.tapAt(Offset(rect.center.dx, rect.bottom - 20));
    await tester.pumpAndSettle();
    expect(overlay, findsNothing);
  });

  testWidgets('زر الإغلاق الصريح يغلق الطبقة', (tester) async {
    await pumpPage(tester, section: InstructionsSection.sendLogs);
    await openZoom(tester, openSendLogs);

    await tester.tap(find.byKey(const Key('instructions_zoom_close')));
    await tester.pumpAndSettle();
    expect(overlay, findsNothing);
  });

  testWidgets('زر الرجوع أثناء التكبير يغلق الطبقة ويُبقي الصفحة',
      (tester) async {
    await pumpPage(tester, section: InstructionsSection.sendLogs);
    await openZoom(tester, openSendLogs);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(overlay, findsNothing);
    expect(find.byType(InstructionsPage), findsOneWidget);
  });

  testWidgets('رجوع النظام أثناء التكبير يغلق الطبقة ويُبقي الصفحة',
      (tester) async {
    await pumpPage(tester, section: InstructionsSection.sendLogs);
    await openZoom(tester, openSendLogs);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(overlay, findsNothing);
    expect(find.byType(InstructionsPage), findsOneWidget);
  });
}
