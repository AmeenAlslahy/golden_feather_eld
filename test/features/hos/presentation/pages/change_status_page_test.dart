import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/features/account/application/models/rules_screen_model.dart';
import 'package:golden_feather_eld/features/account/presentation/providers/rules_screen_provider.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_rules_engine.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/tracking/duty_status_tracker.dart';
import 'package:golden_feather_eld/features/hos/presentation/pages/change_status_page.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/hos_provider.dart';
import 'package:golden_feather_eld/features/hos/presentation/widgets/status_option_tiles.dart';
import 'package:golden_feather_eld/features/tracking/presentation/providers/tracking_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _Storage extends Mock implements LocalStorageService {}

/// Records the transition the page asks for; the answer is scripted.
class _HosNotifier extends StateNotifier<HosEngineResult> implements HosNotifier {
  _HosNotifier(DutyStatus current)
      : super(HosEngineReady(HosStatusUpdate(
          currentStatus: current,
          limits: const HosLimits(
            remainingDriveMinutes: 600,
            remainingShiftMinutes: 800,
            remainingCycleHours: 60,
            breakRequired: false,
            breakRemainingMinutes: 0,
          ),
          alerts: const [],
          violations: const [],
          remainingDriveMinutes: 600,
          remainingShiftMinutes: 800,
          remainingCycleHours: 60,
          breakRequired: false,
          breakRemainingMinutes: 0,
        )));

  final calls = <String>[];
  String? nextError;

  @override
  Future<String?> changeStatus(DutyStatus newStatus,
      {String? annotation, bool isYardMoves = false}) async {
    calls.add('${newStatus.name}|${annotation ?? ''}|ym=$isYardMoves');
    return nextError;
  }

  @override
  void refresh() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

RulesScreenModel _rules(Map<String, dynamic> fixed) => RulesScreenModel(
      ruleSource: 'Federal',
      cycleRule: 'USA 70/8',
      cargoType: 'Property',
      restart: '34 Hour Restart',
      restBreak: '30 Minute Rest Break Required',
      sixteenHourException: false,
      options: const {},
      editableFields: const {},
      readOnlyFields: const {},
      fixedSettings: fixed,
      notice: '',
      limits: HosConfiguration.usa70_8(),
    );

/// SRS 2.3 / 4.7 / 4.8 — Change Status: Driving is never manual, PC / YM
/// only when the carrier allows them (server flags) and only with an
/// annotation, and nothing changes while the vehicle is moving.
void main() {
  late _HosNotifier hos;

  Future<void> pump(
    WidgetTester tester, {
    Map<String, dynamic> fixed = const {},
    double? speedMps,
    DutyStatus current = DutyStatus.offDuty,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    hos = _HosNotifier(current);
    final storage = _Storage();
    when(() => storage.hosConfiguration).thenReturn(HosConfiguration.usa70_8());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hosStatusProvider.overrideWith((ref) => hos),
          rulesScreenProvider.overrideWith((ref) async => _rules(fixed)),
          currentVehicleSpeedProvider.overrideWith((ref) => speedMps),
          localStorageProvider.overrideWithValue(storage),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChangeStatusPage()),
                  ),
                  child: const Text('OPEN'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
  }

  StatusOptionTile tile(WidgetTester tester, DutyStatus status) =>
      tester.widget<StatusOptionTile>(find.byWidgetPredicate(
          (w) => w is StatusOptionTile && w.status == status));

  testWidgets('Driving is locked; PC and Yard Moves hidden unless the server allows',
      (tester) async {
    await pump(tester);

    expect(tile(tester, DutyStatus.driving).onTap, isNull);
    expect(tile(tester, DutyStatus.offDuty).onTap, isNotNull);
    expect(tile(tester, DutyStatus.onDutyNotDriving).onTap, isNotNull);
    expect(find.text('Personal Use'), findsNothing);
    expect(find.byType(YardMovesOptionTile), findsNothing);
  });

  testWidgets('Personal Conveyance needs an annotation, then is sent as such',
      (tester) async {
    await pump(tester, fixed: const {
      'personalConveyanceEnabled': true,
      'yardMoveEnabled': true,
    });

    expect(find.text('Personal Use'), findsOneWidget);
    expect(find.byType(YardMovesOptionTile), findsOneWidget);

    await tester.tap(find.text('Personal Use'));
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(AppButton, 'UPDATE'));
    await tester.tap(find.widgetWithText(AppButton, 'UPDATE'));
    await tester.pump();
    expect(
      find.text('An annotation is required for personal conveyance or yard moves.'),
      findsOneWidget,
    );
    expect(hos.calls, isEmpty);
    // Let the refusal snackbar expire so the next one is not queued behind it.
    await tester.pumpAndSettle(); // entrance animation → timer starts
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    // The refusal is an AppFeedback overlay now (not a SnackBar); it must
    // be gone once its auto-dismiss timer has fired.
    expect(
      find.text('An annotation is required for personal conveyance or yard moves.'),
      findsNothing,
    );

    await tester.enterText(find.widgetWithText(TextField, 'Notes'), 'Driving home');
    await tester.ensureVisible(find.widgetWithText(AppButton, 'UPDATE'));
    await tester.tap(find.widgetWithText(AppButton, 'UPDATE'));
    await tester.pumpAndSettle();

    expect(hos.calls, ['personalUse|Driving home|ym=false']);
    expect(find.text('The server accepted the duty status change.'), findsOneWidget);
    // Accepted → the page pops back.
    expect(find.byType(ChangeStatusPage), findsNothing);
    // AppFeedback auto-dismisses after 3s; pump past the timer so no
    // pending timer is left when the widget tree is disposed.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('Yard Moves forces On Duty and is flagged on the request',
      (tester) async {
    await pump(tester, fixed: const {'yardMoveEnabled': true});

    await tester.tap(find.byType(YardMovesOptionTile));
    await tester.pump();
    expect(tile(tester, DutyStatus.onDutyNotDriving).isSelected, isTrue);

    await tester.enterText(find.widgetWithText(TextField, 'Notes'), 'Moving to dock 4');
    await tester.tap(find.widgetWithText(AppButton, 'UPDATE'));
    await tester.pumpAndSettle();

    expect(hos.calls, ['onDutyNotDriving|Moving to dock 4|ym=true']);
    // Pump past the AppFeedback auto-dismiss timer (3s).
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('while moving nothing can be changed and nothing is sent',
      (tester) async {
    await pump(tester, speedMps: 10, current: DutyStatus.onDutyNotDriving);

    expect(find.text('Cannot change status while the vehicle is moving.'), findsOneWidget);
    expect(tile(tester, DutyStatus.offDuty).onTap, isNull);
    expect(tile(tester, DutyStatus.sleeperBerth).onTap, isNull);

    await tester.tap(find.widgetWithText(AppButton, 'UPDATE'));
    await tester.pump();
    expect(hos.calls, isEmpty);
    expect(find.byType(ChangeStatusPage), findsOneWidget);
    // Pump past the AppFeedback auto-dismiss timer (3s).
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('a refusal from the engine/server is explained and the page stays',
      (tester) async {
    await pump(tester);
    hos.nextError = DutyStampRefusal.sessionMissing;

    await tester.tap(find.text('Sleeper'));
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, 'UPDATE'));
    await tester.pumpAndSettle();

    expect(hos.calls, ['sleeperBerth||ym=false']);
    expect(find.byType(ChangeStatusPage), findsOneWidget);
    expect(find.text('Session missing, please login again'), findsOneWidget);
    // Pump past the AppFeedback auto-dismiss timer (3s).
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
