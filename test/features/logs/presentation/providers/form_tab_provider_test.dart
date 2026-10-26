import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/codriver/domain/entities/codriver.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:golden_feather_eld/features/logs/data/providers/log_repository_providers.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_form_data.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/form_tab_provider.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/logs_provider.dart';
import 'package:golden_feather_eld/features/vehicle/domain/entities/vehicle.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements LogRepository {}

/// A previous day's vehicle/co-driver choice belongs to that day's form; only
/// today's choice may touch the live dashboard (no cross-day bleed).
void main() {
  setUpAll(() {
    registerFallbackValue(const DailyLogId(0));
    registerFallbackValue(DateTime(2026));
  });

  late _Repo repo;
  late ProviderContainer container;

  final oldLog = DailyLog(
    id: const DailyLogId(77),
    uniqueId: 'TRK-OLD',
    date: DateTime(2026, 9, 20),
    totalDrivingHours: 0,
    isFormComplete: false,
    isCertified: false,
    vehicleName: 'Old Truck',
  );

  final todayLog = DailyLog(
    id: const DailyLogId(78),
    date: DateTime(2026, 9, 24),
    totalDrivingHours: 0,
    isFormComplete: false,
    isCertified: false,
    today: true,
  );

  const savedForm = DailyFormData(
    vehicleUniqueId: 'TRK-OLD',
    vehicleName: 'Old Truck',
    coDriverId: 7,
    coDriverName: 'Old Co',
    trailers: ['SRV-1'],
    shippingDocuments: ['SRV-DOC'],
  );

  const pickedVehicle = Vehicle(
    id: '666',
    uniqueId: '666',
    name: 'New Truck',
    year: '2026',
  );
  const pickedCoDriver = CoDriver(id: '55', name: 'New Co');

  Future<void> setUpContainer(DailyLog selected) async {
    repo = _Repo();
    when(
      () => repo.getEvents(any(), any()),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => repo.getLogById(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    when(() => repo.getForm(any())).thenAnswer((invocation) async {
      final id = invocation.positionalArguments.first as DailyLogId;
      return id == oldLog.id
          ? const Right<Failure, DailyFormData?>(savedForm)
          : const Right<Failure, DailyFormData?>(null);
    });

    container = ProviderContainer(
      overrides: [
        logRepositoryProvider.overrideWithValue(repo),
        logsProvider.overrideWith((ref) => LogsNotifier(repo, null)),
        dashboardDataProvider.overrideWith((ref) => DashboardNotifier()),
      ],
    );
    final logsSub = container.listen(logsProvider, (_, __) {});
    final formSub = container.listen(formTabProvider(selected), (_, __) {});
    addTearDown(() {
      formSub.close();
      logsSub.close();
      container.dispose();
    });

    container.read(logsProvider.notifier).selectLog(selected);
    await Future<void>.delayed(Duration.zero);
  }

  test('a previous day keeps its own vehicle and co-driver', () async {
    await setUpContainer(oldLog);
    final dashboardBefore = container.read(dashboardDataProvider);

    final notifier = container.read(formTabProvider(oldLog).notifier);
    notifier.updateVehicle(pickedVehicle);
    notifier.updateCoDriver(pickedCoDriver);

    final data = container.read(formTabDataProvider);
    expect(data.vehicleUniqueId, '666');
    expect(data.vehicleName, '666 | 2026 | New Truck');
    expect(data.coDriverId, '55');
    expect(data.coDriverName, 'New Co');
    expect(data.trailers, 'SRV-1');
    expect(data.shippingDocuments, 'SRV-DOC');

    final update = data.toDailyFormUpdate(fallbackLogUniqueId: oldLog.uniqueId);
    expect(update.vehicleUniqueId, '666');
    expect(update.coDriverId, 55);
    expect(update.trailers, ['SRV-1']);
    expect(update.shippingDocuments, ['SRV-DOC']);

    expect(
      container.read(dashboardDataProvider),
      dashboardBefore,
      reason: 'editing a previous day must not touch the live dashboard',
    );
  });

  test('today still writes the live dashboard', () async {
    await setUpContainer(todayLog);

    final notifier = container.read(formTabProvider(todayLog).notifier);
    notifier.updateVehicle(pickedVehicle);
    notifier.updateCoDriver(pickedCoDriver);

    final dashboard = container.read(dashboardDataProvider);
    expect(dashboard.vehicleId, '666');
    expect(dashboard.vehicleDisplayName, '666 | 2026 | New Truck');
    expect(dashboard.coDriverId, '55');
    expect(dashboard.coDriverName, 'New Co');
    expect(container.read(logsProvider).serverForm, isNull);

    final data = container.read(formTabDataProvider);
    expect(data.vehicleUniqueId, '666');
    expect(data.coDriverId, '55');
  });
}
