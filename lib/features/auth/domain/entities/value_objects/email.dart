/// كائن القيمة (Value Object) لتمثيل البريد الإلكتروني
class Email {
  final String value;
  final bool isValid;

  const Email._(this.value, this.isValid);

  /// إنشاء كائن بريد إلكتروني مع التحقق من صحته
  factory Email(String input) {
    final trimmed = input.trim();
    // Regex للتحقق من البريد الإلكتروني
    final regex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    final isValid = regex.hasMatch(trimmed);
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
