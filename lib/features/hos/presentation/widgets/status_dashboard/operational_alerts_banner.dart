import 'package:flutter/material.dart';
import '../../../../../core/extensions/context_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
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

    if (hardwareAlerts.isNotEmpty) {
      final alert = hardwareAlerts.first;
      return _banner(
        context,
        color: AppColors.warningYellow,
        icon: Icons.info_outline,
        text: alert.message,
      );
    }

    if (alerts.connectionStatus == ConnectionStatus.ok) {
      return const SizedBox.shrink();
    }

    final loc = context.loc;
    final (color, icon, text) = switch (alerts.connectionStatus) {
      ConnectionStatus.warning => (
          AppColors.warningYellow,
          Icons.info_outline,
          loc.weakConnectionDelayedData,
        ),
      ConnectionStatus.disconnected => (
          AppColors.dangerRed,
          Icons.cloud_off,
          loc.noInternetConnection,
        ),
      ConnectionStatus.unknown => (
          context.styles.subtitle.color!,
          Icons.info_outline,
          loc.connectionStatusUnknown,
        ),
      ConnectionStatus.ok => (
          AppColors.successGreen,
          Icons.check_circle,
          '',
        ),
    };

    return _banner(context, color: color, icon: icon, text: text);
  }

  Widget _banner(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String text,
  }) {
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
              style: context.styles.body,
            ),
          ),
        ],
      ),
    );
  }
}
