import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/utils/provider_cache.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/team_status.dart';

export '../../domain/team_status.dart';

/// Team status of **today's** daily log (`GET /eld/daily-logs/{id}/team`).
/// Null when the driver has no daily log for today yet — nothing to show.
final teamStatusProvider = FutureProvider.autoDispose<TeamStatus?>((ref) async {
  cacheFor(ref, const Duration(seconds: 30));
  final driverId = ref.watch(currentDriverIdProvider);
  if (driverId == null || driverId <= 0) return null;
  final backend = ref.read(dailyLogsBackendProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final listed = await backend.list(
    driverId: DriverId(driverId),
    startDate: today,
    endDate: today,
    limit: 1,
  );
  final logId = listed.fold<int?>((failure) => throw failure, (json) {
    final items = json['data'];
    if (items is! List || items.isEmpty) return null;
    final first = items.first;
    final id = first is Map ? first['id'] : null;
    return id is num ? id.toInt() : int.tryParse('$id');
  });
  if (logId == null || logId <= 0) return null;

  final result = await backend.getTeamStatus(DailyLogId(logId));
  return result.fold((failure) => throw failure, (json) {
    final read = parseTeamStatus(json);
    if (read == null) throw const FormatException('team body is not an object');
    return read;
  });
});
