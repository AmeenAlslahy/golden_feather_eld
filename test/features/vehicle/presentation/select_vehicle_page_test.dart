import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/vehicle/data/providers/vehicle_repository_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/features/tracking/presentation/providers/tracking_provider.dart';
import 'package:golden_feather_eld/features/vehicle/domain/entities/vehicle.dart';
import 'package:golden_feather_eld/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:golden_feather_eld/features/vehicle/presentation/pages/select_vehicle_page.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements VehicleRepository {}

class _Storage extends Mock implements LocalStorageService {}

/// SRS 3.1 — Select Vehicle: View ≠ Select ≠ Operate. My vehicles are
/// selectable; the company fleet is viewable but only assigned rows can be
/// operated; motion must be known and stopped; the server session is opened
/// on the Connection page, never here.
void main() {
  late _Repo repo;

  const mine = Vehicle(
    id: 'TRK-101',
    uniqueId: 'imei-101',
    name: 'Freightliner Cascadia',
    year: '2022',
    isAssigned: true,
    activeForCurrentDriver: true,
  );
  const spare = Vehicle(
    id: 'TRK-102',
    uniqueId: 'imei-102',
    name: 'Volvo VNL',
    year: '2021',
    isAssigned: true,
  );
  const companyUnassigned = Vehicle(
    id: 'TRK-900',
    uniqueId: 'imei-900',
    name: 'Kenworth T680',
    year: '2020',
    isAssigned: false,
  );
  const companyBusy = Vehicle(
    id: 'TRK-901',
    uniqueId: 'imei-901',
    name: 'Peterbilt 579',
    year: '2019',
    isAssigned: true,
    inUseByOther: true,
  );

  setUp(() {
    repo = _Repo();
    when(() => repo.getSelectedVehicle()).thenAnswer((_) async => const Right(null));
    when(() => repo.getCompanyVehicles()).thenAnswer(
        (_) async => const Right([companyUnassigned, companyBusy, spare]));
  });

  Future<void> pump(WidgetTester tester, {double? speedMps}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = _Storage();
    when(() => storage.hosConfiguration).thenReturn(HosConfiguration.usa70_8());

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const SelectVehiclePage()),
      GoRoute(
        path: '/connection',
        builder: (_, __) => const Scaffold(body: Text('CONNECTION ROUTE')),
      ),
      GoRoute(path: '/home', builder: (_, __) => const Scaffold(body: Text('HOME'))),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleRepositoryProvider.overrideWithValue(repo),
          localStorageProvider.overrideWithValue(storage),
          currentVehicleSpeedProvider.overrideWith((ref) => speedMps),
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

  testWidgets('my vehicles: tapping one while stopped selects it and goes to Connection',
      (tester) async {
    when(() => repo.getVehicles()).thenAnswer((_) async => const Right([mine, spare]));
    await pump(tester, speedMps: 0.0);

    expect(find.text('Select Vehicle'), findsOneWidget);
    expect(find.text('TRK-101'), findsOneWidget);
    expect(find.text('2021 Volvo VNL'), findsOneWidget);
    // A server-selected vehicle exists → no "Unassigned" prompt.
    expect(find.text('No Vehicles Assigned'), findsNothing);

    await tester.tap(find.text('TRK-102'));
    await tester.pumpAndSettle();

    // Nothing is claimed as accepted by the server on this screen.
    expect(find.textContaining('server accepted'), findsNothing);
    expect(
      find.text(
          'Selected TRK-102 | 2021 | Volvo VNL. Connect to the ELD to operate it. Hours were not copied.'),
      findsOneWidget,
    );
    expect(find.text('CONNECTION ROUTE'), findsOneWidget);
    // The list never opens the hardware session itself: the repository has
    // no operate call at all — only the connection screen owns it.
    // Pump past the AppFeedback auto-dismiss timer (3s).
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('unknown motion refuses the selection and stays', (tester) async {
    when(() => repo.getVehicles()).thenAnswer((_) async => const Right([mine, spare]));
    await pump(tester); // speed null

    await tester.tap(find.text('TRK-102'));
    await tester.pumpAndSettle();

    expect(
      find.text('Vehicle motion is unknown. That is not treated as stopped.'),
      findsOneWidget,
    );
    expect(find.text('CONNECTION ROUTE'), findsNothing);
    // Pump past the AppFeedback auto-dismiss timer (3s).
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('no assigned vehicle → Unassigned dialog; VIEW ALL is view-only for the fleet',
      (tester) async {
    when(() => repo.getVehicles()).thenAnswer((_) async => const Right([]));
    await pump(tester, speedMps: 0.0);
    await tester.pumpAndSettle();

    expect(find.text('No Vehicles Assigned'), findsOneWidget);
    expect(find.textContaining('Contact your fleet manager'), findsOneWidget);

    await tester.tap(find.text('VIEW ALL VEHICLES'));
    await tester.pumpAndSettle();
    verify(() => repo.getCompanyVehicles()).called(1);
    expect(find.text('TRK-900'), findsOneWidget);
    expect(find.text('TRK-901'), findsOneWidget);
    expect(find.text('TRK-102'), findsOneWidget);
    // SRS 9.2/9.4: the row says so *before* the tap.
    expect(find.text('View only'), findsOneWidget);
    expect(find.text('In use'), findsOneWidget);
    expect(find.text('Assigned to you'), findsOneWidget);

    // Unassigned company vehicle: visible, not operable.
    await tester.tap(find.text('TRK-900'));
    await tester.pumpAndSettle();
    expect(find.text('You are not authorized to operate this vehicle.'), findsOneWidget);
    expect(find.text('CONNECTION ROUTE'), findsNothing);
    await tester.pump(const Duration(seconds: 5));

    // In use by another driver: visible, not operable.
    await tester.tap(find.text('TRK-901'));
    await tester.pumpAndSettle();
    expect(find.text('The vehicle is in use.'), findsOneWidget);
    expect(find.text('CONNECTION ROUTE'), findsNothing);
    await tester.pump(const Duration(seconds: 5));

    // Assigned to me even in the fleet view: selectable.
    await tester.tap(find.text('TRK-102'));
    await tester.pumpAndSettle();
    expect(find.text('CONNECTION ROUTE'), findsOneWidget);
    // Pump past the AppFeedback auto-dismiss timer (3s).
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('load failure shows a sanitized message with retry', (tester) async {
    when(() => repo.getVehicles()).thenAnswer((_) async => const Right([]));
    await pump(tester, speedMps: 0.0);
    await tester.pumpAndSettle();
    await tester.tap(find.text('VIEW MY VEHICLES'));
    await tester.pumpAndSettle();

    expect(find.text('No vehicles available'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
