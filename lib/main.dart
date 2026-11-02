import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/utils/logger.dart';
import 'core/utils/startup_profiler.dart';
import 'app/app_initializer.dart';
import 'core/widgets/critical_error_app.dart';

void main() async {
  // M0 — قياس الإقلاع (تشخيص فقط): نقطة الصفر + طوابع حول الخطوات القائمة
  // بلا إعادة ترتيب ولا أثر وظيفي.
  StartupProfiler.start();
  WidgetsFlutterBinding.ensureInitialized();

  // تثبيت اتجاه التطبيق عمودي
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // إعداد شريط الحالة المبدئي — يتناسق مع شريط التطبيق الذهبي والخلفية الفاتحة
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // أخطاء Flutter: تُسجَّل ويُعاد عرضها كما هي — النسخة السابقة كانت
  // تسكت "setState after dispose" و"RenderBox not laid out"، وهما bug حقيقي
  // كان يُخفى عن المطوّر.
  FlutterError.onError = (details) {
    AppLogger.error('Critical Flutter Error', details.exception, details.stack);
    FlutterError.presentError(details);
  };

  final initializer = AppInitializer();

  try {
    // 1. تهيئة النظام والخدمات
    await initializer.initialize();

    // 2. إنشاء الحاوية (ProviderContainer)
    final container = initializer.createProviderContainer();

    // 3. مهام ما بعد الإنشاء
    await initializer.initializePostContainer(container);

    // 4. تشغيل التطبيق
    StartupProfiler.mark('pre-runApp: all initializers done');
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const GoldenFeatherApp(),
      ),
    );
  } catch (e, stack) {
    AppLogger.error('Fatal initialization error', e, stack);
    runApp(
      const CriticalErrorApp(
        message:
            'تعذر تهيئة الخدمات الأساسية للتطبيق.\nيرجى التحقق من اتصالك وإعادة التشغيل.',
      ),
    );
  }
}
