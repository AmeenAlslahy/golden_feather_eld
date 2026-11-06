import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';

/// بطاقة عائمة فوق Scrim تظهر أثناء محاولة الاتصال أو المتابعة بدون اتصال
class ConnectingOverlay extends StatelessWidget {
  final bool isContinuingDisconnected;
  final bool isConnecting;
  final bool serverRequestPending;
  final VoidCallback onCancel;
  final VoidCallback? onContinueDisconnected;

  const ConnectingOverlay({
    super.key,
    required this.isContinuingDisconnected,
    required this.isConnecting,
    required this.serverRequestPending,
    required this.onCancel,
    this.onContinueDisconnected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.scrim.withValues(alpha: 0.38),
      alignment: Alignment.center,
      child: Card(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: AppSpacing.md),
                  Flexible(
                    child: Text(
                      isContinuingDisconnected
                          ? context.loc.continueDisconnectedInProgress
                          : context.loc.connecting,
                      style: context.styles.bodyBold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  AppButton.tertiary(
                    key: const Key('cancel_connection_button'),
                    isFullWidth: false,
                    isCompact: true,
                    onPressed: onCancel,
                    label: context.loc.cancelButton,
                  ),
                  if (isConnecting)
                    AppButton.secondary(
                      key: const Key('continue_disconnected_overlay_button'),
                      isFullWidth: false,
                      isCompact: true,
                      onPressed: serverRequestPending ? null : onContinueDisconnected,
                      label: context.loc.continueDisconnected,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
