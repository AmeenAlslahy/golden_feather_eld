import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/log_graph.dart';
import '../providers/logs_provider.dart';
import '../../domain/entities/audit_entry.dart';
import '../../domain/entities/daily_log.dart';
import 'package:uuid/uuid.dart';
import '../../domain/log_edit.dart';
import '../../../../core/time/time_authority_provider.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../core/widgets/app_feedback.dart';

@visibleForTesting
String? resolveDriverIdForAudit(WidgetRef ref) {
  return ref.read(authStateProvider).user?.id;
}

class EditLogFormState {
  final String selectedStatus;
  final String startTime;
  final String duration;
  final String location;
  final String reason;

  EditLogFormState({
    required this.selectedStatus,
    required this.startTime,
    required this.duration,
    required this.location,
    this.reason = '',
  });

  EditLogFormState copyWith({
    String? selectedStatus,
    String? startTime,
    String? duration,
    String? location,
    String? reason,
  }) {
    return EditLogFormState(
      selectedStatus: selectedStatus ?? this.selectedStatus,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      reason: reason ?? this.reason,
    );
  }
}

class EditLogFormNotifier extends StateNotifier<EditLogFormState> {
  EditLogFormNotifier(super.state);

  void setStatus(String status) =>
      state = state.copyWith(selectedStatus: status);
  void setStartTime(String time) => state = state.copyWith(startTime: time);
  void setReason(String reason) => state = state.copyWith(reason: reason);
}

// دالة مساعدة لتنسيق الوقت الحالي
String _formatCurrentTime() {
  final now = DateTime.now();
  final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
  final hourStr = hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  final second = now.second.toString().padLeft(2, '0');
  final period = now.hour < 12 ? 'AM' : 'PM';
  return '$hourStr:$minute:$second $period';
}

final editLogFormProvider = StateNotifierProvider.autoDispose
    .family<EditLogFormNotifier, EditLogFormState, dynamic>((ref, event) {
  return EditLogFormNotifier(EditLogFormState(
    // الرمز المخزن (D/ON/...) يُعاد إلى قيمة القائمة (Driving/On Duty/...)
    // حتى تُحدد الحالة الحالية في الواجهة.
    selectedStatus: editValueForStatus(event.status),
    startTime: event.formattedStartTime ?? _formatCurrentTime(),
    duration: event.formattedDuration ?? '00:00',
    location: event.location ?? '',
  ));
});

/// شاشة تعديل الحدث
class EditLogPage extends ConsumerWidget {
  final dynamic event;
  final bool isNewEvent;

  const EditLogPage({
    super.key,
    required this.event,
    this.isNewEvent = false,
  });

