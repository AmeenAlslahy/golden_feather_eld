import 'dart:io';

import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_guard.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../domain/inspection/dot_inspection.dart';
import '../../../../backend/contracts/inspection_backend.dart';
import '../../../../backend/contracts/contract_enums.dart';
import '../../../../core/result/result.dart';
import '../../../sync/domain/entities/pending_event.dart';
import '../../../sync/domain/usecases/sync_engine.dart';
import '../../domain/repositories/inspection_repository.dart';
import '../../domain/inspection_transfer.dart';
import '../../domain/transfer_audit.dart';
import '../mappers/inspection_mappers.dart';
import '../services/fmcsa_eld_output_generator.dart';
import '../../../../core/session/session_epoch.dart';
import '../../../../core/time/trusted_time_provider.dart';
import '../datasources/inspection_local_cache.dart';


/// كل طريق في المستودع يمر بالحارس نفسه: فحص الشبكة مع كاشينغ محلي يضمن
/// عمل وضع التفتيش الميداني في نقاط التفتيش النائية (FMCSA § 395.24 / SRS 6.8).
///
/// **ملكية الكاش (P0):** كل قيمة مخزّنة مربوطة بمالكها.
/// - النطاق = [_sessionEpoch]: أي تغيّر هوية (خروج/دخول) يُسقط الكاش كاملاً.
/// - السائق  = [_ownerScreen] / [_ownerCycle] / [_ownerPacket] / بادئة مفتاح
///   [_cachedLogs]: قيمة `null` تعني «غير منسوب لسائق» ولا تُقدَّم لطلب محدَّد بسائق.
///
/// لا تُستخدم أي قيمة مخزّنة إلا إذا ثبت مالكها يطابق الطلب الحالي. عند غياب
/// الدليل تُفشل العملية بدل إنتاج بيانات قد تكون لسائق آخر.
class InspectionRepositoryImpl implements InspectionRepository {
  final InspectionBackend _backend;
  final NetworkInfo _networkInfo;
  final SyncEngine? _syncEngine;
  final InspectionLocalCache? _disk;

  /// مصدر الوقت الموثوق (P3) — شرط إصدار ملف FMCSA في الوضع غير المتصل.
  final TrustedTimeProvider? _trustedTime;

  /// جيل الجلسة الذي تنتمي إليه الكاش presently. يُتبنّى عند كل تغيّر مرصود
  /// (مرة واحدة لكل انتقال) لا عند كل نداء.
  int _sessionEpoch = SessionEpoch.current;

  /// ذاكرة مؤقتة تضمن استمرار عمل التفتيش وعرض السجلات حتى عند انقطاع الاتصال.
  /// على مستوى الكائن لا الصنف: صنف-ثابت يتسرب بين الجلسات والأمثلة.
  DotInspectionScreen? _cachedScreen;
  int? _ownerScreen;
  List<DotInspectionCycleDay> _cachedCycle = [];
  int? _ownerCycle;
  /// المفتاح `'<driverIdValue>:<date|latest>'` — السائق جزء من الهوية.
  final Map<String, DotInspectionLog> _cachedLogs = {};
  InformationPacketView? _cachedPacket;
  int? _ownerPacket;
  List<TransferAuditRow>? _cachedTransfers;

  InspectionRepositoryImpl(
    this._backend,
    this._networkInfo, [
    this._syncEngine,
    this._disk,
    this._trustedTime,
  ]) {
    _restoreFromDisk();
  }

  void _restoreFromDisk() {
    if (_disk == null) return;
    try {
      _cachedScreen = _disk.loadScreen();
      _ownerScreen = _cachedScreen?.driverId.value;
      final cycle = _disk.loadCycle();
      if (cycle != null && cycle.isNotEmpty) {
        _cachedCycle = cycle;
        _ownerCycle = cycle.first.driverId.value;
      }
      final logs = _disk.loadAllLogs();
      if (logs.isNotEmpty) {
        _cachedLogs.addAll(logs);
      }
      _cachedPacket = _disk.loadPacket();
      final transfers = _disk.loadTransfers();
      if (transfers != null) {
        _cachedTransfers = transfers;
      }
    } catch (e) {
      AppLogger.warning('InspectionRepository: restoreFromDisk failed: $e');
    }
  }

