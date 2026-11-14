import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_radius.dart';
import '../theme/app_sizing.dart';
import '../theme/app_spacing.dart';
import '../theme/golden_colors.dart';

/// حقل إدخال موحد يستمد خصائصه البصرية من الثيم المركزي ونظام التصميم 2.0.
///
/// يدعم القيود المرنة لتفادي انقطاع النصوص عند تكبير الخط أو في الحقول متعددة الأسطر،
/// مع توحيد الزوايا، الحدود، الألوان، والأيقونات في الوضعين الفاتح والداكن.
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? errorText;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool readOnly;
  final bool isRequired;
  final bool isUnderlined;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final TextCapitalization? textCapitalization;
  final TextStyle? style;
  final bool isDense;
  final InputBorder? customBorder;
  final int? maxLength;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.errorText,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.isRequired = false,
    this.isUnderlined = false,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofillHints,
    this.textCapitalization,
    this.style,
    this.isDense = false,
    this.customBorder,
    this.maxLength,
    this.autofocus = false,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputDecorationTheme = theme.inputDecorationTheme;
    final goldenColors =
        theme.extension<GoldenColors>() ??
        (theme.brightness == Brightness.dark
            ? GoldenColors.dark
            : GoldenColors.light);

    final effectiveRadius = BorderRadius.circular(AppRadius.input);

    final defaultOutlineBorder = OutlineInputBorder(
      borderRadius: effectiveRadius,
      borderSide: BorderSide(color: goldenColors.inputBorder),
    );

    final defaultFocusedBorder = OutlineInputBorder(
      borderRadius: effectiveRadius,
      borderSide: BorderSide(
        color: goldenColors.focusRing,
        width: 2.0,
      ),
    );

    final defaultErrorBorder = OutlineInputBorder(
      borderRadius: effectiveRadius,
      borderSide: BorderSide(color: goldenColors.errorText, width: 2.0),
    );

    final defaultFocusedErrorBorder = OutlineInputBorder(
      borderRadius: effectiveRadius,
      borderSide: BorderSide(color: goldenColors.errorText, width: 2.5),
    );

    final defaultDisabledBorder = OutlineInputBorder(
      borderRadius: effectiveRadius,
      borderSide: BorderSide(
        color: goldenColors.inputBorder.withValues(alpha: 0.6),
      ),
    );

    final defaultUnderlineBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: goldenColors.inputBorder),
    );

    final defaultUnderlineFocusedBorder = UnderlineInputBorder(
      borderSide: BorderSide(
        color: goldenColors.focusRing,
        width: 2.0,
      ),
    );

    final defaultUnderlineErrorBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: goldenColors.errorText, width: 2.0),
    );

    final defaultUnderlineDisabledBorder = UnderlineInputBorder(
      borderSide: BorderSide(
        color: goldenColors.inputBorder.withValues(alpha: 0.6),
      ),
    );

    final border = customBorder ??
        (isUnderlined
            ? defaultUnderlineBorder
            : (inputDecorationTheme.border ?? defaultOutlineBorder));

    final enabledBorder = customBorder ??
        (isUnderlined
            ? defaultUnderlineBorder
            : (inputDecorationTheme.enabledBorder ?? defaultOutlineBorder));

    final focusedBorder = customBorder ??
        (isUnderlined
            ? defaultUnderlineFocusedBorder
            : (inputDecorationTheme.focusedBorder ?? defaultFocusedBorder));

    final errorBorder = customBorder ??
        (isUnderlined
            ? defaultUnderlineErrorBorder
            : (inputDecorationTheme.errorBorder ?? defaultErrorBorder));

    final focusedErrorBorder = customBorder ??
        (isUnderlined
            ? defaultUnderlineErrorBorder
            : (inputDecorationTheme.focusedErrorBorder ??
                defaultFocusedErrorBorder));

    final disabledBorder = isUnderlined
        ? defaultUnderlineDisabledBorder
        : (inputDecorationTheme.disabledBorder ?? defaultDisabledBorder);

    // قيود مرنة تضمن الحد الأدنى الموحد دون منع نمو الحقول متعددة الأسطر أو قص الخط المكبر
    final effectiveConstraints = BoxConstraints(
      minHeight:
          isDense ? AppSizing.buttonCompactHeight : AppSizing.inputHeight,
    );

    final effectiveContentPadding = inputDecorationTheme.contentPadding ??
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        );

    final effectiveFillColor = !enabled
        ? (theme.brightness == Brightness.dark
            ? theme.colorScheme.surface.withValues(alpha: 0.5)
            : goldenColors.surfaceSecondary)
        : (readOnly
            ? (theme.brightness == Brightness.dark
                ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
                : goldenColors.surfaceSecondary.withValues(alpha: 0.5))
            : (inputDecorationTheme.fillColor ?? theme.colorScheme.surface));

    final effectiveLabel = (label != null && isRequired) ? '$label *' : label;

    Widget? effectiveSuffix = suffixIcon;
    if (errorText != null && errorText!.isNotEmpty && effectiveSuffix == null) {
      effectiveSuffix = Icon(
        Icons.error_outline,
        color: goldenColors.errorText,
        size: AppSizing.iconSmall,
      );
    }

    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      readOnly: readOnly,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      focusNode: focusNode,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      style: style ?? theme.textTheme.bodyLarge,
      maxLength: maxLength,
      autofocus: autofocus,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: effectiveLabel,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: effectiveSuffix,
        constraints: effectiveConstraints,
        border: border,
        enabledBorder: enabledBorder,
        focusedBorder: focusedBorder,
        disabledBorder: disabledBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: focusedErrorBorder,
        contentPadding: effectiveContentPadding,
        filled: inputDecorationTheme.filled,
        fillColor: effectiveFillColor,
        alignLabelWithHint: inputDecorationTheme.alignLabelWithHint,
        floatingLabelBehavior: inputDecorationTheme.floatingLabelBehavior,
        floatingLabelAlignment: inputDecorationTheme.floatingLabelAlignment,
        labelStyle: inputDecorationTheme.labelStyle,
        hintStyle: inputDecorationTheme.hintStyle,
        prefixIconColor:
            inputDecorationTheme.prefixIconColor ?? goldenColors.textMuted,
        suffixIconColor:
            inputDecorationTheme.suffixIconColor ?? goldenColors.textMuted,
        iconColor: inputDecorationTheme.iconColor ?? goldenColors.textMuted,
        errorStyle: inputDecorationTheme.errorStyle,
        errorMaxLines: inputDecorationTheme.errorMaxLines,
        isDense: isDense || inputDecorationTheme.isDense,
      ),
    );
  }
}
