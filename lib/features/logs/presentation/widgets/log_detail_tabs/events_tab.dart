import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/daily_log.dart';
import '../../../domain/log_day_slice.dart';
import '../../../../../../domain/duty_status/duty_status_code.dart';
import '../../providers/logs_provider.dart';
import '../../widgets/log_graph.dart';
import 'log_event_tile.dart';
import '../../../../../../routes.dart';
import '../../../../../../core/error/user_facing_message.dart';
import '../../../../../../core/extensions/context_extensions.dart';
import '../../../../../../core/widgets/eld_retry_view.dart';
import '../../../../../../l10n/app_localizations.dart';

/// SRS 5.2 — Graph-Grid + the day's duty-status events.
///
/// Events are fetched when the log is opened (`selectLog`); this tab renders
/// loading / failure / empty / data from [LogsState].
class EventsTab extends ConsumerWidget {
  final DailyLog selectedLog;

  const EventsTab({super.key, required this.selectedLog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsState = ref.watch(logsProvider);
    final events = selectedLog.events;

    if (events.isEmpty) {
      if (logsState.isLoadingEvents) {
        return const Center(child: CircularProgressIndicator());
      }
      if (logsState.eventsError != null) {
        return EldRetryView(
          message: anyErrorUserMessage(
            logsState.eventsError!,
            loc: AppLocalizations.of(context)!,
          ),
          onRetry: () =>
              ref.read(logsProvider.notifier).loadSelectedLogEvents(),
        );
      }
      final empty = EldRetryView(
        message: selectedLog.today
            ? context.loc.noRecordsToday
            : context.loc.noRecords,
        isError: false,
        onRetry: () => ref.read(logsProvider.notifier).loadSelectedLogEvents(),
      );
      if (!logsState.eventsFromSavedData) return empty;
      return Column(
        children: [
          const _SavedDataBanner(),
          Expanded(child: empty),
        ],
      );
    }

    return Column(
      children: [
        if (logsState.eventsPendingConfirmation) const _UnconfirmedBanner(),
        if (logsState.eventsFromSavedData) const _SavedDataBanner(),
        Directionality(
          textDirection: TextDirection.ltr,
          child: LogGraph(events: events, logDate: selectedLog.date),
        ),
        _StatusTotalsRow(events: events, logDate: selectedLog.date),
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(logsProvider.notifier).loadSelectedLogEvents(),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return LogEventTile(
                    event: event,
                    logDate: selectedLog.date,
                    onTap: () {
                      ref
                          .read(logsProvider.notifier)
                          .toggleEventExpansion(event.id);
                    },
                    // SRS 5.2 / §395.30(b): automatically recorded driving
                    // and server-locked events have no pencil at all.
                    onEdit:
                        (event.automatedDriving == true ||
                            event.editable == false)
                        ? null
                        : () {
                            context.push(
                              AppRoutes.editLog.replaceAll(':id', event.id),
                              extra: event,
                            );
                          },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// تنبيه أن آخر تعديل قُبل من الخادم لكن دون echo قابل للتحليل؛ لا
/// ندّعي نجاحاً كاملاً ولا نمحو تعديل المستخدم.
class _UnconfirmedBanner extends StatelessWidget {
  const _UnconfirmedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('events_unconfirmed_banner'),
      width: double.infinity,
      color: context.warningContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.compact,
        vertical: 6,
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: AppSpacing.iconSmall,
            color: context.warning,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              context.loc.statusSavedUnconfirmed,
              style: context.styles.caption.copyWith(color: context.warning),
            ),
          ),
        ],
      ),
    );
  }
}

/// SRS 5.2 — hour totals per duty status under the Graph-Grid
/// (the "Total" column of the paper grid).
/// تنبيه أن الأحداث المعروضة محفوظة على الجهاز/الكاش وليست تأكيداً
/// حديثاً من الخادم.
class _SavedDataBanner extends StatelessWidget {
  const _SavedDataBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('events_saved_data_banner'),
      width: double.infinity,
      color: context.warningContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.compact,
        vertical: 6,
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: AppSpacing.iconSmall,
            color: context.warning,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              context.loc.eventsShowingSavedData,
              style: context.styles.caption.copyWith(color: context.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTotalsRow extends StatelessWidget {
  const _StatusTotalsRow({required this.events, required this.logDate});

  final List<LogEvent> events;
  final DateTime logDate;

  static const _order = ['OFF', 'SB', 'D', 'ON'];

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final totals = <String, Duration>{for (final s in _order) s: Duration.zero};
    for (final e in events) {
      // نفس القصّ الذي يرسمه المخطط: حدث بدأ أمس لا يُجمع بكامله على
      // يوم السجل. بلا ذلك يعرض الرسم 2h45 بينما يجمع الصف 8h45.
      final slice = sliceLogEventToDay(e, logDate);
      if (slice == null) continue;
      // PC counts as OFF and YM as ON for the daily totals (§395.28).
      final key = DutyStatusCode.normalizeToGridShortCode(e.status);
      if (totals.containsKey(key)) {
        totals[key] = totals[key]! + slice.visibleDuration;
      }
    }
    return Container(
      key: const Key('events_status_totals'),
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.compact,
        vertical: 6,
      ),
      child: Row(
        children: [
          for (final s in _order)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s, style: context.styles.caption),
                  Text(_fmt(totals[s]!), style: context.styles.bodyBold),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
