import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/logger.dart';

class LocalDatabaseService {
  /// يهيّئ Hive فقط — **لا يفتح أي صندوق**.
  ///
  /// الصناديق تُفتح عند أول استخدام عبر `ensureHiveBox` (انظر
  /// `lib/core/storage/hive_box_registry.dart`)، فلا يحجب الإقلاع فتح
  /// خمسة صناديق متتالية وترحيلها. هذا هو الفرق الجوهري عن السابق.
  Future<void> init() async {
    try {
      final watch = Stopwatch()..start();
      await Hive.initFlutter();
      AppLogger.info(
        '✅ Hive initialized in ${watch.elapsedMilliseconds}ms '
        '(boxes open lazily on first use)',
      );
    } catch (e, stack) {
      AppLogger.error('❌ Failed to initialize LocalDatabaseService', e, stack);
      rethrow;
    }
  }

  // All database CRUD operations have been moved to their respective
  // LocalDataSource implementations to adhere to the Single Responsibility Principle.
  // This class now only prepares Hive; boxes are opened lazily by their consumers.
}

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  throw UnimplementedError(
    'Initialize localDatabaseServiceProvider in main.dart',
  );
});
