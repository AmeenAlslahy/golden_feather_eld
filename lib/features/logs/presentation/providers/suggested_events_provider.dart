import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/daily_log.dart';
import 'logs_provider.dart';

/// Provider for daily logs requiring re-certification or carrier-suggested edit actions.
/// Decouples filtering logic from presentation widgets.
final pendingSuggestedLogsProvider = Provider<List<DailyLog>>((ref) {
  final logsState = ref.watch(logsProvider);
  return logsState.logs
      .where(
        (log) =>
            log.requiresAction ||
            log.certificationStatus ==
                CertificationStatus.reCertificationRequired,
      )
      .toList();
});
