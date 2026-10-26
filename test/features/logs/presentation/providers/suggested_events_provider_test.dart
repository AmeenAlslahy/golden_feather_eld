import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/logs_provider.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/suggested_events_provider.dart';

class _FakeLogsNotifier extends StateNotifier<LogsState>
    implements LogsNotifier {
  _FakeLogsNotifier(super.state);

  @override
  void selectLog(DailyLog log) {
    state = state.copyWith(selectedLog: log);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DailyLog _makeLog({
  required int id,
  bool requiresAction = false,
  CertificationStatus certificationStatus = CertificationStatus.certified,
}) {
  return DailyLog(
    id: DailyLogId(id),
    date: DateTime(2026, 10, 24),
    totalDrivingHours: 4.5,
    isFormComplete: true,
    isCertified: certificationStatus == CertificationStatus.certified,
    requiresAction: requiresAction,
    certificationStatus: certificationStatus,
  );
}

void main() {
  test(
    'pendingSuggestedLogsProvider filters only logs requiring action or re-certification',
    () {
      final normalLog = _makeLog(id: 1);
      final actionLog = _makeLog(id: 2, requiresAction: true);
      final recertLog = _makeLog(
        id: 3,
        certificationStatus: CertificationStatus.reCertificationRequired,
      );

      final container = ProviderContainer(
        overrides: [
          logsProvider.overrideWith(
            (ref) => _FakeLogsNotifier(
              LogsState(logs: [normalLog, actionLog, recertLog]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final pending = container.read(pendingSuggestedLogsProvider);
      expect(pending, hasLength(2));
      expect(pending, containsAll([actionLog, recertLog]));
      expect(pending, isNot(contains(normalLog)));
    },
  );

  test(
    'pendingSuggestedLogsProvider returns empty list when no logs match',
    () {
      final normalLog = _makeLog(id: 1);
      final container = ProviderContainer(
        overrides: [
          logsProvider.overrideWith(
            (ref) => _FakeLogsNotifier(LogsState(logs: [normalLog])),
          ),
        ],
      );
      addTearDown(container.dispose);

      final pending = container.read(pendingSuggestedLogsProvider);
      expect(pending, isEmpty);
    },
  );
}
