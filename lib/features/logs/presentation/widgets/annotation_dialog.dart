import 'package:flutter/material.dart';
import '../../../../core/widgets/app_text_field.dart';

/// حوار إدخال الملاحظات أو أسباب الرفض للأحداث غير المحددة
class AnnotationDialog extends StatefulWidget {
  final String title;
  final String hint;

  const AnnotationDialog({super.key, required this.title, required this.hint});

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
    return AlertDialog(
      title: Text(widget.title),
      content: AppTextField(
        controller: _controller,
        maxLines: 3,
        hint: widget.hint,
        keyboardType: TextInputType.text,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}
