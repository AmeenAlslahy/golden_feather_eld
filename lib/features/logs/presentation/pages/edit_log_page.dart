import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../widgets/log_graph.dart';
import '../providers/logs_provider.dart';
import '../../../../core/time/time_authority_provider.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/log_edit.dart';
import '../controllers/edit_log_controller.dart';

import '../providers/edit_log_form_provider.dart';
import '../../../../core/widgets/dashed_line_painter.dart';
import '../widgets/time_picker_sheet.dart';
import '../widgets/status_radio_group.dart';
import '../widgets/time_field_widget.dart';

/// شاشة تعديل الحدث
class EditLogPage extends ConsumerStatefulWidget {
  final LogEvent? event;
  final bool isNewEvent;

  const EditLogPage({super.key, required this.event, this.isNewEvent = false});

  @override
  ConsumerState<EditLogPage> createState() => _EditLogPageState();
}

class _EditLogPageState extends ConsumerState<EditLogPage> {
  final _formKey = GlobalKey<FormState>();

  void _showTimePicker(BuildContext context, WidgetRef ref) {
    final formState = ref.read(editLogFormProvider(widget.event));
    final logDate = ref.read(logsProvider).selectedLog?.date;
    final initial = parseEditFormTime(formState.startTime, logDate) ??
        ref.read(timeAuthorityProvider).nowUtc().toLocal();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => TimePickerSheet(
        initialTime: initial,
        onDone: (time) {
          ref.read(editLogFormProvider(widget.event).notifier).setStartTime(time);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(
      editLogControllerProvider,
      (_, state) {
        if (state.isLoading) return;
        
        if (state.hasError) {
          final err = state.error;
          if (err is EditLogError) {
            switch (err.code) {
              case EditLogErrorCode.invalidTime:
                AppFeedback.error(context, context.loc.invalidValue);
                break;
              case EditLogErrorCode.autoDrivingRefused:
                AppFeedback.error(context, context.loc.automaticDrivingTimeCannotBeShortened);
                break;
              case EditLogErrorCode.saveFailed:
                AppFeedback.error(context, context.loc.theEventCouldNotBeSaved);
                break;
              case EditLogErrorCode.auditFailed:
                AppFeedback.error(context, context.loc.theEventWasSavedButThe);
                break;
              case EditLogErrorCode.authMissing:
                AppFeedback.error(context, context.loc.sessionMissing);
                break;
            }
          } else {
            AppFeedback.error(context, context.loc.theEventCouldNotBeSaved);
          }
        } else if (state.hasValue) {
          AppFeedback.success(context, context.loc.eventSavedSuccessfully);
          Navigator.pop(context, true);
        }
      },
    );

    final dashboard = ref.watch(dashboardDataProvider);
    final formState = ref.watch(editLogFormProvider(widget.event));
    final selectedLog = ref
        .watch(logsProvider)
        .selectedLog; // جلب اليوم المختار

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isNewEvent
              ? context.loc.insertDutyStatus
              : context.loc.editDutyStatus,
          style: context.styles.appBarTitle,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
        ), // تم تصغير الـ padding الجانبي
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. الرسم البياني الحقيقي (بدلاً من EldCard)
            const SizedBox(height: AppSpacing.md),
            LogGraph(
              events: selectedLog?.events ?? [],
            ), // تمرير الأحداث الحقيقية لليوم
            // 2. حقل الوقت والمدة
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TimeFieldWidget(
                    label: context.loc.startTime,
                    value: formState.startTime,
                    onTap: () => _showTimePicker(context, ref),
                  ),
                ),
                Expanded(
                  child: TimeFieldWidget(
                    label: context.loc.duration,
                    value: formState.duration,
                    onTap: () {},
                  ),
                ),
              ],
            ),
            // خط متقطع أسفل الوقت (للمطابقة)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: CustomPaint(
                painter: DashedLinePainter(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 3. قائمة الحالات
            StatusRadioGroup(
              groupValue: formState.selectedStatus,
              onChanged: (value) {
                ref.read(editLogFormProvider(widget.event).notifier).setStatus(value);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // 4. المركبة
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc.vehicle,
                  style: context.styles.bodyBold.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(dashboard.vehicleId, style: context.styles.body),
                const SizedBox(height: 8),
                Divider(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  height: 1,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 5. الموقع (Location) - read only label
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc.location,
                  style: context.styles.bodyBold.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  formState.location.isEmpty
                      ? ' '
                      : formState
                            .location, // empty space to keep height if empty
                  style: context.styles.subtitle,
                ),
                const SizedBox(height: 8),
                Divider(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  height: 1,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 6. إدخال موقع يدوي
            AppTextField(
              hint: context.loc.manualLocation,
              keyboardType: TextInputType.streetAddress,
              suffixIcon: Icon(
                Icons.my_location,
                color: context.styles.body.color,
              ),
              onChanged: (value) {
                ref
                    .read(editLogFormProvider(widget.event).notifier)
                    .setLocation(value);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // حقل سبب التعديل (إجباري)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc.reasonForChange,
                  style: context.styles.sectionTitle,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  hint: context.loc.enterReasonRequired,
                  keyboardType: TextInputType.text,
                  validator: (value) => value == null || value.trim().isEmpty ? context.loc.aReasonForTheChangeIs : null,
                  onChanged: (value) {
                    ref
                        .read(editLogFormProvider(widget.event).notifier)
                        .setReason(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 7. زر الحفظ
            AppButton(
              label: widget.isNewEvent
                  ? context.loc.addButton
                  : context.loc.saveButton,
              type: EldButtonType.agree,
              isLoading: ref.watch(editLogControllerProvider).isLoading,
              onPressed: () {
                if (!_formKey.currentState!.validate()) {
                  return;
                }
                final formState = ref.read(editLogFormProvider(widget.event));
                final controller = ref.read(editLogControllerProvider.notifier);

                controller.saveEvent(
                  isNewEvent: widget.isNewEvent,
                  existing: widget.event,
                  selectedStatus: formState.selectedStatus,
                  startTimeStr: formState.startTime,
                  location: formState.location,
                  reason: formState.reason,
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
      ),
    );
  }
}
