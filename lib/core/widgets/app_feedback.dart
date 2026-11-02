import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_sizing.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/golden_colors.dart';

/// الأنواع الدلالية لرسائل التنبيهات الفورية (AppFeedback)
enum AppFeedbackType {
  success,
  error,
  warning,
  info,
}

/// سطح التنبيهات الموحد للتطبيق (Design System 2.0).
///
/// يستمد جميع درجات الخلفيات والنصوص والأيقونات من [GoldenColors]،
/// والظلال العائمة المتكيفة من [AppShadows]، مما يضمن تباينًا تاماً في Light وDark.
class AppFeedback {
  AppFeedback._();

  static OverlayEntry? _activeEntry;

  /// إظهار تنبيه نجاح الإجراء
  static void success(BuildContext context, String message) {
    _show(context, message, AppFeedbackType.success);
  }

  /// إظهار تنبيه خطأ
  static void error(BuildContext context, String message) {
    _show(context, message, AppFeedbackType.error);
  }

  /// إظهار تنبيه معلوماتي
  static void info(BuildContext context, String message) {
    _show(context, message, AppFeedbackType.info);
  }

  /// إظهار تنبيه تحذيري
  static void warn(BuildContext context, String message) {
    _show(context, message, AppFeedbackType.warning);
  }

  /// اسم بديل متوافق لـ [warn]
  static void warning(BuildContext context, String message) {
    _show(context, message, AppFeedbackType.warning);
  }

  static void _show(
    BuildContext context,
    String message,
    AppFeedbackType type,
  ) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    if (_activeEntry != null && _activeEntry!.mounted) {
      _activeEntry!.remove();
      _activeEntry = null;
    }

    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final goldenColors =
        theme.extension<GoldenColors>() ??
        (brightness == Brightness.dark
            ? GoldenColors.dark
            : GoldenColors.light);

    final (Color background, Color foreground, IconData icon) = switch (type) {
      AppFeedbackType.success => (
        goldenColors.successBackground,
        goldenColors.successText,
        Icons.check_circle_outline,
      ),
      AppFeedbackType.error => (
        goldenColors.errorBackground,
        goldenColors.errorText,
        Icons.error_outline,
      ),
      AppFeedbackType.warning => (
        goldenColors.warningBackground,
        goldenColors.warningText,
        Icons.warning_amber_rounded,
      ),
      AppFeedbackType.info => (
        goldenColors.infoBackground,
        goldenColors.infoText,
        Icons.info_outline,
      ),
    };

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.feedbackPadding),
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
                      borderRadius: BorderRadius.circular(AppRadius.feedback),
                      border: Border.all(
                        color: foreground.withValues(alpha: 0.25),
                        width: 1.0,
                      ),
                      boxShadow: AppShadows.floatingFor(brightness),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: foreground,
                          size: AppSizing.iconStandard,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            message,
                            style: (overlayContext.styles.bodyMedium).copyWith(
                              color: foreground,
                              fontWeight: AppTypography.semiBold,
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
