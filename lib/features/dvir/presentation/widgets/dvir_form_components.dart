import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';

class DvirFieldGroup extends StatelessWidget {
  final String title;
  final Widget child;

  const DvirFieldGroup({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.rowVertical,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.styles.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class DvirCell extends StatelessWidget {
  final String title;
  final Widget child;

  /// null = يستخدم لون الثيم الافتراضي (outline).
  /// يُمرر فقط عند تجاوز اللون (مثل حالة خطأ التحقق).
  final Color? borderColor;

  const DvirCell({
    super.key,
    required this.title,
    required this.child,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: borderColor ?? Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.styles.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class DvirTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;

  const DvirTwoColumn({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class DvirFlatTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool readOnly;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const DvirFlatTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: context.styles.body,
      readOnly: readOnly,
      validator: validator,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: context.styles.subtitle,
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 2),
      ),
    );
  }
}

class DvirDropdownField extends StatelessWidget {
  final String text;
  final String hint;
  final VoidCallback? onTap;
  final bool readOnly;

  const DvirDropdownField({
    super.key,
    required this.text,
    required this.hint,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = text.trim().isNotEmpty;
    return InkWell(
      onTap: readOnly ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            hasValue ? text : hint,
            style: hasValue ? context.styles.body : context.styles.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