  /// يتبنّى جيل الجلسة الحالي ويُسقط الكاش — مرة واحدة لكل انتقال مرصود.
  /// يُستدعى قبل كل عملية. إعادة التبني هنا تمنع المسح المتكرر الذي كان يُبقي
  /// الكاش ميتاً بعد أول تغيير هوية.
  void _adoptSessionIfChanged() {
    final current = SessionEpoch.current;
    if (current == _sessionEpoch) return;
    _sessionEpoch = current;
    _cachedScreen = null;
    _ownerScreen = null;
    _cachedCycle = <DotInspectionCycleDay>[];
    _ownerCycle = null;
    _cachedLogs.clear();
    _cachedPacket = null;
    _ownerPacket = null;
    _cachedTransfers = null;
    _disk?.clear();
    AppLogger.info(
      'InspectionRepository: session generation moved to $current; cache dropped',
    );
  }

  /// جيل الجلسة لحظة بدء العملية. يُقارن بعد كل `await` وقبل أي كتابة كاش.
  int _captureEpoch() => _sessionEpoch;

  /// هل انتهت صلاحية العملية لأن الهوية تغيّرت أثناء تنفيذها؟
  bool _isStale(int operationEpoch) => SessionEpoch.current != operationEpoch;

  Failure _staleFailure(int operationEpoch) {
    AppLogger.warning(
      'InspectionRepository: dropping a result from session $operationEpoch '
      '(now ${SessionEpoch.current})',
    );
    return const ServerFailure(message: 'inspectionStaleSession');
  }

  /// مطابقة صارمة بين مالك مخزَّن ومالك الطلب — `null` لا يطابق أي سائق محدَّد.
  bool _ownedBy(int? cachedOwner, DriverId? requestedDriverId) =>
      cachedOwner == requestedDriverId?.value;

  /// **ملكية البيانات المُتحقَّق منها** — مختلفة عن ملكية الطلب.
  ///
  /// السجل نفسه يجب أن يعلن `driverId` موجباً يطابق السائق الطالب. القيمة
  /// `0`/المفقودة تعني «غير معروف» ولا تُعامَل كـ«مُتحقَّق».
  ///
  /// ملاحظة عقد (2026-10): `DotInspectionScreenResponse` و `InspectionLogDisplayResponse`
  /// في `openapi.yaml` يُعلنان `driver -> DriverResponse`، لكن حقل `id` ليس
  /// `required`. استجابة الدورة والحزمة لا تعلن `driver` إطلاقاً — لذلك
  /// التحقق هناك يعتمد على القيمة المُشاهَدة وقت التشغيل فقط.
  bool _verifiedOwnerMatches(DriverId? declared, DriverId requested) =>
      declared != null && declared.value > 0 && declared.value == requested.value;

  /// هل يمكن قبول هذا السجل للتخزين أو لتقديمه لهذا السائق؟
  ///
  /// - يعلن سائقاً مطابقاً  ⇒ قبول (ملكية مُتحقَّق منها).
  /// - يعلن سائقاً مختلفاً  ⇒ **رفض صريح**: لا تخزين ولا تقديم.
  /// - لا يعلن شيئاً (0/مفقود) ⇒ يُخزَّن بوسم الطلب، لكن **لا يُعدّ
  ///   مُتحقَّقاً**، فلا يصل إلى مسار FMCSA.
  bool _acceptsDataFrom(DriverId? declared, DriverId? requested) {
    if (declared == null || declared.value <= 0) return true; // غير معروف — لا رفض
    if (requested == null) return true; // لا يوجد طالب محدَّد للمقارنة
    return declared.value == requested.value;
  }

  /// هل هذه البيانات مُتحقَّقة الملكية وجاهزة لملف نظامي؟
  bool _isVerifiedFor(DriverId? declared, DriverId requested) =>
      _verifiedOwnerMatches(declared, requested);

  String _logKey(DriverId driverId, DateTime? date) =>
      '${driverId.value}:${date != null ? date.toIso8601String().split('T').first : 'latest'}';

  /// سجلات هذا السائق وحده — تُستخدم في المسار غير المتصل وتوليد ملف FMCSA.
  Map<String, DotInspectionLog> _logsOwnedBy(DriverId driverId) {
    final prefix = '${driverId.value}:';
    return {
      for (final e in _cachedLogs.entries)
        if (e.key.startsWith(prefix) &&
            _isVerifiedFor(e.value.driverId, driverId))
          e.key: e.value,
    };
  }

