import '../../domain/entities/tracking_event.dart';
import '../../domain/entities/connection_status.dart';

/// واجهة موحدة لجميع مصادر التتبع
/// (مثل TraccarDataSource أو Backend الشركة مستقبلاً).
/// تعزل الـ Repository تماماً عن طريقة الاتصال أو التقنية المستخدمة.
import '../../domain/repositories/tracking_data_source_port.dart';

abstract class TrackingDataSource implements TrackingDataSourcePort {
  /// تدفق (Stream) الأحداث الحية والمواقع الواردة
  @override
  Stream<TrackingEvent> get events;

  /// حالة الاتصال بالخادم
  @override
  Stream<ConnectionStatus> get connectionStatusStream;

  /// بدء عملية التتبع
  Future<void> start();

  /// إيقاف التتبع
  Future<void> stop();

  /// جلب آخر حدث تم تسجيله
  Future<TrackingEvent?> getLastEvent();
}
