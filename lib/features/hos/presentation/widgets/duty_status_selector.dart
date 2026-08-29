import 'package:golden_feather_eld/core/engine/hos_models.dart';
import 'package:golden_feather_eld/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/engine/hos_rules_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/hos_provider.dart';

class DutyStatusSelector extends ConsumerWidget {
  const DutyStatusSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusUpdate = ref.watch(hosStatusProvider);
    final currentStatus = statusUpdate.currentStatus;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: DutyStatus.values.map((status) {
        final isSelected = status == currentStatus;
        return ChoiceChip(
          label: Text(status.arabicName),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              _showStatusChangeDialog(context, ref, status);
            }
          },
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.surface : AppColors.textPrimaryLight,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  void _showStatusChangeDialog(BuildContext context, WidgetRef ref, DutyStatus newStatus) {
    showDialog(
      context: context,
      builder: (context) => _DutyStatusDialog(newStatus: newStatus, ref: ref),
    );
  }
}

class _DutyStatusDialog extends StatefulWidget {
  final DutyStatus newStatus;
  final WidgetRef ref;
  
  const _DutyStatusDialog({required this.newStatus, required this.ref});

  @override
  State<_DutyStatusDialog> createState() => _DutyStatusDialogState();
}

class _DutyStatusDialogState extends State<_DutyStatusDialog> {
  late final TextEditingController annotationController;

  @override
  void initState() {
    super.initState();
    annotationController = TextEditingController();
  }

  @override
  void dispose() {
    annotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.loc.changeStatusTo(widget.newStatus.arabicName)),
      content: TextField(
        controller: annotationController,
        decoration: const InputDecoration(
          labelText: 'ملاحظات (اختياري)',
          hintText: 'أدخل سبب التغيير...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.loc.cancelButton),
        ),
        TextButton(
          onPressed: () {
            widget.ref.read(hosStatusProvider.notifier).changeStatus(
              widget.newStatus,
              annotation: annotationController.text.isNotEmpty ? annotationController.text : null,
            );
            Navigator.pop(context);
          },
          child: Text(context.loc.okButton),
        ),
      ],
    );
  }
}