  Failure _failure(AppError error) {
    AppLogger.error(
      'InspectionRepository backend error: ${error.code} (${error.l10nKey})',
    );
    return ServerFailure(message: error.l10nKey);
  }

  Either<Failure, T> _done<T>(Result<T> result) {
    return result.fold((error) => Left(_failure(error)), Right.new);
  }

  @override
  Future<Either<Failure, List<DotInspectionCycleDay>>> getCycle({
    DriverId? driverId,
    required int days,
  }) {
    _adoptSessionIfChanged();
    final operationEpoch = _captureEpoch();
    return guardedNetwork(_networkInfo, () async {
      final result = await _backend.getCycle(driverId: driverId, days: days);
      if (_isStale(operationEpoch)) return Left(_staleFailure(operationEpoch));
      return result.fold(
        (error) => _cycleFallback(_failure(error), driverId),
        (cycleDays) {
          //Ownership gate: reject a mismatched declared driver outright.
          for (final day in cycleDays) {
            if (!_acceptsDataFrom(day.driverId, driverId)) {
              AppLogger.error(
                'InspectionRepository: rejecting DOT cycle stamped for driver '
                '${day.driverId.value} while serving ${driverId?.value}',
              );
              return const Left(ServerFailure(message: 'inspectionOwnerMismatch'));
            }
          }
          _cachedCycle = cycleDays;
          _ownerCycle = driverId?.value;
          _disk?.saveCycle(cycleDays, ownerId: driverId?.value);
          return Right(cycleDays);
        },
      );
    }, offline: () async {
      return _cycleFallback(const NetworkFailure(), driverId);
    });
  }

  Either<Failure, List<DotInspectionCycleDay>> _cycleFallback(
      Failure failure, DriverId? driverId) {
    if (_cachedCycle.isNotEmpty && _ownedBy(_ownerCycle, driverId)) {
      if (driverId == null ||
          _cachedCycle.every((d) => _isVerifiedFor(d.driverId, driverId))) {
        return Right(_cachedCycle);
      }
    }
    return Left(failure);
  }

  @override
  Future<Either<Failure, DotInspectionLog>> getLogs({
    required DriverId driverId,
    DateTime? date,
  }) {
    _adoptSessionIfChanged();
    final operationEpoch = _captureEpoch();
    final key = _logKey(driverId, date);
    return guardedNetwork(_networkInfo, () async {
      final result = await _backend.getLogs(driverId: driverId, date: date);
      if (_isStale(operationEpoch)) return Left(_staleFailure(operationEpoch));
      return result.fold(
        (error) => _logsFallback(_failure(error), key, driverId),
        (log) {
          if (!_acceptsDataFrom(log.driverId, driverId)) {
            AppLogger.error(
              'InspectionRepository: rejecting DOT log stamped for driver '
              '${log.driverId.value} while serving ${driverId.value}',
            );
            return const Left(ServerFailure(message: 'inspectionOwnerMismatch'));
          }
          _cachedLogs[key] = log;
          _disk?.saveLog(key, log);
          return Right(log);
        },
      );
    }, offline: () async {
      return _logsFallback(const NetworkFailure(), key, driverId);
    });
  }

  Either<Failure, DotInspectionLog> _logsFallback(
      Failure failure, String key, DriverId driverId) {
    final cached = _cachedLogs[key];
    if (cached != null) {
      if (!_acceptsDataFrom(cached.driverId, driverId)) {
        return Left(failure);
      }
      //Verified ownership is required to *serve* on behalf of a named driver.
      if (!_isVerifiedFor(cached.driverId, driverId)) {
        return Left(failure);
      }
      return Right(cached);
    }

    // Fallback: If this day is in _cachedCycle, synthesize a compliant baseline log:
    for (final day in _cachedCycle) {
      if (_acceptsDataFrom(day.driverId, driverId) &&
          _isVerifiedFor(day.driverId, driverId)) {
        final dKey = _logKey(driverId, day.logDate);
        if (dKey == key) {
          final synthesized = _synthesizeLogFromCycleDay(day);
          _cachedLogs[key] = synthesized;
          return Right(synthesized);
        }
      }
    }

    return Left(failure);
  }

