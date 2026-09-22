library;

/// منظومة التغذية الراجعة الموحدة — تحميل / خطأ / فارغ / نجاح.
///
/// **المشكلة:** 33 تكرار لـ CircularProgressIndicator + 78 SnackBar + 60 حالة فارغة.
/// **الحل:** 4 مكوّنات موحّدة بهوية واحدة.
import 'package:flutter/material.dart';

import '../error/app_error_l10n.dart';
import '../theme/app_durations.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_gap.dart';

// ========== التحميل ==========

class AppLoading extends StatelessWidget {
  final String? message;
  final double size;
  const AppLoading({super.key, this.message, this.size = 32});

  /// تحميل يملأ الشاشة
  const AppLoading.fullscreen({super.key, this.message})
      : size = 36;

  /// تحميل صغير داخل زر
  const AppLoading.button({super.key})
      : message = null,
        size = 18;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: size < 24 ? 2 : 3, color: color),
    );
    if (message == null) return Center(child: indicator);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          AppGap.md,
          Text(message!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// غطاء تحميل فوق المحتوى — يمنع التفاعل أثناء المعالجة.
class AppLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  const AppLoadingOverlay({super.key, required this.child, required this.isLoading, this.message});

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: AppLoading(message: message),
          ),
        ),
      ],
    );
  }
}

// ========== الخطأ ==========

class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  const AppErrorView({super.key, required this.message, this.onRetry, this.icon = Icons.error_outline});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // ترجمة تلقائية إذا كان message هو l10nKey
    final displayMessage = message.localized(context, fallback: message);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSpacing.xxxl, color: colors.error),
            AppGap.md,
            Text(displayMessage, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            if (onRetry != null) ...[
              AppGap.lg,
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ========== الفارغ ==========

class AppEmptyView extends StatelessWidget {
  final String message;
  final String? hint;
  final IconData icon;
  final Widget? action;
  const AppEmptyView({super.key, required this.message, this.hint, this.icon = Icons.inbox_outlined, this.action});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSpacing.xxxl, color: colors.onSurfaceVariant.withValues(alpha: 0.6)),
            AppGap.md,
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
            if (hint != null) ...[
              AppGap.sm,
              Text(hint!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ],
            if (action != null) ...[AppGap.lg, action!],
          ],
        ),
      ),
    );
  }
}

// ========== الإشعارات (SnackBar) ==========

/// مدير إشعارات موحد — لا تكرار لـ ScaffoldMessenger.
class AppSnackBar {
  AppSnackBar._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, backgroundColor: const Color(0xFF1B5E20));
  }

  static void showError(BuildContext context, String message) {
    // مرونة مع l10nKey: إذا كان المفتاح (مثل networkTimeout) يُترجم تلقائياً
    final localized = message.localized(context, fallback: message);
    _show(context, localized, backgroundColor: Theme.of(context).colorScheme.error);
  }

  /// عرض خطأ من AppError مباشرة
  static void showAppError(BuildContext context, dynamic error) {
    String message;
    if (error is String) {
      message = error.localized(context, fallback: error);
    } else {
      message = error.toString();
    }
    showError(context, message);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message);
  }

  static void _show(BuildContext context, String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
          margin: const EdgeInsets.all(AppSpacing.md),
          duration: AppDurations.snackBar,
        ),
      );
  }
}
