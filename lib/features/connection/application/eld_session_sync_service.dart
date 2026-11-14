import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../backend/providers/backend_providers.dart';
import '../../../core/error/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/shared/value_objects.dart';
import '../data/datasources/eld_session_snapshot_store.dart';
import '../data/datasources/server_session_lookup.dart';
import '../data/providers/eld_session_store_provider.dart';
import '../domain/eld_session_snapshot.dart';

/// مزامنة الجلسات التي بدأت محلياً أثناء انقطاع الشبكة.
///
/// التدفق:
/// 1. لا شيء للعمل إن لم توجد لقطة `pending` للسائق.
/// 2. `GET /eld/sessions/{driverId}` أولاً:
///    * جلسة نشطة على نفس المركبة → تُتبنّى (بلا كتابة ثانية).
///    * جلسة نشطة على مركبة أخرى → تُترك اللقطة كما هي (تعارض يحتاج تدخل).
///    * لا جلسة (إثبات) → `POST /connect` بنفس وضع الجلسة (يدوي/عادي).
///    * تعذّر السؤال → لا كتابة إطلاقاً؛ تُعاد المحاولة عند تغيّر الشبكة.
/// 3. نتيجة `POST` تُحفظ بلقطة `synced` فقط إذا أكدها السيرفر.
///
/// **لماذا لا POST مباشرة؟** لا يوجد Idempotency-Key في العقد. الطلب الذي
/// فُقد رده قد يكون أنشأ جلسة؛ `GET` هو الفاصل الوحيد بين «لم تُنشأ» و«لا
/// نعرف».
class EldSessionSyncService {
  EldSessionSyncService(this._ref);

  final Ref _ref;

  /// يمنع تداخل مزامنتين (تغيّر الشبكة والسائق معاً).
  bool _running = false;

  bool get isRunning => _running;

  Future<void> syncPendingForDriver(int driverId) async {
    if (_running || driverId <= 0) return;

    final store = _ref.read(eldSessionSnapshotStoreProvider);
    final local = store.load(driverId);
    if (local == null || local.syncState != EldSessionSyncState.pending) {
      return;
    }
    final uniqueId = local.vehicleUniqueId?.trim();
    if (uniqueId == null || uniqueId.isEmpty) {
      AppLogger.warning(
        'ELD session sync skipped: pending snapshot has no vehicle identity',
      );
      return;
    }

    _running = true;
    try {
      final lookup = await lookupServerSession(
        backend: _ref.read(driverSessionBackendProvider),
        driverId: driverId,
      );

      switch (lookup.state) {
        case ServerSessionState.unknown:
          // لا نعرف حالة السيرفر — لا كتابة. تبقى اللقطة pending.
          return;

        case ServerSessionState.active:
          final server = lookup.snapshot!;
          if (server.vehicleUniqueId != null &&
              server.vehicleUniqueId != uniqueId) {
            AppLogger.warning(
              'ELD session sync: active server session belongs to another '
              'vehicle (${server.vehicleUniqueId}); keeping local snapshot',
            );
            return;
          }
          await store.save(
            local.copyWith(
              sessionId: server.sessionId,
              vehicleUniqueId: uniqueId,
              status: server.status,
              connectionStatus: server.connectionStatus,
              origin: EldSessionOrigin.server,
              syncState: EldSessionSyncState.synced,
              lastSyncedAt: DateTime.now().toUtc(),
            ),
          );
          AppLogger.info('ELD session sync: adopted active server session');
          return;

        case ServerSessionState.none:
          await _writeLocalSession(
            store: store,
            local: local,
            driverId: driverId,
            uniqueId: uniqueId,
          );
      }
    } catch (e) {
      AppLogger.warning('ELD session sync failed: $e');
    } finally {
      _running = false;
    }
  }

  Future<void> _writeLocalSession({
    required EldSessionSnapshotStore store,
    required EldSessionSnapshot local,
    required int driverId,
    required String uniqueId,
  }) async {
    final result = await _ref
        .read(hardwareBackendProvider)
        .connectSession(
          uniqueId: uniqueId,
          disconnected: local.manualMode,
          driverId: DriverId(driverId),
        );

    await result.fold<Future<void>>(
      (error) async {
        if (_isTransient(error)) {
          // الشبكة عادت ثم انقطعت مرة أخرى: تبقى pending للمحاولة القادمة.
          return;
        }
        // رفض صريح أو خطوة غير مؤكدة: لا نعلن نجاحاً. نُبقي اللقطة pending
        // لأن `GET` التالي قد يكشف جلسة أنشأها طلب سابق.
        AppLogger.warning(
          'ELD session sync not confirmed: ${error.code}'
          '${error is ServerError && error.statusCode != null ? ' (${error.statusCode})' : ''}',
        );
      },
      (data) async {
        if (data.isEmpty) return;
        final synced = EldSessionSnapshot.fromServerData(
          data,
          driverId: driverId,
          fallbackVehicleUniqueId: uniqueId,
          fallbackVehicleName: local.vehicleName,
          fallbackStartedAt: local.startedAt,
          manualMode: local.manualMode,
          bleMac: local.bleMac,
        );
        if (!synced.confirmedByServer) {
          AppLogger.warning(
            'ELD session sync: server did not confirm the session '
            '(status=${synced.status}, connection=${synced.connectionStatus})',
          );
          return;
        }
        await store.save(synced.copyWith(localId: local.localId));
        AppLogger.info('ELD session sync: local session confirmed by server');
      },
    );
  }

  bool _isTransient(AppError error) {
    return error is NetworkError ||
        error.code.contains('network') ||
        error.code.contains('offline') ||
        error.code.contains('timeout');
  }
}

final eldSessionSyncServiceProvider = Provider<EldSessionSyncService>((ref) {
  return EldSessionSyncService(ref);
});
