import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';

/// انحدار حرج: كل مفتاح يقرأه/يكتبه `LocalStorageService` يجب أن يكون ضمن
/// allowList في `SharedPreferencesWithCache` — أي مفتاح ناقص يرمي
/// ArgumentError لحظة الوصول (كان يُسقط فحص السبلاش ويُعلّق الإقلاع).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // SharedPreferencesWithCache يستخدم منصة SharedPreferencesAsync —
    // محاكيها هو المطلوب هنا، لا محاكي المنصة القديمة.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({});
  });

  test('onboardingSeen reads and writes without allowlist rejection', () async {
    final storage = LocalStorageService();
    await storage.init();

    // أول قراءة على مخزن فارغ = false، والكتابة تُثبّتها.
    await storage.setOnboardingSeen();

    expect(storage.onboardingSeen, isTrue);
  });

  test('all facade getters tolerate missing keys without throwing',
      () async {
    final storage = LocalStorageService();
    await storage.init();

    // لمسات كل الخواص العامة — أي مفتاح خارج allowList يرمي هنا فوراً.
    // (الحالة static مشتركة داخل العملية، فالتأكيدات هنا "لا يرمي" فقط)
    expect(storage.onboardingSeen, isA<bool>());
    expect(storage.currentDutyStatus, isA<String>());
    expect(storage.serverUrl, isA<String>());
    expect(storage.backendType, isA<String>());
  });

  test('trusted_time_anchor reads and writes without allowlist rejection',
      () async {
    final storage = LocalStorageService();
    await storage.init();

    await storage.prefs.setString('trusted_time_anchor', '{"anchor":"test"}');
    expect(storage.prefs.getString('trusted_time_anchor'), '{"anchor":"test"}');
  });

  test('phase 2 offline cache keys are permitted in allowList', () async {
    final storage = LocalStorageService();
    await storage.init();

    final keys = [
      'codriver_list_cache',
      'codriver_current_cache',
      'inspection_screen_cache',
      'inspection_cycle_cache',
      'inspection_logs_cache',
      'inspection_packet_cache',
      'inspection_transfers_cache',
      'rules_screen_cache',
    ];

    for (final key in keys) {
      await storage.prefs.setString(key, '{"test":1}');
      expect(storage.prefs.getString(key), '{"test":1}');
      await storage.prefs.remove(key);
      expect(storage.prefs.getString(key), isNull);
    }
  });
}
