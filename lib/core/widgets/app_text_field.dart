import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// حقل إدخال موحد يستخدم نمط التطبيق الثيم الموحد
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
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
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
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

    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
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
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: customBorder ??
            (isUnderlined
                ? const UnderlineInputBorder()
                : inputDecorationTheme.border),
        enabledBorder: customBorder ??
            (isUnderlined
                ? const UnderlineInputBorder()
                : inputDecorationTheme.enabledBorder),
        focusedBorder: customBorder ??
            (isUnderlined
                ? const UnderlineInputBorder()
                : inputDecorationTheme.focusedBorder),
        disabledBorder: isUnderlined
            ? const UnderlineInputBorder()
            : inputDecorationTheme.disabledBorder,
        errorBorder: isUnderlined
            ? const UnderlineInputBorder()
            : inputDecorationTheme.errorBorder,
        focusedErrorBorder: isUnderlined
            ? const UnderlineInputBorder()
            : inputDecorationTheme.focusedErrorBorder,
        contentPadding: inputDecorationTheme.contentPadding,
        filled: inputDecorationTheme.filled,
        fillColor: inputDecorationTheme.fillColor,
        alignLabelWithHint: inputDecorationTheme.alignLabelWithHint,
        floatingLabelBehavior: inputDecorationTheme.floatingLabelBehavior,
        floatingLabelAlignment: inputDecorationTheme.floatingLabelAlignment,
        labelStyle: inputDecorationTheme.labelStyle,
        hintStyle: inputDecorationTheme.hintStyle,
        prefixIconColor: inputDecorationTheme.prefixIconColor,
        suffixIconColor: inputDecorationTheme.suffixIconColor,
        iconColor: inputDecorationTheme.iconColor,
        errorStyle: inputDecorationTheme.errorStyle,
        errorMaxLines: inputDecorationTheme.errorMaxLines,
        isDense: isDense || inputDecorationTheme.isDense,
      ),
    );
  }
}
