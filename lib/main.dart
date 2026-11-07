import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/utils/logger.dart';
import 'core/utils/startup_profiler.dart';
import 'app/app_initializer.dart';
import 'app/bootstrap_app.dart';
import 'core/widgets/critical_error_app.dart';

void main() {
  // نقطة الصفر قبل أي عمل — القياس لا يغيّر الترتيب.
  StartupProfiler.start();
  WidgetsFlutterBinding.ensureInitialized();

  // لا ننتظر تثبيت الاتجاه: كان await هنا يؤخر أول إطار ~5.9 ثانية على
  // جهاز الاختبار. الإطار الأول يُرسم بالاتجاه الحالي ثم يُثبّت فوراً.
  unawaited(
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).catchError((Object e) {
      AppLogger.warning('Failed to lock orientation: $e');
    }),
  );

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

  // 1) إطار فوري: شعار + مؤشر تحميل، بلا أي اعتماد على الخدمات.
  runApp(const BootstrapApp());

  // 2) بعد رسم الإطار الأول فقط نبدأ التهيئة الثقيلة في الخلفية.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_bootstrap());
  });
}

Future<void> _bootstrap() async {
  final initializer = AppInitializer();

  try {
    // تهيئة النظام والخدمات (لم تعد تتضمن فتح صناديق Hive).
    await initializer.initialize();

    // إنشاء الحاوية (ProviderContainer)
    final container = initializer.createProviderContainer();

    // مهام ما بعد الإنشاء
    await initializer.initializePostContainer(container);

    // 3) استبدال شاشة الـ Bootstrap بالتطبيق الحقيقي.
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
