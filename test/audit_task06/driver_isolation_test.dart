import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/constants/storage_constants.dart';
import 'package:golden_feather_eld/core/services/user_preferences_storage_service.dart';
import 'package:golden_feather_eld/features/logs/data/datasources/log_local_data_source.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // SharedPreferencesWithCache is built on SharedPreferencesAsync (نمط
  // audit_task03) — يتطلب InMemorySharedPreferencesAsync.
  const initial = {
    'language': 'ar',
    'selected_vehicle': 'truck-9',
    'current_duty_status': 'driving',
    'stationary_since': '2026-03-01T08:00:00Z',
  };

  group('P0 — driver isolation wipes', () {
    test('clearDutyTrackingState removes both duty keys and keeps the rest',
        () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData(initial);
      final prefs = await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(
          allowList: {
            'language',
            'selected_vehicle',
            'current_duty_status',
            'stationary_since',
          },
        ),
      );
      final service = UserPreferencesStorageService(prefs);

      expect(service.currentDutyStatus, 'driving');

      await service.clearDutyTrackingState();

      expect(service.currentDutyStatus, 'off_duty',
          reason: 'يعود للافتراضي بدل حالة السائق السابق');
      expect(service.stationarySince, isNull);
      expect(service.language, 'ar', reason: 'بقية التفضيلات لا تُمس');
      expect(service.selectedVehicleId, 'truck-9');
    });

    test('clearPeriods empties the periods box only', () async {
      final dir = await Directory.systemTemp.createTemp('audit06_hive');
      Hive.init(dir.path);
      final periods = await Hive.openBox<String>(StorageConstants.periodsBox);
      final events = await Hive.openBox<String>(StorageConstants.eventsBox);
      await periods.put('2026-03-01', '{"period":"stale-owner"}');
      await events.put('2026-03-01', '{"event":"keep"}');

      await LogLocalDataSourceImpl().clearPeriods();

      expect(periods.isEmpty, isTrue,
          reason: 'فترات السائق السابق لا يجوز أن تظهر لسائق جديد');
      expect(events.isNotEmpty, isTrue, reason: 'صندوق الأحداث لا يُمس');

      await Hive.close();
      await dir.delete(recursive: true);
    });
  });
}
