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
}
