import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/domain/entities/connection_status.dart';
import '../../../../core/events/eld_events_provider.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../routes.dart';

class ConnectionStatusIndicator extends ConsumerWidget {
  final bool showWarningTriangle;

  const ConnectionStatusIndicator({super.key, this.showWarningTriangle = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsyncValue = ref.watch(eldConnectionStatusProvider);

    // لا تسجيل داخل build: المعرّف يظهر في AppBar ويُعاد بناؤه كثيراً.
    final status = statusAsyncValue.value ?? ConnectionStatus.disconnected;

    return _buildIndicator(context, status);
  }

  Widget _buildIndicator(BuildContext context, ConnectionStatus status) {
    if (status == ConnectionStatus.disconnected ||
        status == ConnectionStatus.error ||
        status == ConnectionStatus.unconfigured) {
      if (!showWarningTriangle) {
        return const SizedBox.shrink();
      }
      return IconButton(
        icon: Icon(
          Icons.warning_amber,
          color: context.warning,
          size: AppSpacing.iconLarge,
        ),
        onPressed: () {
          context.push(AppRoutes.connection);
        },
      );
    }

    Color color;
    String text;
    IconData icon;
    bool isSyncingOrConnecting = false;

    if (status == ConnectionStatus.connected) {
      color = context.success;
      text = context.loc.connected;
      icon = Icons.wifi;
    } else {
      color = context.warning;
      text = context.loc.connecting;
      icon = Icons.wifi_protected_setup;
      isSyncingOrConnecting = true;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.compact,
          vertical: AppSpacing.xs,
        ),
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.dialog),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSyncingOrConnecting)
              SizedBox(
                width: AppSpacing.compact,
                height: AppSpacing.compact,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(icon, size: AppSpacing.iconSmall, color: color),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: context.styles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
