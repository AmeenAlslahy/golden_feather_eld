import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';

class DvirFieldGroup extends StatelessWidget {
  final String title;
  final Widget child;
  final Color borderColor;
  final Color textColor;

  const DvirFieldGroup({
    super.key,
    required this.title,
    required this.child,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.styles.sectionTitle),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class DvirCell extends StatelessWidget {
  final String title;
  final Widget child;
  final Color borderColor;
  final Color textColor;

  const DvirCell({
    super.key,
    required this.title,
    required this.child,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.styles.sectionTitle),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class DvirTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;

  const DvirTwoColumn({
    super.key,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 32),
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

  const DvirFlatTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: context.styles.body,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: context.styles.subtitle,
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
    );
  }
}
