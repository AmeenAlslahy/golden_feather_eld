// lib/core/error/user_facing_message.dart
import 'app_error.dart';
import 'failure.dart';
import '../../l10n/app_localizations.dart';

/// Message shown to the driver. Never the exception, stack, or `toString()`.
String anyErrorUserMessage(Object error, {required AppLocalizations loc}) {
  if (error is AppError) return appErrorUserMessage(error, loc: loc);
  if (error is Failure) {
    if (error is NetworkFailure || error.message == 'noInternet') {
      return loc.errNoInternet;
    }
    // 🔴 رسالة الخادم أولاً — فهي تشرح **ما حدث للسائق** بدل أن تصف
    // سلوك الخادم. «السجل اليومي معتمد مسبقاً، ألغِ الاعتماد أولاً» أنفع
    // من «الخادم رفض الطلب».
    //
    // النثر يُعرض حرفياً؛ الرمز الآلي يُترجَم. الأمان في الحالتين.
    final server = error.serverMessage;
    if (server != null && server.trim().isNotEmpty) {
      final prose = _serverProseOrNull(server);
      if (prose != null) return prose;
      final mapped = _mapTechnicalCode(server, loc);
      if (mapped != null) return mapped;
    }
    if (error is ServerFailure && error.message.isNotEmpty) {
      // 🔴 نثراً بشرياً ⇒ حرفياً. رمزاً آلياً ⇒ نترجمه.
      //
      // ⚠️ الترتيب مقصود: `[appErrorUserMessage]` يمرّر `context['message']`
      // هنا كـ `ServerFailure.message` نثراً، و«already»/«conflict» كلمتان
      // طبيعيتان في جملة إنجليزية — فلو صُنِّف أولاً لاختزل تفسير الخادم
      // الدقيق إلى رمز عام.
      final prose = _serverProseOrNull(error.message);
      if (prose != null) return prose;
      final mapped = _mapTechnicalCode(error.message, loc);
      if (mapped != null) return mapped;
    }
    return loc.errRequestFailed;
  }
  if (error is String) {
    final text = error.trim();
    if (text == 'noInternet') return loc.errNoInternet;
    final prose = _serverProseOrNull(text);
    if (prose != null) return prose;
    final mapped = _mapTechnicalCode(text, loc);
    if (mapped != null) return mapped;
  }
  return loc.errRequestFailedNetwork;
}

String appErrorUserMessage(AppError error, {required AppLocalizations loc}) {
  // 🔴 نثر الخادم يتقدّم على كل شيء: هو التفسير الأدقّ والأقلّ التباساً.
  for (final raw in [error.context?['serverMessage'], error.context?['message']]) {
    final prose = _serverProseOrNull(raw is String ? raw : null);
    if (prose != null) return prose;
    if (raw is String && raw.trim().isNotEmpty) {
      // غير آمن أو رمز آلي ⇒ ترجمناه بأنفسنا.
      final mapped = _mapTechnicalCode(raw, loc);
      if (mapped != null) return mapped;
    }
  }

  return switch (error) {
    NetworkError() => loc.errCannotReachServer,
    ValidationError() => loc.errCheckYourInput,
    SessionExpiredError() => loc.errSessionExpiredAction,
    PermissionError() => loc.errPermissionDenied,
    NotFoundError() => loc.errNotFoundAction,
    ConflictError() => loc.errConflictingChange,
    ServerError() => loc.errServerError,
    _ => loc.errRequestFailed,
  };
}

/// نص الخادم كما هو إن كان **نثراً بشرياً**، و`null` إن كان رمزاً آلياً
/// أو غير آمن.
///
/// ### لماذا النثر يُعرض كما هو
///
/// `[appErrorUserMessage]` كان يمرّر نص الخادم عبر [\_mapTechnicalCode]
/// أولاً. ومحرّك التصنيف يبحث عن كلمات مثل `already` و`conflict` — وهي
/// كلمات **طبيعية** في جملة إنجليزية. فالنص «This event was already
/// assigned.» كان يُختزل إلى «تغيّر هذا السجل من جهاز آخر» — أي إبدال
/// تفسير دقيق ودقيق من الخادم برمز عام.
///
/// **القاعدة: الخادم يشرح، ونحن نترجم فقط ما لا نعرفه.**
/// 1. نصّ بشري ⇒ يُعرض حرفياً (بعد بوابة الأمان).
/// 2. رمز آلي ⇒ يُترجَم بنصّنا.
/// 3. غير آمن ⇒ يُسقط.
String? _serverProseOrNull(String? raw) {
  if (raw == null) return null;
  final text = raw.trim();
  if (text.isEmpty) return null;
  return _isSafeUserFacingText(text) ? text : null;
}

