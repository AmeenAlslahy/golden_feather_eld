import '../entities/pending_event.dart';

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
}
