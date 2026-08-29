/// امتدادات String
extension StringExtensions on String {
  /// التحقق من صحة البريد الإلكتروني
  bool get isValidEmail {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(this);
  }

  /// التحقق من صحة رقم الهاتف
  bool get isValidPhone {
    return RegExp(r'^\+?[\d\s-]{8,15}$').hasMatch(this);
  }

  /// التحقق من صحة URL
  bool get isValidUrl {
    return Uri.tryParse(this)?.hasAbsolutePath ?? false;
  }

  /// التحقق من أن النص ليس فارغاً
  bool get isNotEmptyAfterTrim => trim().isNotEmpty;

  /// تحويل النص إلى عنوان (أول حرف كبير)
  String get toTitleCase {
    if (isEmpty) return this;
    return split(' ')
        .map((word) =>
            word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  /// اختصار النص
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$suffix';
  }

  /// إزالة علامات HTML
  String get stripHtml => replaceAll(RegExp(r'<[^>]*>'), '');

  /// إخفاء جزء من النص (مثل رقم الهاتف)
  String mask({int visibleChars = 4, String maskChar = '*'}) {
    if (length <= visibleChars) return this;
    final masked = maskChar * (length - visibleChars);
    return '$masked${substring(length - visibleChars)}';
  }
}


