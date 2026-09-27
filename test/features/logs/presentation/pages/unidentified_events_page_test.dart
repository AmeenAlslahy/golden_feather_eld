import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/vehicle/data/providers/vehicle_repository_providers.dart';
import 'package:golden_feather_eld/backend/contracts/contract_enums.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/backend/contracts/unidentified_events_backend.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/logs/data/repositories/log_repository_impl.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/pages/unidentified_events_page.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:golden_feather_eld/features/vehicle/domain/entities/vehicle.dart';
import 'package:golden_feather_eld/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:mocktail/mocktail.dart';

class _Logs extends Mock implements LogRepository {}

/// Server-only backend double: the list is whatever the server returns and
/// every claim / reject is recorded with the exact ids sent.
class _Vehicles extends Mock implements VehicleRepository {}

class _Backend implements UnidentifiedEventsBackend {
  _Backend({required this.rows});
  List<Map<String, dynamic>> rows;
  final calls = <String>[];
  final tabsRequested = <UnidentifiedTab>[];
  final uniqueIdsRequested = <String?>[];
  AppError? nextError;

  @override
  Future<Result<RawJson>> list({
    UnidentifiedTab tab = UnidentifiedTab.unclaimed,
    String? uniqueId,
    DriverId? driverId,
  }) async {
    tabsRequested.add(tab);
    uniqueIdsRequested.add(uniqueId);
    return ok({'items': tab == UnidentifiedTab.unclaimed ? rows : const []});
  }

  @override
  Future<Result<void>> claim({
    required DutyStatusId id,
    required DriverId driverId,
    required String annotation,
  }) async {
    calls.add('claim:${id.value}:${driverId.value}:$annotation');
    if (nextError != null) return err(nextError!);
    rows = rows.where((r) => r['statusId'] != id.value).toList();
    return ok(null);
  }

  @override
  Future<Result<void>> reject({
    required DutyStatusId id,
    required DriverId driverId,
    required String rejectionReason,
  }) async {
    calls.add('reject:${id.value}:${driverId.value}:$rejectionReason');
    rows = rows.where((r) => r['statusId'] != id.value).toList();
    return ok(null);
  }
}