  DotInspectionLog _synthesizeLogFromCycleDay(DotInspectionCycleDay day) {
    return DotInspectionLog(
      driverId: day.driverId,
      driverName: day.driverName,
      logDate: day.logDate,
      displayDate: day.displayDate,
      displayLocation: day.displayLocation,
      certified: day.certified,
      certifiedAt: day.certifiedAt,
      eldRegistrationId: day.eldRegistrationId,
      eldIdentifier: day.eldIdentifier,
      eldProvider: day.eldProvider,
      vehicleNumber: day.vehicleNumber,
      uniqueId: day.uniqueId,
      vin: day.vin,
      startOdometerKm: day.startOdometerKm,
      endOdometerKm: day.endOdometerKm,
      totalDistanceKm: day.totalDistanceKm,
      engineHours: day.engineHours,
      trailers: day.trailers,
      shippingDocuments: day.shippingDocuments,
      carrierName: day.carrierName,
      usdotNumber: day.usdotNumber,
      mainOfficeAddress: day.mainOfficeAddress,
      homeTerminalAddress: day.homeTerminalAddress,
      activeDataDiagnostics: day.activeDataDiagnostics,
      activeDeviceMalfunctions: day.activeDeviceMalfunctions,
      events: const [],
      readOnly: true,
      period24HourStartTime: '00:00:00',
    );
  }

  InspectionTransferType _transferTypeFor(TransferMethod method) {
    switch (method) {
      case TransferMethod.webService:
        return InspectionTransferType.webServices;
      case TransferMethod.email:
        return InspectionTransferType.email;
      case TransferMethod.usb:
        return InspectionTransferType.usb;
      case TransferMethod.bluetooth:
        return InspectionTransferType.bluetooth;
    }
  }

  @override
  Future<Either<Failure, TransferOutcome>> sendLogs({
    required DriverId driverId,
    required TransferMethod method,
    String? email,
    String? routingCode,
    required String comment,
  }) {
    _adoptSessionIfChanged();
    final operationEpoch = _captureEpoch();
    return guardedNetwork(_networkInfo, () async {
      final recipient = email?.trim() ?? '';
      final note = comment.trim();
      final route = routingCode?.trim();

      final result = method == TransferMethod.email && recipient.isNotEmpty
          ? await _backend.emailLogs(
              driverId: driverId,
              recipientEmail: recipient,
              comment: note,
              routingCode: route == null || route.isEmpty ? null : route,
            )
          : await _backend.sendLogs(
              driverId: driverId,
              transferType: _transferTypeFor(method),
              outputFileComment: note,
              routingCode: route == null || route.isEmpty ? null : route,
              recipientEmail: (recipient.isEmpty) ? null : recipient,
);
      if (_isStale(operationEpoch)) return Left(_staleFailure(operationEpoch));

      return result.fold(
        (error) => Left(_failure(error)),
        (json) => Right(readTransferOutcome(json)),
      );
    }, offline: () async {
      // FMCSA § 395.24 / § 395.34: Offline local generation and transfer queuing.
      //
      // P0: الملف المُنتج وثيقة نظامية. لا يجوز أن يحمل سجلاً أو شاشة أو
      // دورة لاOwnership مُتحقَّق منها لهذا السائق تحديداً — لا وسم الطلب،
      // بل **قيمة `driverId` التي يعلنها السجل نفسه**.
      //
      // قيد عقد موثّق (openapi.yaml 2026-10):
      //   • `DotInspectionScreenResponse` و `InspectionLogDisplayResponse`
      //     يُعلنان `driver -> DriverResponse`  ⇒ قابلة للتحقق.
      //   • استجابة الدورة **لا تعلن** `driver` ⇒ التحقق يعتمد على القيمة
      //     المُشاهَدة وقت التشغيل فقط؛ إن كانت `0` تُستبعد ولا تُعدّ مُتحقَّقة.
      if (_isStale(operationEpoch)) return Left(_staleFailure(operationEpoch));

      final ownedLogs = _logsOwnedBy(driverId);
      final screen = _cachedScreen;
      final ownedScreen = _isVerifiedFor(screen?.driverId, driverId)
          ? screen
          : null;
      final cycle = _cachedCycle;
      final ownedCycle =
          _isVerifiedFor(cycle.isEmpty ? null : cycle.first.driverId, driverId)
              ? cycle
              : null;

      if (ownedScreen == null &&
          ownedCycle == null &&
          ownedLogs.isEmpty) {
        AppLogger.error(
          'InspectionRepository: refusing offline ELD generation for driver '
          '${driverId.value} — no data with verified ownership',
        );
        return const Left(ServerFailure(message: 'inspectionNoVerifiedData'));
      }

      // P3 (49 CFR 395 Appendix A): الملف وثيقة نظامية بطابع زمني موثوق.
      // بلا وقت موثوق لا نُصدر ملفاً بوقت مزيف — فشل صريح قابل لإعادة المحاولة.
      final trusted = _trustedTime?.currentTime;
      if (trusted is! TrustedTimeAvailable) {
        AppLogger.error(
          'InspectionRepository: refusing offline ELD generation for driver '
          '${driverId.value} — trusted time unavailable',
        );
        return const Left(ServerFailure(message: 'inspectionTrustedTimeRequired'));
      }
      final generatedAtUtc = trusted.utc;

      try {
        final filePath = await FmcsaEldOutputGenerator.generateAndSave(
          screen: ownedScreen,
          cycleDays: ownedCycle ?? const [],
          logs: ownedLogs,
          outputFileComment: comment,
          fileCreationUtc: generatedAtUtc,
          fallbackDriverId: driverId.value.toString(),
        );

        //Post-generation gate: a written file is not proof of a valid file.
        final problem = _invalidIdentifyingFields(filePath);
        if (problem != null) {
          AppLogger.error(
            'InspectionRepository: discarding invalid offline ELD file '
            '($problem): $filePath',
          );
          _deleteQuietly(filePath);
          return const Left(ServerFailure(message: 'inspectionIncompleteOutput'));
        }

        if (_syncEngine != null) {
          // P3: طابع الحدث الموثوق نفسه المستخدم في الملف — لا ساعة جهاز.
          await _syncEngine.submitEvent(PendingEvent(
            id: 'transfer_${generatedAtUtc.millisecondsSinceEpoch}',
            type: 'inspection_transfer',
            payload: {
              'driverId': driverId.value,
              'method': method.name,
              'email': email,
              'routingCode': routingCode,
              'comment': comment,
              'localFilePath': filePath,
            },
            createdAt: generatedAtUtc,
          ));
        }

        return Right(TransferOutcome(
          accepted: true,
          text: 'OFFLINE_GENERATED:$filePath',
        ));
      } catch (e, st) {
        AppLogger.error('Offline ELD file generation failed', e, st);
        return Left(ServerFailure(message: 'Failed to generate offline ELD file: $e'));
      }
    });
  }

