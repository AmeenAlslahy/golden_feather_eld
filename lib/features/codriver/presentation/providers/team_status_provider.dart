import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/team_status.dart';

export '../../domain/team_status.dart';

/// Team status (`GET /eld/daily-logs/{id}/team`) is not part of the adopted
/// 12-route Daily Logs API surface, so there is nothing to show.
final teamStatusProvider = FutureProvider.autoDispose<TeamStatus?>(
  (ref) async => null,
);
