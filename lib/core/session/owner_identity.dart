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

  /// يُركّب مصدر الهوية الموحّد (من auth_state_provider حصراً).
  static void install(Future<int?> Function() resolver) => _resolver =
      resolver;

  /// هوية المالك الحالية بنفس فضاء الختم، أو null إن لم تُركَّب/لا جلسة.
  static Future<int?> resolve() async =>
      _resolver == null ? null : await _resolver!();

  /// اختبارات فقط — عزل الحاوية بين الاختبارات.
  static void resetForTests() => _resolver = null;
}
