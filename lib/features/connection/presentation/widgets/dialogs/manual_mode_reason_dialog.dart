import 'package:flutter/material.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/widgets/app_text_field.dart';

/// FMCSA §395.34 reason dialog for manual recording mode toggle.
///
/// Owns its text controller so it is disposed with the route, after the
/// dialog's exit animation — not while the TextField is still attached.
class ManualModeReasonDialog extends StatefulWidget {
  const ManualModeReasonDialog({super.key, required this.enable});

  final bool enable;

  @override
  State<ManualModeReasonDialog> createState() => _ManualModeReasonDialogState();
}

class _ManualModeReasonDialogState extends State<ManualModeReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final enable = widget.enable;
    return AlertDialog(
      title: Text(
        enable
            ? loc.eldMalfunctionReasonStart
            : loc.eldMalfunctionReasonEnd,
      ),
      content: AppTextField(
        controller: _controller,
        maxLines: 2,
        keyboardType: TextInputType.text,
        hint: enable
            ? loc.eldMalfunctionHintStart
            : loc.eldMalfunctionHintEnd,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancelAction),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(loc.okButton),
        ),
      ],
    );
  }
}
