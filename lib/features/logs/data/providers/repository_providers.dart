import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/contracts/daily_logs_backend.dart';
import '../../../../backend/providers/backend_providers.dart';

final logBackendProviderAlias = Provider<DailyLogsBackend>((ref) {
  return ref.watch(dailyLogsBackendProvider);
});
