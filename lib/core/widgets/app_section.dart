import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// قسم تخطيط موحد وشامل في شاشات التطبيق (Design System 2.0).
///
/// يحدد ترويسة القسم المركزية (العنوان، التسمية التوضيحية، الإجراء الجانبي)
/// ويوحد المسافات الرأسية بين الترويسة والمحتوى وبين الأقسام المتتالية.
class AppSection extends StatelessWidget {
  /// عنوان القسم الرئيسي
  final String title;

  /// عنوان فرعي أو إرشادي تحت عنوان القسم (اختياري)
  final String? subtitle;

  /// عنصر إجرائي في طرف الترويسة كزر إجراء أو شارة (اختياري)
  final Widget? action;

  /// محتوى القسم الداخلي (بطاقات، قوائم، جداول...)
  final Widget child;

  /// الحشوة الداخلية للقسم بأكمله (الافتراضي بدون حشوة إضافية)
  final EdgeInsetsGeometry? padding;

  /// الهامش الخارجي للقسم (الافتراضي [AppSpacing.sectionGap] في الأسفل)
  final EdgeInsetsGeometry? margin;

  /// نمط مدمج للمسافات المضغوطة
  final bool isCompact;

  const AppSection({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    required this.child,
    this.padding,
    this.margin,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleToContentGap =
        isCompact ? AppSpacing.sm : AppSpacing.titleToContent;
    final bottomMargin =
        isCompact ? AppSpacing.md : AppSpacing.sectionGap;

    return Padding(
      padding: margin ?? EdgeInsets.only(bottom: bottomMargin),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── ترويسة القسم ───
            _buildHeader(context),
            SizedBox(height: titleToContentGap),
            // ─── محتوى القسم ───
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final goldenColors = context.goldenColors;

    final headerTextWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          label: title,
          child: Text(
            title,
            style: context.styles.sectionTitle.copyWith(
              fontWeight: AppTypography.semiBold,
              color: context.textPrimary,
            ),
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space1),
          Text(
            subtitle!,
            style: context.styles.caption.copyWith(
              color: goldenColors.textMuted,
            ),
          ),
        ],
      ],
    );

    if (action == null) {
      return headerTextWidget;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: headerTextWidget),
        const SizedBox(width: AppSpacing.sm),
        action!,
      ],
    );
  }
}
