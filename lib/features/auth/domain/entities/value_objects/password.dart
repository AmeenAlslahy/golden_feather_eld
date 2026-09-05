/// كائن القيمة (Value Object) لتمثيل كلمة المرور
class Password {
  final String value;
  final bool isValid;

  const Password._(this.value, this.isValid);

  /// إنشاء كائن كلمة مرور مع التحقق من صحتها
  factory Password(String input) {
    // التحقق المبدئي لطول كلمة المرور
    final isValid = input.length >= 6;
    return Password._(input, isValid);
  }

  /// إرجاع رسالة الخطأ إذا كانت كلمة المرور غير صالحة
  String? get errorMessage {
    if (value.isEmpty) {
      return 'passwordRequired';
    }
    if (!isValid) {
      return 'invalidValue';
    }
    return null;
  }
}
