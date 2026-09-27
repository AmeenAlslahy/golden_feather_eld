import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/codriver/domain/current_codriver.dart';
import 'package:golden_feather_eld/features/codriver/domain/entities/codriver.dart';
import 'package:golden_feather_eld/features/codriver/domain/repositories/codriver_repository.dart';
import 'package:golden_feather_eld/features/codriver/presentation/pages/codriver_page.dart';
import 'package:golden_feather_eld/features/codriver/presentation/providers/codriver_provider.dart';
import 'package:golden_feather_eld/features/codriver/presentation/providers/team_status_provider.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_rules_engine.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/hos_provider.dart';
import 'package:golden_feather_eld/features/tracking/presentation/providers/tracking_provider.dart';
import 'package:golden_feather_eld/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:golden_feather_eld/features/vehicle/presentation/providers/vehicle_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements CoDriverRepository {}

class _VehicleRepo extends Mock implements VehicleRepository {}

class _Storage extends Mock implements LocalStorageService {}

class _HosNotifier extends StateNotifier<HosEngineResult> implements HosNotifier {
  _HosNotifier() : super(HosEngineTimeUnavailable(TrustedTimeState.uninitialized));
  @override
  void refresh() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// SRS 4.9 / 5.x — Co-driver page: link a session co-driver through the
/// existing endpoint, and SWITCH is guarded (motion known + stopped) and
/// explains that hours / duty status are not transferred.
void main() {
  late _Repo repo;
  late _VehicleRepo vehicleRepo;
  late _Storage storage;

  const alex = CoDriver(id: '7', name: 'Alex Rivera');
  const sam = CoDriver(id: '8', name: 'Sam Lee');

  setUp(() {
    repo = _Repo();
    vehicleRepo = _VehicleRepo();
    storage = _Storage();
    when(() => repo.getAvailableDrivers())
        .thenAnswer((_) async => const Right([alex, sam]));
    when(() => repo.getCurrentCoDriver()).thenAnswer((_) async =>
        const Right(CurrentCoDriverRead(coDriverId: 0, teamDrivingActive: false)));
    when(() => repo.updateSessionCoDriver(
          remove: any(named: 'remove'),
          coDriverId: any(named: 'coDriverId'),
          uniqueId: any(named: 'uniqueId'),
        )).thenAnswer((_) async => const Right(true));
    when(() => repo.switchPrimary(coDriverId: any(named: 'coDriverId')))
        .thenAnswer((_) async => const Right(true));
    when(() => vehicleRepo.getVehicles()).thenAnswer((_) async => const Right([]));
    when(() => vehicleRepo.getSelectedVehicle())
        .thenAnswer((_) async => const Right(null));
    when(() => storage.hosConfiguration).thenReturn(HosConfiguration.usa70_8());
  });

  Future<void> pump(
    WidgetTester tester, {
    double? speedMps,
    TeamStatus? team,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const CoDriverPage()),
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Text('HOME ROUTE')),
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coDriverRepositoryProvider.overrideWithValue(repo),
          vehicleRepositoryProvider.overrideWithValue(vehicleRepo),
          localStorageProvider.overrideWithValue(storage),
          currentDriverIdProvider.overrideWithValue(106),
          hosStatusProvider.overrideWith((ref) => _HosNotifier()),
          currentVehicleSpeedProvider.overrideWith((ref) => speedMps),
          teamStatusProvider.overrideWith((ref) async => team),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('shows server link state and SWITCH is disabled with nobody selected',
      (tester) async {
    await pump(tester);

    expect(find.text('Select Co-driver'), findsOneWidget);
    expect(find.text('NO CO-DRIVER'), findsOneWidget);
    expect(find.text('Linked co-driver'), findsOneWidget);
    expect(find.text('No linked co-driver.'), findsOneWidget);

    final button = tester.widget<AppButton>(find.widgetWithText(AppButton, 'SWITCH'));
    expect(button.onPressed, isNull);
  });

  testWidgets('picking a co-driver links the session via the existing endpoint',
      (tester) async {
    await pump(tester);

    await tester.tap(find.text('NO CO-DRIVER'));
    await tester.pumpAndSettle();
    expect(find.byType(RadioListTile<String>), findsNWidgets(3));

    await tester.tap(find.text('ALEX RIVERA'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    verify(() => repo.updateSessionCoDriver(
          remove: false,
          coDriverId: 7,
          uniqueId: null,
        )).called(1);
    // Selector reflects the pick and the server link is re-read.
    expect(find.text('ALEX RIVERA'), findsOneWidget);
    verify(() => repo.getCurrentCoDriver()).called(2);

    final button = tester.widget<AppButton>(find.widgetWithText(AppButton, 'SWITCH'));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('SWITCH refuses when vehicle motion is unknown — no server call',
      (tester) async {
    await pump(tester); // speed null
    await tester.tap(find.text('NO CO-DRIVER'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SAM LEE'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'SWITCH'));
    await tester.pumpAndSettle();

    expect(
      find.text('Vehicle motion is unknown. That is not treated as stopped.'),
      findsOneWidget,
    );
    verifyNever(() => repo.switchPrimary(coDriverId: any(named: 'coDriverId')));
  });

  testWidgets('SWITCH while stopped: confirm → switchPrimary → home', (tester) async {
    await pump(tester, speedMps: 0.0);
    await tester.tap(find.text('NO CO-DRIVER'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SAM LEE'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'SWITCH'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Switch'), findsOneWidget);
    expect(
      find.text(
          'This asks the server to switch roles. Hours are not copied and duty status is not changed.'),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    verify(() => repo.switchPrimary(coDriverId: 8)).called(1);
    // SRS 10.4: the new roles are shown before leaving the screen.
    expect(find.byKey(const Key('switch_result_dialog')), findsOneWidget);
    expect(find.textContaining('Sam Lee is now the primary driver'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('HOME ROUTE'), findsOneWidget);
  });

  testWidgets('server refusal on switch is shown to the driver, no navigation',
      (tester) async {
    when(() => repo.switchPrimary(coDriverId: any(named: 'coDriverId'))).thenAnswer(
        (_) async => const Left(ServerFailure(
            message: 'Co-driver is not on duty with this vehicle.', statusCode: 409)));
    await pump(tester, speedMps: 0.0);
    await tester.tap(find.text('NO CO-DRIVER'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SAM LEE'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'SWITCH'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Co-driver is not on duty with this vehicle.'), findsWidgets);
    expect(find.text('HOME ROUTE'), findsNothing);
  });

  testWidgets('linked co-driver shows the server team state; refresh re-reads it',
      (tester) async {
    var reads = 0;
    when(() => repo.getCurrentCoDriver()).thenAnswer((_) async {
      reads++;
      return Right(CurrentCoDriverRead(
        coDriverId: 7,
        name: 'Alex Rivera',
        teamDrivingActive: reads >= 2,
      ));
    });
    await pump(tester);

    expect(find.text('Alex Rivera'), findsOneWidget);
    expect(find.text('Team driving inactive'), findsOneWidget);

    // Pull-to-refresh (the reference AppBar has no refresh icon).
    await tester.fling(find.byType(SingleChildScrollView), const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(reads, 2);
    expect(find.text('Team driving active'), findsOneWidget);
    expect(find.text('Team driving inactive'), findsNothing);
  });

  testWidgets('SRS 5.8: HOS isolation line comes from /team and is verbatim',
      (tester) async {
    await pump(
      tester,
      team: const TeamStatus(
        dailyLogId: 1,
        teamModeActive: false,
        hosRecordsIsolated: true,
        complianceNote: 'HOS records are fully isolated (5.8 / FMCSA).',
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('HOS records isolated'), findsOneWidget);
    expect(find.text('HOS records are fully isolated (5.8 / FMCSA).'), findsOneWidget);
  });

  testWidgets('no daily log today → no isolation line, no invented state',
      (tester) async {
    await pump(tester, team: null);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('HOS records isolated'), findsNothing);
    expect(find.text('HOS records not isolated'), findsNothing);
  });
}
