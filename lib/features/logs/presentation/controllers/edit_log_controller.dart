import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/time/time_authority_provider.dart';
import '../../../../core/di/id_generator_provider.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/entities/audit_entry.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/log_edit.dart';
import '../providers/logs_provider.dart';
import '../../data/providers/log_repository_providers.dart';

enum EditLogErrorCode {
  invalidTime,
  autoDrivingRefused,
  saveFailed,
  auditFailed,
  authMissing,
}

class EditLogError implements Exception {
  final EditLogErrorCode code;
  EditLogError(this.code);
}

class EditLogController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> saveEvent({
    required bool isNewEvent,
    required LogEvent? existing,
    required String selectedStatus,
    required String startTimeStr,
    required String location,
    required String reason,
  }) async {
    state = const AsyncLoading();
    try {
      final logsState = ref.read(logsProvider);
      final selectedLog = logsState.selectedLog;
      final status = selectedStatus;
      final parsedTime = parseEditFormTime(startTimeStr, selectedLog?.date);

      if (parsedTime == null) {
        throw EditLogError(EditLogErrorCode.invalidTime);
      }

      final newStart = parsedTime;
      final timeAuthority = ref.read(timeAuthorityProvider);

      // FMCSA § 395: Duty status events cannot be recorded in the future
      if (newStart.isAfter(timeAuthority.nowUtc().toLocal().add(const Duration(minutes: 1)))) {
        throw EditLogError(EditLogErrorCode.invalidTime);
      }

      if (existing != null) {
        final refusal = refuseAutomaticDrivingEdit(
          original: existing,
          newStatusCode: status,
          newStart: newStart,
        );
        if (refusal != null) {
          throw EditLogError(EditLogErrorCode.autoDrivingRefused);
        }
      }

      final idGenerator = ref.read(idGeneratorProvider);
      
      final updatedEvent = existing?.copyWith(
            status: status,
            startTime: newStart,
            location: location,
          ) ??
          LogEvent(
            id: idGenerator.v4(),
            status: status,
            startTime: newStart,
            duration: Duration.zero,
            location: location,
          );

      final authState = ref.read(authStateProvider);
      final driverId = authState.user?.id;
      if (driverId == null || driverId.isEmpty) {
        throw EditLogError(EditLogErrorCode.authMissing);
      }

      final notifier = ref.read(logsProvider.notifier);
      final result = isNewEvent
          ? await notifier.addEvent(updatedEvent, reason: reason)
          : await notifier.updateEvent(updatedEvent, reason: reason);
          
      final saveFailed = result.fold((_) => true, (_) => false);
      if (saveFailed) {
        throw EditLogError(EditLogErrorCode.saveFailed);
      }

      final entry = AuditEntry(
        id: idGenerator.v4(),
        timestamp: timeAuthority.nowUtc(),
        driverId: driverId,
        oldStatus: isNewEvent ? null : existing?.status,
        newStatus: status,
        reason: reason,
      );

      final repo = ref.read(logRepositoryProvider);
      final auditSaved = (await repo.logAudit(entry)).fold((_) => false, (ok) => ok);
      if (!auditSaved) {
        throw EditLogError(EditLogErrorCode.auditFailed);
      }

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final editLogControllerProvider = AutoDisposeAsyncNotifierProvider<EditLogController, void>(() {
  return EditLogController();
});
