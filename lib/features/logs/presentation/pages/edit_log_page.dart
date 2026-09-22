import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/providers/app_repository_providers.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/time/time_authority_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_gap.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../domain/entities/audit_entry.dart';
import '../../domain/entities/daily_log.dart';
import '../providers/logs_provider.dart';
import '../widgets/log_graph.dart';

@visibleForTesting
String? resolveDriverIdForAudit(WidgetRef ref) {
  return ref.read(authStateProvider).user?.id;
}

class EditLogFormState {
  final String selectedStatus;
  final DateTime startTime;
  final Duration duration;
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
    DateTime? startTime,
    Duration? duration,
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

  String get formattedStartTime {
    final hour = startTime.hour > 12
        ? startTime.hour - 12
        : (startTime.hour == 0 ? 12 : startTime.hour);
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = startTime.minute.toString().padLeft(2, '0');
    final secondStr = startTime.second.toString().padLeft(2, '0');
    final period = startTime.hour < 12 ? 'AM' : 'PM';
    return '$hourStr:$minuteStr:$secondStr $period';
  }

  String get formattedDuration {
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class EditLogFormNotifier extends StateNotifier<EditLogFormState> {
  EditLogFormNotifier(super.state);

  void setStatus(String status) =>
      state = state.copyWith(selectedStatus: status);
  void setStartTime(DateTime time) => state = state.copyWith(startTime: time);
  void setReason(String reason) => state = state.copyWith(reason: reason);
}

final editLogFormProvider = StateNotifierProvider.autoDispose
    .family<EditLogFormNotifier, EditLogFormState, dynamic>((ref, event) {
  if (event is! LogEvent) {
    throw ArgumentError('event must be a LogEvent');
  }
  return EditLogFormNotifier(EditLogFormState(
    selectedStatus: event.status,
    startTime: event.startTime,
    duration: event.duration,
    location: event.location,
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
    final logEvent = event as LogEvent;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _TimePickerSheet(
        onDone: (hour, minute, second) {
          final newDateTime = DateTime(
            logEvent.startTime.year,
            logEvent.startTime.month,
            logEvent.startTime.day,
            hour,
            minute,
            second,
          );
          ref
              .read(editLogFormProvider(event).notifier)
              .setStartTime(newDateTime);
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
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.surface,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md), // تم تصغير الـ padding الجانبي
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. الرسم البياني الحقيقي (بدلاً من EldCard)
            AppGap.md,
            LogGraph(
                events:
                    selectedLog?.events ?? []), // تمرير الأحداث الحقيقية لليوم

            // 2. حقل الوقت والمدة
            AppGap.md,
            Row(
              children: [
                Expanded(
                    child: _buildTimeField(
                        context,
                        context.loc.startTime,
                        formState.formattedStartTime,
                        () => _showTimePicker(context, ref))),
                Expanded(
                    child: _buildTimeField(context, context.loc.duration,
                        formState.formattedDuration, () {})),
              ],
            ),
            // خط متقطع أسفل الوقت (للمطابقة)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: CustomPaint(
                  painter:
                      DashedLinePainter(color: Theme.of(context).dividerColor)),
            ),
            AppGap.lg,

            // 3. قائمة الحالات
            ...statuses.map((status) {
              final isSelected = formState.selectedStatus == status['value'];
              return Column(
                children: [
                  RadioListTile<String>(
                    title: Text(
                      status['label']!,
                      style: TextStyle(
                        fontSize: AppTypography.bodySize,
                        fontWeight: isSelected
                            ? AppTypography.semiBold
                            : AppTypography.regular,
                        color: isSelected
                            ? AppColors.primaryBlue
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    value: status['value']!,
                    // ignore: deprecated_member_use
                    groupValue: formState.selectedStatus,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      ref
                          .read(editLogFormProvider(event).notifier)
                          .setStatus(value!);
                    },
                    activeColor: AppColors.primaryBlue,
                    controlAffinity: ListTileControlAffinity.trailing,
                    contentPadding: EdgeInsets.zero,
                  ),
                  Divider(
                      color:
                          Theme.of(context).dividerColor.withValues(alpha: 0.5),
                      height: 1),
                ],
              );
            }),
            AppGap.md,

            // 4. المركبة
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc.vehicle,
                  style: const TextStyle(
                    fontSize: AppTypography.bodySize,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                AppGap.sm,
                Text(
                  dashboard.vehicleId,
                  style: const TextStyle(
                    fontSize: AppTypography.bodySize,
                  ),
                ),
                AppGap.sm,
                Divider(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.5),
                    height: 1),
              ],
            ),
            AppGap.md,

            // 5. الموقع
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc.location,
                  style: const TextStyle(
                    fontSize: AppTypography.bodySize,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                AppGap.sm,
                Text(
                  formState.location,
                  style: const TextStyle(
                    fontSize: AppTypography.bodySize,
                  ),
                ),
                AppGap.sm,
                Divider(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.5),
                    height: 1),
              ],
            ),
            AppGap.md,

            // 6. إدخال موقع يدوي
            TextField(
              decoration: InputDecoration(
                hintText: context.loc.manualLocation,
                hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: AppTypography.bodySize),
              onChanged: (value) {},
            ),
            AppGap.md,

            // حقل سبب التعديل (إجباري)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reason for Change',
                  style: TextStyle(
                    fontSize: AppTypography.bodySize,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                AppGap.sm,
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter reason (Required)',
                    hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    border: const UnderlineInputBorder(),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  ),
                  style: const TextStyle(fontSize: AppTypography.bodySize),
                  onChanged: (value) {
                    ref
                        .read(editLogFormProvider(event).notifier)
                        .setReason(value);
                  },
                ),
              ],
            ),
            AppGap.lg,

            // 7. زر الحفظ
            AppButton(
              label:
                  isNewEvent ? context.loc.addButton : context.loc.saveButton,
              type: EldButtonType.agree,
              onPressed: formState.reason.trim().isEmpty
                  ? null
                  : () async {
                      // حفظ التعديلات وسجل التدقيق
                      final notifier = ref.read(logsProvider.notifier);
                      final repository = ref.read(logRepositoryProvider);

                      final driverId = resolveDriverIdForAudit(ref);

                      if (driverId == null || driverId.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Cannot save: driver session not found.'),
                              backgroundColor: AppColors.dangerRed,
                            ),
                          );
                        }
                        return;
                      }

                      if (!isNewEvent) {
                        final logEvent = event as LogEvent;
                        final result = await repository.updateEvent(
                          LogEvent(
                            id: logEvent.id,
                            status: formState.selectedStatus,
                            statusArabic: formState.selectedStatus,
                            startTime: formState.startTime,
                            duration: formState.duration,
                            location: formState.location,
                            notes: formState.reason,
                            odometer: logEvent.odometer,
                            engineHours: logEvent.engineHours,
                          ),
                        );

                        if (context.mounted) {
                          result.match(
                            (failure) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Failed to update event: ${failure.message}'),
                                  backgroundColor: AppColors.dangerRed,
                                ),
                              );
                            },
                            (success) {
                              // Event updated successfully
                            },
                          );
                        }
                      } else {
                        // isNewEvent
                        final result = await repository.addEvent(
                          LogEvent(
                            id: const Uuid().v4(),
                            status: formState.selectedStatus,
                            statusArabic: formState.selectedStatus,
                            startTime: formState.startTime,
                            duration: formState.duration,
                            location: formState.location,
                            notes: formState.reason,
                            odometer: 0, // Should be fetched from dashboard/vehicle
                            engineHours: 0,
                          ),
                        );

                        if (context.mounted) {
                          result.match(
                            (failure) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Failed to add event: ${failure.message}'),
                                  backgroundColor: AppColors.dangerRed,
                                ),
                              );
                            },
                            (success) {},
                          );
                        }
                      }

                      final timeAuthority = ref.read(timeAuthorityProvider);

                      final entry = AuditEntry(
                        id: const Uuid().v4(),
                        timestamp: timeAuthority.nowUtc(),
                        driverId: driverId,
                        oldStatus: isNewEvent ? null : event.status,
                        newStatus: formState.selectedStatus,
                        reason: formState.reason,
                      );

                      await notifier.saveAuditEntry(entry);
                      // Force refresh the logs so the UI reflects the edit
                      await notifier.loadLogs(refresh: true);
                      
                      if (context.mounted) Navigator.pop(context, true);
                    },
            ),
            AppGap.md,
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
              style: const TextStyle(
                fontSize: AppTypography.subtitleSize,
                fontWeight: AppTypography.semiBold,
              ),
            ),
            AppGap.sm,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: AppTypography.bodySize,
                    fontWeight: AppTypography.regular,
                  ),
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
  final Function(int, int, int) onDone;

  const _TimePickerSheet({required this.onDone});

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  int _selectedHour = 12;
  int _selectedMinute = 0;
  int _selectedSecond = 0;
  String _selectedPeriod = 'AM';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedHour =
        now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    _selectedMinute = now.minute;
    _selectedSecond = now.second;
    _selectedPeriod = now.hour < 12 ? 'AM' : 'PM';
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
                onPressed: () => context.pop(),
                child: Text(context.loc.cancelButton,
                    style: const TextStyle(color: AppColors.dangerRed)),
              ),
              TextButton(
                onPressed: () {
                  int hour24 = _selectedPeriod == 'AM'
                      ? (_selectedHour == 12 ? 0 : _selectedHour)
                      : (_selectedHour == 12 ? 12 : _selectedHour + 12);
                  widget.onDone(hour24, _selectedMinute, _selectedSecond);
                },
                child: Text(context.loc.saveButton,
                    style: const TextStyle(color: AppColors.primaryBlue)),
              ),
            ],
          ),
          const Divider(),
          // العجلات
          Expanded(
            child: Row(
              children: [
                _buildWheel(24, _selectedHour,
                    (v) => setState(() => _selectedHour = v)),
                _buildWheel(60, _selectedMinute,
                    (v) => setState(() => _selectedMinute = v)),
                _buildWheel(60, _selectedSecond,
                    (v) => setState(() => _selectedSecond = v)),
                _buildPeriodWheel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheel(int max, int selected, Function(int) onChanged) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,
        diameterRatio: 1.5,
        onSelectedItemChanged: onChanged,
        controller: FixedExtentScrollController(initialItem: selected),
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) => Center(
            child: Text(
              index.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: AppTypography
                    .headerSize, // replaced AppTypography.headerSize directly? Wait, AppTypography.headerSize is 28.0, so this is fine.
                fontWeight: index == selected
                    ? AppTypography.bold
                    : AppTypography.regular,
                color: index == selected
                    ? AppColors.primaryBlue
                    : AppColors.textSecondary,
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
              style: TextStyle(
                fontSize: AppTypography.bodySize,
                fontWeight: _selectedPeriod == (index == 0 ? 'AM' : 'PM')
                    ? AppTypography.bold
                    : AppTypography.regular,
                color: _selectedPeriod == (index == 0 ? 'AM' : 'PM')
                    ? AppColors.primaryBlue
                    : AppColors.textSecondary,
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

