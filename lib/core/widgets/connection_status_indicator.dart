import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/connection_status.dart';
import '../events/eld_events_provider.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizing.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/golden_colors.dart';

/// مؤشر حالة الاتصال الموحد (Design System 2.0).
///
/// يستمد الألوان الدلالية من [GoldenColors]، ويدعم الأيقونات وحالات التحميل والنص المختصر
/// مع Semantics وTooltip مناسبين وتوافق كامل مع RTL وLTR.
class ConnectionStatusIndicator extends ConsumerWidget {
  final bool showWarningTriangle;
  final VoidCallback? onTap;
  final ConnectionStatus? statusOverride;

  const ConnectionStatusIndicator({
    super.key,
    this.showWarningTriangle = true,
    this.onTap,
    this.statusOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = statusOverride ??
        ref.watch(eldConnectionStatusProvider).value ??
        ConnectionStatus.disconnected;

    return _buildIndicator(context, status);
  }

  Widget _buildIndicator(BuildContext context, ConnectionStatus status) {
    final goldenColors = context.goldenColors;

    final isDisconnected = status == ConnectionStatus.disconnected ||
        status == ConnectionStatus.error ||
        status == ConnectionStatus.unconfigured;

    if (isDisconnected) {
      if (!showWarningTriangle) {
        return const SizedBox.shrink();
      }
      return Tooltip(
        message: context.loc.disconnected,
        child: Semantics(
          label: context.loc.disconnected,
          button: onTap != null,
          child: IconButton(
            icon: Icon(
              Icons.warning_amber,
              color: goldenColors.warningText,
              size: AppSizing.iconLarge,
            ),
            onPressed: onTap,
          ),
        ),
      );
    }

    final bool isConnected = status == ConnectionStatus.connected;
    final Color color =
        isConnected ? goldenColors.successText : goldenColors.warningText;
    final Color backgroundColor = isConnected
        ? goldenColors.successBackground
        : goldenColors.warningBackground;
    final String text =
        isConnected ? context.loc.connected : context.loc.connecting;
    final IconData icon = isConnected ? Icons.wifi : Icons.wifi_protected_setup;
    final bool isSyncingOrConnecting = !isConnected;

    return Center(
      child: Tooltip(
        message: text,
        child: Semantics(
          label: text,
          button: onTap != null,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.dialog),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.compact,
                  vertical: AppSpacing.xs,
                ),
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.dialog),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
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
                      Icon(icon, size: AppSizing.iconSmall, color: color),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        text,
                        overflow: TextOverflow.ellipsis,
                        style: context.styles.badge.copyWith(
                          color: color,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
