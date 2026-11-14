import 'package:flutter/material.dart';
import '../../../../core/design_system.dart';
import '../providers/unidentified_events_provider.dart';

/// شريط عرض إحصائيات الأحداث غير المحددة في شبكة 2×2 متجاوبة (SRS 11.2 & SRS 11.6)
class UnidentifiedStatsRow extends StatelessWidget {
  final UnidentifiedStats stats;

  const UnidentifiedStatsRow({super.key, required this.stats});

  String _value(int value) => stats.available ? '$value' : '—';

  @override
  Widget build(BuildContext context) {
    final isAlert = stats.pendingOver8Days > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  key: const Key('unidentified-stat-total'),
                  label: context.loc.total,
                  value: _value(stats.total),
                  icon: Icons.assignment_outlined,
                  iconColor: context.gold,
                  iconBg: context.gold.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _StatCard(
                  key: const Key('unidentified-stat-unclaimed'),
                  label: context.loc.unclaimed,
                  value: _value(stats.unclaimed),
                  icon: Icons.help_outline_rounded,
                  iconColor: context.warning,
                  iconBg: context.warning.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  key: const Key('unidentified-stat-rejected'),
                  label: context.loc.rejected,
                  value: _value(stats.rejected),
                  icon: Icons.cancel_outlined,
                  iconColor: context.textSecondary,
                  iconBg: context.textSecondary.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _StatCard(
                  key: const Key('unidentified-stat-over-8-days'),
                  label: context.loc.k8DaysRule,
                  value: _value(stats.pendingOver8Days),
                  icon: Icons.warning_amber_rounded,
                  iconColor: isAlert ? context.danger : context.textSecondary,
                  iconBg: (isAlert ? context.danger : context.textSecondary)
                      .withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return EldCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.compact,
        vertical: AppSpacing.compact,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: context.styles.bodyBold.copyWith(
                    fontSize: 16,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: context.styles.caption.copyWith(
                    color: context.textSecondary,
                    fontSize: 11.5,
                    fontWeight: AppTypography.medium,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

