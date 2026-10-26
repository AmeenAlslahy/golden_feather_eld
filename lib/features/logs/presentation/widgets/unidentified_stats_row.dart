import 'package:flutter/material.dart';
import '../../../../core/design_system.dart';
import '../providers/unidentified_events_provider.dart';

/// شريط عرض إحصائيات الأحداث غير المحددة (SRS 11.2 & SRS 11.6)
class UnidentifiedStatsRow extends StatelessWidget {
  final UnidentifiedStats stats;

  const UnidentifiedStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          _StatCard(label: context.loc.total, value: '${stats.total}'),
          const SizedBox(width: AppSpacing.sm),
          _StatCard(label: context.loc.unclaimed, value: stats.unclaimed),
          const SizedBox(width: AppSpacing.sm),
          _StatCard(label: context.loc.rejected, value: stats.rejected),
          const SizedBox(width: AppSpacing.sm),
          _StatCard(
            label: context.loc.driving24h,
            value: '${stats.driving24h}',
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      // كانت Card تلفّ EldCard (تداخل بطاقتين وظلّين) — بطاقة واحدة قياسية.
      child: EldCard(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            Text(value, style: context.styles.bodyBold),
            Text(label, style: context.styles.caption),
          ],
        ),
      ),
    );
  }
}
