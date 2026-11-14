import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_sizing.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// الأنواع الدلالية لرسائل التنبيهات الفورية (AppFeedback)
enum AppFeedbackType {
  success,
  error,
  warning,
  info,
}

/// سطح التنبيهات الموحد للتطبيق (Design System 2.0).
///
/// يستخدم تعبئة صلبة بالألوان الدلالية المألوفة (أحمر/أخضر/برتقالي/أزرق)
/// من رموز [AppColors]، مع لون نص مفحوص لكل تعبئة (≥ 4.5:1)، وظلال
/// عائمة متكيفة من [AppShadows].
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

    final brightness = Theme.of(context).brightness;

    // خلفية مصمتة باللون الدلالي المألوف (أحمر/أخضر/برتقالي/أزرق) بدل
    // الخلفيات الباستيل الباهتة، مع لون نص مفحوص لكل تعبئة.
    final (Color background, Color foreground, IconData icon) = switch (type) {
      AppFeedbackType.success => (
        AppColors.successFill,
        AppColors.onSuccessFill,
        Icons.check_circle,
      ),
      AppFeedbackType.error => (
        AppColors.dangerFill,
        AppColors.onDangerFill,
        Icons.error,
      ),
      AppFeedbackType.warning => (
        AppColors.warningFill,
        AppColors.onWarningFill,
        Icons.warning_rounded,
      ),
      AppFeedbackType.info => (
        AppColors.infoFill,
        AppColors.onInfoFill,
        Icons.info,
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
