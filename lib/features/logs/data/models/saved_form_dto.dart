import '../../domain/saved_form_status.dart';

/// DTO المسؤول عن فك تشفير استجابة حفظ النموذج من الخادم (Data Layer).
class SavedFormDto {
  /// قراءة حالة اكتمال النموذج من استجابة الخادم.
  static SavedFormRead fromJson(Map<String, dynamic> json) {
    final body = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    var raw = body['formStatus']?.toString().trim();
    final indicator = body['formIndicator'] is Map
        ? Map<String, dynamic>.from(body['formIndicator'] as Map)
        : null;
    if (raw == null || raw.isEmpty) {
      raw = indicator?['status']?.toString().trim();
    }
    final message = body['message']?.toString().trim();
    final text = message == null || message.isEmpty ? null : message;

    final indicatorPositive = indicator?['positive'] as bool?;
    final indicatorColor = indicator?['color']?.toString().toUpperCase();

    bool? complete;
    if (raw != null && raw.isNotEmpty) {
      final upper = raw.toUpperCase();
      complete = switch (upper) {
        'COMPLETED' || 'COMPLETE' => true,
        'INCOMPLETE' || 'IN_PROGRESS' || 'DRAFT' => false,
        _ => null,
      };
    }
    if (complete == null) {
      if (indicatorPositive == true || indicatorColor == 'GREEN') {
        complete = true;
      } else if (indicatorPositive == false || indicatorColor == 'RED') {
        complete = false;
      }
    }

    return SavedFormRead(formStatus: raw, complete: complete, message: text);
  }
}
