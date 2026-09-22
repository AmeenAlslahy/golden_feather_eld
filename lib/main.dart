import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/app_initializer.dart';
import 'core/utils/logger.dart';
import 'core/widgets/critical_error_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تثبيت اتجاه التطبيق عمودي
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // إعداد شريط الحالة
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // تسجيل أخطاء Flutter الحرجة
  FlutterError.onError = (details) {
    if (_isExpectedError(details.exception)) {
      return;
    }
    AppLogger.error('Critical Flutter Error', details.exception, details.stack);
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
      CriticalErrorApp(
        message:
            'تعذر تهيئة الخدمات الأساسية للتطبيق.\nيرجى التحقق من اتصالك وإعادة التشغيل.',
        exception: e,
      ),
    );
  }
}

bool _isExpectedError(Object error) {
  if (error is FlutterError) {
    final msg = error.message;
    if (msg.contains('setState() called after dispose') ||
        msg.contains('RenderBox was not laid out')) {
      AppLogger.debug('Expected Flutter error (ignored): $msg');
      return true;
    }
  }
  return false;
}
