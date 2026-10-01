/// مساعدات تحليل JSON المشتركة بين كل mappers محرك ELD.
///
/// كانت منسوخة حرفياً بين `StatusDashboardMapper` و`DotInspectionMapper`
/// (~80 سطراً) — الآن مصدر واحد. ملفات mapper لا تعرّف مساعدات خاصة
/// إلا لقاعدة تحليل خاصة بمجالها الفعلي.
abstract final class JsonPrimitives {
  /// نص مقطوع من الفراغ، مع fallback عند العدم أو النص الفارغ.
  static String asString(Object? v, {String fallback = ''}) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  /// نص أو null عند العدم/الفارغ — للحقول الاختيارية.
  static String? asStringOrNull(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int asInt(Object? v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static double asDouble(Object? v, {double fallback = 0.0}) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static bool asBool(Object? v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true';
    return fallback;
  }

  static List<String> asStringList(Object? v) {
    if (v is! List) return const [];
    return v
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  /// التاريخ الناقص يُعلَّم بميلاد Unix (1970) لا بتاريخ وهمي يبدو حقيقياً —
  /// عرض 2026-01-01 كان قد يُقدَّم كأنه تاريخ رسمي في شاشة التفتيش.
  static DateTime asDate(Object? v) {
    return asDateOrNull(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? asDateOrNull(Object? v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  /// `LocalTime` = `{hour, minute, second, nano}` (أو نص `HH:mm[:ss]`).
  static String? asLocalTime(Object? raw) {
    if (raw is Map) {
      final h = asInt(raw['hour']);
      final m = asInt(raw['minute']);
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }
    if (raw is String && raw.length >= 5) return raw.substring(0, 5);
    return null;
  }
}
