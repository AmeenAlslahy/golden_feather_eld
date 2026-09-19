/// كائن القيمة (Value Object) لتمثيل كلمة المرور
class Password {
  final String value;
  final bool isValid;

  const Password._(this.value, this.isValid);

  /// إنشاء كائن كلمة مرور — يقبل أي قيمة غير فارغة بأي طول
  factory Password(String input) {
    final isValid = input.isNotEmpty;
    return Password._(input, isValid);
  }

  /// إرجاع رسالة الخطأ إذا كانت كلمة المرور فارغة
  String? get errorMessage {
    if (value.isEmpty) {
      return 'passwordRequired';
    }
    return null;
  }
}
