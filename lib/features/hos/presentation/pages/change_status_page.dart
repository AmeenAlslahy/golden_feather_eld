import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/core/widgets/eld_card.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../duty_change_message.dart';
import '../extensions/duty_status_l10n.dart';
import '../providers/change_status_provider.dart';
import '../widgets/status_option_tiles.dart';

/// شاشة تغيير حالة خدمة السائق — شاشة عرض نقية تعتمد كلياً على [changeStatusProvider]
class ChangeStatusPage extends ConsumerWidget {
  const ChangeStatusPage({super.key});

  Future<void> _handleSave(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(changeStatusProvider.notifier).submit();
    if (!context.mounted) return;

    switch (result) {
      case DutyChangeSuccess():
        AppFeedback.success(context, dutyChangeAcceptedMessage(context));
        Navigator.pop(context);
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(changeStatusProvider);
    final notifier = ref.read(changeStatusProvider.notifier);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.loc.changeStatus),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EldCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ...DutyStatus.values
                      .where(
                        (s) =>
                            s != DutyStatus.personalUse ||
                            state.isPersonalConveyanceAllowed,
                      )
                      .map((status) {
                        final drivingLocked = status == DutyStatus.driving;
                        final isCurrent = state.selectedStatus == status;
                        final disabled =
                            drivingLocked ||
                            (state.isVehicleMoving && !isCurrent);
                        return Opacity(
                          opacity: disabled ? 0.45 : 1.0,
                          child: StatusOptionTile(
                            status: status,
                            label: status.displayName(context),
                            isSelected: isCurrent && !drivingLocked,
                            isLast: false,
                            onTap: disabled
                                ? null
                                : () => notifier.selectStatus(status),
                          ),
                        );
                      }),
                  if (state.isYardMoveAllowed)
                    Opacity(
                      opacity: state.isVehicleMoving ? 0.45 : 1.0,
                      child: YardMovesOptionTile(
                        isYardMoves: state.isYardMoves,
                        onTap: state.isVehicleMoving
                            ? null
                            : () => notifier.toggleYardMoves(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Location & Notes Card
            /// TODO: لا تقم بفتح التعليقات اجعلها كما هي حتى اشعار اخر
            // EldCard(
            //   padding: const EdgeInsets.all(AppSpacing.lg),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Text(
            //         context.loc.location,
            //         style: theme.textTheme.titleMedium?.copyWith(
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //       const SizedBox(height: AppSpacing.md),
            //       const LocationDisplayWidget(),
            //       const SizedBox(height: AppSpacing.lg),
            //       AppTextField(
            //         label: context.loc.customLocation,
            //         hint: context.loc.customLocation,
            //         prefixIcon: const Icon(Icons.edit_location_alt),
            //         onChanged: notifier.updateLocation,
            //       ),
            //       const SizedBox(height: AppSpacing.md),
            //       AppTextField(
            //         label: context.loc.notes,
            //         hint: context.loc.notes,
            //         prefixIcon: const Icon(Icons.note_alt_outlined),
            //         maxLines: 3,
            //         minLines: 1,
            //         onChanged: notifier.updateNotes,
            //       ),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: AppSpacing.xl),

            // Save Button
            AppButton(
              label: context.loc.updateButton.toUpperCase(),
              isLoading: state.isSaving,
              onPressed: state.isSaving
                  ? null
                  : () => _handleSave(context, ref),
              type: EldButtonType.primary,
            ),
            if (state.isVehicleMoving)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  context.loc.errorCannotChangeStatusWhileMoving,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
