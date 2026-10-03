import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../account/presentation/providers/account_provider.dart';
import '../../../codriver/presentation/providers/codriver_provider.dart';
import '../providers/inspection_provider.dart';
import '../widgets/inspection_duty_graph.dart';
import '../widgets/inspection_events_table.dart';
import '../widgets/inspection_log_header_table.dart';

/// عرض التفتيش النشط (مقفل بـ PIN).
///
/// الـ ref يُقرأ في قمة الـ build فقط؛ كل ما تحته ودجات عميقة تستقبل
/// قيماً جاهزة وcallbacks — لا منطق ولا مزودات داخل الشجرة.
class InspectionActiveView extends ConsumerWidget {
  const InspectionActiveView({super.key, required this.onExitRequest});

  final VoidCallback onExitRequest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inspectionProvider);
    final log = state.log;
    final day = state.selectedDay;
    final license = ref.watch(
      accountProvider.select((s) => s.accountData?.license),
    );
    // Fallback الحي الموثق (SRS 670-675): قيم السجل أولاً والحساب/
    // المرافق الحي احتياطاً — التنسيق الوحيد المسموح في الواجهة.
    final co = ref.watch(codriverProvider.select((s) => s.currentCoDriver));
    final coDriverName = co?.name ?? '';
    final coDriverId = co?.isLinked == true ? '\${co.coDriverId}' : '';

    return Column(
      children: [
        if (state.bannerError != null) _Banner(text: state.bannerError!),
        _DaySelector(
          dateLabel: day?.displayDate.isNotEmpty == true
              ? day!.displayDate
              : (log?.displayDate ?? ''),
          isDayLoading: state.isDayLoading,
          canGoNewer: state.selectedDayIndex < state.cycle.length - 1,
          canGoOlder: state.selectedDayIndex > 0,
          onSelectDay: (index) =>
              ref.read(inspectionProvider.notifier).selectDay(index),
        ),
        const Divider(height: 1),
        Expanded(
          child: log == null
              ? Center(
                  child: Text(
                    state.error ?? context.loc.noData,
                    textAlign: TextAlign.center,
                    style: state.error != null
                        ? context.styles.error
                        : context.styles.muted,
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      InspectionLogHeaderTable(
                        log: log,
                        day: day,
                        driverLicense: license?.number ?? '-',
                        driverLicenseState: license?.state ?? '-',
                        coDriver: coDriverName,
                        coDriverId: coDriverId,
                      ),
                      const Divider(height: 1),
                      InspectionDutyGraph(events: log.events),
                      const Divider(height: 1),
                      InspectionEventsTable(events: log.events),
                      const SizedBox(height: AppSpacing.lg),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AppButton(
                          label: context.loc.driverExit,
                          type: EldButtonType.danger,
                          onPressed: onExitRequest,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// لافتة خطأ الشاشة النشطة — النص جاهز من [InspectionState.bannerError].
class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warningYellow.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: context.styles.warning,
        ),
      ),
    );
  }
}

/// شريط التنقل بين الأيام — عميل أعمى: يستقبل التسمية وحالتي الحدود
/// ويبث الاختيار؛ تعطيل الأسهم أثناء التحميل قرار الحالة لا قراره.
class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.dateLabel,
    required this.isDayLoading,
    required this.canGoNewer,
    required this.canGoOlder,
    required this.onSelectDay,
  });

  final String dateLabel;
  final bool isDayLoading;
  final bool canGoNewer;
  final bool canGoOlder;
  final ValueChanged<int> onSelectDay;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryGold.withValues(alpha: 0.05),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Arrow(
            icon: Icons.chevron_left,
            enabled: !isDayLoading && canGoNewer,
            onPressed: () => onSelectDay(1),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dateLabel,
                key: const Key('inspection-day-label'),
                style: context.styles.bodyBold,
              ),
              if (isDayLoading) ...[
                const SizedBox(width: AppSpacing.sm),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          _Arrow(
            icon: Icons.chevron_right,
            enabled: !isDayLoading && canGoOlder,
            onPressed: () => onSelectDay(-1),
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: Icon(icon), onPressed: enabled ? onPressed : null);
  }
}
