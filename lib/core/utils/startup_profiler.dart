import 'package:flutter/widgets.dart';

import 'logger.dart';

/// M0 — قياس زمن الإقلاع (تشخيص فقط، بلا أي أثر وظيفي).
///
/// العقد:
/// - قراءة Stopwatch + أسطر سجل فقط. لا شبكة، لا حالة أعمال، لا PII
///   (لا Tokens ولا Cookies ولا معرفات سائقين — المعرف الوحيد هو بصمة
///   زمن التشغيل لربط أسطر القياس معًا).
/// - [mark]/[phase]/[markOnce] لا تعدّل ترتيب أي `await`: تُستدعى حول
///   العمليات القائمة كما هي.
/// - كلفة كل قياس = قراءة عدّاد + سطر سجل (يُكتم في وضع الإنتاج العادي
///   بمستوى السجل، ولا تُبنى منها أي عمليات).
/// - يُحذف كله مع المراحل التالية أو يبقى معطّلًا بقرار المالك.
abstract final class StartupProfiler {
  static final Stopwatch _boot = Stopwatch()..start();
  static String? _runId;
  static final Set<String> _once = <String>{};

  /// يُستدعى أول سطر في main() لضبط نقطة الصفر.
  static void start() {
    _boot
      ..reset()
      ..start();
    _log('boot clock started');
  }

  /// معرف تشغيل موحد يربط كل أسطر القياس لنفس الإقلاع (غير حساس، بلا PII).
  static String get runId {
    final current = _runId;
    if (current != null) return current;
    final ms = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final suffix = (_boot.elapsedMicroseconds & 0xFFF).toRadixString(36);
    return _runId =
        '${ms.substring(ms.length > 6 ? ms.length - 6 : 0)}-$suffix';
  }

  /// طابع لحظي: `label @+Xms` — الزمن منذ [start].
  static void mark(String label) =>
      _log('$label @+${_boot.elapsedMilliseconds}ms');

  /// طابع يُسجل مرة واحدة فقط (أول إطار، أول صفحة تفاعلية...).
  static void markOnce(String label) {
    if (_once.add(label)) mark(label);
  }

  /// يلف خطوة تهيئة قائمة كما هي: نفس الـ await، نفس الترتيب، نفس سلوك
  /// الخطأ (الاستثناء يمر كما هو بعد تسجيل المدة).
  static Future<void> phase(String label, Future<void> Function() body) async {
    final watch = Stopwatch()..start();
    _log('$label ▶');
    try {
      await body();
    } finally {
      _log('$label ◀ ${watch.elapsedMilliseconds}ms');
    }
  }

  /// يحدد ظهور أول إطار مرة واحدة — يُستدعى من بناء الجذر، والحارس
  /// الداخلي يجعل الاستدعاءات المتكررة بلا أثر.
  ///
  /// [label] يسمح بتمييز إطار الـ Bootstrap عن إطار التطبيق الحقيقي.
  static void scheduleFirstFrameMark([String label = 'first-frame']) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_once.add(label)) return;
      mark('$label rendered');
    });
  }

  static void _log(String message) =>
      AppLogger.info('STARTUP[${runId.toString()}] $message');
}