  void _showTimePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _TimePickerSheet(
        onDone: (time) {
          ref.read(editLogFormProvider(event).notifier).setStartTime(time);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardDataProvider);
    final formState = ref.watch(editLogFormProvider(event));
    final selectedLog =
        ref.watch(logsProvider).selectedLog; // جلب اليوم المختار

    final List<Map<String, String>> statuses = [
      {'value': 'Off Duty', 'label': context.loc.offDuty},
      {'value': 'Sleeper', 'label': context.loc.sleeperBerth},
      {'value': 'Driving', 'label': context.loc.drivingStatus},
      {'value': 'On Duty', 'label': context.loc.onDuty},
      {'value': 'Personal Use', 'label': context.loc.personalUse},
      {'value': 'Yard Moves', 'label': context.loc.yardMoves},
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.surface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isNewEvent
              ? context.loc.insertDutyStatus
              : context.loc.editDutyStatus,
          style: context.styles.appBarTitle,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md), // تم تصغير الـ padding الجانبي
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. الرسم البياني الحقيقي (بدلاً من EldCard)
            const SizedBox(height: AppSpacing.md),
            LogGraph(
                events:
                    selectedLog?.events ?? []), // تمرير الأحداث الحقيقية لليوم

            // 2. حقل الوقت والمدة
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                    child: _buildTimeField(
                        context,
                        context.loc.startTime,
                        formState.startTime,
                        () => _showTimePicker(context, ref))),
                Expanded(
                    child: _buildTimeField(context, context.loc.duration,
                        formState.duration, () {})),
              ],
            ),
            // خط متقطع أسفل الوقت (للمطابقة)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: CustomPaint(
                  painter:
                      DashedLinePainter(color: Theme.of(context).dividerColor)),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 3. قائمة الحالات
            RadioGroup<String>(
              groupValue: formState.selectedStatus,
              onChanged: (value) {
                if (value == null) return;
                ref.read(editLogFormProvider(event).notifier).setStatus(value);
              },
              child: Column(
                children: statuses.map((status) {
              final isSelected = formState.selectedStatus == status['value'];
              return Column(
                children: [
                  RadioListTile<String>(
                    title: Text(
                      status['label']!,
                      style: context.styles.body.copyWith(
                        fontWeight: isSelected
                            ? AppTypography.semiBold
                            : AppTypography.regular,
                        color: isSelected
                            ? AppColors.primaryGold
                            : null,
                      ),
                    ),
                    value: status['value']!,
                    activeColor: AppColors.primaryGold,
                    controlAffinity: ListTileControlAffinity.trailing,
                    contentPadding: EdgeInsets.zero,
                  ),
                  Divider(
                      color:
                          Theme.of(context).dividerColor.withValues(alpha: 0.5),
                      height: 1),
                ],
              );
                }).toList(),
              ),
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
                Text(
                  dashboard.vehicleId,
                  style: context.styles.body,
                ),
                const SizedBox(height: 8),
                Divider(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.5),
                    height: 1),
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
                  formState.location.isEmpty ? ' ' : formState.location, // empty space to keep height if empty
                  style: context.styles.subtitle,
                ),
                const SizedBox(height: 8),
                Divider(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.5),
                    height: 1),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 6. إدخال موقع يدوي
            TextField(
              decoration: InputDecoration(
                hintText: context.loc.manualLocation,
                hintStyle: context.styles.subtitle,
                border: const UnderlineInputBorder(),
                suffixIcon:  Icon(Icons.my_location, color: context.styles.body.color),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: context.styles.body,
              onChanged: (value) {},
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
                TextField(
                  decoration: InputDecoration(
                    hintText:
                        context.loc.enterReasonRequired,
                    hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    border: const UnderlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: context.styles.body,
                  onChanged: (value) {
                    ref
                        .read(editLogFormProvider(event).notifier)
                        .setReason(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 7. زر الحفظ
            AppButton(
              label:
                  isNewEvent ? context.loc.addButton : context.loc.saveButton,
              type: EldButtonType.agree,
              onPressed: () async {
                      if (formState.reason.trim().isEmpty) {
                        AppFeedback.error(
                          context,
                          context.loc.aReasonForTheChangeIs,
                        );
                        return;
                      }
                      // حفظ التعديلات وسجل التدقيق
                      final notifier = ref.read(logsProvider.notifier);
                      
                      final driverId = resolveDriverIdForAudit(ref);

                      if (driverId == null || driverId.isEmpty) {
                        if (context.mounted) {
                          AppFeedback.error(context, 
                                context.loc.cannotSaveDriverSessionNotFound);
                        }
                        return;
                      }

                      // بناء الحدث كما عدّله المستخدم (القيمة الحالية للنموذج)
                      final selectedLog = ref.read(logsProvider).selectedLog;
                      final status =
                          statusFromEditValue(formState.selectedStatus);
                      final existing = event is LogEvent ? event : null;
                      final newStart = parseEditFormTime(
                              formState.startTime, selectedLog?.date) ??
                          existing?.startTime ??
                          DateTime.now();
                      if (existing != null) {
                        final refusal = refuseAutomaticDrivingEdit(
                          original: existing,
                          newStatusCode: status.code,
                          newStart: newStart,
                        );
                        if (refusal != null) {
                          if (context.mounted) {
AppFeedback.error(
                              context,
                              context.loc.automaticDrivingTimeCannotBeShortened,
                            );
                          }
                          return;
                        }
                      }

                      final updatedEvent = existing?.copyWith(
                            status: status.code,
                            statusArabic: status.arabic,
                            startTime: newStart,
                          ) ??
                          LogEvent(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            status: status.code,
                            statusArabic: status.arabic,
                            startTime: newStart,
                            duration: Duration.zero,
                            location: formState.location,
                          );

                      // حفظ الحدث أولاً؛ الفشل يبقى المستخدم على الشاشة.
                      final saved = isNewEvent
                          ? await notifier.addEvent(updatedEvent,
                              reason: formState.reason)
                          : await notifier.updateEvent(updatedEvent,
                              reason: formState.reason);
                      if (!saved) {
                        if (context.mounted) {
AppFeedback.error(context, 
                                context.loc.theEventCouldNotBeSaved);
                        }
                        return;
                      }

                      final timeAuthority = ref.read(timeAuthorityProvider);

                      final entry = AuditEntry(
                        id: const Uuid().v4(),
                        timestamp: timeAuthority.nowUtc(),
                        driverId: driverId,
                        oldStatus:
                            isNewEvent ? null : (existing?.status),
                        newStatus: status.code,
                        reason: formState.reason,
                      );

                      final auditSaved = (await notifier.saveAuditEntry(entry))
                          .fold((_) => false, (ok) => ok);
                      if (!auditSaved) {
                        if (context.mounted) {
AppFeedback.error(context, 
                                context.loc.theEventWasSavedButThe);
                        }
                        return;
                      }

                      if (context.mounted) {
AppFeedback.success(
                          context,
                          context.loc.eventSavedSuccessfully,
                        );
                        Navigator.pop(context, true);
                      }
                    },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField(
      BuildContext context, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.styles.sectionTitle
                  .copyWith(fontSize: AppTypography.subtitleSize),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: context.styles.body,
                ),
                Icon(Icons.access_time,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// منتقي الوقت (Picker Wheel)
class _TimePickerSheet extends StatefulWidget {
  final Function(String) onDone;

  const _TimePickerSheet({required this.onDone});

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  int _selectedHour = 12;
  int _selectedMinute = 0;
  int _selectedSecond = 0;
  String _selectedPeriod = 'AM';

  // تُنشأ مرة واحدة مع الـ State وتُدمَّر معه — كانت سابقاً تُنشأ داخل
  // كل build (تسريب متحكمات جديد مع كل setState) وبلا أي dispose.
  late final FixedExtentScrollController _hourWheel;
  late final FixedExtentScrollController _minuteWheel;
  late final FixedExtentScrollController _secondWheel;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedHour =
        now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    _selectedMinute = now.minute;
    _selectedSecond = now.second;
    _selectedPeriod = now.hour < 12 ? 'AM' : 'PM';
    _hourWheel = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteWheel = FixedExtentScrollController(initialItem: _selectedMinute);
    _secondWheel = FixedExtentScrollController(initialItem: _selectedSecond);
  }

  @override
  void dispose() {
    _hourWheel.dispose();
    _minuteWheel.dispose();
    _secondWheel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      height: 300,
      child: Column(
        children: [
          // أزرار CANCEL / DONE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.loc.cancelButton,
                    style: context.styles.error),
              ),
              TextButton(
                onPressed: () {
                  final time =
                      '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}:${_selectedSecond.toString().padLeft(2, '0')} ${_selectedPeriod == 'AM' ? context.loc.am : context.loc.pm}';
                  widget.onDone(time);
                },
                child: Text(context.loc.saveButton,
                    style: context.styles.gold),
              ),
            ],
          ),
          const Divider(),
          // العجلات
          Expanded(
            child: Row(
              children: [
                _buildWheel(24, _hourWheel, _selectedHour,
                    (v) => setState(() => _selectedHour = v)),
                _buildWheel(60, _minuteWheel, _selectedMinute,
                    (v) => setState(() => _selectedMinute = v)),
                _buildWheel(60, _secondWheel, _selectedSecond,
                    (v) => setState(() => _selectedSecond = v)),
                _buildPeriodWheel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheel(int max, FixedExtentScrollController controller,
      int selected, Function(int) onChanged) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,
        diameterRatio: 1.5,
        onSelectedItemChanged: onChanged,
        controller: controller,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) => Center(
            child: Text(
              index.toString().padLeft(2, '0'),
              style: context.styles.body.copyWith(
                fontSize: AppTypography.headerSize,
                fontWeight: index == selected
                    ? AppTypography.bold
                    : AppTypography.regular,
                color: index == selected
                    ? AppColors.primaryGold
                    : context.styles.subtitle.color,
              ),
            ),
          ),
          childCount: max,
        ),
      ),
    );
  }

  Widget _buildPeriodWheel() {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,
        diameterRatio: 1.5,
        onSelectedItemChanged: (index) {
          setState(() => _selectedPeriod = index == 0 ? 'AM' : 'PM');
        },
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) => Center(
            child: Text(
              index == 0 ? context.loc.am : context.loc.pm,
              style: context.styles.body.copyWith(
                fontWeight: _selectedPeriod == (index == 0 ? 'AM' : 'PM')
                    ? AppTypography.bold
                    : AppTypography.regular,
                color: _selectedPeriod == (index == 0 ? 'AM' : 'PM')
                    ? AppColors.primaryGold
                    : context.styles.subtitle.color,
              ),
            ),
          ),
          childCount: 2,
        ),
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    var max = size.width;
    var dashWidth = 5;
    var dashSpace = 3;
    double startX = 0;
    while (startX < max) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
