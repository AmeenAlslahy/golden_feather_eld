import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/utils/logger.dart';
import 'app/app_initializer.dart';
import 'core/widgets/critical_error_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تثبيت اتجاه التطبيق عمودي
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // إعداد شريط الحالة — شريط التطبيق ذهبي ثابت في الوضعين،
  // فالأيقونات تكون فاتحة دائماً.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
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
