import '../entities/pending_event.dart';
import '../entities/quarantine_record.dart';

abstract class OfflineQueue {
  /// إضافة حدث للطابور
  Future<void> enqueue(PendingEvent event);

  /// الحصول على دفعة من الأحداث الجاهزة للمزامنة (وقتها حان)
  Future<List<PendingEvent>> getReadyEvents({int limit = 50});

  /// تحديث حالة الحدث (مثلاً: زيادة مرات المحاولة)
  Future<void> updateEvent(PendingEvent event);

  /// إزالة الحدث من الطابور (بعد نجاح المزامنة أو استنفاد المحاولات)
  Future<void> removeEvent(String eventId);

  /// الحصول على عدد الأحداث المتبقية
  Future<int> get count;

  /// نقل الحدث إلى طابور الأحداث الميتة (بعد استنفاد المحاولات)
  Future<void> moveToDeadLetter(PendingEvent event);

  /// نقل ذري لصف مؤجل (مالك مخالف/بلا جلسة): يُحذف من pending ويُحفظ
  /// مع السبب والحالة — بلا حذف وبلا تغيير مالك. يُعاد تقييمه عند تغير
  /// الشروط فقط (لا retry دوري).
  Future<void> moveToDeferred(
    PendingEvent event, {
    required StoredEventState state,
    required String reason,
    int? ownerDriverId,
  });

  /// نقل ذري لصف محجور (مالك مجهول): لا إفراج تلقائي أبداً.
  Future<void> moveToQuarantine(
    PendingEvent event, {
    required String reason,
    int? ownerDriverId,
  });

  /// قراءة الصفوف المؤجلة (للمراجعة المشروطة) — لا تشمل المحجورة.
  Future<List<QuarantineRecord>> getDeferred({int limit = 50});

  /// قراءة الصفوف المحجورة (للمراجعة الصريحة فقط).
  Future<List<QuarantineRecord>> getQuarantined({int limit = 50});

  /// إعادة صف (مؤجل مؤهل) إلى pending — ذرية: حذف من الحجر + إدراج.
  /// تُستدعى من سياج Part 2 فقط بعد تحقق كامل، لا تلقائياً هنا.
  Future<void> releaseToPending(String eventId);
}