/// Mappings for raw backend error codes or keys like 'validation.badRequest',
/// 'resource.conflict', 'noInternet', 'server.noResponse', etc.
///
/// ### الترتيب مقصود
///
/// **الضبط قبل التخمين**: الرموز المتكرّرة من هذا الخادم تُطابَق أولاً
/// بنصّها الكامل. ثم الأجزاء المحدّدة. ثم العام.
///
/// ❌ كان الترتيب يجعل `session` تسبق `conflict`، فيصير
/// `resource.sessionConflict` رسالة «انتهت الجلسة» — وهي نقيض ما حدث.
String? _mapTechnicalCode(String code, AppLocalizations loc) {
  final trimmed = code.trim();
  if (trimmed.isEmpty) return null;
  final lower = trimmed.toLowerCase();

  // 💡 نسخة بلا فواصل: `connection.refused` و `CONNECTION_REFUSED` و
  // `connection-refused` كلها تصبح `connectionrefused` — فيتعرّف عليها
  // المُصنِّف بدل أن تسقط إلى «تعذّر الطلب» العام.
  final flat = lower.replaceAll(RegExp(r'[._\-\s/]+'), '');

  // ── 1) رموز هذا الخادم تماماً (من `openapi.yaml` وسجلات التشغيل) ──────
  if (lower == 'business_rule_violation' || flat == 'businessruleviolation') {
    return loc.errBusinessRuleViolation;
  }

  // ── 2) الشبكة ────────────────────────────────────────────────────────
  if (lower == 'nointernet' ||
      flat == 'nointernet' ||
      flat.contains('nointernet') ||
      flat.contains('timeout') ||
      flat.contains('connectionrefused') ||
      flat.contains('connectionreset') ||
      flat.contains('connectionfailed') ||
      flat.contains('econnreset') ||
      // ⚠️ لا `enotfound`: `resource.notFound` يُبسَط إلى
      // `resourcenotfound` فيحتويه نصاً ⇒ صار «غير موجود» يُقال عنه
      // «تحقّق من الشبكة». (getaddrinfo مغطّى بـ `hostlookup`.)
      flat.contains('unreachable') ||
      flat.contains('hostlookup') ||
      flat.contains('networkerror')) {
    return loc.errNoInternet;
  }

  // ── 3) الجلسة — 401 (قبل `forbidden`/403) ─────────────────────────────
  if (flat.contains('unauthorized') ||
      flat.contains('tokenexpired') ||
      flat.contains('sessionexpired') ||
      (flat.contains('session') &&
          (flat.contains('expired') || flat.contains('invalid')))) {
    return loc.errSessionExpiredAction;
  }
  if (flat.contains('forbidden') ||
      flat.contains('permission') ||
      flat.contains('accessdenied')) {
    return loc.errPermissionDenied;
  }

  // ── 4) التحقّق من صحّة المدخلات ──────────────────────────────────────
  if (flat.contains('badrequest') ||
      flat.contains('validation') ||
      flat.contains('invalidpayload')) {
    return loc.errCheckYourInput;
  }

  // ── 5) التعارض (409) — بعد الجلسة والتحقّق ────────────────────────────
  if (flat.contains('conflict') ||
      flat.contains('already') ||
      flat.contains('duplicate') ||
      flat.contains('unique') ||
      flat.contains('busrule')) {
    return loc.errConflictingChange;
  }

  // ── 6) غير موجود ──────────────────────────────────────────────────────
  if (flat.contains('notfound')) {
    return loc.errNotFoundAction;
  }

  // ── 7) الخادم ─────────────────────────────────────────────────────────
  if (flat.contains('server') || flat.contains('internal')) {
    return loc.errServerError;
  }

  if (_looksLikeTechnicalCode(trimmed)) {
    return loc.errRequestFailed;
  }
  return null;
}

bool _looksLikeTechnicalCode(String text) {
  final trimmed = text.trim();
  // Dot-separated codes like "validation.badRequest", "server.noResponse", etc.
  if (trimmed.contains('.') &&
      RegExp(r'^[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_.-]+)+$').hasMatch(trimmed)) {
    return true;
  }
  // Single token with no spaces like "badRequest", "validationError", "UNAUTHORIZED"
  if (!trimmed.contains(' ') &&
      RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(trimmed)) {
    return true;
  }
  return false;
}

/// Strict gate: only curated, short, PII-free text reaches the driver.
///
/// Rejects anything that looks like a stack trace, framework dump, URL,
/// email, phone number, long identifier, or technical code/extension.
bool _isSafeUserFacingText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.length > 140) return false;
  if (_looksLikeServerDump(trimmed)) return false;
  if (_containsPii(trimmed)) return false;
  if (_containsUrl(trimmed)) return false;
  if (_looksLikeTechnicalCode(trimmed)) return false;
  return true;
}

bool _looksLikeServerDump(String text) {
  final lower = text.toLowerCase();
  return lower.contains('hibernate') ||
      lower.contains('dioexception') ||
      lower.contains('org.postgresql') ||
      lower.contains('org.springframework') ||
      lower.contains('java.lang.') ||
      lower.contains('kotlin.') ||
      lower.contains('eldpersistenceexception') ||
      lower.contains('exception:') ||
      lower.contains('stacktrace') ||
      lower.contains('\tat ') ||
      lower.contains('instance of') ||
      lower.contains('package:');
}

/// Detects common PII shapes: emails, phones, long digit runs, UUIDs.
bool _containsPii(String text) {
  // Email
  if (RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+').hasMatch(text)) return true;
  // Phone (7+ digits allowing separators)
  if (RegExp(r'\+?\d[\d\s\-\(\)]{6,}').hasMatch(text)) return true;
  // UUID
  if (RegExp(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}')
      .hasMatch(text)) {
    return true;
  }
  // Long digit run (IDs, tokens)
  if (RegExp(r'\d{8,}').hasMatch(text)) return true;
  return false;
}

bool _containsUrl(String text) {
  return RegExp(r'https?://', caseSensitive: false).hasMatch(text) ||
      RegExp(r'\bwww\.', caseSensitive: false).hasMatch(text);
}