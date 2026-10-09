import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../routes.dart';
import '../../domain/entities/daily_log.dart';
import '../providers/logs_provider.dart';
import '../providers/log_detail_tab_provider.dart';

/// SRS 6.6 / §395.30: Central review hub for carrier-proposed edits and pending actions.
class SuggestedEventsPage extends ConsumerWidget {
  const SuggestedEventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsState = ref.watch(logsProvider);
    final pendingLogs = logsState.logs
        .where(
          (log) =>
              log.requiresAction ||
              log.certificationStatus ==
                  CertificationStatus.reCertificationRequired,
        )
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.loc.suggestedEvents,
          style: context.styles.appBarTitle,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.loc.carrierProposedEdits39530Are,
              key: const Key('suggested_events_carrier_hint'),
              textAlign: TextAlign.center,
              style: context.styles.body,
            ),
            const SizedBox(height: AppSpacing.md),
            if (pendingLogs.isNotEmpty) ...[
              Text(
                context.loc.reCertificationRequiredMsg,
                style: context.styles.sectionTitle.copyWith(
                  color: AppColors.warningYellow,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...pendingLogs.map(
                (log) => Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  color: Theme.of(context).colorScheme.surface,
                  child: ListTile(
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warningYellow,
                    ),
                    title: Text(
                      log.formattedDate,
                      style: context.styles.bodyBold,
                    ),
                    subtitle: Text(
                      log.certificationStatus ==
                              CertificationStatus.reCertificationRequired
                          ? context.loc.reCertificationRequiredMsg
                          : context.loc.carrierProposedEdit,
                      style: context.styles.subtitle,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ref.read(logsProvider.notifier).selectLog(log);
                      ref.read(logDetailTabProvider.notifier).state = 2; // Certify tab
                      context.push(
                        AppRoutes.logDetail.replaceAll(
                          ':id',
                          log.id.value.toString(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(
              context.loc.unidentifiedDrivingIsReviewedInUnidentified,
              textAlign: TextAlign.center,
              style: context.styles.body,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: context.loc.logsTitle,
              type: EldButtonType.primary,
              onPressed: () => context.go(AppRoutes.logs),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: context.loc.unidentifiedEvents,
              type: EldButtonType.secondary,
              onPressed: () => context.push(AppRoutes.unidentifiedEvents),
            ),
          ],
        ),
      ),
    );
  }
}
