import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:golden_feather_eld/features/logs/data/providers/log_repository_providers.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_form_data.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/log_events_snapshot.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log_page.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/logs_provider.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements LogRepository {}

/// The saved `/form` snapshot outranks the list row and the detail endpoint;
/// whichever network response lands first, `/form` must be applied last.
void main() {
  setUpAll(() {
    registerFallbackValue(const DailyLogId(0));
    registerFallbackValue(DateTime(2026));
  });

  late _Repo repo;
  late ProviderContainer container;
  late Completer<Either<Failure, DailyLog>> detail;
  late Completer<Either<Failure, DailyFormData?>> form;

  final today = DailyLog(
    id: const DailyLogId(7),
    uniqueId: 'TRK-7',
    date: DateTime(2026, 9, 24),
    totalDrivingHours: 0,
    isFormComplete: false,
    isCertified: false,
    today: true,
    vehicleName: 'Row Truck',
    trailers: const ['ROW-T'],
    shippingDocuments: const ['ROW-D'],
  );

  setUp(() {
    repo = _Repo();
    detail = Completer<Either<Failure, DailyLog>>();
    form = Completer<Either<Failure, DailyFormData?>>();

    when(
      () => repo.getDailyLogs(
        driverId: any(named: 'driverId'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => Right(DailyLogPage(logs: [today])));
    when(
      () => repo.getEvents(any(), any()),
    ).thenAnswer((_) async => const Right(LogEventsSnapshot.server([])));
    when(() => repo.getLogById(any())).thenAnswer((_) => detail.future);
    when(() => repo.getForm(any())).thenAnswer((_) => form.future);

    container = ProviderContainer(
      overrides: [
        logRepositoryProvider.overrideWithValue(repo),
        currentDriverIdProvider.overrideWithValue(106),
        dashboardDataProvider.overrideWith((ref) => DashboardNotifier()),
        logsProvider.overrideWith((ref) => LogsNotifier(repo, 106, ref)),
      ],
    );
    final sub = container.listen(logsProvider, (_, __) {});
    addTearDown(() {
      sub.close();
      container.dispose();
    });
  });

  Future<void> flush() async {
    for (var i = 0; i < 4; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> selectToday() async {
    await flush(); // allow the initial list load to settle
    container.read(logsProvider.notifier).selectLog(today);
    await flush();
  }

  test('form response arriving before detail still wins', () async {
    await selectToday();

    // الصف يُطبق فوراً حتى تصل الاستجابات.
    expect(container.read(dashboardDataProvider).trailerId, 'ROW-T');

    form.complete(
      const Right(
        DailyFormData(
          vehicleUniqueId: 'TRK-7',
          trailers: ['FORM-T'],
          shippingDocuments: ['FORM-D'],
        ),
      ),
    );
    await flush();
    expect(
      container.read(dashboardDataProvider).trailerId,
      'ROW-T',
      reason: 'form is applied only after detail, in order',
    );

    detail.complete(
      Right(
        today.copyWith(
          trailers: ['DETAIL-T'],
          shippingDocuments: const ['DETAIL-D'],
        ),
      ),
    );
    await flush();

    expect(container.read(dashboardDataProvider).trailerId, 'FORM-T');
    expect(container.read(dashboardDataProvider).shippingDocuments, 'FORM-D');
    expect(container.read(logsProvider).serverForm?.trailers, ['FORM-T']);
  });

  test('form response arriving after detail still wins', () async {
    await selectToday();

    detail.complete(
      Right(
        today.copyWith(
          trailers: ['DETAIL-T'],
          shippingDocuments: const ['DETAIL-D'],
        ),
      ),
    );
    await flush();
    expect(container.read(dashboardDataProvider).trailerId, 'DETAIL-T');

    form.complete(
      const Right(
        DailyFormData(
          vehicleUniqueId: 'TRK-7',
          trailers: ['FORM-T'],
          shippingDocuments: ['FORM-D'],
        ),
      ),
    );
    await flush();

    expect(container.read(dashboardDataProvider).trailerId, 'FORM-T');
    expect(container.read(dashboardDataProvider).shippingDocuments, 'FORM-D');
  });
}
