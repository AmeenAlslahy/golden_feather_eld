import 'pending_event.dart';

/// حالة تخزين صف محجور/مؤجل — تميّز الإفراج التلقائي المشروط عن المنع الدائم.
enum StoredEventState {
  /// مالك مثبَت لكنه ≠ الجلسة الحالية (أو انتقال جارٍ).
  /// يُعاد تقييمها عند تغير الشروط فقط — ليست retry دورية.
  deferredOwnerMismatch,

  /// لا جلسة مصادقة أصلاً. تُعاد للتصنيف عند قيام أي جلسة.
  deferredUnauthenticated,

  /// مالك مجهول — لا إفراج تلقائي أبداً (مراجعة صريحة فقط).
  quarantinedUnknownOwner,
}

/// درجة الإثبات المحفوظة مع الصف (للتدقيق والمراجعة اللاحقة فقط —
/// لا تُستخدم وحدها سبباً للإرسال: الإفراج قرار سياج Part 2).
enum OwnershipProof {
  none,
  cache,
  attested,
}

/// صف محجور/مؤجل كما هو مخزن: الحدث الأصلي intact + بيانات الحجر.
class QuarantineRecord {
  final PendingEvent event;
  final StoredEventState state;
  final String reason;
  final DateTime quarantinedAt;
  final int? ownerDriverId;
  final OwnershipProof proof;

  const QuarantineRecord({
    required this.event,
    required this.state,
    required this.reason,
    required this.quarantinedAt,
    this.ownerDriverId,
    this.proof = OwnershipProof.none,
  });
}
