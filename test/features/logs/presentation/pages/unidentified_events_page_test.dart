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
import 'package:golden_feather_eld/features/logs/data/providers/log_repository_providers.dart';

import 'package:golden_feather_eld/features/logs/domain/entities/daily_log_page.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/pages/unidentified_events_page.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/logs_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/features/vehicle/domain/entities/vehicle.dart';
import 'package:golden_feather_eld/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:mocktail/mocktail.dart';

class _Logs extends Mock implements LogRepository {}

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

/// Server-only backend double: the list is whatever the server returns and
/// every claim / reject is recorded with the exact ids sent.
class _Vehicles extends Mock implements VehicleRepository {}

class _Backend implements UnidentifiedEventsBackend {
  _Backend({required this.rows, List<Map<String, dynamic>>? rejectedRows})
    : rejectedRows = rejectedRows ?? [];

  List<Map<String, dynamic>> rows;
  List<Map<String, dynamic>> rejectedRows;
  final calls = <String>[];
  final tabsRequested = <UnidentifiedTab>[];
  final pagesRequested = <int>[];
  final sizesRequested = <int>[];
  int summaryCalls = 0;
  AppError? nextError;

  @override
  Future<Result<RawJson>> list({
    UnidentifiedTab tab = UnidentifiedTab.unclaimed,
    int page = 0,
    int size = 20,
    String sortBy = 'id',
    String sortDirection = 'ASC',
    List<UnidentifiedEventFilter> filters = const [],
  }) async {
    tabsRequested.add(tab);
    pagesRequested.add(page);
    sizesRequested.add(size);
    return ok({
      'items': tab == UnidentifiedTab.unclaimed ? rows : rejectedRows,
    });
  }

  @override
  Future<Result<RawJson>> getById({required DutyStatusId id}) async {
    final row = [
      ...rows,
      ...rejectedRows,
    ].firstWhere((row) => row['id'] == id.value);
    return ok(row);
  }

