import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_sizing.dart';
import '../theme/app_spacing.dart';

/// واجهة تحميل موحدة ومركزية للتطبيق (Design System 2.0).
///
/// تستخدم لون الهوية الذهبي الدلالي [GoldenColors.gold] أو اللون المخصص،
/// مع دعم الرسائل الإرشادية وإمكانية الوصول الحية [Semantics.liveRegion].
class AppLoadingState extends StatelessWidget {
  /// الرسالة التوضيحية أسفل مؤشر التحميل (اختيارية)
  final String? message;

  /// حجم مؤشر التحميل (الافتراضي [AppSizing.iconLarge])
  final double size;

  /// لون مؤشر التحميل (الافتراضي [GoldenColors.gold])
  final Color? color;

  /// نمط مدمج بحشوات مصغرة للحاويات المحدودة
  final bool isCompact;

  const AppLoadingState({
    super.key,
    this.message,
    this.size = AppSizing.iconLarge,
    this.color,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final goldenColors = context.goldenColors;
    final effectiveColor = color ?? goldenColors.gold;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isCompact ? AppSpacing.sm : AppSpacing.xl,
        ),
        child: Semantics(
          liveRegion: true,
          label: message ?? 'Loading',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                ),
              ),
              if (message != null && message!.isNotEmpty) ...[
                SizedBox(height: isCompact ? AppSpacing.xs : AppSpacing.md),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: context.styles.body.copyWith(
                    color: goldenColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
