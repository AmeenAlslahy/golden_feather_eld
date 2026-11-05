import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/golden_app_bar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../widgets/log_graph.dart';
import '../providers/logs_provider.dart';
import '../../../../core/time/time_authority_provider.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/daily_form_rules.dart';
import '../formatters/log_date_formatter.dart';
import '../providers/edit_log_provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final selectedLog = ref.read(logsProvider).selectedLog;
      if (selectedLog != null) {
        ref
            .read(editLogFormProvider(widget.event).notifier)
            .updateSelectedLog(selectedLog);
      }
    });
  }

  void _showTimePicker(BuildContext context) {
    final formNotifier = ref.read(editLogFormProvider(widget.event).notifier);
    final selectedLog = ref.read(logsProvider).selectedLog;
    final logDate = selectedLog?.date;
    final initial = formNotifier.getInitialTime(
      logDate,
      ref.read(timeAuthorityProvider),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (context) => TimePickerSheet(
        initialTime: initial,
        dateLabel: selectedLog?.formattedDate,
        onDone: (time) {
          formNotifier.setStartTime(time, selectedLog);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(editLogControllerProvider, (_, state) {
      if (state.isLoading) return;

      if (state.hasError) {
        AppFeedback.error(
          context,
          editLogErrorUserMessage(state.error, context.loc),
        );
      } else if (state.hasValue) {
        AppFeedback.success(context, context.loc.eventSavedSuccessfully);
        Navigator.pop(context, true);
      }
    });

    final formState = ref.watch(editLogFormProvider(widget.event));
    final selectedLog = ref
        .watch(logsProvider)
        .selectedLog; // جلب اليوم المختار

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GoldenAppBar(
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
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. الرسم البياني الحقيقي (بدلاً من EldCard)
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
                      onTap: () => _showTimePicker(context),
                    ),
                  ),
                  Expanded(
                    child: TimeFieldWidget(
                      label: context.loc.duration,
                      value: formState.duration,
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
                  ref
                      .read(editLogFormProvider(widget.event).notifier)
                      .setStatus(value);
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // 4. المركبة — قابلة للنقر: قائمة اختيار بحوار مستقل.
              // if (widget.isNewEvent)
              //   InkWell(
              //     onTap: () async {
              //       final picked = await showDialog<Vehicle>(
              //         context: context,
              //         builder: (_) => VehiclePickerDialog(
              //           currentVehicleId: dashboard.vehicleId,
              //         ),
              //       );
              //       if (picked != null && context.mounted) {
              //         if (selectedLog?.today ?? true) {
              //           ref
              //               .read(dashboardDataProvider.notifier)
              //               .updateVehicle(picked);
              //         }
              //       }
              //     },
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Row(
              //           children: [
              //             Expanded(
              //               child: Text(
              //                 context.loc.vehicle,
              //                 style: context.styles.sectionTitle,
              //               ),
              //             ),
              //             Icon(
              //               Icons.edit,
              //               size: AppSpacing.iconMedium,
              //               color: context.styles.body.color,
              //             ),
              //           ],
              //         ),
              //         const SizedBox(height: AppSpacing.xs),
              //         Text(dashboard.vehicleId, style: context.styles.body),
              //         const SizedBox(height: AppSpacing.sm),
              //         Divider(
              //           color: Theme.of(
              //             context,
              //           ).dividerColor.withValues(alpha: 0.5),
              //           height: AppSpacing.dividerHeight,
              //         ),
              //       ],
              //     ),
              //   ),
              // const SizedBox(height: AppSpacing.md),

              // 5. الموقع (Location) - read only label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.loc.location,
                    style: context.styles.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    formState.location.isEmpty
                        ? ' '
                        : formState
                              .location, // empty space to keep height if empty
                    style: context.styles.subtitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Divider(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
                    height: AppSpacing.dividerHeight,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // 6. إدخال موقع يدوي — يقبل العربية ويرفض الترقيم الخالص
              AppTextField(
                hint: context.loc.manualLocation,
                keyboardType: TextInputType.streetAddress,
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) return null;
                  return isFreeTextValid(v) ? null : context.loc.invalidValue;
                },
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
                    validator: (value) {
                      final v = (value ?? '').trim();
                      if (v.isEmpty) return context.loc.aReasonForTheChangeIs;
                      return isFreeTextValid(v)
                          ? null
                          : context.loc.invalidValue;
                    },
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
                  ref
                      .read(editLogControllerProvider.notifier)
                      .submit(
                        isNewEvent: widget.isNewEvent,
                        existing: widget.event,
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
