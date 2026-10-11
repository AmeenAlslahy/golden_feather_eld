import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../inspection/domain/transfer_audit.dart';
import '../../../inspection/presentation/providers/dot_inspection_providers.dart';

/// قسم سجل التدقيق لعمليات نقل بيانات التفتيش
class InspectionAuditTrailSection extends ConsumerWidget {
  const InspectionAuditTrailSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditsAsync = ref.watch(transferAuditProvider);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.transferAuditTitle,
            style: context.styles.bodyBold.copyWith(
              fontSize: AppTypography.subtitleSize,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          auditsAsync.when(
            data: (audits) {
              if (audits.isEmpty) {
                return Text(
                  context.loc.noTransfersFromServer,
                  style: context.styles.subtitle,
                );
              }
              return Column(
                children: [
                  for (final audit in audits) _TransferAuditTile(audit: audit),
                ],
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, _) =>
                Text(context.loc.transferAuditNotLoaded(error.toString())),
          ),
        ],
      ),
    );
  }
}

class _TransferAuditTile extends StatelessWidget {
  final TransferAuditRow audit;
  const _TransferAuditTile({required this.audit});

  @override
  Widget build(BuildContext context) {
    final lines = [
      if (audit.status.isNotEmpty) audit.status,
      if (audit.channel.isNotEmpty) audit.channel,
      if (audit.recipient.isNotEmpty) audit.recipient,
      if (audit.transferredAt.isNotEmpty) audit.transferredAt,
      if (audit.period.isNotEmpty) audit.period,
      if (audit.recordCount.isNotEmpty) audit.recordCount,
      if (audit.message.isNotEmpty) audit.message,
    ];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(lines.join(' · '), style: context.styles.caption),
    );
  }
}
