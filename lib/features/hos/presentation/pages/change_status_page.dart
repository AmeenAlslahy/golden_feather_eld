import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system.dart';

import '../duty_change_message.dart';
import '../providers/change_status_provider.dart';
import '../widgets/status_option_tiles.dart';

/// شاشة تغيير حالة خدمة السائق — مطابقة لنظام التصميم Golden Feather 2.0
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
    _customLocationController = TextEditingController(
      text: state.customLocation,
    );
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

    final customLocationHint = context.loc.customLocation;
    final notesHint = context.loc.notes;
    final updateLabel = context.loc.updateButton.toUpperCase();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GoldenAppBar(
        variant: GoldenAppBarVariant.brand,
        titleText: context.loc.changeStatus,
        leading: IconButton(
          icon: const Icon(Icons.close, size: AppSpacing.iconSize),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 1. Duty Status Options Group ───
            EldCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < state.availableOptions.length; i++) ...[
                    Builder(
                      builder: (context) {
                        final option = state.availableOptions[i];
                        final isCurrentStatus = option == state.initialOption;
                        final isSelected =
                            state.selectedOption == option && !isCurrentStatus;
                        final disabled =
                            (state.isVehicleMoving &&
                                option != DutyStatusOption.driving) ||
                            isCurrentStatus;

                        return StatusOptionTile(
                          label: option.displayName(context),
                          isSelected: isSelected,
                          isLast: i == state.availableOptions.length - 1,
                          enabled: !disabled,
                          onTap: disabled
                              ? null
                              : () => notifier.selectOption(option),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ─── 2. Location & Notes Card ───
            EldCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // سطر الموقع الجغرافي المسجل
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: context.gold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: context.gold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          state.location.isNotEmpty
                              ? state.location
                              : context.loc.location,
                          style: context.styles.body.copyWith(
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // حقل الموقع المخصص
                  AppTextField(
                    controller: _customLocationController,
                    onChanged: notifier.updateCustomLocation,
                    hint: customLocationHint,
                    errorText:
                        state.customLocation.isNotEmpty &&
                                !state.hasValidCustomLocation
                            ? context.loc.invalidValue
                            : null,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // حقل الملاحظات
                  AppTextField(
                    controller: _notesController,
                    onChanged: notifier.updateNotes,
                    hint: notesHint,
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ─── 3. Action Button ───
            AppButton(
              label: updateLabel,
              type: EldButtonType.primary,
              isLoading: state.isSaving,
              onPressed: (state.isSaving || !state.isValid) ? null : _handleSave,
            ),

            if (state.isVehicleMoving &&
                state.selectedOption != DutyStatusOption.driving)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: context.colors.error.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: context.colors.error,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          context.loc.errorCannotChangeStatusWhileMoving,
                          style: context.styles.body.copyWith(
                            color: context.colors.onErrorContainer,
                            fontWeight: AppTypography.semiBold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

