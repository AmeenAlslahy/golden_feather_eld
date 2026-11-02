import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/time/trusted_time_provider.dart';
import '../../../../../domain/duty_status/duty_status_code.dart';
import '../../../../../domain/duty_status/status_dashboard.dart';
import '../../../../../core/utils/duration_format.dart';
import 'circular_timer_logic.dart';
import 'main_circular_timer.dart';

extension HosIndicatorCriticalX on HosIndicator {
  bool get isCritical =>
      type == IndicatorType.remaining && value <= const Duration(hours: 1);
}

/// "HOURS OF SERVICE" table with the four HOS indicators
/// (drive, shift, break, cycle) — reference layout (screenshot 1):
/// grey header row, then label / limit description on the left and the
/// large HH:MM value on the right.
///
/// 🔴 **ينزلق الآن** بنفس عدّاد الدائرة تماماً.
///
/// كان يعرض `indicator.value` الخام: قيمة ثابتة من آخر جلب، بينما
/// الدائرة تنقص في نفس اللحظة. فكان التطبيق يعرض رقمين مختلفين لنفس
/// الحدّ القانوني على الشاشة نفسها.
class HosIndicatorsCard extends ConsumerStatefulWidget {
  final HosIndicators indicators;

  /// Rule set and legal limits applied by the server (SRS 4.x); they feed
  /// the description line under each label ("11-Hour Driving Limit").
  final RegulatoryConstraints? constraints;

  /// لحظة قياس اللقطة — **نفس** قيمة `MainCircularTimer.snapshotTimestamp`.
  final DateTime? snapshotTimestamp;

  /// حالة الخدمة الحالية، لتحديد هل ينزلق الوقت أصلاً.
  final DutyStatusCode? dutyStatus;

  /// اسم الحالة المعروض (يُستخدم في كشف الراحة كحل احتياطي).
  final String statusLabel;

  /// اختياري: مصدر موحّد للزمن المنقضي لمزامنة البطاقة مع الدائرة المركزية
  final ValueListenable<Duration>? elapsedNotifier;

  const HosIndicatorsCard({
    super.key,
    required this.indicators,
    this.constraints,
    this.snapshotTimestamp,
    this.dutyStatus,
    this.statusLabel = '',
    this.elapsedNotifier,
  });

  @override
  ConsumerState<HosIndicatorsCard> createState() => _HosIndicatorsCardState();
}

class _HosIndicatorsCardState extends ConsumerState<HosIndicatorsCard> {
  Timer? _ticker;
  late final Stopwatch _stopwatch;
  late final ValueNotifier<Duration> _elapsedNotifier;

  ValueListenable<Duration> get _effectiveElapsedNotifier =>
      widget.elapsedNotifier ?? _elapsedNotifier;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _elapsedNotifier = ValueNotifier(_computeElapsed());
    _startTickerIfNeeded();
  }

  @override
  void didUpdateWidget(HosIndicatorsCard old) {
    super.didUpdateWidget(old);
    if (widget.elapsedNotifier == null &&
        (old.snapshotTimestamp != widget.snapshotTimestamp ||
            old.dutyStatus != widget.dutyStatus ||
            old.indicators != widget.indicators)) {
      _stopwatch.reset();
      _stopwatch.start();
      _elapsedNotifier.value = _computeElapsed();
      _startTickerIfNeeded();
    }
  }

  Duration _computeElapsed() => computeElapsedSinceSnapshot(
    trustedTime: ref.read(trustedTimeProvider).currentTime,
    snapshotTimestamp: widget.snapshotTimestamp,
    stopwatchElapsed: _stopwatch.elapsed,
  );

  bool get _isRestDuty =>
      CircularTimerLogic.isRestDuty(widget.dutyStatus, widget.statusLabel);

  void _startTickerIfNeeded() {
    _ticker?.cancel();
    _ticker = null;
    if (widget.elapsedNotifier != null) return;
    // في الراحة لا عمل ولا قيادة: لا شيء ينزلق، فلا داعي لنبضة كل ثانية.
    if (!_isRestDuty) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) _elapsedNotifier.value = _computeElapsed();
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    _elapsedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final descriptions = _descriptions(context);

    return ValueListenableBuilder<Duration>(
      valueListenable: _effectiveElapsedNotifier,
      builder: (context, elapsed, _) {
        final live = CircularTimerLogic.liveIndicators(
          indicators: widget.indicators,
          dutyStatus: widget.dutyStatus,
          statusLabel: widget.statusLabel,
          elapsedSinceSnapshot: elapsed,
        );

        return Column(
          children: [
            Container(
              width: double.infinity,
              // الشريط تحت دائرة الوقت: كان يستخدم رمز الخلفية الفاتحة فيظهر
              // أبيض في الوضع الداكن (بلاغ المالك).
              color: context.colorScheme.surfaceBright,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                loc.hoursOfService,
                textAlign: TextAlign.center,
                style: context.styles.caption.copyWith(letterSpacing: 1.0),
              ),
            ),
            const Divider(height: 1),
            _IndicatorRow(indicator: live.drive, description: descriptions[0]),
            const Divider(height: 1),
            _IndicatorRow(indicator: live.shift, description: descriptions[1]),
            const Divider(height: 1),
            _IndicatorRow(
              indicator: live.breakTime,
              description: descriptions[2],
            ),
            const Divider(height: 1),
            _IndicatorRow(indicator: live.cycle, description: descriptions[3]),
            const Divider(height: 1),
          ],
        );
      },
    );
  }

  /// Drive / shift / break / cycle descriptions. Server limits win when they
  /// carry a number (e.g. `maxDrivingHours: 11`, `Hour Driving Limit-11`);
  /// otherwise the localized reference wording is used.
  List<String> _descriptions(BuildContext context) {
    final loc = context.loc;
    final drive = widget.constraints?.limitHoursFor(['driving', 'drive']);
    final shift = widget.constraints?.limitHoursFor([
      'shift',
      'onduty',
      'on duty',
      'on_duty',
    ]);
    final rest = widget.constraints?.limitHoursFor(['break']);
    final ruleSet = widget.constraints?.ruleSet ?? CycleRule.unknown;

    return [
      drive == null ? loc.driveLimitDesc : loc.driveLimitFormat(drive),
      shift == null ? loc.shiftLimitDesc : loc.shiftLimitFormat(shift),
      rest == null ? loc.breakLimitDesc : loc.breakLimitFormat(rest),
      ruleSet == CycleRule.unknown ? loc.cycleLimitDesc : ruleSet.wire,
    ];
  }
}

class _IndicatorRow extends StatelessWidget {
  final HosIndicator indicator;
  final String description;

  const _IndicatorRow({required this.indicator, required this.description});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final isCritical = indicator.isCritical;
    final baseDesc =
        (indicator.subtitle != null && indicator.subtitle!.trim().isNotEmpty)
            ? indicator.subtitle!.trim()
            : description;
    final detail = indicator.type == IndicatorType.used
        ? loc.usedFormat(baseDesc)
        : baseDesc;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  indicator.label,
                  style: context.styles.sectionTitle.copyWith(
                    fontWeight: AppTypography.bold,
                    color: context.styles.body.color,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(detail, style: context.styles.caption),
              ],
            ),
          ),
          Expanded(
            child: Text(
              DurationFormat.hhMm(indicator.value),
              textAlign: TextAlign.end,
              style: context.styles.body.copyWith(
                fontSize: AppTypography.headerSize,
                fontWeight: AppTypography.regular,
                color: isCritical ? context.styles.error.color : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
