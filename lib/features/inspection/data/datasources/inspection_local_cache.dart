import 'dart:convert';

import '../../../../backend/adapters/eld_engine/mappers/dot_inspection_mapper.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/inspection/dot_inspection.dart';
import '../../domain/inspection_transfer.dart';
import '../../domain/transfer_audit.dart';
import '../mappers/inspection_mappers.dart';

abstract class InspectionLocalCache {
  Future<void> saveScreen(DotInspectionScreen screen, {int? ownerId});
  DotInspectionScreen? loadScreen({int? ownerId});

  Future<void> saveCycle(List<DotInspectionCycleDay> cycle, {int? ownerId});
  List<DotInspectionCycleDay>? loadCycle({int? ownerId});

  Future<void> saveLog(String key, DotInspectionLog log);
  DotInspectionLog? loadLog(String key);
  Map<String, DotInspectionLog> loadAllLogs({int? ownerId});

  Future<void> savePacket(InformationPacketView packet, {int? ownerId});
  InformationPacketView? loadPacket({int? ownerId});

  Future<void> saveTransfers(List<TransferAuditRow> transfers, {int? ownerId});
  List<TransferAuditRow>? loadTransfers({int? ownerId});

  Future<void> clear();
}

class PrefsInspectionLocalCache implements InspectionLocalCache {
  final LocalStorageService _storage;

  static const String _screenKey = 'inspection_screen_cache';
  static const String _cycleKey = 'inspection_cycle_cache';
  static const String _logsKey = 'inspection_logs_cache';
  static const String _packetKey = 'inspection_packet_cache';
  static const String _transfersKey = 'inspection_transfers_cache';

  PrefsInspectionLocalCache(this._storage);

  @override
  Future<void> saveScreen(DotInspectionScreen screen, {int? ownerId}) async {
    try {
      final map = {
        'ownerId': ownerId ?? screen.driverId.value,
        'data': {
          'screenTitle': screen.screenTitle,
          'guidanceText': screen.guidanceText,
          'handOverDeviceNotice': screen.handOverDeviceNotice,
          'carrierComplianceStatement': screen.carrierComplianceStatement,
          'carrierName': screen.carrierName,
          'usdotNumber': screen.usdotNumber,
          'eldIdentifier': screen.eldIdentifier,
          'eldRegistrationId': screen.eldRegistrationId,
          'driver': {'id': screen.driverId.value, 'name': screen.driverName},
          'inspectionDate': screen.inspectionDate.toIso8601String(),
          'cycleDaysCovered': screen.cycleDaysCovered,
          'canStartInspection': screen.canStartInspection,
          'canSendLogs': screen.canSendLogs,
          'canEmailLogs': screen.canEmailLogs,
          'canViewInformationPacket': screen.canViewInformationPacket,
          'inspectionActive': screen.inspectionActive,
          'readOnlyMode': screen.readOnlyMode,
          'activeInspectionId': screen.activeInspectionId,
          'inspectorName': screen.inspectorName,
        },
      };
      await _storage.prefs.setString(_screenKey, jsonEncode(map));
    } catch (e) {
      AppLogger.warning('InspectionLocalCache.saveScreen failed: $e');
    }
  }

