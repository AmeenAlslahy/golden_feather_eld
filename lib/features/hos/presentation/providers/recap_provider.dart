import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../logs/data/repositories/log_repository_impl.dart';
import '../../domain/entities/recap_data.dart';

import 'hos_provider.dart';

import '../../../../features/hos/domain/engine/hos_state_machine.dart';
import '../../domain/usecases/get_recap_use_case.dart';

final getRecapUseCaseProvider = Provider<GetRecapUseCase>((ref) {
  final logRepo = ref.watch(logRepositoryProvider);
  return GetRecapUseCase(logRepo);
});

final recapProvider = FutureProvider<RecapData>((ref) async {
  // Add keepAlive to cache the recap calculation unless invalidated
  ref.keepAlive();
  
  final getRecapUseCase = ref.watch(getRecapUseCaseProvider);
  final hosStatus = ref.watch(hosStatusProvider);
  final config = ref.watch(hosConfigurationProvider);

  return getRecapUseCase.execute(
    currentLimits: hosStatus.limits,
    cycleLimitHours: config.cycleLimitHours.toDouble(),
  );
});
