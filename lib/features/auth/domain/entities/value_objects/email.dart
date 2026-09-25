import 'email_regex.dart';

/// كائن القيمة (Value Object) لتمثيل البريد الإلكتروني
class Email {
  final String value;
  final bool isValid;

  const Email._(this.value, this.isValid);

  /// إنشاء كائن بريد إلكتروني مع التحقق من صحته
  factory Email(String input) {
    final trimmed = input.trim();
    final isValid = RegExp(emailPattern).hasMatch(trimmed);
    return Email._(trimmed, isValid);
  }

  /// إرجاع رسالة الخطأ إذا كان البريد غير صالح
  String? get errorMessage {
    if (value.isEmpty) {
      return 'emailRequired';
    }
    if (!isValid) {
      return 'invalidEmailFormat';
    }
    return null;
  }
}
