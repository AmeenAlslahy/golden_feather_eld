import 'package:golden_feather_eld/core/engine/hos_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/engine/hos_rules_engine.dart';
import '../../../../core/engine/hos_violations_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/hos_provider.dart';

class HosAlertsCard extends ConsumerWidget {
  const HosAlertsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(hosStatusProvider);

    if (status.alerts.isEmpty && status.violations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status.violations.isNotEmpty) ...[
          _buildViolations(status.violations),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (status.alerts.isNotEmpty) ...[
          _buildAlerts(status.alerts),
        ],
      ],
    );
  }

  Widget _buildViolations(List<HosViolation> violations) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: violations.map((v) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  v.message,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildAlerts(List<HosAlert> alerts) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: alerts.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              Icon(
                a.severity == AlertSeverity.critical ? Icons.warning : Icons.info_outline,
                color: a.severity == AlertSeverity.critical ? AppColors.error : AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  a.message,
                  style: TextStyle(
                    color: a.severity == AlertSeverity.critical ? AppColors.error : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}



