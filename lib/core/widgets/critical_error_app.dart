import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';

import '../theme/app_theme.dart';

/// تطبيق طوارئ يتم عرضه عندما تفشل تهيئة الخدمات الأساسية (مثل Firebase)
/// تفاصيل الاستثناء تُسجَّل في main.dart ولا تُعرض هنا (قد تحوي مسارات أو PII).
class CriticalErrorApp extends StatelessWidget {
  final String message;

  const CriticalErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Golden Feather ELD - Error',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  'عذراً، حدث خطأ حرج',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                // تفاصيل الاستثناء لا تُعرض للمستخدم (قد تحوي مسارات أو PII)؛
                // تُسجَّل في السجلات فقط عند التهيئة.
              ],
            ),
          ),
        ),
      ),
    );
  }
}
