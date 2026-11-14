import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/golden_app_bar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../domain/shared/value_objects.dart';
import '../widgets/log_graph.dart';
import '../providers/logs_provider.dart';
import '../../../../core/time/time_authority_provider.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/providers/log_repository_providers.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/daily_form_rules.dart';
import '../../domain/log_edit.dart';
import '../formatters/log_date_formatter.dart';
import '../providers/edit_log_provider.dart';
import '../providers/edit_log_form_provider.dart';
import '../../../../core/widgets/dashed_line_painter.dart';
import '../widgets/time_picker_sheet.dart';
import '../widgets/status_radio_group.dart';
import '../providers/event_options_provider.dart';
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
  late final TextEditingController _manualLocationController;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    final initialManualLoc =
        ref.read(editLogFormProvider(widget.event)).manualLocation;
    _manualLocationController = TextEditingController(text: initialManualLoc);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final selectedLog = ref.read(logsProvider).selectedLog;
      if (selectedLog != null) {
        ref
            .read(editLogFormProvider(widget.event).notifier)
            .updateSelectedLog(selectedLog);
      }
      _fetchServerEventDetails();
    });
  }

  @override
  void dispose() {
    _manualLocationController.dispose();
    super.dispose();
  }

  Future<void> _fetchServerEventDetails() async {
    final event = widget.event;
    if (widget.isNewEvent || event == null) return;
    final selectedLog = ref.read(logsProvider).selectedLog;
    if (selectedLog == null) return;
    final eventIntId = int.tryParse(event.id);
    if (eventIntId == null) return;

    try {
      final repo = ref.read(logRepositoryProvider);
      final result = await repo.getEventDetails(
        selectedLog.id,
        DutyStatusId(eventIntId),
      );
      if (!mounted) return;
      result.fold((_) {}, (data) {
        if (data == null) return;
        final serverManual = data['manualLocation']?.toString().trim();
        final rawLocation = data['location'];
        String? serverLocDesc;
        double? lat;
        double? lng;
        if (rawLocation is Map) {
          serverLocDesc = rawLocation['description']?.toString().trim();
          lat = double.tryParse(rawLocation['latitude']?.toString() ?? '');
          lng = double.tryParse(rawLocation['longitude']?.toString() ?? '');
        } else if (rawLocation is String) {
          serverLocDesc = rawLocation.trim();
        }

        final serverLocationString =
            (serverManual != null && serverManual.isNotEmpty)
                ? serverManual
                : ((serverLocDesc != null &&
                        !isPlaceholderLocation(serverLocDesc))
                    ? serverLocDesc
                    : null);

        if (serverLocationString != null && serverLocationString.isNotEmpty) {
          if (_manualLocationController.text.isEmpty ||
              _manualLocationController.text == widget.event?.location) {
            _manualLocationController.text = serverLocationString;
            ref
                .read(editLogFormProvider(widget.event).notifier)
                .setManualLocation(
                  serverLocationString,
                  latitude: lat,
                  longitude: lng,
                );
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _fetchCurrentLocation() async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          AppFeedback.error(context, context.loc.locationDisabled);
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            AppFeedback.error(context, context.loc.locationPermissionDenied);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          AppFeedback.error(context, context.loc.locationPermissionDenied);
        }
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        if (mounted) {
          AppFeedback.error(context, context.loc.dvirLocationUnavailable);
        }
        return;
      }

      final coordsText =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';

      if (mounted) {
        _manualLocationController.text = coordsText;
        ref.read(editLogFormProvider(widget.event).notifier).setManualLocation(
          coordsText,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.error(context, context.loc.theEventCouldNotBeSaved);
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
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
    ref.listen<AsyncValue<EditLogOutcome?>>(editLogControllerProvider, (
      _,
      state,
    ) {
      if (state.isLoading) return;

      if (state.hasError) {
        AppFeedback.error(
          context,
          editLogErrorUserMessage(state.error, context.loc),
        );
      } else if (state.hasValue && state.value != null) {
        final outcome = state.value!;
        switch (outcome.type) {
          case EditLogOutcomeType.confirmed:
            AppFeedback.success(context, context.loc.eventSavedSuccessfully);
          case EditLogOutcomeType.offlineQueued:
            AppFeedback.info(context, context.loc.eventSavedOffline);
          case EditLogOutcomeType.unconfirmed:
            AppFeedback.warning(context, context.loc.statusSavedUnconfirmed);
        }
        Navigator.pop(context, true);
      }
    });

    final formState = ref.watch(editLogFormProvider(widget.event));
    final selectedLog = ref
        .watch(logsProvider)
        .selectedLog; // جلب اليوم المختار
    final optionsAsync = selectedLog != null
        ? ref.watch(eventScreenOptionsProvider(selectedLog.id))
        : null;

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
                allowedStatuses: optionsAsync?.value?.statuses,
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
                    formState.originalLocation.isEmpty
                        ? (formState.location.isEmpty
                              ? ' '
                              : formState.location)
                        : formState.originalLocation,
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
                controller: _manualLocationController,
                hint: context.loc.manualLocation,
                keyboardType: TextInputType.streetAddress,
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) return null;
                  return isFreeTextValid(v) ? null : context.loc.invalidValue;
                },
                suffixIcon: _isFetchingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.my_location),
                        color: context.styles.body.color,
                        tooltip: context.loc.location,
                        onPressed: _fetchCurrentLocation,
                      ),
                onChanged: (value) {
                  ref
                      .read(editLogFormProvider(widget.event).notifier)
                      .setManualLocation(value);
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
