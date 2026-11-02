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

/// هل النص قيمة عرض بديلة لا تمثل موقعاً حقيقياً؟
///
/// نماذج الخادم/الكاش تضع `Unknown Location` أو `Unknown` عند غياب الموقع.
/// هذه ليست مواقع تُرسل في طلب تعديل، وإرسالها يستبدل `null` بقيمة كاذبة.
bool isPlaceholderLocation(String? value) {
  final text = value?.trim().toLowerCase() ?? '';
  if (text.isEmpty) return true;
  return const {
    'unknown location',
    'unknown',
    '-',
    'n/a',
    'none',
  }.contains(text);
}

/// يحول مدة نموذج التعديل إلى [Duration].
///
/// يقبل تنسيق المحرر `HH:mm` (مثل `02:30`) وتنسيق العرض `2h 30m` الذي
/// يبدأ به النموذج من الحدث الحالي. يرجع null إذا تعذر التحليل.
Duration? parseEditFormDuration(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final clock = RegExp(r'^(\d{1,3}):(\d{2})$').firstMatch(trimmed);
  if (clock != null) {
    final hours = int.tryParse(clock.group(1)!);
    final minutes = int.tryParse(clock.group(2)!);
    if (hours == null || minutes == null || minutes > 59) return null;
    return Duration(hours: hours, minutes: minutes);
  }

  final short = RegExp(
    r'^(\d{1,3})\s*h(?:\s*(\d{1,2})\s*m)?$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (short != null) {
    final hours = int.tryParse(short.group(1)!);
    final minutes = short.group(2) == null ? 0 : int.tryParse(short.group(2)!);
    if (hours == null || minutes == null || minutes > 59) return null;
    return Duration(hours: hours, minutes: minutes);
  }

  return null;
}

/// يحول وقت نموذج التعديل إلى [DateTime] على يوم السجل.
///
/// يدعم: `HH:mm`، `h:mm[:ss] AM/PM`. يرجع null إذا تعذر التحليل
/// (يستخدم الداعي وقت الحدث الحالي أو الحاضر كقيمة بديلة).
DateTime? parseEditFormTime(
  String raw,
  DateTime? logDate, [
  DateTime? fallbackDate,
]) {
  final base = logDate ?? fallbackDate;
  if (base == null) return null;
  final trimmed = raw.trim();

  final m24 = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(trimmed);
  if (m24 != null) {
    final h = int.tryParse(m24.group(1)!);
    final m = int.tryParse(m24.group(2)!);
    if (h != null && h < 24 && m != null && m < 60) {
      return DateTime(base.year, base.month, base.day, h, m);
    }
  }

  final m12 = RegExp(
    r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)$',
    caseSensitive: false,
  ).firstMatch(trimmed);
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
