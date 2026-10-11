import '../../domain/saved_form_status.dart';

/// DTO المسؤول عن فك تشفير استجابة حفظ النموذج من الخادم (Data Layer).
class SavedFormDto {
  /// قراءة حالة اكتمال النموذج من استجابة الخادم.
  static SavedFormRead fromJson(Map<String, dynamic> json) {
    final body = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final raw = body['formStatus']?.toString().trim();
    final message = body['message']?.toString().trim();
    final text = message == null || message.isEmpty ? null : message;
    if (raw == null || raw.isEmpty) {
      return SavedFormRead(message: text);
    }
    final upper = raw.toUpperCase();
    final bool? complete = switch (upper) {
      'COMPLETED' || 'COMPLETE' => true,
      'INCOMPLETE' || 'IN_PROGRESS' => false,
      _ => null,
    };
    return SavedFormRead(formStatus: raw, complete: complete, message: text);
  }
}
