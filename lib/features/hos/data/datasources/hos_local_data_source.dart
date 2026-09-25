import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/storage_constants.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/utils/logger.dart';

abstract class HosLocalDataSource {
  Future<bool> saveDiagnostic(Map<String, dynamic> diagnosticData);
  Future<List<Map<String, dynamic>>> getDiagnostics(DateTime date);

  Future<bool> saveViolation(Map<String, dynamic> violationData);
  Future<List<Map<String, dynamic>>> getViolations(DateTime date);
}

class HosLocalDataSourceImpl implements HosLocalDataSource {
  Box<String> get _diagnosticsBox =>
      Hive.box<String>(StorageConstants.diagnosticsBox);
  Box<String> get _violationsBox =>
      Hive.box<String>(StorageConstants.violationsBox);

  // --- Helper Methods ---

  Future<bool> _saveToBox(
    Box<String> box,
    Map<String, dynamic> data,
    String timestampKey,
    String entityName,
  ) async {
    try {
      final dateStr =
          AppDateUtils.extractDateStr(data[timestampKey] as String?);
      final currentList = _getListFromBox(box, dateStr);
      currentList.add(data);

      await box.put(dateStr, jsonEncode(currentList));
      return true;
    } catch (e) {
      AppLogger.error('Failed to save $entityName', e);
      throw Exception('Failed to save $entityName: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getFromBox(
    Box<String> box,
    DateTime date,
    String entityName,
  ) async {
    try {
      final dateStr = AppDateUtils.formatDate(date);
      return _getListFromBox(box, dateStr);
    } catch (e) {
      AppLogger.error('Failed to get $entityName', e);
      throw Exception('Failed to get $entityName: $e');
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

  // --- Implementations ---

  @override
  Future<bool> saveDiagnostic(Map<String, dynamic> diagnosticData) =>
      _saveToBox(_diagnosticsBox, diagnosticData, 'timestamp', 'diagnostic');

  @override
  Future<List<Map<String, dynamic>>> getDiagnostics(DateTime date) =>
      _getFromBox(_diagnosticsBox, date, 'diagnostics');

  @override
  Future<bool> saveViolation(Map<String, dynamic> violationData) =>
      _saveToBox(_violationsBox, violationData, 'timestamp', 'violation');

  @override
  Future<List<Map<String, dynamic>>> getViolations(DateTime date) =>
      _getFromBox(_violationsBox, date, 'violations');
}

final hosLocalDataSourceProvider = Provider<HosLocalDataSource>((ref) {
  return HosLocalDataSourceImpl();
});
