import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_constants.dart';
import '../utils/logger.dart';

class LocalDatabaseService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    try {
      await Hive.initFlutter();

      await Hive.openBox<String>(StorageConstants.eventsBox);
      await Hive.openBox<String>(StorageConstants.periodsBox);
      await Hive.openBox<String>(StorageConstants.diagnosticsBox);
      await Hive.openBox<String>(StorageConstants.violationsBox);
      await Hive.openBox<String>(StorageConstants.auditBox);

      _prefs = await SharedPreferences.getInstance();

      AppLogger.info('✅ LocalDatabaseService initialized successfully');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to initialize LocalDatabaseService', e, stack);
      rethrow;
    }
  }

  // All database CRUD operations have been moved to their respective
  // LocalDataSource implementations to adhere to the Single Responsibility Principle.
  // This class now acts purely as a DatabaseManager that initializes Hive boxes at startup.

  // --- Simple Settings (SharedPreferences) ---
  Future<void> saveSetting(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getSetting(String key) {
    return _prefs.getString(key);
  }
}

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  throw UnimplementedError(
      'Initialize localDatabaseServiceProvider in main.dart');
});
