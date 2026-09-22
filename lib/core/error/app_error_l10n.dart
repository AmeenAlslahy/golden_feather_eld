library;
/// ترجمة AppError.l10nKey إلى رسالة صديقة للمستخدم
/// **المبدأ:** لا قيم يدوية في الواجهة — كل رسالة خطأ تمر عبر هذا الملف

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'app_error.dart';

extension AppErrorL10n on AppError {
  String localized(BuildContext context) {
    return l10nKey.localized(context, fallback: code);
  }
}

extension StringL10nKeyX on String {
  /// ترجمة l10nKey إلى رسالة مستخدم — مع fallback إلى الكود
  String localized(BuildContext context, {String? fallback}) {
    final loc = AppLocalizations.of(context);
    if (loc == null) return fallback ?? this;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    switch (this) {
      // Network
      case 'networkTimeout':
        return isAr ? 'انتهت مهلة الاتصال بالشبكة' : 'Network timeout';
      case 'networkConnectionFailed':
        return isAr ? 'فشل الاتصال بالإنترنت' : 'Network connection failed';
      case 'networkBadCertificate':
        return isAr ? 'شهادة الخادم غير صالحة' : 'Invalid server certificate';
      case 'networkCancelled':
        return isAr ? 'تم إلغاء الطلب' : 'Request cancelled';
      case 'network.unknown':
      case 'network.unknownError':
        return isAr ? 'خطأ شبكة غير معروف' : 'Unknown network error';
      // Validation
      case 'validationError':
        return isAr ? 'البيانات غير صالحة' : 'Validation error';
      case 'validation.badRequest':
        return isAr ? 'طلب غير صالح' : 'Bad request';
      case 'fileTooLarge':
        return isAr ? 'الملف كبير جداً' : 'File too large';
      case 'unsupportedFileType':
        return isAr ? 'نوع الملف غير مدعوم' : 'Unsupported file type';
      // Auth
      case 'sessionExpired':
        return loc.sessionExpired;
      case 'permissionDenied':
        return isAr ? 'ليس لديك صلاحية' : 'Permission denied';
      // Resource
      case 'notFound':
        return isAr ? 'العنصر غير موجود' : 'Not found';
      case 'conflictError':
      case 'resource.conflict':
        return isAr ? 'تعارض في البيانات' : 'Data conflict';
      // Server
      case 'serverError':
      case 'server.noResponse':
      case 'server.unavailable':
        return isAr ? 'خطأ في الخادم' : 'Server error';
      case 'featureNotSupported':
        return isAr ? 'الميزة غير مدعومة' : 'Feature not supported';
      // Time
      case 'timeUnavailable':
        return isAr ? 'الوقت الموثوق غير متاح' : 'Trusted time unavailable';
      // Generic fallback from AppLocalizations
      case 'unknownError':
        return loc.unexpectedError;
      case 'unexpectedError':
        return loc.unexpectedError;
      default:
        // Try to resolve via AppLocalizations if key matches a getter
        if (this == 'serverError' || this == 'unknownError') {
          return loc.unexpectedError;
        }
        // Return fallback or raw key translated
        return fallback ?? (isAr ? 'حدث خطأ غير متوقع' : 'Unexpected error');
    }
  }
}

/// Helper for providers that store `String? error` as l10nKey
String localizeErrorKey(BuildContext context, String? key, {String? fallback}) {
  if (key == null || key.isEmpty) return '';
  return key.localized(context, fallback: fallback);
}
