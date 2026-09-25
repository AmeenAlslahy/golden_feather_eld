import 'package:flutter/material.dart';

/// تطبيق طوارئ يتم عرضه عندما تفشل تهيئة الخدمات الأساسية (مثل Firebase)
/// تفاصيل الاستثناء تُسجَّل في main.dart ولا تُعرض هنا (قد تحوي مسارات أو PII).
class CriticalErrorApp extends StatelessWidget {
  final String message;

  const CriticalErrorApp({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Golden Feather ELD - Error',
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 24),
                const Text(
                  'عذراً، حدث خطأ حرج',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
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
