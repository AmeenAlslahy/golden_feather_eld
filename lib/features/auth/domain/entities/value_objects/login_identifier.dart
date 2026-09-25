import 'email_regex.dart';

/// كائن القيمة (Value Object) لتمثيل مُعرف تسجيل الدخول (بريد إلكتروني أو اسم مستخدم)
class LoginIdentifier {
  final String value;
  final bool isValid;
  final bool isEmail;

  const LoginIdentifier._(this.value, this.isValid, this.isEmail);

  /// إنشاء كائن المُعرف مع التحقق الذكي (بريد أو اسم مستخدم)
  factory LoginIdentifier(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return LoginIdentifier._(trimmed, false, false);
    }

    if (trimmed.contains('@')) {
      // التحقق كبريد إلكتروني (النمط الواحد في email_regex.dart)
      final isValidEmail = RegExp(emailPattern).hasMatch(trimmed);
      return LoginIdentifier._(trimmed, isValidEmail, true);
    } else {
      // التحقق كاسم مستخدم (طوله أكبر من 0)
      return LoginIdentifier._(trimmed, true, false);
    }
  }

  /// إرجاع رسالة الخطأ المناسبة
  String? get errorMessage {
    if (value.isEmpty) {
      return 'emailRequired';
    }
    if (isEmail && !isValid) {
      return 'invalidEmailFormat';
    }
    if (!isValid) {
      return 'invalidValue';
    }
    return null;
  }
}
