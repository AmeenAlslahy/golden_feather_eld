/// حاوية إسناد هوية المالك لسياج الإرسال (P0 2B-1 — مراجعة 2026-10-30).
///
/// **لماذا توجد؟** سياج `AuthInterceptor` يجب أن يقرأ هوية المالك بنفس
/// فضاء الختم (`currentDriverIdProvider` — معرّف سائق ELD)، لكن المزود
/// يسكن في features/auth والذي يستورد طبقة backend — فاستيراد معاكس من
/// backend إلى features يصنع دائرة استيراد/مزودات. الحاوية الساكنة هنا
/// (نفس نمط [SessionEpoch]) تكسر الدائرة: تُملأ من تركيب المزود مرة
/// واحدة وتُقرأ لحظة الإرسال.
///
/// **العقد:** `install` يُستدعى من مزود الجلسة حصراً؛ غياب الإسناد يعيد
/// `null` — أي رفض فاشل-مغلق لأي طلب ملزم بمالك (لا إرسال مجهول).
abstract final class OwnerIdentityBinding {
  static Future<int?> Function()? _resolver;

  /// هوية آخر تركيب. تُستخدم كي لا يمحو `uninstall` الخاص بحاوية قديمة
  /// إسنادَ حاوية أحدث (آخر تركيب يفوز).
  static Object? _token;

  /// يُركّب مصدر الهوية الموحّد (من auth_state_provider حصراً).
  /// يعيد رمزاً يُمرَّر إلى [uninstall] عند التخلص من الحاوية.
  static Object install(Future<int?> Function() resolver) {
    final token = Object();
    _resolver = resolver;
    _token = token;
    return token;
  }

  /// يفكّ الإسناد فقط إن كان [token] هو التركيب النشط.
  ///
  /// بدونه كان الإسناد الثابت يحتفظ بـ `ref` حاوية مُتلَفة، فتُقرأ هوية
  /// من جلسة ميتة (أو يُرفع استخدام-بعد-التخلص).
  static void uninstall(Object token) {
    if (!identical(_token, token)) return;
    _resolver = null;
    _token = null;
  }

  /// هوية المالك الحالية بنفس فضاء الختم، أو null إن لم تُركَّب/لا جلسة.
  static Future<int?> resolve() async =>
      _resolver == null ? null : await _resolver!();

  /// اختبارات فقط — عزل الحاوية بين الاختبارات.
  static void resetForTests() {
    _resolver = null;
    _token = null;
  }
}
