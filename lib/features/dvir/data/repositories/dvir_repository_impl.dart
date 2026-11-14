import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import '../../../sync/domain/entities/pending_event.dart';
import '../../../sync/domain/repositories/offline_queue.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_guard.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/dvir_catalog.dart';
import '../../domain/dvir_vehicle.dart';
import '../../domain/entities/dvir_report.dart';
import '../../domain/repositories/dvir_repository.dart';
import '../../../../backend/contracts/dvir_backend.dart';
import '../../../../backend/contracts/raw_json.dart';
import '../../../../core/result/result.dart';
import '../../../../backend/adapters/eld_engine/models/dvir_dto.dart';
import '../../../../domain/shared/value_objects.dart';
import '../mappers/dvir_mappers.dart';
import '../mappers/dvir_defect_mappers.dart';
import '../datasources/dvir_report_cache.dart';
import '../../domain/entities/dvir_defect.dart';

class DvirRepositoryImpl implements DvirRepository {
  final DvirBackend dvirBackend;
  final NetworkInfo networkInfo;
  final OfflineQueue offlineQueue;
  final DvirReportCache _cache;
  final Uuid _uuid;

  final Map<String, Future<Either<Failure, List<DvirReport>>>>
  _inFlightReports = {};
  final Map<String, Future<Either<Failure, DvirReport?>>> _inFlightPrevious =
      {};
  final Map<String, Future<Either<Failure, List<DvirDefect>>>>
  _inFlightDefects = {};
  final Map<String, List<DvirReport>> _cachedReports = {};
  final Map<String, DvirReport?> _cachedPrevious = {};

  DvirRepositoryImpl({
    required this.dvirBackend,
    required this.networkInfo,
    required this.offlineQueue,
    DvirReportCache cache = const DvirReportCache(),
  }) : _cache = cache,
       _uuid = const Uuid();

  Failure _failure(AppError error) {
    AppLogger.error('DvirRepository backend error: ${error.code}');
    return ServerFailure(message: error.code);
  }

  /// خطأ عابر (شبكة/مهلة/انقطاع) = الإرسال قابل للطابور دون اتصال؛
  /// ما عداه فشل صلب يُعرض على السائق ولا يُصفّ في طابور.
  static bool _isTransientNetworkError(AppError error) {
    return error is NetworkError ||
        error.code.startsWith('network') ||
        error.code.contains('timeout') ||
        error.code.contains('offline') ||
        error.code.contains('connection');
  }

