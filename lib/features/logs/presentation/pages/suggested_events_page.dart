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
    final logsState = ref.watch(logsProvider);
    final pendingLogs = ref.watch(pendingSuggestedLogsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GoldenAppBar(
        titleText: context.loc.suggestedEvents,
        variant: GoldenAppBarVariant.brand,
        leading: const BackButton(),
      ),
      body: logsState.isLoading && pendingLogs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : logsState.error != null && pendingLogs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    child: EldRetryView(
                      message: logsState.error!,
                      onRetry: () => ref
                          .read(logsProvider.notifier)
                          .loadLogs(refresh: true),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (pendingLogs.isNotEmpty) ...[
                        // Contextual Page-Level Warning
                        () {
                          final hasRecertification = pendingLogs.any(
                            (l) =>
                                l.certificationStatus ==
                                CertificationStatus.reCertificationRequired,
                          );
                          if (hasRecertification) {
                            return EldCard(
                              color: context.warningContainer,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: context.warning,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      context.loc.reCertificationRequiredMsg,
                                      style: context.styles.bodyBold.copyWith(
                                        color: context.warning,
                                        fontSize: 13,
                                        fontWeight: AppTypography.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return EldCard(
                            color: context.gold.withValues(alpha: 0.08),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: context.gold,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    context.loc.carrierProposedEdits39530Are,
                                    style: context.styles.caption.copyWith(
                                      fontWeight: AppTypography.medium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }(),
                        const SizedBox(height: AppSpacing.sm),

                        // Suggested Event Cards
                        for (final log in pendingLogs) ...[
                          SuggestedLogCard(
                            log: log,
                            onTap: () => _onLogSelected(context, ref, log),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        const SizedBox(height: AppSpacing.xs),
                        EldFooterNotice(
                          message: context
                              .loc.unidentifiedDrivingIsReviewedInUnidentified,
                          icon: Icons.info_outline,
                        ),
                      ] else ...[
                        // Empty State
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xl,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: context.successContainer
                                      .withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.verified_outlined,
                                  size: 36,
                                  color: context.success,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                context.loc.noRecords,
                                style: context.styles.cardTitle.copyWith(
                                  fontWeight: AppTypography.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                child: Text(
                                  context.loc.carrierProposedEdits39530Are,
                                  textAlign: TextAlign.center,
                                  style: context.styles.caption.copyWith(
                                    color: context.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        EldFooterNotice(
                          message: context
                              .loc.unidentifiedDrivingIsReviewedInUnidentified,
                          icon: Icons.info_outline,
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

