import '../../../../backend/contracts/driver_session_backend.dart';
import '../../../../core/error/app_error.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../domain/eld_session_snapshot.dart';

/// نتيجة قراءة `GET /eld/sessions/{driverId}`.
///
/// الفرق بين [none] و[unknown] جوهري للمزامنة: «لا توجد جلسة» إثبات يسمح
/// بإرسال `POST /connect`، أما «تعذّر السؤال» فلا يسمح بأي كتابة (قد تكون
/// هناك جلسة أنشأها طلب سابق فُقد رده).
enum ServerSessionState { active, none, unknown }

class ServerSessionLookup {
  final ServerSessionState state;
  final EldSessionSnapshot? snapshot;

  const ServerSessionLookup._(this.state, [this.snapshot]);

  static const ServerSessionLookup none = ServerSessionLookup._(
    ServerSessionState.none,
  );

  static const ServerSessionLookup unknown = ServerSessionLookup._(
    ServerSessionState.unknown,
  );

  static ServerSessionLookup active(EldSessionSnapshot snapshot) =>
      ServerSessionLookup._(ServerSessionState.active, snapshot);
}

/// يقرأ الجلسة النشطة لسائق ويميّز الحالات الثلاث أعلاه.
///
/// لا يرمي: أي استثناء غير متوقع = [ServerSessionState.unknown].
Future<ServerSessionLookup> lookupServerSession({
  required DriverSessionBackend backend,
  required int driverId,
}) async {
  if (driverId <= 0) return ServerSessionLookup.none;
  try {
    final result = await backend.getActiveSession(DriverId(driverId));
    return await result.fold((error) {
      // الخادم يعبّر عن «لا توجد جلسة» بـ 404 أو بحمولة فارغة (انظر
      // `EldDriverSessionBackend.getActiveSession`). أي خطأ آخر يبقى مجهولاً.
      if (error is NotFoundError || error.code == 'eld.session.noneActive') {
        return ServerSessionLookup.none;
      }
      return ServerSessionLookup.unknown;
    }, (data) {
      if (data.isEmpty) return ServerSessionLookup.none;
      final snapshot = EldSessionSnapshot.fromServerData(
        data,
        driverId: driverId,
      );
      return snapshot.isActive
          ? ServerSessionLookup.active(snapshot)
          : ServerSessionLookup.none;
    });
  } catch (_) {
    return ServerSessionLookup.unknown;
  }
}
