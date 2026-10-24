/// P0 2B-1 — لقطة هوية الجلسة لقرارات الإرسال/الإفراج.
///
/// قيم بدائية فقط (لا جلسات ولا أسرار): تُبنى في طبقة providers من
/// المصادر الموثوقة، وتُستهلك في domain/data للمقارنة.
class DispatchAuthContext {
  /// معرف السائق المصادق حالياً (null = بلا جلسة).
  final int? driverId;

  /// انتقال جارٍ (logout/login غير مكتمل) — كل إرسال محظور أثناءه.
  final bool transitioning;

  const DispatchAuthContext({
    required this.driverId,
    required this.transitioning,
  });

  const DispatchAuthContext.unauthenticated()
    : this(driverId: null, transitioning: false);
}
