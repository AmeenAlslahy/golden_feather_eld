import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/duty_status/weekly_recap.dart';
import '../../data/providers/status_dashboard_repository_providers.dart';
import '../../domain/usecases/get_weekly_recap_use_case.dart';
import '../../../../core/events/app_events.dart';

final getWeeklyRecapUseCaseProvider = Provider<GetWeeklyRecapUseCase>((ref) {
  return GetWeeklyRecapUseCase(ref.watch(statusDashboardRepositoryProvider));
});

final recapProvider = FutureProvider<WeeklyRecap>((ref) async {
  ref.keepAlive();
  
  final bus = ref.watch(appEventBusProvider);
  final sub = bus.stream.listen((event) {
    if (event == AppEvent.logDataChanged) {
      ref.invalidateSelf();
    }
  });
  ref.onDispose(sub.cancel);

  final getWeeklyRecapUseCase = ref.watch(getWeeklyRecapUseCaseProvider);

  final result = await getWeeklyRecapUseCase.execute();
  return result.fold(
    (failure) => throw failure,
    (recap) => recap,
  );
});
