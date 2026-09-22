import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_gap.dart';

/// تطبيق طوارئ يتم عرضه عندما تفشل تهيئة الخدمات الأساسية (مثل Firebase)
class CriticalErrorApp extends StatelessWidget {
  final String message;
  final Object? exception;

  const CriticalErrorApp({
    super.key,
    required this.message,
    this.exception,
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
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                AppGap.lg,
                const Text(
                  'عذراً، حدث خطأ حرج',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                AppGap.smMd,
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                if (exception != null) ...[
                  AppGap.lg,
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.smMd),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(AppRadius.input),
                    ),
                    child: Text(
                      exception.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.black87,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}