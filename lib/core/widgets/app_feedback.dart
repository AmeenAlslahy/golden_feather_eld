import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Unified feedback surface for the application.
///
/// Every state owns a background/foreground pair so bright semantic colors
/// are never rendered with an unreadable white label.
class AppFeedback {
  AppFeedback._();

  static OverlayEntry? _activeEntry;

  static void success(BuildContext context, String message) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    _show(
      context,
      message,
      dark ? AppColors.darkSuccessBg : AppColors.successBg,
      dark ? AppColors.successOnDark : AppColors.successText,
      Icons.check_circle_outline,
    );
  }

  static void error(BuildContext context, String message) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    _show(
      context,
      message,
      dark ? AppColors.darkDangerBg : AppColors.dangerBg,
      dark ? AppColors.dangerOnDark : AppColors.dangerText,
      Icons.error_outline,
    );
  }

  static void info(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    _show(
      context,
      message,
      scheme.inverseSurface,
      scheme.onInverseSurface,
      Icons.info_outline,
    );
  }

  static void warn(BuildContext context, String message) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    _show(
      context,
      message,
      dark ? AppColors.darkWarningBg : AppColors.warningBg,
      dark ? AppColors.warningOnDark : AppColors.warningText,
      Icons.warning_amber_rounded,
    );
  }

  static void _show(
    BuildContext context,
    String message,
    Color background,
    Color foreground,
    IconData icon,
  ) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    if (_activeEntry != null && _activeEntry!.mounted) {
      _activeEntry!.remove();
      _activeEntry = null;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Material(
              color: Colors.transparent,
              child: Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.up,
                onDismissed: (_) => _remove(entry),
                child: GestureDetector(
                  onTap: () => _remove(entry),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.compact,
                    ),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(AppRadius.dialog),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: foreground,
                          size: AppSpacing.iconMedium,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            message,
                            style: Theme.of(overlayContext).textTheme.bodyMedium
                                ?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.w600,
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
        ),
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => _remove(entry));
  }

  static void _remove(OverlayEntry entry) {
    if (!entry.mounted) return;
    entry.remove();
    if (_activeEntry == entry) _activeEntry = null;
  }
}