  @override
  Future<Result<RawJson>> summary() async {
    summaryCalls++;
    final all = [...rows, ...rejectedRows];
    final pending = all.where((row) => row['pendingOver8Days'] == true).length;
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
  }) async {
    calls.add('claim:${id.value}:${driverId?.value}:$annotation');
    if (nextError != null) return err(nextError!);
    rows = rows.where((row) => row['id'] != id.value).toList();
    return ok(null);
  }

  @override
  Future<Result<void>> reject({
    required DutyStatusId id,
    DriverId? driverId,
    required String rejectionReason,
  }) async {
    calls.add('reject:${id.value}:${driverId?.value}:$rejectionReason');
    if (nextError != null) return err(nextError!);
    final row = rows.firstWhere((row) => row['id'] == id.value);
    rows = rows.where((row) => row['id'] != id.value).toList();
    rejectedRows = [
      ...rejectedRows,
      {...row, 'status': 'REJECTED', 'rejectionReason': rejectionReason},
    ];
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
      'id': 501,
      'deviceId': 4,
      'vehicleName': 'Truck 4',
      'vehicleVin': 'VIN-4',
      'startTime': iso(const Duration(hours: 3)),
      'endTime': iso(const Duration(hours: 2, minutes: 20)),
      'durationMinutes': 40,
      'durationFormatted': '40m',
      'latitude': 34.0522,
      'longitude': -118.2437,
      'locationDescription': 'I-80 mile 12',
      'odometerMiles': 125430.5,
      'engineHours': 3450.2,
      'status': 'UNCLAIMED',
      'allocationType': 'UNASSIGNED',
      'annotation': 'Yard move',
      'pendingOver8Days': false,
    },
    {
      'id': 502,
      'deviceId': 5,
      'vehicleName': 'Truck 5',
      'vehicleVin': 'VIN-5',
      'startTime': iso(const Duration(hours: 30)),
      'durationFormatted': '15m',
      'locationDescription': 'Yard',
      'status': 'UNCLAIMED',
      'allocationType': 'UNASSIGNED',
      'pendingOver8Days': true,
    },
    {
      // Driving, but older than the 24-hour window → not in DRIVING 24H.
      'id': 503,
      'deviceId': 4,
      'vehicleName': 'Truck 4',
      'vehicleVin': 'VIN-4',
      'startTime': iso(const Duration(hours: 50)),
      'endTime': iso(const Duration(hours: 49)),
      'durationFormatted': '60m',
      'locationDescription': 'US-50 rest area',
      'status': 'UNCLAIMED',
      'allocationType': 'UNASSIGNED',
      'pendingOver8Days': false,
    },
  ];

  final rejectedRows = <Map<String, dynamic>>[
    {
      'id': 601,
      'deviceId': 6,
      'vehicleName': 'Truck 6',
      'vehicleVin': 'VIN-6',
      'startTime': iso(const Duration(hours: 4)),
      'durationFormatted': '20m',
      'locationDescription': 'Depot',
      'status': 'REJECTED',
      'allocationType': 'UNASSIGNED',
      'rejectionReason': 'Not my vehicle',
      'pendingOver8Days': false,
    },
  ];

  setUp(() {
    logs = _Logs();
    when(
      () => logs.getDailyLogs(
        driverId: any(named: 'driverId'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => const Right(DailyLogPage.empty));
  });

  Future<void> pump(WidgetTester tester) async {
    final vehicles = _Vehicles();
    const truck = Vehicle(
      id: 'TRK-4',
      uniqueId: 'imei-4',
      deviceId: 4,
      name: 'Truck 4',
      year: '2022',
      vin: 'VIN-4',
      isAssigned: true,
      activeForCurrentDriver: true,
    );
    when(
      () => vehicles.getSelectedVehicle(),
    ).thenAnswer((_) async => const Right(truck));
    when(
      () => vehicles.getVehicles(),
    ).thenAnswer((_) async => const Right([truck]));
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
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

  Finder statValue(String key, String value) =>
      find.descendant(of: find.byKey(Key(key)), matching: find.text(value));

  testWidgets('lists server rows with summary counters, no tab double-fetch', (
    tester,
  ) async {
    backend = _Backend(
      rows: List.of(rows),
      rejectedRows: List.of(rejectedRows),
    );
    await pump(tester);

    expect(find.text('Unidentified Events'), findsOneWidget);
    expect(find.text('Location: I-80 mile 12'), findsOneWidget);
    expect(find.text('Truck 4'), findsOneWidget);
    expect(find.text('VIN: VIN-4'), findsOneWidget);
    expect(find.text('ELD Identifier: 4'), findsOneWidget);
    expect(find.text('UNASSIGNED'), findsWidgets);
    expect(find.text('Odometer: 125430.5 miles'), findsOneWidget);
    expect(find.text('Engine Hours: 3450.2'), findsOneWidget);
    expect(find.text('Notes: Yard move'), findsOneWidget);

    // The active tab is fetched once; counters come from the summary.
    expect(backend.tabsRequested, [UnidentifiedTab.unclaimed]);
    expect(backend.summaryCalls, 1);
    expect(backend.pagesRequested, [0]);
    expect(backend.sizesRequested, [100]);

    expect(statValue('unidentified-stat-total', '4'), findsOneWidget);
    expect(statValue('unidentified-stat-unclaimed', '3'), findsOneWidget);
    expect(statValue('unidentified-stat-rejected', '1'), findsOneWidget);
    expect(statValue('unidentified-stat-over-8-days', '1'), findsOneWidget);
    expect(find.textContaining('8 days rule:'), findsOneWidget);

    // Lazy list: the second card may be below the fold.
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Original record preserved'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Recorded on this device'), findsNothing);
    expect(find.text('ASSUME'), findsAtLeastNWidgets(1));
    expect(find.text('NOT MINE'), findsAtLeastNWidgets(1));
  });

  testWidgets('ASSUME without an annotation is refused; with one it claims', (
    tester,
  ) async {
    backend = _Backend(
      rows: List.of(rows),
      rejectedRows: List.of(rejectedRows),
    );
    await pump(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(UnidentifiedEventsPage)),
    );
    final sub = container.listen(logsProvider, (_, __) {});
    addTearDown(sub.close);

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

    // Too short → refused by the documented 4..500 rule, nothing sent.
    await tester.tap(find.text('ASSUME').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(
      find.text('Annotation must be between 4 and 500 characters.'),
      findsOneWidget,
    );
    expect(backend.calls, isEmpty);

    // With text → claim with the server id and the signed-in driver.
    await tester.tap(find.text('ASSUME').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'I was driving, forgot to log in',
    );
    await tester.tap(find.text('OK'));
    await tester.pump();
    // The success overlay is inserted immediately; assert before any
    // further pumping can let its 3s auto-dismiss expire.
    expect(
      find.text(
        'Your record was updated. Review the daily log; it may need re-certification.',
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle();

    expect(backend.calls, ['claim:501:106:I was driving, forgot to log in']);
    // List reloaded from the server: the claimed row is gone.
    expect(find.text('Location: I-80 mile 12'), findsNothing);
    expect(find.text('Location: Yard'), findsOneWidget);
    // The driver's own record changed → daily logs re-read from the server
    // and the driver is pointed at the log for possible re-certification.
    verify(
      () => logs.getDailyLogs(
        driverId: 106,
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).called(greaterThanOrEqualTo(1));
    // Expire any remaining feedback timers so nothing is left pending.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('NOT MINE sends the rejection reason through reject', (
    tester,
  ) async {
    backend = _Backend(
      rows: List.of(rows),
      rejectedRows: List.of(rejectedRows),
    );
    await pump(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(UnidentifiedEventsPage)),
    );
    final sub = container.listen(logsProvider, (_, __) {});
    addTearDown(sub.close);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NOT MINE').at(1));
    await tester.pumpAndSettle();
    expect(find.text('Required rejection reason'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'Vehicle was with the mechanic',
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(backend.calls, ['reject:502:106:Vehicle was with the mechanic']);
    expect(find.text('Location: Yard'), findsNothing);
    // Pump past the AppFeedback auto-dismiss timer (3s).
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('a server refusal is shown as a plain message, row stays', (
    tester,
  ) async {
    backend = _Backend(rows: List.of(rows), rejectedRows: List.of(rejectedRows))
      ..nextError = const ConflictError(
        code: 'UNIDENTIFIED_CLAIM_FAILED',
        l10nKey: 'conflict',
        context: {'message': 'This event was already assigned.'},
      );
    await pump(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(UnidentifiedEventsPage)),
    );
    final sub = container.listen(logsProvider, (_, __) {});
    addTearDown(sub.close);

    await tester.tap(find.text('ASSUME').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'mine');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('This event was already assigned.'), findsOneWidget);
    expect(find.text('Location: I-80 mile 12'), findsOneWidget);
    // Pump past the AppFeedback auto-dismiss timer (3s).
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'SRS 11.2 filters: current vehicle is matched on documented fields, date is local',
    (tester) async {
      backend = _Backend(
        rows: List.of(rows),
        rejectedRows: List.of(rejectedRows),
      );
      await pump(tester);
      await tester.pumpAndSettle();
      // Only the active tab is fetched; no undocumented vehicle query param.
      expect(backend.tabsRequested, [UnidentifiedTab.unclaimed]);

      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          CheckedPopupMenuItem<String>,
          'Current vehicle only',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Current vehicle'), findsOneWidget);
      expect(find.text('Location: I-80 mile 12'), findsOneWidget);
      expect(find.text('Location: Yard'), findsNothing);

      // Clear → reloads without the vehicle filter.
      await tester.tap(find.byIcon(Icons.filter_alt));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(PopupMenuItem<String>, 'Clear filters'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Current vehicle'), findsNothing);
      expect(backend.tabsRequested.last, UnidentifiedTab.unclaimed);
    },
  );
}
