import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/inspection/dot_inspection.dart';
import '../../../../domain/duty_status/duty_status_code.dart';
import '../../../../core/widgets/eld_graph_grid.dart';

/// 24-hour duty graph for inspection mode, drawn from DOT log events.
class InspectionDutyGraph extends StatelessWidget {
  const InspectionDutyGraph({super.key, required this.events});

  final List<DotInspectionEvent> events;

  @override
  Widget build(BuildContext context) {
    // 1) حلل كل حدث (المتعذر يُسقط)، 2) رتب زمنياً — ترتيب الخادم غير مضمون
    // وبدون الترتيب تُرسم مقاطع عكسية/مكسورة، 3) نهاية كل مقطع = بداية التالي.
    final parsed = <_Segment>[];
    for (final event in events) {
      // استبعاد أحداث التوقيع/الاعتماد والأحداث غير المتعلقة بتغيير حالة الخدمة
      // وفقاً لمعايير FMCSA: الرسم البياني لـ 24 ساعة يمثل خطوط حالات الخدمة فقط.
      if (event.certificationEvent ||
          event.eventType.toUpperCase() == 'CERTIFICATION' ||
          event.eventCode.trim().toUpperCase() == 'CERT') {
        continue;
      }

      final startHour = _hourOf(event.timeEt);
      if (startHour == null) continue;

      final row = _rowOf(event);
      final parsedCode = DutyStatusCode.fromAny(row);
      parsed.add(_Segment(
        startHour: startHour,
        status: parsedCode.canonicalGridShortCode,
        special: parsedCode.specialCategoryTag,
      ));
    }
    parsed.sort((a, b) => a.startHour.compareTo(b.startHour));

    final points = <EldGraphPoint>[];
    if (parsed.isEmpty) {
      // FMCSA requirement: A day with no duty status changes is recorded as
      // continuous OFF duty across the entire 24-hour period.
      points.add(
        const EldGraphPoint(
          startHour: 0.0,
          endHour: 24.0,
          status: 'OFF',
        ),
      );
    } else {
      for (int i = 0; i < parsed.length; i++) {
        final seg = parsed[i];
        double endHour = 24.0;
        if (i + 1 < parsed.length) {
          endHour = parsed[i + 1].startHour;
        }
        // تجاهل المقاطع الصفرية/العكسية بعد التقريب.
        if (endHour - seg.startHour < 1 / 3600) continue;
        points.add(
          EldGraphPoint(
            startHour: seg.startHour,
            endHour: endHour,
            status: seg.status,
            tag: seg.special,
            isDashed: seg.special != null,
          ),
        );
      }
    }

    return Container(
      height: 180,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xs,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: EldGraphGrid(
              points: points,
              // Inspection screen doesn't need right-side stats shown in the graph widget itself
            ),
          );
        },
      ),
    );
  }

  static double? _hourOf(String timeEt) {
    final text = timeEt.trim();
    if (text.isEmpty) return null;

    // ISO / datetime (مع منطقة زمنية أو بدونها).
    final parsed = DateTime.tryParse(text);
    if (parsed != null) {
      return parsed.hour + parsed.minute / 60.0 + parsed.second / 3600.0;
    }

    // Epoch بالثواني (10 أرقام) أو الميلي ثانية (13 رقماً) → توقيت محلي.
    final epoch = int.tryParse(text);
    if (epoch != null && (text.length == 10 || text.length == 13)) {
      final ms = text.length == 10 ? epoch * 1000 : epoch;
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return dt.hour + dt.minute / 60.0 + dt.second / 3600.0;
    }

    // 12 ساعة مع AM/PM — يدعم ملحقات المنطقة الزمنية والملاحظات مثل:
    // "12:00 AM ET (السابق)" أو "01:01 AM ET" أو "6:05 PM"
    final meridiem = RegExp(
      r'(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([AaPp])\.?\s?[Mm]\.?',
    ).firstMatch(text);
    if (meridiem != null) {
      var h = int.parse(meridiem.group(1)!);
      final m = int.parse(meridiem.group(2)!);
      if (h >= 1 && h <= 12 && m <= 59) {
        final isPm = meridiem.group(4)!.toUpperCase() == 'P';
        if (isPm && h < 12) h += 12;
        if (!isPm && h == 12) h = 0;
        final s = meridiem.group(3) != null ? int.parse(meridiem.group(3)!) : 0;
        if (s <= 59) {
          return h + m / 60.0 + s / 3600.0;
        }
      }
    }

    // 24 ساعة "HH:mm" أو "HH:mm:ss" أو "HH:mm:ss.SSS" (يدعم مسافات أو نصوص ملحقة).
    final hms = RegExp(
      r'(?:^|[^\d])(\d{1,2}):(\d{2})(?::(\d{2}))?(?:\.\d+)?',
    ).firstMatch(text);
    if (hms != null) {
      final h = int.parse(hms.group(1)!);
      final m = int.parse(hms.group(2)!);
      if (h <= 23 && m <= 59) {
        final s = hms.group(3) != null ? int.parse(hms.group(3)!) : 0;
        if (s <= 59) {
          return h + m / 60.0 + s / 3600.0;
        }
      }
    }

    // "HHMM" المدمجة ("0600").
    if (RegExp(r'^\d{4}$').hasMatch(text)) {
      final h = int.parse(text.substring(0, 2));
      final m = int.parse(text.substring(2, 4));
      if (h <= 23 && m <= 59) {
        return h + m / 60.0;
      }
    }

    return null;
  }

  static String _rowOf(DotInspectionEvent event) {
    // The standard duty code is authoritative; free-text matching below is
    // only a fallback for servers that send descriptive codes.
    switch (event.eventCode.trim().toUpperCase()) {
      case '1':
      case 'OFF':
        return 'OFF';
      case '2':
      case 'SB':
        return 'SB';
      case '3':
      case 'D':
        return 'D';
      case '4':
      case 'ON':
        return 'ON';
      case 'PC':
        return 'PC';
      case 'YM':
        return 'YM';
    }
    final raw = '${event.eventCode} ${event.eventType} ${event.description}'
        .toUpperCase();
    // Word boundaries (\b): 'OFFICE' must not match OFF, 'PERSONAL
    // CONVEYANCE' must not land on ON via "cONveyance".
    if (RegExp(r'\bPC\b|\bPERSONAL\b').hasMatch(raw)) return 'PC';
    if (RegExp(r'\bYM\b|\bYARD\b').hasMatch(raw)) return 'YM';
    if (RegExp(r'\bSB\b|\bSLEEPER\b').hasMatch(raw)) return 'SB';
    if (RegExp(r'\bDRIV').hasMatch(raw)) return 'D';
    if (RegExp(r'\bON\b').hasMatch(raw)) return 'ON';
    if (RegExp(r'\bOFF\b').hasMatch(raw)) return 'OFF';
    return 'OFF';
  }
}

/// مقطع زمني محلل قبل بناء النقاط (يُفرز حسب البداية ثم تُشتق النهايات).
class _Segment {
  final double startHour;
  final String status;
  final String? special;

  const _Segment({
    required this.startHour,
    required this.status,
    this.special,
  });
}
