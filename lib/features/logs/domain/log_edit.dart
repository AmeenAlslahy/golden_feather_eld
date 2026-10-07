import 'entities/daily_log.dart';

/// Automatic driving time cannot be shortened or removed by a driver edit.
bool isAutomaticDrivingEvent(LogEvent event) {
  if (event.automatedDriving == true) return true;
  if (event.status == 'D' && event.editable == false) return true;
  return false;
}

String? refuseAutomaticDrivingEdit({
  required LogEvent original,
  required String newStatusCode,
  required DateTime newStart,
}) {
  if (!isAutomaticDrivingEvent(original)) return null;
  if (newStatusCode != original.status || newStart != original.startTime) {
    return 'automatic_driving';
  }
  return null;
}



/// يحول وقت نموذج التعديل إلى [DateTime] على يوم السجل.
///
/// يدعم: `HH:mm`، `h:mm[:ss] AM/PM`. يرجع null إذا تعذر التحليل
/// (يستخدم الداعي وقت الحدث الحالي أو الحاضر كقيمة بديلة).
DateTime? parseEditFormTime(String raw, DateTime? logDate) {
  final base = logDate ?? DateTime.now();
  final trimmed = raw.trim();

  final m24 = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(trimmed);
  if (m24 != null) {
    final h = int.tryParse(m24.group(1)!);
    final m = int.tryParse(m24.group(2)!);
    if (h != null && h < 24 && m != null && m < 60) {
      return DateTime(base.year, base.month, base.day, h, m);
    }
  }

  final m12 = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)$',
          caseSensitive: false)
      .firstMatch(trimmed);
  if (m12 != null) {
    var h = int.tryParse(m12.group(1)!) ?? 0;
    final m = int.tryParse(m12.group(2)!) ?? 0;
    final s = m12.group(3) == null ? 0 : (int.tryParse(m12.group(3)!) ?? 0);
    final pm = (m12.group(4) ?? '').toUpperCase() == 'PM';
    if (pm && h < 12) h += 12;
    if (!pm && h == 12) h = 0;
    if (h < 24 && m < 60) {
      return DateTime(base.year, base.month, base.day, h, m, s);
    }
  }

  return null;
}
