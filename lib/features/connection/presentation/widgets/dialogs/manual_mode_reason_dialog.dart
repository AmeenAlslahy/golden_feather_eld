import 'package:flutter/material.dart';
import '../../../../../core/design_system.dart';

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
    return AppDialog(
      title:
          enable ? loc.eldMalfunctionReasonStart : loc.eldMalfunctionReasonEnd,
      type: AppDialogType.confirmation,
      contentWidget: AppTextField(
        controller: _controller,
        maxLines: 2,
        keyboardType: TextInputType.text,
        hint: enable ? loc.eldMalfunctionHintStart : loc.eldMalfunctionHintEnd,
      ),
      secondaryActionLabel: loc.cancelAction,
      onSecondaryAction: () => Navigator.pop(context),
      primaryActionLabel: loc.okButton,
      onPrimaryAction: () => Navigator.pop(context, _controller.text),
    );
  }
}

