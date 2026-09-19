import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../domain/duty_status/status_dashboard.dart';

/// Banner shown at the top of the dashboard when connection status
/// is not OK.
///
/// Renders nothing when [alerts.connectionStatus] is
/// [ConnectionStatus.ok].
class OperationalAlertsBanner extends StatelessWidget {
  final OperationalAlerts alerts;

  const OperationalAlertsBanner({
    super.key,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.connectionStatus == ConnectionStatus.ok) {
      return const SizedBox.shrink();
    }

    final (color, icon, text) = _presentation();

    return Container(
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
