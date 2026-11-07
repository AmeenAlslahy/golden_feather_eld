import 'package:flutter/material.dart';

import '../core/utils/startup_profiler.dart';

/// شاشة الإقلاع الفورية.
///
/// تُعرض قبل أي تهيئة ثقيلة (Firebase/SharedPreferences/Hive) حتى يظهر أول
/// إطار خلال أقل من ثانية بدل انتظار اكتمال كل الخدمات. بعد انتهاء التهيئة
/// يستبدلها `main()` بالتطبيق الحقيقي عبر `runApp` ثانٍ.
class BootstrapApp extends StatelessWidget {
  const BootstrapApp({super.key});

  @override
  Widget build(BuildContext context) {
    StartupProfiler.scheduleFirstFrameMark('bootstrap-first-frame');
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _BootstrapScreen(),
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/ic_launcher.png',
                width: 120,
                height: 120,
                cacheWidth: 360,
                cacheHeight: 360,
                filterQuality: FilterQuality.medium,
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
