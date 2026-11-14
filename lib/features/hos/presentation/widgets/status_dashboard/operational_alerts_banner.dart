import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/routes/app_routes.dart';
import '../../../../connection/presentation/providers/hardware_alerts_provider.dart';

/// شريط التنبيهات التشغيلية وحالة اتصال جهاز ELD أعلى شاشة الداشبورد.
class OperationalAlertsBanner extends ConsumerWidget {
  final OperationalAlerts alerts;

  const OperationalAlertsBanner({super.key, required this.alerts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hardwareAlertsAsync = ref.watch(hardwareAlertsProvider);
    final hardwareAlerts = hardwareAlertsAsync.valueOrNull ?? [];

    if (hardwareAlerts.isNotEmpty) {
      final alert = hardwareAlerts.first;
      return _banner(
        context,
        color: context.warning,
        icon: Icons.info_outline,
        text: alert.message,
        onTap: () => context.push(AppRoutes.connection),
      );
    }

    final loc = context.loc;

    if (alerts.connectionStatus == ConnectionStatus.disconnected) {
      return _banner(
        context,
        color: context.danger,
        icon: Icons.warning_amber,
        text: '${loc.eldConnectionStatus}: ${loc.disconnected}',
        onTap: () => context.push(AppRoutes.connection),
      );
    }

    if (alerts.connectionStatus == ConnectionStatus.warning) {
      return _banner(
        context,
        color: context.warning,
        icon: Icons.info_outline,
        text: loc.weakConnectionDelayedData,
        onTap: () => context.push(AppRoutes.connection),
      );
    }

    if (alerts.connectionStatus == ConnectionStatus.unknown) {
      return _banner(
        context,
        color: context.styles.subtitle.color ?? context.warning,
        icon: Icons.info_outline,
        text: loc.connectionStatusUnknown,
        onTap: () => context.push(AppRoutes.connection),
      );
    }

    if (alerts.warningTriangleIcon) {
      return _banner(
        context,
        color: context.warning,
        icon: Icons.warning_amber,
        text: loc.serverReportsEldAlert,
        onTap: () => context.push(AppRoutes.connection),
      );
    }

    if (alerts.toolIcon) {
      return _banner(
        context,
        color: context.warning,
        icon: Icons.build,
        text: loc.serverReportsEldAlert,
        onTap: () => context.push(AppRoutes.connection),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _banner(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    final bannerWidget = Container(
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
              style: context.styles.bodyBold.copyWith(color: color),
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right, color: color, size: 20),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: bannerWidget,
        ),
      );
    }
    return bannerWidget;
  }
}
