import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/logger.dart';
import '../constants/storage_constants.dart';

class LocalDatabaseService {
  Future<void> init() async {
    try {
      await Hive.initFlutter();

      await Hive.openBox<String>(StorageConstants.eventsBox);
      await Hive.openBox<String>(StorageConstants.periodsBox);
      await Hive.openBox<String>(StorageConstants.auditBox);
      await Hive.openBox<String>(StorageConstants.dailyLogsCacheBox);

      AppLogger.info('✅ LocalDatabaseService initialized successfully');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to initialize LocalDatabaseService', e, stack);
      rethrow;
    }
  }

  // All database CRUD operations have been moved to their respective
  // LocalDataSource implementations to adhere to the Single Responsibility Principle.
  // This class now acts purely as a DatabaseManager that initializes Hive boxes at startup.
}

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  throw UnimplementedError(
      'Initialize localDatabaseServiceProvider in main.dart');
});
