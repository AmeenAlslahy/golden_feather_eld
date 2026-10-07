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
import '../widgets/inspection_log_header_table.dart';
import '../../../../core/widgets/eld_date_paginator.dart';
import '../../../../core/widgets/eld_events_table.dart';
/// عرض التفتيش النشط (مقفل بـ PIN).
///
/// الـ ref يُقرأ في قمة الـ build فقط؛ كل ما تحته ودجات عميقة تستقبل
/// قيماً جاهزة وcallbacks — لا منطق ولا مزودات داخل الشجرة.
class InspectionActiveView extends ConsumerWidget {
  const InspectionActiveView({super.key, required this.onExitRequest});

  final VoidCallback onExitRequest;

  /// ملصق اليوم = تاريخ السجل (logDate) لا displayDate — الثاني ثابت لكل
  /// الأيام (تاريخ محطة التفتيش من الخادم) فكان يجعل التنقل يبدو ميّتاً.
  String _dayLabel(InspectionState state) {
    final date = state.selectedDay?.logDate ?? state.log?.logDate;
    if (date == null) return '';
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

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
        EldDatePaginator(
          dateLabel: _dayLabel(state),
          isLoading: state.isDayLoading,
          backgroundColor: AppColors.primaryGold.withValues(alpha: 0.05),
          textColor: context.styles.bodyBold.color,
          iconColor: context.theme.iconTheme.color ?? context.styles.body.color,
          // ترتيب cycle: index 0 = الأحدث. الأيسر = يوم أقدم (index+1)
          // والأيمن = يوم أحدث (index-1) — فهارس مطلقة لا دلتا نسبية.
          canGoOlder: state.selectedDayIndex < state.cycle.length - 1,
          canGoNewer: state.selectedDayIndex > 0,
          onSelectOlder: () => ref
              .read(inspectionProvider.notifier)
              .selectDay(state.selectedDayIndex + 1),
          onSelectNewer: () => ref
              .read(inspectionProvider.notifier)
              .selectDay(state.selectedDayIndex - 1),
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
                      EldEventsTable(
                        rows: log.events.map((e) => EldTableRow(
                          time: e.timeEt,
                          status: e.eventCode,
                          location: e.location,
                          odom: e.odometer.toStringAsFixed(0),
                          eng: e.engineHours.toStringAsFixed(1),
                          src: e.origin,
                          statusColor: null,
                        )).toList(),
                      ),
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

