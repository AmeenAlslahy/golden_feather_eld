import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_repository_providers.dart';
import '../../../../core/domain/duty_status/weekly_recap.dart';
import '../../domain/usecases/get_weekly_recap_use_case.dart';

final getWeeklyRecapUseCaseProvider = Provider<GetWeeklyRecapUseCase>((ref) {
  return GetWeeklyRecapUseCase(ref.watch(statusDashboardRepositoryProvider));
});

final recapProvider = FutureProvider<WeeklyRecap>((ref) async {
  // Add keepAlive to cache the recap calculation unless invalidated
  ref.keepAlive();

  final getWeeklyRecapUseCase = ref.watch(getWeeklyRecapUseCaseProvider);

  final result = await getWeeklyRecapUseCase.execute();
  return result.fold(
    (failure) => throw failure,
    (recap) => recap,
  );
});
