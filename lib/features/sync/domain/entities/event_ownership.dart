import 'pending_event.dart';

/// درجة إثبات مالك حدث معلق — تُستخرج من الـ payload الموجود فقط.
///
/// لا يدخل المستخدم الحالي (أو الأخير) في التقييم أبداً: التوقيع لا
/// يستقبل أي هوية خارجية، فلا يمكن استخدامه لاستنتاج مالك قديم.
enum OwnerEvidence {
  /// معرف موجب في خانة النوع الموثقة (لا يقبل التأويل).
  proven,

  /// لا معرف مباشر، لكن logId يطابق سجلاً مخزناً لمالك واحد فقط.
  /// لا تُرسل تلقائياً أبداً — تحتاج دليلاً إضافياً (مراجعة Part 2).
  recoverable,

  /// لا دليل — تُحفظ ولا تُرسل.
  unknown,

  /// مجهولة بالتصميم (قيادة غير محددة) — ليست ملك أحد أصلاً.
  unidentifiedByDesign,
}

/// نتيجة استخراج الملكية لحدث واحد.
class EventOwnership {
  final OwnerEvidence evidence;

  /// معرف السائق المثبت أو المسترد (null لغيرهما).
  final int? driverId;

  const EventOwnership._(this.evidence, this.driverId);

  const EventOwnership.proven(int driverId)
      : this._(OwnerEvidence.proven, driverId);

  const EventOwnership.recoverable(int driverId)
      : this._(OwnerEvidence.recoverable, driverId);

  static const unknown =
      EventOwnership._(OwnerEvidence.unknown, null);

  static const unidentified =
      EventOwnership._(OwnerEvidence.unidentifiedByDesign, null);

  bool get isProven => evidence == OwnerEvidence.proven;
}

/// مستخرج ملكية pure: (حدث + lookup اختياري) → ملكية.
///
/// [cachedLogOwner] يُرجع معرف مالك سجل مخزن لـ logId، أو null عند
/// غيابه/غموضه. غياب الدالة نفسها = لا دليل مخزن (UNKNOWN لا RECOVERABLE).
/// لا يوجد أي مسار ترقية تلقائية: إقرار السائق وحده (proof لاحق) لا
/// يغير هذه النتيجة — الإفراج قرار سياج Part 2 الصريح فقط.
abstract final class EventOwnershipResolver {
  static EventOwnership resolve(
    PendingEvent event, {
    int? Function(int logId)? cachedLogOwner,
  }) {
    if (event.type == 'unidentified_driving') {
      return EventOwnership.unidentified;
    }

    final direct = _directDriverId(event);
    if (direct != null) return EventOwnership.proven(direct);

    final logId = _asPositiveInt(event.payload['logId']);
    if (logId != null && cachedLogOwner != null) {
      final owner = cachedLogOwner(logId);
      if (owner != null && owner > 0) {
        return EventOwnership.recoverable(owner);
      }
    }
    return EventOwnership.unknown;
  }

  /// خانات المالك المباشرة الموثقة لكل نوع (duty/DVIR/inspection).
  /// certification/form بلا خانة — عمداً (الفجوة المؤكدة تُعالج بالتخزين).
  static int? _directDriverId(PendingEvent event) {
    final payload = event.payload;
    switch (event.type) {
      case 'duty_status':
      case 'dvir_create':
      case 'inspection_transfer':
        return _asPositiveInt(payload['driverId']);
      case 'dvir_review':
        final review = payload['review'];
        if (review is Map) {
          return _asPositiveInt(review['reviewingDriverId']);
        }
        return null;
      default:
        return null;
    }
  }

  static int? _asPositiveInt(dynamic raw) {
    final value = raw is int
        ? raw
        : raw is num
            ? raw.toInt()
            : int.tryParse('${raw ?? ''}');
    if (value == null || value <= 0) return null;
    return value;
  }
}
