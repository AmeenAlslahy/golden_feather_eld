import 'package:flutter/material.dart';
import '../error/failure.dart';

/// فئة مساعدة لتسهيل التعامل مع الأخطاء في واجهة المستخدم (UI Layer)
class UiErrorHandler {
  
  /// دالة لإظهار رسالة خطأ قياسية باستخدام SnackBar
  /// يمكنك تمرير [Failure] أو [String] أو [Exception]
  static void showError(BuildContext context, dynamic error) {
    String message = 'حدث خطأ غير متوقع';

    if (error is Failure) {
      message = error.arabicMessage ?? error.message;
    } else if (error is String) {
      message = error;
    } else {
      message = error.toString();
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 4),
        ),
      );
  }
}