  @override
  DotInspectionScreen? loadScreen({int? ownerId}) {
    try {
      final raw = _storage.prefs.getString(_screenKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (ownerId != null && decoded['ownerId'] != ownerId) return null;
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return null;
      return DotInspectionMapper.fromScreenJson(data);
    } catch (e) {
      AppLogger.warning('InspectionLocalCache.loadScreen failed: $e');
      return null;
    }
  }

  @override
  Future<void> saveCycle(List<DotInspectionCycleDay> cycle, {int? ownerId}) async {
    try {
      final list = cycle.map((d) => _encodeCycleDay(d)).toList();
      final map = {
        'ownerId': ownerId,
        'data': list,
      };
      await _storage.prefs.setString(_cycleKey, jsonEncode(map));
    } catch (e) {
      AppLogger.warning('InspectionLocalCache.saveCycle failed: $e');
    }
  }

  @override
  List<DotInspectionCycleDay>? loadCycle({int? ownerId}) {
    try {
      final raw = _storage.prefs.getString(_cycleKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (ownerId != null && decoded['ownerId'] != ownerId) return null;
      final data = decoded['data'];
      if (data is! List) return null;
      return DotInspectionMapper.fromCycleJson(data);
    } catch (e) {
      AppLogger.warning('InspectionLocalCache.loadCycle failed: $e');
      return null;
    }
  }

  @override
  Future<void> saveLog(String key, DotInspectionLog log) async {
    try {
      final existing = _loadRawLogsMap();
      existing[key] = _encodeLog(log);
      await _storage.prefs.setString(_logsKey, jsonEncode(existing));
    } catch (e) {
      AppLogger.warning('InspectionLocalCache.saveLog failed: $e');
    }
  }

  @override
  DotInspectionLog? loadLog(String key) {
    try {
      final map = _loadRawLogsMap();
      final rawLog = map[key];
      if (rawLog is Map<String, dynamic>) {
        return DotInspectionMapper.fromLogJson(rawLog);
      }
      return null;
    } catch (e) {
      AppLogger.warning('InspectionLocalCache.loadLog failed: $e');
      return null;
    }
  }

  @override
  Map<String, DotInspectionLog> loadAllLogs({int? ownerId}) {
    try {
      final map = _loadRawLogsMap();
      final result = <String, DotInspectionLog>{};
      final prefix = ownerId != null ? '$ownerId:' : null;
      for (final entry in map.entries) {
        if (prefix != null && !entry.key.startsWith(prefix)) continue;
        if (entry.value is Map<String, dynamic>) {
          result[entry.key] = DotInspectionMapper.fromLogJson(entry.value as Map<String, dynamic>);
        }
      }
      return result;
    } catch (e) {
      AppLogger.warning('InspectionLocalCache.loadAllLogs failed: $e');
      return {};
    }
  }

  Map<String, dynamic>? _logsCache;

  Map<String, dynamic> _loadRawLogsMap() {
    // P2 — فكّ الأرشيف مرة واحدة وذاكرته في المثيل: قبل ذلك كان كل
    // save/load يعيد jsonDecode للأرشيف كاملاً (كل السجلات لكل الأيام).
    // الكتابة تبقى encode واحداً (key واحد في التخزين) لكن الفكّ صار
    // مرة واحدة، و`clear()` تُبطل الذاكرة.
    final cached = _logsCache;
    if (cached != null) return cached;
    final raw = _storage.prefs.getString(_logsKey);
    if (raw == null || raw.isEmpty) return _logsCache = {};
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return _logsCache = decoded;
    return _logsCache = {};
  }

  @override
  Future<void> savePacket(InformationPacketView packet, {int? ownerId}) async {
    try {
      final map = {
        'ownerId': ownerId,
        'data': {
          'title': packet.title,
          'regulationReference': packet.regulation,
          'completenessStatusText': packet.statusText,
          'complete': packet.complete,
          'missingItems': packet.missing,
          'items': packet.items
              .map((i) => {
                    'title': i.title,
                    'available': i.available,
                    'mandatory': i.mandatory,
                  })
              .toList(),
        },
      };
      await _storage.prefs.setString(_packetKey, jsonEncode(map));
    } catch (e) {
      AppLogger.warning('InspectionLocalCache.savePacket failed: $e');
    }
  }

  @override
  InformationPacketView? loadPacket({int? ownerId}) {
    try {
      final raw = _storage.prefs.getString(_packetKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (ownerId != null && decoded['ownerId'] != ownerId) return null;
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return null;
      return parseInformationPacket(data);
    } catch (e) {
      AppLogger.warning('InspectionLocalCache.loadPacket failed: $e');
      return null;
    }
  }

  @override
  Future<void> saveTransfers(List<TransferAuditRow> transfers, {int? ownerId}) async {
    try {
      final list = transfers
          .map((t) => {
                'channel': t.channel,
                'recipient': t.recipient,
                'status': t.status,
                'transferredAt': t.transferredAt,
                'message': t.message,
                'period': t.period,
                'recordCount': t.recordCount,
              })
          .toList();
      final map = {
        'ownerId': ownerId,
        'data': list,
      };
      await _storage.prefs.setString(_transfersKey, jsonEncode(map));
    } catch (e) {
      AppLogger.warning('InspectionLocalCache.saveTransfers failed: $e');
    }
  }

  @override
  List<TransferAuditRow>? loadTransfers({int? ownerId}) {
    try {
      final raw = _storage.prefs.getString(_transfersKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (ownerId != null && decoded['ownerId'] != ownerId) return null;
      final data = decoded['data'];
      if (data is! List) return null;
      return parseTransferAudit(data);
    } catch (e) {
      AppLogger.warning('InspectionLocalCache.loadTransfers failed: $e');
      return null;
    }
  }

  @override
  Future<void> clear() async {
    try {
      _logsCache = null;
      await _storage.prefs.remove(_screenKey);
      await _storage.prefs.remove(_cycleKey);
      await _storage.prefs.remove(_logsKey);
      await _storage.prefs.remove(_packetKey);
      await _storage.prefs.remove(_transfersKey);
    } catch (e) {
      AppLogger.warning('InspectionLocalCache.clear failed: $e');
    }
  }

  static Map<String, dynamic> _encodeCycleDay(DotInspectionCycleDay d) => {
        'driver': {'id': d.driverId.value, 'name': d.driverName},
        'logDate': d.logDate.toIso8601String(),
        'displayDate': d.displayDate,
        'displayLocation': d.displayLocation,
        'certified': d.certified,
        'certifiedAt': d.certifiedAt?.toIso8601String(),
        'eldRegistrationId': d.eldRegistrationId,
        'eldIdentifier': d.eldIdentifier,
        'eldProvider': d.eldProvider,
        'vehicleNumber': d.vehicleNumber,
        'uniqueId': d.uniqueId,
        'vin': d.vin,
        'startOdometerKm': d.startOdometerKm,
        'endOdometerKm': d.endOdometerKm,
        'totalDistanceKm': d.totalDistanceKm,
        'engineHours': d.engineHours,
        'trailers': d.trailers,
        'shippingDocuments': d.shippingDocuments,
        'carrierName': d.carrierName,
        'usdotNumber': d.usdotNumber,
        'mainOfficeAddress': d.mainOfficeAddress,
        'homeTerminalAddress': d.homeTerminalAddress,
        'activeDataDiagnostics': d.activeDataDiagnostics,
        'activeDeviceMalfunctions': d.activeDeviceMalfunctions,
        'exemptDriver': d.exemptDriver,
        'exemptReason': d.exemptReason,
        'hasUnidentifiedDriving': d.hasUnidentifiedDriving,
        'unidentifiedDrivingCount': d.unidentifiedDrivingCount,
      };

  static Map<String, dynamic> _encodeLog(DotInspectionLog l) => {
        'driver': {'id': l.driverId.value, 'name': l.driverName},
        'logDate': l.logDate.toIso8601String(),
        'displayDate': l.displayDate,
        'displayLocation': l.displayLocation,
        'certified': l.certified,
        'certifiedAt': l.certifiedAt?.toIso8601String(),
        'eldRegistrationId': l.eldRegistrationId,
        'eldIdentifier': l.eldIdentifier,
        'eldProvider': l.eldProvider,
        'vehicleNumber': l.vehicleNumber,
        'uniqueId': l.uniqueId,
        'vin': l.vin,
        'startOdometerKm': l.startOdometerKm,
        'endOdometerKm': l.endOdometerKm,
        'totalDistanceKm': l.totalDistanceKm,
        'engineHours': l.engineHours,
        'trailers': l.trailers,
        'shippingDocuments': l.shippingDocuments,
        'carrierName': l.carrierName,
        'usdotNumber': l.usdotNumber,
        'mainOfficeAddress': l.mainOfficeAddress,
        'homeTerminalAddress': l.homeTerminalAddress,
        'activeDataDiagnostics': l.activeDataDiagnostics,
        'activeDeviceMalfunctions': l.activeDeviceMalfunctions,
        'readOnly': l.readOnly,
        'period24HourStartTime': l.period24HourStartTime,
        'driverLicenseNumber': l.driverLicenseNumber,
        'driverLicenseState': l.driverLicenseState,
        'coDriverName': l.coDriverName,
        'coDriverId': l.coDriverId,
        'events': l.events
            .map((e) => {
                  'sequenceNumber': e.sequenceNumber,
                  'timeEt': e.timeEt,
                  'eventCode': e.eventCode,
                  'eventType': e.eventType,
                  'description': e.description,
                  'location': e.location,
                  'odometer': e.odometer,
                  'engineHours': e.engineHours,
                  'origin': e.origin,
                  'notes': e.notes,
                  'certificationEvent': e.certificationEvent,
                })
            .toList(),
      };
}
