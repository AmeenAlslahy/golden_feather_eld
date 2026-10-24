import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../logs/data/providers/log_repository_providers.dart';
import '../../domain/repositories/duty_period_store.dart';
import '../repositories/log_duty_period_store.dart';

final dutyPeriodStoreProvider = Provider<DutyPeriodStore>((ref) {
  return LogDutyPeriodStore(ref.watch(logRepositoryProvider));
});
