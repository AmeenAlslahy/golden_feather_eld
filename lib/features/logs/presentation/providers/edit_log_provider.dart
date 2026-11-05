import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/logger.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import '../../../../core/time/time_authority_provider.dart';
import '../../../../core/di/id_generator_provider.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/entities/audit_entry.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/log_edit.dart';
import 'logs_provider.dart';
import 'edit_log_form_provider.dart';
import '../../data/providers/log_repository_providers.dart';

enum EditLogErrorCode {
  invalidTime,
  futureTime,
  autoDrivingRefused,
  saveFailed,
  auditFailed,
  authMissing,
  overlapConflict,
}

class EditLogError implements Exception {
  final EditLogErrorCode code;
  EditLogError(this.code);
}

/// تحويل كود الخطأ إلى رسالة مترجمة واضحة للمستخدم
String editLogErrorUserMessage(Object? error, AppLocalizations loc) {
  if (error is EditLogError) {
    switch (error.code) {
      case EditLogErrorCode.invalidTime:
        return loc.invalidValue;
      case EditLogErrorCode.futureTime:
        return loc.eventCannotBeInFuture;
      case EditLogErrorCode.autoDrivingRefused:
        return loc.automaticDrivingTimeCannotBeShortened;
      case EditLogErrorCode.saveFailed:
        return loc.theEventCouldNotBeSaved;
      case EditLogErrorCode.auditFailed:
        return loc.theEventWasSavedButThe;
      case EditLogErrorCode.authMissing:
        return loc.sessionMissing;
      case EditLogErrorCode.overlapConflict:
        return loc.eventTimeOverlap;
    }
  }
  return loc.theEventCouldNotBeSaved;
}

class EditLogNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// إرسال وحفظ الحدث استناداً إلى حالة النموذج الحالية
  Future<void> submit({
    required bool isNewEvent,
    required LogEvent? existing,
  }) async {
    final formState = ref.read(editLogFormProvider(existing));
    await saveEvent(
      isNewEvent: isNewEvent,
      existing: existing,
      selectedStatus: formState.selectedStatus,
      startTimeStr: formState.startTime,
      durationStr: formState.duration,
      location: formState.location,
      reason: formState.reason,
    );
  }

  Future<void> saveEvent({
    required bool isNewEvent,
    required LogEvent? existing,
    required String selectedStatus,
    required String startTimeStr,
    required String durationStr,
    required String location,
    required String reason,
  }) async {
    state = const AsyncLoading();
    try {
      final logsState = ref.read(logsProvider);
      final selectedLog = logsState.selectedLog;
      final status = selectedStatus;
      final timeAuthority = ref.read(timeAuthorityProvider);
      final parsedTime = parseEditFormTime(
        startTimeStr,
        selectedLog?.date,
        timeAuthority.nowUtc().toLocal(),
      );

      if (parsedTime == null) {
        throw EditLogError(EditLogErrorCode.invalidTime);
      }

      // المدة التي رآها السائق في النموذج هي ما يُرسل، لا المدة القديمة
      // للحدث. تغيير البداية يغيّر المدة المحسوبة دون تعديل الحدث نفسه.
      final parsedDuration = parseEditFormDuration(durationStr);
      if (parsedDuration == null) {
        throw EditLogError(EditLogErrorCode.invalidTime);
      }

      final newStart = parsedTime;
      final normalizedLocation = isPlaceholderLocation(location)
          ? ''
          : location.trim();

      // FMCSA § 395: Duty status events cannot be recorded in the future
      if (newStart.isAfter(
        timeAuthority.nowUtc().toLocal().add(const Duration(minutes: 1)),
      )) {
        throw EditLogError(EditLogErrorCode.futureTime);
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

      // التحقق من عدم التداخل مع أحداث أخرى مسجلة في نفس اليوم
      if (selectedLog != null && parsedDuration > Duration.zero) {
        final otherEvents = existing == null
            ? selectedLog.events
            : selectedLog.events.where((e) => e.id != existing.id).toList();
        final newEnd = newStart.add(parsedDuration);
        for (final other in otherEvents) {
          if (other.duration > Duration.zero) {
            final otherEnd = other.startTime.add(other.duration);
            if (newStart.isBefore(otherEnd) && other.startTime.isBefore(newEnd)) {
              throw EditLogError(EditLogErrorCode.overlapConflict);
            }
          }
        }
      }

      final idGenerator = ref.read(idGeneratorProvider);

      final updatedEvent =
          existing?.copyWith(
            status: status,
            startTime: newStart,
            duration: parsedDuration,
            location: normalizedLocation,
          ) ??
          LogEvent(
            id: idGenerator.v4(),
            status: status,
            startTime: newStart,
            duration: parsedDuration,
            location: normalizedLocation,
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

      final failure = result.fold((f) => f, (_) => null);
      if (failure != null) {
        final msg = failure.message.toLowerCase();
        if (msg.contains('overlap') || msg.contains('no_overlap')) {
          throw EditLogError(EditLogErrorCode.overlapConflict);
        }
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
      final auditSaved = (await repo.logAudit(
        entry,
      )).fold((_) => false, (ok) => ok);
      if (!auditSaved) {
        // الحدث محفوظ فعلاً — فشل التدقيق لا يُكذب على السائق برسالة
        // "فشل الحفظ" (تناقض بيانات مؤكد بالمراجعة). يُسجَّل للتشخيص
        // وتنجح العملية.
        AppLogger.warning(
          'Edit-log audit trail not saved (event ${isNewEvent ? 'created' : 'updated'} '
          'persisted): driverId=$driverId newStatus=$status',
        );
      }

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// موفر تعديل السجل
final editLogProvider = AutoDisposeAsyncNotifierProvider<EditLogNotifier, void>(
  () {
    return EditLogNotifier();
  },
);

/// اسم بديل للتوافق البرمجي الكامل مع الكود القائم
final editLogControllerProvider = editLogProvider;
typedef EditLogController = EditLogNotifier;