/// SRS 7.13 / 11 — Unidentified Events: server rows only, annotation is
/// mandatory, ASSUME / NOT MINE go through the existing claim / reject API.
void main() {
  late _Backend backend;
  late _Logs logs;

  final now = DateTime.now().toUtc();
  String iso(Duration ago) => now.subtract(ago).toIso8601String();

  final rows = <Map<String, dynamic>>[
    {
      'statusId': 501,
      'status': 'DRIVING',
      'startTime': iso(const Duration(hours: 3)),
      'endTime': iso(const Duration(hours: 2, minutes: 20)),
      'formattedDuration': '40m',
      'locationText': 'I-80 mile 12',
      'vehicleName': 'Truck 4',
      'uniqueId': 'imei-4',
      'allocationStatus': 'PENDING_REVIEW',
      'daysPending': 1,
    },
    {
      'statusId': 502,
      'status': 'ON_DUTY',
      'startTime': iso(const Duration(hours: 30)),
      'formattedDuration': '15m',
      'locationText': 'Yard',
      'overdue': true,
    },
    {
      // Driving, but older than the 24-hour window → not in DRIVING 24H.
      'statusId': 503,
      'status': 'DRIVING',
      'startTime': iso(const Duration(hours: 50)),
      'endTime': iso(const Duration(hours: 49)),
      'formattedDuration': '60m',
      'locationText': 'US-50 rest area',
    },
  ];

  setUp(() {
    logs = _Logs();
    when(() => logs.getDailyLogs(
          driverId: any(named: 'driverId'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).thenAnswer((_) async => const Right([]));
  });

  Future<void> pump(WidgetTester tester) async {
    final vehicles = _Vehicles();
    const truck = Vehicle(
      id: 'TRK-4',
      uniqueId: 'imei-4',
      name: 'Truck 4',
      year: '2022',
      isAssigned: true,
      activeForCurrentDriver: true,
    );
    when(() => vehicles.getSelectedVehicle())
        .thenAnswer((_) async => const Right(truck));
    when(() => vehicles.getVehicles())
        .thenAnswer((_) async => const Right([truck]));
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unidentifiedEventsBackendProvider.overrideWithValue(backend),
          currentDriverIdProvider.overrideWithValue(106),
          logRepositoryProvider.overrideWithValue(logs),
          vehicleRepositoryProvider.overrideWithValue(vehicles),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const UnidentifiedEventsPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('lists server rows with counters, and no device-local rows',
      (tester) async {
    backend = _Backend(rows: List.of(rows));
    await pump(tester);

    expect(find.text('Unidentified Events'), findsOneWidget);
    expect(find.text('I-80 mile 12'), findsOneWidget);
    expect(find.text('Truck 4'), findsOneWidget);
    expect(find.text('ELD: imei-4'), findsOneWidget);
    expect(find.text('PENDING REVIEW'), findsOneWidget);
    // Both tabs are fetched so the counters are real: 3 unclaimed, 0 rejected.
    expect(backend.tabsRequested,
        containsAll([UnidentifiedTab.unclaimed, UnidentifiedTab.rejected]));
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Pending 1 day(s)'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    // Lazy list: the third card may be below the fold.
    expect(find.text('Original record preserved'), findsAtLeastNWidgets(2));
    expect(find.textContaining('Recorded on this device'), findsNothing);
    // Counters: TOTAL 3, DRIVING 24H 1 (the 50-hour-old driving row is out).
    expect(find.text('3'), findsWidgets);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('ASSUME'), findsAtLeastNWidgets(2));
    expect(find.text('NOT MINE'), findsAtLeastNWidgets(2));
  });

  testWidgets('ASSUME without an annotation is refused; with one it claims',
      (tester) async {
    backend = _Backend(rows: List.of(rows));
    await pump(tester);

    await tester.tap(find.text('ASSUME').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Required annotation. This time is assumed as driving.'),
      findsOneWidget,
    );

    // Empty → refused, nothing sent.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('An annotation is required.'), findsOneWidget);
    expect(backend.calls, isEmpty);

    // With text → claim with the server statusId and the signed-in driver.
    await tester.tap(find.text('ASSUME').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'I was driving, forgot to log in');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(backend.calls, ['claim:501:106:I was driving, forgot to log in']);
    // List reloaded from the server: the claimed row is gone.
    expect(find.text('I-80 mile 12'), findsNothing);
    expect(find.text('Yard'), findsOneWidget);
    // The driver's own record changed → daily logs re-read from the server
    // and the driver is pointed at the log for possible re-certification.
    verify(() => logs.getDailyLogs(
          driverId: 106,
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).called(greaterThanOrEqualTo(1));
    // The earlier refusal snackbar must expire before the queued one shows.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Your record was updated. Review the daily log; it may need re-certification.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('NOT MINE sends the rejection reason through reject',
      (tester) async {
    backend = _Backend(rows: List.of(rows));
    await pump(tester);

    await tester.tap(find.text('NOT MINE').at(1));
    await tester.pumpAndSettle();
    expect(find.text('Required rejection reason'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Vehicle was with the mechanic');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(backend.calls, ['reject:502:106:Vehicle was with the mechanic']);
    expect(find.text('Yard'), findsNothing);
  });

  testWidgets('a server refusal is shown as a plain message, row stays',
      (tester) async {
    backend = _Backend(rows: List.of(rows))
      ..nextError = const ConflictError(
        code: 'UNIDENTIFIED_CLAIM_FAILED',
        l10nKey: 'conflict',
        context: {'message': 'This event was already assigned.'},
      );
    await pump(tester);

    await tester.tap(find.text('ASSUME').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'mine');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('This event was already assigned.'), findsOneWidget);
    expect(find.text('I-80 mile 12'), findsOneWidget);
  });

  testWidgets('SRS 11.2 filters: current vehicle goes to the server, date is local',
      (tester) async {
    backend = _Backend(rows: List.of(rows));
    await pump(tester);
    await tester.pumpAndSettle();
    // Both tabs are fetched per load (counters); neither carries a vehicle.
    expect(backend.uniqueIdsRequested, [null, null]);

    await tester.tap(find.byIcon(Icons.filter_alt_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Current vehicle only'));
    await tester.pumpAndSettle();

    expect(backend.uniqueIdsRequested.last, 'imei-4');
    expect(find.text('Current vehicle'), findsOneWidget);

    // Clear → reloads without the vehicle filter.
    await tester.tap(find.byIcon(Icons.filter_alt));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(backend.uniqueIdsRequested.last, isNull);
    expect(find.text('Current vehicle'), findsNothing);
  });
}
