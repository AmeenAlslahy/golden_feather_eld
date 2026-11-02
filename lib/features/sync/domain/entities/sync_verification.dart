import 'pending_event.dart';

/// حكم التحقق من نتيجة إرسال حدث بعد استجابة الخادم.
///
/// `confirmed` لا يُمنح لمجرد نجاح النقل: مسار الاعتماد لا يمنحه إلا عندما
/// يؤكد الخادم `isCertified == true`، ومسار النموذج يمنحه بعد قبول الحفظ
/// (مع الحفاظ على حالة الاكتمال كما وردت في الاستجابة).
enum SyncVerification { confirmed, retryable, rejected }

/// نتيجة موثقة لحدث بعد محاولة إرساله.
class VerifiedSyncResult {
  final PendingEvent event;
  final int ownerDriverId;
  final SyncVerification verification;

  /// استجابة الخادم الخام عند النجاح (مثل جسم حفظ النموذج) — null عند
  /// الفشل أو عندما لا يحمل النوع استجابة مفيدة.
  final Map<String, dynamic>? serverData;

  const VerifiedSyncResult({
    required this.event,
    required this.ownerDriverId,
    required this.verification,
    this.serverData,
  });
}

/// يُستدعى بعد كل محاولة إرسال (نجاح مؤكد/قابل لإعادة المحاولة/رفض نهائي).
typedef SyncResultCallback = Future<void> Function(VerifiedSyncResult result);