  /// الحقول الإلزامية في سطر النوع 1 من 49 CFR 395 Appendix A.
  ///
  /// فحص **بعد** الكتابة: إنشاء الملف ليس دليلاً على صلاحيته. يُرجع اسم أول
  /// حقل فارغ أو `null` إن كان الملف صالحاً.
  ///
  /// ⚠️ هذا **ليس** اختبار مطابقة (conformance) كاملاً — المشروع لا يملك
  /// مخطط ملف FMCSA موثّقاً ولا اختبارات مطابقة. الحقول المفحوصة هي الهوية
  /// الحاملة فقط؛ رقم الرخصة والـ coDriver قد يكونان فارغين بشرعية.
  String? _invalidIdentifyingFields(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return 'fileMissing';
    final String firstLine;
    try {
      firstLine = file
          .readAsLinesSync()
          .firstWhere((l) => l.startsWith('1,'), orElse: () => '');
    } catch (_) {
      return 'headerUnreadable';
    }
    if (firstLine.isEmpty) return 'headerMissing';

    final f = firstLine.split(',');
    const required = <int, String>{
      1: 'ELDRegistrationId',
      2: 'ELDIdentifier',
      3: 'CMVPowerUnitNumber',
      4: 'VIN',
      6: 'USDOTNumber',
      7: 'DriverLastName',
      8: 'DriverFirstName',
      9: 'DriverID',
    };
    for (final entry in required.entries) {
      final v = f.length > entry.key ? f[entry.key].trim() : '';
      if (v.isEmpty || v == '""') return entry.value;
    }
    return null;
  }

  void _deleteQuietly(String path) {
    try {
      File(path).deleteSync();
    } catch (e) {
      AppLogger.error('InspectionRepository: could not delete invalid ELD file', e);
    }
  }

