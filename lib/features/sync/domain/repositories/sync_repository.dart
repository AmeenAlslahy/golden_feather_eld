import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/sync_item.dart';

/// واجهة مستودع المزامنة
abstract class SyncRepository {
  /// إضافة حدث للطابور
  Future<Either<Failure, bool>> enqueue(SyncEventType type, Map<String, dynamic> data);

  /// معالجة الطابور (محاولة إرسال جميع الأحداث)
  Future<Either<Failure, int>> processQueue();

  /// الحصول على الأحداث المعلقة
  Future<List<SyncItem>> getPendingItems();

  /// عدد الأحداث المعلقة
  Future<int> getPendingCount();

  /// مسح الطابور
  Future<Either<Failure, bool>> clearQueue();

  /// وقت آخر مزامنة ناجحة
  Future<DateTime?> getLastSyncTime();
}
