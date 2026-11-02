import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/eld_card.dart';

/// بطاقة قسم مجمعة داخل نموذج DVIR — تجمع حقول الفحص المترابطة داخل إطار أنيق.
class DvirCardSection extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DvirCardSection({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs,
      ),
      child: EldCard(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: AppSpacing.iconMedium,
                      color: context.gold,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      title!,
                      style: context.styles.sectionTitle,
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: context.styles.caption,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// مجموعة حقل فحص — عنوان الحقل ومحتواه مع مسافات وهوامش متناسقة.
class DvirFieldGroup extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;

  const DvirFieldGroup({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: AppSpacing.iconSmall,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  title,
                  style: context.styles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

/// خلية فحص داخل شبكة أو عمودين — تدعم تجاوز لون الحدود في حالات الخطأ.
class DvirCell extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? borderColor;
  final IconData? icon;

  const DvirCell({
    super.key,
    required this.title,
    required this.child,
    this.borderColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final goldenColors = context.goldenColors;
    final border = borderColor ?? goldenColors.border;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: goldenColors.surfaceSecondary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
          color: border,
          width: borderColor != null ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: AppSpacing.iconSmall,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  title,
                  style: context.styles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

/// تخطيط عمودين متجاوب يدعم الشاشات الصغيرة والكبيرة بسلاسة.
class DvirTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;

  const DvirTwoColumn({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 320) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              const SizedBox(height: AppSpacing.sm),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

/// حقل إدخال نصي قياسي لـ DVIR — يفوض التصميم بالكامل لـ [AppTextField] المركزي
/// لضمان نشر أي تعديل على الحواف أو التركيز أو حالات الخطأ تلقائياً.
class DvirFlatTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool readOnly;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const DvirFlatTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hint: hint,
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: validator,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: true,
    );
  }
}

/// حقل اختيار منبثق — يتضمن InkWell متوافقاً مع الاختبارات ورمز سهمي أنيق
/// مع اشتقاق الألوان والحدود من نظام التصميم المركزي [GoldenColors].
class DvirDropdownField extends StatelessWidget {
  final String text;
  final String hint;
  final VoidCallback? onTap;
  final bool readOnly;
  final IconData? icon;

  const DvirDropdownField({
    super.key,
    required this.text,
    required this.hint,
    this.onTap,
    this.readOnly = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final goldenColors = context.goldenColors;
    final hasValue = text.trim().isNotEmpty;
    final isError = hasValue &&
        (text.contains('defect') ||
            text.contains('Defect') ||
            text.contains('عطل') ||
            text.contains('عطال') ||
            text.contains('عيب'));

    final Color bgColor = readOnly
        ? goldenColors.surfaceSecondary.withValues(alpha: 0.25)
        : (isError
            ? goldenColors.errorBackground.withValues(alpha: 0.3)
            : goldenColors.surfaceSecondary.withValues(alpha: 0.35));

    final Color borderColor = isError ? goldenColors.errorText : goldenColors.border;

    return InkWell(
      onTap: readOnly ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(
            color: borderColor,
            width: isError ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: AppSpacing.iconSmall,
                color: isError ? goldenColors.errorText : context.gold,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Expanded(
              child: Text(
                hasValue ? text : hint,
                style: hasValue
                    ? context.styles.body.copyWith(
                        color: isError ? goldenColors.errorText : null,
                        fontWeight: isError ? FontWeight.w600 : FontWeight.normal,
                      )
                    : context.styles.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!readOnly)
              Icon(
                Icons.arrow_drop_down,
                color: context.colorScheme.onSurfaceVariant,
                size: AppSpacing.iconMedium,
              ),
          ],
        ),
      ),
    );
  }
}
