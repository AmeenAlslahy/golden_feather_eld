import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system.dart';
import '../../../../routes.dart';
import '../../domain/entities/daily_log.dart';
import '../providers/log_detail_tab_provider.dart';
import '../providers/logs_provider.dart';
import '../providers/suggested_events_provider.dart';
import '../widgets/suggested_log_card.dart';

/// SRS 6.6 / §395.30: Central review hub for carrier-proposed edits and pending actions.
class SuggestedEventsPage extends ConsumerWidget {
  const SuggestedEventsPage({super.key});

  void _onLogSelected(BuildContext context, WidgetRef ref, DailyLog log) {
    ref.read(logsProvider.notifier).selectLog(log);
    ref.read(logDetailTabProvider.notifier).state = LogDetailTab.certify.index;
    context.push(AppRoutes.logDetailPath(log.id.value));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingLogs = ref.watch(pendingSuggestedLogsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.loc.suggestedEvents,
          style: context.styles.appBarTitle,
        ),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (pendingLogs.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.warningContainer,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: context.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: context.warning,
                      size: AppSpacing.iconMedium,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        context.loc.reCertificationRequiredMsg,
                        style: context.styles.bodyBold.copyWith(
                          color: context.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final log in pendingLogs) ...[
                SuggestedLogCard(
                  log: log,
                  onTap: () => _onLogSelected(context, ref, log),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: context.successContainer.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified_outlined,
                        size: 40,
                        color: context.success,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      context.loc.noRecords,
                      style: context.styles.sectionTitle,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        context.loc.carrierProposedEdits39530Are,
                        textAlign: TextAlign.center,
                        style: context.styles.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            EldFooterNotice(
              message: context.loc.unidentifiedDrivingIsReviewedInUnidentified,
              icon: Icons.info_outline,
            ),
          ],
        ),
      ),
    );
  }
}
