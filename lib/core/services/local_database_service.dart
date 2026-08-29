import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../error/failure.dart';
import '../utils/logger.dart';
import '../utils/app_date_utils.dart';
import '../constants/storage_constants.dart';

class LocalDatabaseService {
  late Box<String> _eventsBox;
  late Box<String> _periodsBox;
  late Box<String> _diagnosticsBox;
  late Box<String> _violationsBox;
  late Box<String> _auditBox;
  late SharedPreferences _prefs;

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      
      _eventsBox = await Hive.openBox<String>(StorageConstants.eventsBox);
      _periodsBox = await Hive.openBox<String>(StorageConstants.periodsBox);
      _diagnosticsBox = await Hive.openBox<String>(StorageConstants.diagnosticsBox);
      _violationsBox = await Hive.openBox<String>(StorageConstants.violationsBox);
      _auditBox = await Hive.openBox<String>(StorageConstants.auditBox);
      
      _prefs = await SharedPreferences.getInstance();
      
      AppLogger.info('✅ LocalDatabaseService initialized successfully');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to initialize LocalDatabaseService', e, stack);
      rethrow;
    }
  }

  // --- Generic Repository Methods ---

  Future<Either<Failure, bool>> _saveToBox(
    Box<String> box, 
    Map<String, dynamic> data, 
    String timestampKey, 
    String entityName,
  ) async {
    try {
      final dateStr = AppDateUtils.extractDateStr(data[timestampKey] as String?);
      final currentList = _getListFromBox(box, dateStr);
      currentList.add(data);
      
      await box.put(dateStr, jsonEncode(currentList));
      return const Right(true);
    } catch (e) {
      AppLogger.error('Failed to save $entityName', e);
      return Left(CacheFailure(
        message: 'Failed to save $entityName: $e', 
        arabicMessage: 'فشل في حفظ البيانات',
      ));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> _getFromBox(
    Box<String> box, 
    DateTime date, 
    String entityName,
  ) async {
    try {
      final dateStr = AppDateUtils.formatDate(date);
      final list = _getListFromBox(box, dateStr);
      return Right(list);
    } catch (e) {
      AppLogger.error('Failed to get $entityName', e);
      return Left(CacheFailure(
        message: 'Failed to get $entityName: $e', 
        arabicMessage: 'فشل في جلب البيانات',
      ));
    }
  }

  List<Map<String, dynamic>> _getListFromBox(Box<String> box, String dateStr) {
    final data = box.get(dateStr);
    if (data == null) return [];
    try {
      final decoded = jsonDecode(data) as List;
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Specific Entity Implementations ---

  // Events
  Future<Either<Failure, bool>> saveEvent(Map<String, dynamic> eventData) => 
      _saveToBox(_eventsBox, eventData, 'timestamp', 'event');

  Future<Either<Failure, List<Map<String, dynamic>>>> getEventsByDate(DateTime date) => 
      _getFromBox(_eventsBox, date, 'events');

  // Periods
  Future<Either<Failure, bool>> savePeriod(Map<String, dynamic> periodData) => 
      _saveToBox(_periodsBox, periodData, 'start_time', 'period');

  Future<Either<Failure, List<Map<String, dynamic>>>> getPeriodsByDate(DateTime date) => 
      _getFromBox(_periodsBox, date, 'periods');

  // Diagnostics
  Future<Either<Failure, bool>> saveDiagnostic(Map<String, dynamic> diagnosticData) => 
      _saveToBox(_diagnosticsBox, diagnosticData, 'timestamp', 'diagnostic');

  Future<Either<Failure, List<Map<String, dynamic>>>> getDiagnostics(DateTime date) => 
      _getFromBox(_diagnosticsBox, date, 'diagnostics');

  // Violations
  Future<Either<Failure, bool>> saveViolation(Map<String, dynamic> violationData) => 
      _saveToBox(_violationsBox, violationData, 'timestamp', 'violation');

  Future<Either<Failure, List<Map<String, dynamic>>>> getViolations(DateTime date) => 
      _getFromBox(_violationsBox, date, 'violations');

  // Audit
  Future<Either<Failure, bool>> saveAudit(Map<String, dynamic> auditData) => 
      _saveToBox(_auditBox, auditData, 'timestamp', 'audit');

  Future<Either<Failure, List<Map<String, dynamic>>>> getAudit(DateTime date) => 
      _getFromBox(_auditBox, date, 'audit');

  // --- Simple Settings (SharedPreferences) ---
  Future<void> saveSetting(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getSetting(String key) {
    return _prefs.getString(key);
  }
}

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  throw UnimplementedError('Initialize localDatabaseServiceProvider in main.dart');
});