  @override
  Future<Either<Failure, InformationPacketView>> getInformationPacket({
    DriverId? driverId,
  }) {
    _adoptSessionIfChanged();
    final operationEpoch = _captureEpoch();
    return guardedNetwork(_networkInfo, () async {
      final result = await _backend.getInformationPacket(driverId: driverId);
      if (_isStale(operationEpoch)) return Left(_staleFailure(operationEpoch));
      return result.fold(
        (error) => _packetFallback(_failure(error), driverId),
        (json) {
          try {
            final packet = parseInformationPacket(json);
            //`InformationPacketView` carries no driverId (contract limitation),
            //so ownership here is request-scoped only and never "verified".
            _cachedPacket = packet;
            _ownerPacket = driverId?.value;
            _disk?.savePacket(packet, ownerId: driverId?.value);
            return Right(packet);
          } catch (e, stackTrace) {
            AppLogger.error(
              'InspectionRepository: information packet body unreadable',
              e,
              stackTrace,
            );
            return _packetFallback(
              const ServerFailure(message: 'packetBodyUnreadable'),
              driverId,
            );
          }
        },
      );
    }, offline: () async {
      return _packetFallback(const NetworkFailure(), driverId);
    });
  }

  Either<Failure, InformationPacketView> _packetFallback(
      Failure failure, DriverId? driverId) {
    final packet = _cachedPacket;
    if (packet == null || !_ownedBy(_ownerPacket, driverId)) {
      return Left(failure);
    }
    return Right(packet);
  }

  @override
  Future<Either<Failure, DotInspectionScreen>> getScreen({DriverId? driverId}) {
    _adoptSessionIfChanged();
    final operationEpoch = _captureEpoch();
    return guardedNetwork(_networkInfo, () async {
      final result = await _backend.getScreen(driverId: driverId);
      if (_isStale(operationEpoch)) return Left(_staleFailure(operationEpoch));
      return result.fold(
        (error) => _screenFallback(_failure(error), driverId),
        (screen) {
          if (!_acceptsDataFrom(screen.driverId, driverId)) {
            AppLogger.error(
              'InspectionRepository: rejecting DOT screen stamped for driver '
              '${screen.driverId.value} while serving ${driverId?.value}',
            );
            return const Left(ServerFailure(message: 'inspectionOwnerMismatch'));
          }
          _cachedScreen = screen;
          _ownerScreen = driverId?.value;
          _disk?.saveScreen(screen, ownerId: driverId?.value);
          return Right(screen);
        },
      );
    }, offline: () async {
      return _screenFallback(const NetworkFailure(), driverId);
    });
  }

  Either<Failure, DotInspectionScreen> _screenFallback(
      Failure failure, DriverId? driverId) {
    final screen = _cachedScreen;
    if (screen != null && _ownedBy(_ownerScreen, driverId)) {
      if (_acceptsDataFrom(screen.driverId, driverId)) {
        if (driverId == null || _isVerifiedFor(screen.driverId, driverId)) {
          return Right(screen);
        }
      }
    }
    return Left(failure);
  }

  @override
  Future<Either<Failure, List<TransferAuditRow>>> getTransfers(
      {DriverId? driverId}) {
    return guardedNetwork(_networkInfo, () async {
      final result = await _backend.getTransfers(driverId: driverId);
      return result.fold(
        (error) => Left(_failure(error)),
        (json) {
          try {
            // A body that is not a list is an error, never an empty record.
            final rows = parseTransferAudit(json);
            if (rows != null) {
              _cachedTransfers = rows;
              _disk?.saveTransfers(rows, ownerId: driverId?.value);
            }
            return rows == null
                ? const Left(ServerFailure(message: 'transferAuditNotList'))
                : Right(rows);
          } catch (e, stackTrace) {
            AppLogger.error(
              'InspectionRepository: transfer audit body unreadable',
              e,
              stackTrace,
            );
            return const Left(
              ServerFailure(message: 'transferAuditUnreadable'),
            );
          }
        },
      );
    }, offline: () async {
      final cached = _cachedTransfers ?? _disk?.loadTransfers(ownerId: driverId?.value);
      if (cached != null) return Right(cached);
      return const Right([]);
    });
  }

  @override
  Future<Either<Failure, Unit>> registerInspectionStart({
    required DriverId driverId,
  }) {
    return guardedNetwork(_networkInfo, () async {
      final result = await _backend.startInspection(driverId: driverId);
      return _done(result).map((_) => unit);
    });
  }
}
