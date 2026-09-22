import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';

import '../../../../core/services/live_tracking_data_source.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_gap.dart';

final logGraphEventsProvider = StreamProvider.autoDispose<EldEvent>((ref) {
  return ref.watch(liveTrackingDataSourceProvider).events;
});

/// رسم بياني لـ 24 ساعة على شكل خط متصل (تخطيط قلب)
class LogGraph extends ConsumerWidget {
  final List<dynamic> events;

  const LogGraph({super.key, required this.events});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // الاستماع للتدفق الحي للأحداث
    final latestEldEvent = ref.watch(logGraphEventsProvider).valueOrNull;

    return Container(
      height: 190,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.sm,
        top: AppSpacing.md,
        bottom: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الرسم البياني
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _LogGraphPainter(
                    events: events,
                    latestEldEvent: latestEldEvent,
                    textColor: Theme.of(context).colorScheme.onSurface,
                    surfaceColor: Theme.of(context).colorScheme.surface,
                    gridColor: Theme.of(context).colorScheme.outlineVariant,
                  ),
                );
              },
            ),
          ),

          // محور الوقت
          AppGap.xs,
          _buildTimeAxis(context),
        ],
      ),
    );
  }

  Widget _buildTimeAxis(BuildContext context) {
    final hours = [
      'M',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      '11',
      'N',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      '11',
      'M'
    ];
    return Row(
      children: hours.map((h) {
        return Expanded(
          child: Text(
            h,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// رسام المخطط الخطي المتصل (ECG Style)
class _LogGraphPainter extends CustomPainter {
  final List<dynamic> events;
  final EldEvent? latestEldEvent;
  final Color textColor;
  final Color surfaceColor;
  final Color gridColor;

  _LogGraphPainter({
    required this.events,
    this.latestEldEvent,
    required this.textColor,
    required this.surfaceColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width - 40;
    final chartHeight = size.height;
    const offsetX = 40.0;
    final rowHeight = chartHeight / 4;

    // 1. رسم خطوط الشبكة
    _drawGridLines(canvas, size, offsetX, chartWidth, rowHeight);

    // 2. رسم تسميات المحور Y (OFF, SB, D, ON)
    _drawYAxisLabels(canvas, size, rowHeight);

    // 3. رسم إحصائيات الساعات على اليمين
    _drawRightSideStats(canvas, size, rowHeight);

    // 4. رسم الخط الأزرق المتصل (القلب) بناءً على الأحداث
    _drawStepLine(canvas, size, offsetX, chartWidth, chartHeight, rowHeight);

    // 5. رسم مؤشر الحدث الحي (Live Event Marker)
    if (latestEldEvent != null) {
      _drawLiveMarker(canvas, size, offsetX, chartWidth, rowHeight);
    }
  }

  void _drawLiveMarker(Canvas canvas, Size size, double offsetX,
      double chartWidth, double rowHeight) {
    final now = latestEldEvent!.timestamp;
    final startHour = now.hour + now.minute / 60.0;
    final xPos = offsetX + (startHour / 24.0) * chartWidth;

    // الحصول على الحالة الحالية (افتراضياً ON إذا لم يتم تحديدها بدقة)
    // يمكن تحسينها لاحقاً لتقرأ الحالة الفعلية من محرك HOS
    final yPos = _getYPosition('ON', rowHeight);

    final markerPaint = Paint()
      ..color = AppColors.warningYellow
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = AppColors.warningYellow.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // رسم هالة (Glow) حول النقطة الحية
    canvas.drawCircle(Offset(xPos, yPos), 6.0, glowPaint);
    // رسم النقطة الحية
    canvas.drawCircle(Offset(xPos, yPos), 3.0, markerPaint);
  }

  void _drawGridLines(Canvas canvas, Size size, double offsetX,
      double chartWidth, double rowHeight) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    // أفقي
    for (int i = 0; i <= 4; i++) {
      canvas.drawLine(Offset(offsetX, i * rowHeight),
          Offset(size.width, i * rowHeight), gridPaint);
    }

    // عمودي (كل ساعة)
    final colWidth = chartWidth / 24;
    for (int i = 0; i <= 24; i++) {
      canvas.drawLine(Offset(offsetX + i * colWidth, 0),
          Offset(offsetX + i * colWidth, size.height), gridPaint);
    }
  }

  void _drawYAxisLabels(Canvas canvas, Size size, double rowHeight) {
    const labels = ['OFF', 'SB', 'D', 'ON'];
    for (int i = 0; i < labels.length; i++) {
      final textSpan = TextSpan(
        text: labels[i],
        style: TextStyle(
            fontSize: 9,
            color: textColor.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500),
      );
      final textPainter =
          TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas,
          Offset(4, i * rowHeight + rowHeight / 2 - textPainter.height / 2));
    }
  }

  void _drawRightSideStats(Canvas canvas, Size size, double rowHeight) {
    const labels = ['OFF', 'SB', 'D', 'ON'];
    // حساب الإحصائيات
    final Map<String, double> stats = {'OFF': 0, 'SB': 0, 'D': 0, 'ON': 0};
    for (final event in events) {
      final status = event.status as String;
      final duration = event.duration as Duration;
      if (stats.containsKey(status)) {
        stats[status] = stats[status]! + (duration.inMinutes / 60.0);
      }
    }

    for (int i = 0; i < labels.length; i++) {
      final String formattedStat =
          (stats[labels[i]] ?? 0.0).toStringAsFixed(2).padLeft(5, '0');
      final textSpan = TextSpan(
        text: formattedStat,
        style: TextStyle(
            fontSize: 10,
            color: textColor.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600),
      );
      final textPainter =
          TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(size.width - textPainter.width - 4,
              i * rowHeight + rowHeight / 2 - textPainter.height / 2));
    }
  }

  /// الدالة الأساسية لرسم الخط المتصل الأزرق
  void _drawStepLine(Canvas canvas, Size size, double offsetX,
      double chartWidth, double chartHeight, double rowHeight) {
    if (events.isEmpty) return;

    // إعدادات القلم للخط الأزرق الرفيع
    final linePaint = Paint()
      ..color = AppColors.primaryBlue // لون أزرق داكن مشابه للصورة
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // ترتيب الأحداث حسب الوقت (ضروري لرسم خط متصل صحيح)
    final sortedEvents = List<dynamic>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // 1. إيجاد الحالة عند منتصف الليل (لبدء الرسم من أقصى اليسار)
    // نفترض أن أول حدث يبدأ عند منتصف الليل أو قبله.
    // سنبدأ رسم الخط من الساعة 0:00 (x = offsetX) عند مستوى الحالة الأولى
    final firstEvent = sortedEvents.first;
    final double startY = _getYPosition(firstEvent.status, rowHeight);

    path.moveTo(offsetX, startY); // نقطة البداية عند أقصى اليسار

    double currentX = offsetX;
    double currentY = startY;

    for (final event in sortedEvents) {
      final startTime = event.startTime as DateTime;
      final duration = event.duration as Duration;
      final status = event.status as String;

      // حساب الوقت بالساعات منذ منتصف الليل (0.0 إلى 24.0)
      final startHour = startTime.hour + startTime.minute / 60.0;
      final endHour = startHour + (duration.inMinutes / 60.0);

      // تحويل الوقت إلى احداثيات X
      final xStart = offsetX + (startHour / 24.0) * chartWidth;
      final xEnd = offsetX + (endHour / 24.0) * chartWidth;

      // 2. الحركة العمودية المفاجئة (تغيير الحالة)
      final double newY = _getYPosition(status, rowHeight);

      // إذا تغيرت الحالة، ارسم خطاً عمودياً (انتقال مباشر للأسفل/للأعلى)
      // (ملاحظة: نحرص على عدم رسم خط عامودي إذا كانت xStart مساوية لـ currentX بسبب أخطاء التوقيت)
      if (xStart > currentX + 0.01) {
        path.lineTo(xStart, currentY); // خط أفقي قبل تغيير الحالة
      }

      path.lineTo(xStart, newY); // خط عمودي (نقلة نوعية)

      // 3. الحركة الأفقية (استمرار الحالة)
      path.lineTo(xEnd, newY);

      // تحديث المتغيرات الحالية للنقطة التالية
      currentX = xEnd;
      currentY = newY;
    }

    // التأكد من أن الخط ينتهي عند أقصى اليمين (الساعة 24:00)
    if (currentX < offsetX + chartWidth) {
      path.lineTo(offsetX + chartWidth, currentY);
    }

    canvas.drawPath(path, linePaint);
  }

  /// دالة مساعدة لحساب موقع Y بناءً على الحالة
  double _getYPosition(String status, double rowHeight) {
    int index = 0;
    switch (status) {
      case 'OFF':
        index = 0;
        break;
      case 'SB':
        index = 1;
        break;
      case 'D':
        index = 2;
        break;
      case 'ON':
        index = 3;
        break;
      default:
        index = 0;
    }
    // إضافة (rowHeight / 2) ليتمركز الخط في منتصف الصف بالضبط
    return index * rowHeight + (rowHeight / 2);
  }

  @override
  bool shouldRepaint(covariant _LogGraphPainter oldDelegate) {
    return events != oldDelegate.events ||
        latestEldEvent != oldDelegate.latestEldEvent;
  }
}