  /// SRS 6.8 — دون اتصال: ضع الحدث في طابور المزامنة ولا تُفقد بيانات
  /// السائق أبداً؛ نسخة الجلسة تُظهر التقرير في القائمة فوراً.
  Future<Either<Failure, bool>> _enqueueCreate(
    Map<String, dynamic> body,
    DvirReport report,
  ) async {
    await offlineQueue.enqueue(
      PendingEvent(
        id: _uuid.v4(),
        type: 'dvir_create',
        payload: body,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    _addToLocalCache(report);
    return const Right(true);
  }

  /// SRS 6.8 / 7.9 — مراجعة §396.13 دون اتصال: نفس العقد، طابور + تحديث
  /// الكاش حتى لا يُطلب من السائق نفسه مراجعةً أعطاها.
  Future<Either<Failure, bool>> _enqueueReview({
    required int dvirId,
    required ReviewDvirRequestDto dto,
    required String reviewerName,
  }) async {
    await offlineQueue.enqueue(
      PendingEvent(
        id: _uuid.v4(),
        type: 'dvir_review',
        payload: {'dvirId': dvirId, 'review': dto.toJson()},
        createdAt: DateTime.now().toUtc(),
      ),
    );
    _updateReviewInCache('$dvirId', reviewerName);
    return const Right(true);
  }

  List<DvirReport>? _loadReportsFromCache(String key) {
    final cached = _cache.readReports(key);
    if (cached == null) return null;
    final reports = <DvirReport>[];
    var skipped = 0;
    for (final json in cached) {
      try {
        reports.add(mapDvirDtoToReport(DvirDto.fromJson(json)));
      } catch (error) {
        skipped++;
        AppLogger.warning('Skipped unreadable cached DVIR: $error');
      }
    }
    if (skipped > 0) {
      AppLogger.warning(
        'DVIR cache contained $skipped unreadable record(s); '
        'the remaining ${reports.length} loaded.',
      );
    }
    return reports;
  }

  /// A tri-state cache read: `null` = unknown, `known: true` = the server
  /// answered (with or without a report).
  ({bool known, DvirReport? report})? _cachedPreviousAnswer(String key) {
    if (_cachedPrevious.containsKey(key)) {
      final report = _cachedPrevious[key];
      if (report == null || (int.tryParse(report.id) ?? 0) > 0) {
        return (known: true, report: report);
      }
    }
    final disk = _cache.readPrevious(key);
    if (disk == null) return null;
    final raw = disk.report;
    if (raw == null) return (known: true, report: null);
    try {
      final report = mapDvirDtoToReport(DvirDto.fromJson(raw));
      _cachedPrevious[key] = report;
      return (known: true, report: report);
    } catch (error) {
      AppLogger.warning('Skipped unreadable cached previous DVIR: $error');
      return null;
    }
  }

  /// Adds an offline-submitted report to the *session* cache only.
  ///
  /// The durable copy of the submission is the offline queue event, not this
  /// cache: request bodies have no server `id` and must never be parsed as
  /// DVIR records (that used to break the whole vehicle cache on restart).
  void _addToLocalCache(DvirReport report) {
    final key = report.vehicleId.trim();
    final current = _cachedReports[key] ?? _loadReportsFromCache(key) ?? [];
    final updated = [
      report,
      ...current.where((r) => r.id.isEmpty || r.id != report.id),
    ];
    _cachedReports[key] = updated;
    if ((int.tryParse(report.id) ?? 0) > 0) {
      _cachedPrevious[key] = report;
    }
  }

  void _updateReviewInCache(String dvirId, String reviewerName) {
    final reviewed = <String>{};
    for (final entry in _cachedReports.entries) {
      final list = entry.value;
      for (int i = 0; i < list.length; i++) {
        if (list[i].id == dvirId) {
          list[i] = list[i].copyWith(
            nextDriverReviewed: true,
            reviewingDriverName: reviewerName,
          );
          reviewed.add(entry.key);
        }
      }
    }
    for (final key in _cachedPrevious.keys) {
      final prev = _cachedPrevious[key];
      if (prev != null && prev.id == dvirId) {
        _cachedPrevious[key] = prev.copyWith(
          nextDriverReviewed: true,
          reviewingDriverName: reviewerName,
        );
        reviewed.add(key);
      }
    }
    final parsedId = int.tryParse(dvirId);
    if (parsedId != null) {
      for (final vehicleId in reviewed) {
        _cache.markReviewCompleted(
          vehicleId: vehicleId,
          dvirId: parsedId,
          reviewerName: reviewerName,
        );
      }
    }
  }

  @override
  Future<Either<Failure, List<DvirReport>>> getDvirReports(
    String vehicleId,
  ) async {
    final key = vehicleId.trim();
    if (_inFlightReports.containsKey(key)) {
      return _inFlightReports[key]!;
    }
    final future = _fetchDvirReports(vehicleId);
    _inFlightReports[key] = future;
    try {
      return await future;
    } finally {
      _inFlightReports.remove(key);
    }
  }

  Future<Either<Failure, List<DvirReport>>> _fetchDvirReports(
    String vehicleId,
  ) async {
    final key = vehicleId.trim();
    return guardedNetwork(
      networkInfo,
      () async {
        // معرّف غير معيّن (فارغ أو "No Vehicle") يعني قائمة بلا تصفية مركبة.
        final result = isUnassignedVehicleId(vehicleId)
            ? await dvirBackend.list()
            : await dvirBackend.list(uniqueId: vehicleId);

        return result.fold(
          (error) {
            if (_cachedReports.containsKey(key)) {
              return Right(_cachedReports[key]!);
            }
            final diskReports = _loadReportsFromCache(key);
            if (diskReports != null) {
              _cachedReports[key] = diskReports;
              return Right(diskReports);
            }
            return Left(_failure(error));
          },
          (rawJson) {
            final rawReports = (rawJson['data'] as List<dynamic>?) ?? [];
            final reports = rawReports.map((json) {
              final dto = DvirDto.fromJson(json as Map<String, dynamic>);
              return mapDvirDtoToReport(dto);
            }).toList();
            _cachedReports[key] = reports;
            _cache.saveReports(key, rawReports);
            return Right(reports);
          },
        );
      },
      offline: () async {
        AppLogger.debug(
          'DVIR reports request not sent: network guard reports offline.',
        );
        if (_cachedReports.containsKey(key)) {
          return Right(_cachedReports[key]!);
        }
        final diskReports = _loadReportsFromCache(key);
        if (diskReports != null) {
          _cachedReports[key] = diskReports;
          return Right(diskReports);
        }
        return const Left(NetworkFailure());
      },
    );
  }

  @override
  Future<Either<Failure, DvirReport?>> getPreviousDvir(
    String vehicleId, {
    int? deviceId,
  }) async {
    final key = vehicleId.trim();
    final inFlightKey = '$key|${deviceId ?? ''}';
    if (_inFlightPrevious.containsKey(inFlightKey)) {
      return _inFlightPrevious[inFlightKey]!;
    }
    final future = _fetchPreviousDvir(vehicleId, deviceId: deviceId);
    _inFlightPrevious[inFlightKey] = future;
    try {
      return await future;
    } finally {
      _inFlightPrevious.remove(inFlightKey);
    }
  }

  Future<Either<Failure, DvirReport?>> _fetchPreviousDvir(
    String vehicleId, {
    int? deviceId,
  }) async {
    final key = vehicleId.trim();
    return guardedNetwork(
      networkInfo,
      () async {
        if (isUnassignedVehicleId(vehicleId)) {
          return const Right(null);
        }
        final Result<RawJson> result;
        try {
          result = await dvirBackend.getPreviousDvir(
            vehicleId.trim(),
            deviceId: deviceId,
          );
        } catch (e, stackTrace) {
          AppLogger.error(
            'DvirRepository: pre-trip read failed',
            e,
            stackTrace,
          );
          return const Left(ServerFailure(message: 'pre-trip read failed'));
        }
        return result.fold(
          (error) {
            final cached = _cachedPreviousAnswer(key);
            if (cached != null) return Right(cached.report);
            return Left(_failure(error));
          },
          (raw) {
            final nested = raw['data'];
            final body = nested is Map
                ? Map<String, dynamic>.from(nested)
                : raw;
            // Live shape with no record: {message:"No Records", hasPreviousDvir:false} or empty data.
            if (body['hasPreviousDvir'] == false ||
                (raw['data'] == null && body['hasPreviousDvir'] != true) ||
                (body['message'] == 'No Records' &&
                    body['hasPreviousDvir'] != true)) {
              _cachedPrevious[key] = null;
              _cache.saveNoPrevious(key);
              return const Right(null);
            }
            final candidate = _previousDvirObject(body);
            if (candidate == null) {
              // If server explicitly stated hasPreviousDvir: true but provided no DVIR object,
              // it is malformed, so return Left so caller can fall back to the vehicle list.
              if (body['hasPreviousDvir'] == true) {
                return const Left(
                  ServerFailure(message: 'pre-trip body has no DVIR'),
                );
              }
              _cachedPrevious[key] = null;
              _cache.saveNoPrevious(key);
              return const Right(null);
            }
            try {
              final mapped = mapDvirDtoToReport(DvirDto.fromJson(candidate));
              _cachedPrevious[key] = mapped;
              _cache.savePrevious(key, candidate);
              return Right(mapped);
            } catch (e, stackTrace) {
              AppLogger.error(
                'DvirRepository: pre-trip body unreadable',
                e,
                stackTrace,
              );
              return const Left(
                ServerFailure(message: 'pre-trip body unreadable'),
              );
            }
          },
        );
      },
      offline: () async {
        AppLogger.debug(
          'DVIR previous inspection request not sent: network guard reports offline.',
        );
        // Only a recorded server answer is authoritative. No cache means the
        // §396.13 obligation is *unknown*; the caller must not silently treat
        // that as "there is no previous report".
        final cached = _cachedPreviousAnswer(key);
        if (cached != null) return Right(cached.report);
        return const Left(NetworkFailure());
      },
    );
  }

  /// The record may be the body itself or nested under a documented-looking
  /// key; anything without an `id` is not a DVIR.
  static Map<String, dynamic>? _previousDvirObject(Map<String, dynamic> body) {
    if (body['id'] is num) return body;
    for (final key in const ['dvir', 'previousDvir', 'report', 'lastDvir']) {
      final value = body[key];
      if (value is Map && value['id'] is num) {
        return Map<String, dynamic>.from(value);
      }
    }
    return null;
  }

  @override
  Future<Either<Failure, DvirReport>> getDvirDetails(String id) async {
    return guardedNetwork(networkInfo, () async {
      final parsedId = int.tryParse(id);
      if (parsedId == null) {
        return const Left(ServerFailure(message: 'Invalid DVIR ID'));
      }
      final result = await dvirBackend.getById(DvirId(parsedId));
      return result.fold((error) => Left(_failure(error)), (rawJson) {
        try {
          return Right(mapDvirDtoToReport(DvirDto.fromJson(rawJson)));
        } catch (e, stackTrace) {
          AppLogger.error(
            'DvirRepository: failed to parse DVIR details',
            e,
            stackTrace,
          );
          return const Left(
            ServerFailure(message: 'Failed to parse DVIR details'),
          );
        }
      });
    });
  }

  @override
  Future<Either<Failure, List<DvirCatalogItem>>> getDefectsCatalog() async {
    return guardedNetwork(
      networkInfo,
      () async {
        final result = await dvirBackend.getDefectsCatalog();
        return result.fold((error) => Left(_failure(error)), (raw) {
          final items = parseDvirCatalog(raw);
          // جسم غير مقروء خطأ، وليس كتالوجاً فارغاً.
          return items == null
              ? const Left(ServerFailure(message: 'catalog body is not a list'))
              : Right(items);
        });
      },
      offline: () async {
        // An empty list would claim the §396.11 catalog is empty. Offline
        // means unknown, so the picker shows its offline explanation instead.
        return const Left(NetworkFailure());
      },
    );
  }

  @override
  Future<Either<Failure, DvirDefect>> getDefectDetails(int defectId) async {
    return guardedNetwork(networkInfo, () async {
      final result = await dvirBackend.getDefectDetails(defectId);
      return result.fold((error) => Left(_failure(error)), (raw) {
        final body = raw['data'] is Map ? raw['data'] : raw;
        final defect = parseDvirDefect(body);
        return defect == null
            ? const Left(ServerFailure(message: 'defectDetailsUnreadable'))
            : Right(defect);
      });
    });
  }

  @override
  Future<Either<Failure, List<DvirDefect>>> getActiveDefects({
    required String uniqueId,
    int? deviceId,
  }) async {
    final key = '${uniqueId.trim()}|${deviceId ?? ''}';
    if (_inFlightDefects.containsKey(key)) {
      return _inFlightDefects[key]!;
    }
    final future = _fetchActiveDefects(uniqueId, deviceId: deviceId);
    _inFlightDefects[key] = future;
    try {
      return await future;
    } finally {
      _inFlightDefects.remove(key);
    }
  }

  Future<Either<Failure, List<DvirDefect>>> _fetchActiveDefects(
    String uniqueId, {
    int? deviceId,
  }) async {
    return guardedNetwork(
      networkInfo,
      () async {
        final result = await dvirBackend.getVehicleDefects(
          uniqueId,
          deviceId: deviceId,
        );
        return result.fold((error) => Left(_failure(error)), (raw) {
          final defects = parseDvirDefectList(
            raw['data'] ?? raw['items'] ?? raw,
          );
          return defects == null
              ? const Left(ServerFailure(message: 'vehicleDefectsUnreadable'))
              : Right(defects);
        });
      },
      offline: () async {
        return const Left(NetworkFailure());
      },
    );
  }

  @override
  String? get lastSuccessMessage => dvirBackend.lastServerMessage;

  @override
  Future<Either<Failure, bool>> submitDvirReport(
    DvirReport report, {
    required int driverId,
  }) async {
    // SRS 6.8 — offline: enqueue DVIR for sync, never lose the driver's report.
    // الحالة الرسمية من الكيان نفسه (طُبِّعت ثوابتها عند البناء في
    // `DvirReport.draft`)؛ لا مصدر ثانٍ للحقيقة هنا.
    final body = _buildCreateBody(report, driverId: driverId);
    if (body == null) {
      return const Left(
        ServerFailure(message: 'Driver, vehicle, or signature is missing.'),
      );
    }
    if (!networkInfo.isConnected) {
      return _enqueueCreate(body, report);
    }
    return guardedNetwork(networkInfo, () async {
      final result = await dvirBackend.create(body);
      return result.fold(
        (error) => _isTransientNetworkError(error)
            ? _enqueueCreate(body, report)
            : Left(_failure(error)),
        (_) {
          _addToLocalCache(report);
          return const Right(true);
        },
      );
    }, offline: () => _enqueueCreate(body, report));
  }

  Map<String, dynamic>? _buildCreateBody(
    DvirReport report, {
    required int driverId,
  }) {
    final inspectionTypeWire = report.type == InspectionType.postTrip
        ? 'Post-Trip'
        : 'Pre-Trip';

    return buildDvirCreateBody(
      driverId: driverId,
      deviceId: report.deviceId,
      uniqueId: report.vehicleId,
      status: report.conditionStatus.wire,
      signatureData: report.signature,
      inspectionTime:
          report.date?.toUtc().toIso8601String() ??
          DateTime.now().toUtc().toIso8601String(),
      inspectionType: inspectionTypeWire,
      location: report.location,
      latitude: report.latitude,
      longitude: report.longitude,
      odometer: report.odometer,
      trailerNumber: report.trailerId,
      companyName: report.companyName,
      remarks: report.notes,
      vehicleDefects: report.vehicleDefects,
      trailerDefects: report.trailerDefects,
      catalogDefects: report.selectedDefects
          .map(defectSelectionToWire)
          .toList(),
    );
  }

  @override
  Future<Either<Failure, bool>> reviewDvir({
    required String dvirId,
    required int reviewingDriverId,
    required String reviewingDriverName,
    required String signatureData,
    required bool driverAgreed,
    String? reviewNotes,
  }) async {
    final parsedId = int.tryParse(dvirId);
    if (parsedId == null) {
      return const Left(ServerFailure(message: 'Invalid DVIR ID for review'));
    }
    final dto = ReviewDvirRequestDto(
      previousDvirId: parsedId,
      reviewingDriverId: reviewingDriverId,
      reviewingDriverName: reviewingDriverName,
      signatureData: signatureData,
      driverAgreed: driverAgreed,
      reviewNotes: reviewNotes,
      driverSatisfiedSafe: driverAgreed,
    );
    // SRS 6.8 / 7.9 — offline: enqueue §396.13 review for sync.
    if (!networkInfo.isConnected) {
      return _enqueueReview(
        dvirId: parsedId,
        dto: dto,
        reviewerName: reviewingDriverName,
      );
    }
    return guardedNetwork(
      networkInfo,
      () async {
        final result = await dvirBackend.review(
          dvirId: DvirId(parsedId),
          review: dto.toJson(),
        );
        return result.fold(
          (error) => _isTransientNetworkError(error)
              ? _enqueueReview(
                  dvirId: parsedId,
                  dto: dto,
                  reviewerName: reviewingDriverName,
                )
              : Left(_failure(error)),
          (_) {
            _updateReviewInCache(dvirId, reviewingDriverName);
            return const Right(true);
          },
        );
      },
      offline: () => _enqueueReview(
        dvirId: parsedId,
        dto: dto,
        reviewerName: reviewingDriverName,
      ),
    );
  }
}
