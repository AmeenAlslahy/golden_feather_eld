import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/core/design_system.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_button.dart';
import '../duty_change_message.dart';
import '../providers/change_status_provider.dart';
import '../widgets/status_option_tiles.dart';

/// شاشة تغيير حالة خدمة السائق — مطابقة بنسبة 100% للتطبيق الأصلي
class ChangeStatusPage extends ConsumerStatefulWidget {
  const ChangeStatusPage({super.key});

  @override
  ConsumerState<ChangeStatusPage> createState() => _ChangeStatusPageState();
}

class _ChangeStatusPageState extends ConsumerState<ChangeStatusPage> {
  late final TextEditingController _customLocationController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(changeStatusProvider);
    _customLocationController =
        TextEditingController(text: state.customLocation);
    _notesController = TextEditingController(text: state.notes);
  }

  @override
  void dispose() {
    _customLocationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final result = await ref.read(changeStatusProvider.notifier).submit();
    if (!mounted) return;

    switch (result) {
      case DutyChangeSuccess():
        AppFeedback.success(context, dutyChangeAcceptedMessage(context));
        Navigator.pop(context);
      case DutyChangeAlreadyInProgress():
        break;
      case DutyChangeAnnotationRequired():
        AppFeedback.error(context, annotationRequiredMessage(context));
      case DutyChangeVehicleMoving():
        AppFeedback.error(
          context,
          context.loc.errorCannotChangeStatusWhileMoving,
        );
      case DutyChangeEngineRefusal(:final reason):
        AppFeedback.error(context, dutyChangeMessage(context, reason));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changeStatusProvider);
    final notifier = ref.read(changeStatusProvider.notifier);

    final availableOptions = [
      DutyStatusOption.offDuty,
      DutyStatusOption.sleeperBerth,
      DutyStatusOption.driving,
      DutyStatusOption.onDuty,
      if (state.isPersonalConveyanceAllowed) DutyStatusOption.personalConveyance,
      if (state.isYardMoveAllowed) DutyStatusOption.yardMoves,
    ];

    final customLocationHint = context.loc.customLocation;
    final notesHint = context.loc.notes;
    final updateLabel = context.loc.updateButton.toUpperCase();

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.loc.changeStatus),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ========== قائمة الخيارات ==========
            for (var i = 0; i < availableOptions.length; i++) ...[
              Builder(
                builder: (context) {
                  final option = availableOptions[i];
                  final isSelected = state.selectedOption == option;
                  final disabled = state.isVehicleMoving &&
                      option != DutyStatusOption.driving &&
                      !isSelected;

                  return StatusOptionTile(
                    label: option.displayName(context),
                    isSelected: isSelected,
                    isLast: false,
                    enabled: !disabled,
                    onTap: disabled
                        ? null
                        : () => notifier.selectOption(option),
                  );
                },
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // ========== سطر الموقع الحالي ==========
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                state.location.isNotEmpty
                    ? state.location
                    : context.loc.location,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ),
            const Divider(),

            // ========== حقل الموقع اليدوي (Custom location) ==========
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: _customLocationController,
                onChanged: notifier.updateCustomLocation,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: customLocationHint,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  fillColor: Colors.transparent,
                ),
              ),
            ),
            const Divider(),

            // ========== حقل الملاحظات (Notes) ==========
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: _notesController,
                onChanged: notifier.updateNotes,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: notesHint,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  fillColor: Colors.transparent,
                ),
              ),
            ),
            const Divider(),

            // ========== زر الحفظ UPDATE ==========
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                28,
                AppSpacing.md,
                24,
              ),
              child: AppButton(
                label: updateLabel,
                type: EldButtonType.primary,
                isLoading: state.isSaving,
                onPressed: state.isSaving ? null : _handleSave,
              ),
            ),

            if (state.isVehicleMoving &&
                state.selectedOption != DutyStatusOption.driving)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  context.loc.errorCannotChangeStatusWhileMoving,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
