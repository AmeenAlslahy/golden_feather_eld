import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../domain/duty_status/status_dashboard.dart';
import '../../../../connection/presentation/providers/hardware_alerts_provider.dart';

/// Banner shown at the top of the dashboard when connection status
/// is not OK, or when there are hardware alerts.
class OperationalAlertsBanner extends ConsumerWidget {
  final OperationalAlerts alerts;

  const OperationalAlertsBanner({
    super.key,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hardwareAlertsAsync = ref.watch(hardwareAlertsProvider);
    final hardwareAlerts = hardwareAlertsAsync.valueOrNull ?? [];

    if (alerts.connectionStatus == ConnectionStatus.ok && hardwareAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    final (color, icon, text) = _presentation();

    return Column(
      children: [
        if (alerts.connectionStatus != ConnectionStatus.ok)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            color: color.withValues(alpha: 0.15),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: AppTypography.subtitleSize,
                      fontWeight: AppTypography.semiBold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // عرض تنبيهات الهاردوير
        for (final alert in hardwareAlerts)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            color: AppColors.dangerRed.withValues(alpha: 0.15),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.dangerRed, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    alert.message,
                    style: const TextStyle(
                      fontSize: AppTypography.subtitleSize,
                      fontWeight: AppTypography.semiBold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),


      ],
    );
  }

  (Color, IconData, String) _presentation() {
    return switch (alerts.connectionStatus) {
      ConnectionStatus.ok => (
          AppColors.successGreen,
          Icons.check_circle,
          '',
        ),
      ConnectionStatus.warning => (
          AppColors.warningYellow,
          Icons.warning_amber,
          'Connection warning — some data may be delayed',
        ),
      ConnectionStatus.disconnected => (
          AppColors.dangerRed,
          Icons.cloud_off,
          'Disconnected from server',
        ),
      ConnectionStatus.unknown => (
          AppColors.textSecondary,
          Icons.help_outline,
          'Connection status unknown',
        ),
    };
  }
}
