import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/audit_entry.dart';
import 'package:golden_feather_eld/features/logs/presentation/pages/audit_trail_page.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/audit_trail_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<AuditEntry> entries,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          auditTrailProvider.overrideWith((ref) async => entries),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const AuditTrailPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('renders the confirmatory note, actions, entities and users',
      (tester) async {
    await pump(tester, entries: [
      AuditEntry(
        id: 'a1',
        timestamp: DateTime.utc(2026, 9, 28, 14),
        driverId: '106',
        newStatus: '',
        reason: '',
        action: 'sign_dvir',
        entityType: 'dvir',
        entityId: 'dvir-77',
        userName: 'Naseem Adam',
        userRole: 'driver',
      ),
      AuditEntry(
        id: 'a2',
        timestamp: DateTime.utc(2026, 9, 28, 15),
        driverId: '106',
        oldStatus: 'OFF',
        newStatus: 'D',
        reason: 'correction',
      ),
    ]);

    // The confirmatory note (SRS 7.16) is always shown.
    expect(find.textContaining('cannot be edited or deleted'), findsOneWidget);
    // Action names and entity/user context are rendered.
    expect(find.text('sign_dvir'), findsOneWidget);
    expect(find.textContaining('dvir #dvir-77'), findsOneWidget);
    expect(find.textContaining('Naseem Adam (driver)'), findsOneWidget);
    // A legacy row without an action falls back to the new status.
    expect(find.text('D'), findsOneWidget);
  });

  testWidgets('empty trail shows the No Records state', (tester) async {
    await pump(tester, entries: const []);

    expect(find.text('No Records'), findsOneWidget);
    expect(find.textContaining('cannot be edited or deleted'), findsOneWidget);
  });
}
