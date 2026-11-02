import 'package:flutter/material.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';

/// حوار إدخال الملاحظات أو أسباب الرفض للأحداث غير المحددة وفق Design System 2.0
class AnnotationDialog extends StatefulWidget {
  final String title;
  final String hint;
  final int maxLength;

  const AnnotationDialog({
    super.key,
    required this.title,
    required this.hint,
    this.maxLength = 500,
  });

  @override
  State<AnnotationDialog> createState() => _AnnotationDialogState();
}

class _AnnotationDialogState extends State<AnnotationDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matLoc = MaterialLocalizations.of(context);
    return AppDialog(
      title: widget.title,
      icon: Icons.edit_note_rounded,
      type: AppDialogType.confirmation,
      primaryActionLabel: matLoc.okButtonLabel,
      onPrimaryAction: () => Navigator.pop(context, _controller.text.trim()),
      secondaryActionLabel: matLoc.cancelButtonLabel,
      onSecondaryAction: () => Navigator.pop(context),
      contentWidget: SingleChildScrollView(
        child: AppTextField(
          controller: _controller,
          maxLines: 3,
          maxLength: widget.maxLength,
          hint: widget.hint,
          keyboardType: TextInputType.text,
        ),
      ),
    );
  }
}
