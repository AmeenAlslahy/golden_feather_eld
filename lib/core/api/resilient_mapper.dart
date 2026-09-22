/// مرونة API — طبقة عزل تمنع انهيار التطبيق عند تغيير الباك-إند.
///
/// **المبدأ:** كل حقل يُقرأ بمرونة عبر aliases وقيم افتراضية وآمان نوعي.
/// لا يعتمد أي DTO على اسم حقل واحد فقط.
///
/// **الفائدة:** عند إعادة تسمية حقل في الباك-إند (مثل `driver_id` → `driverId`)
/// فإن التطبيق يستمر بالعمل دون تعديل.
library;

/// قارئ حقول مرن — يدعم أسماء بديلة وتحويل آمن.
class ResilientField {
  final Map<String, dynamic> json;
  const ResilientField(this.json);

  /// اقرأ قيمة بمرونة عبر قائمة أسماء بديلة.
  /// يجرّب كل اسم بالترتيب ويُعيد أول قيمة غير-null.
  T? get<T>(List<String> aliases, {T? fallback}) {
    for (final key in aliases) {
      final value = _getNested(key);
      if (value != null) {
        final casted = _safeCast<T>(value);
        if (casted != null) return casted;
        // محاولة تحويل رقمي/نصي مرن
        final coerced = _coerce<T>(value);
        if (coerced != null) return coerced;
      }
    }
    return fallback;
  }

  /// اقرأ قيمة مطلوبة — يرمي فقط في وضع التطوير لتسهيل اكتشاف الأخطاء.
  T require<T>(List<String> aliases, {T? fallback}) {
    final value = get<T>(aliases, fallback: fallback);
    if (value == null) {
      assert(() {
        // في التطوير: نبّه بوضوح عن الحقل المفقود
        return true;
      }());
      throw FormatException('Missing required field: ${aliases.join(" | ")}');
    }
    return value;
  }

  // دعم الحقول المتداخلة مثل "driver.name"
  dynamic _getNested(String key) {
    if (!key.contains('.')) return json[key];
    dynamic cur = json;
    for (final part in key.split('.')) {
      if (cur is Map<String, dynamic>) {
        cur = cur[part];
      } else {
        return null;
      }
    }
    return cur;
  }

  T? _safeCast<T>(dynamic value) {
    if (value is T) return value;
    return null;
  }

  T? _coerce<T>(dynamic value) {
    // int من String
    if (T == int && value is String) {
      return int.tryParse(value) as T?;
    }
    if (T == int && value is double) {
      return value.toInt() as T;
    }
    if (T == double && value is String) {
      return double.tryParse(value) as T?;
    }
    if (T == double && value is int) {
      return value.toDouble() as T;
    }
    if (T == String) {
      return value.toString() as T;
    }
    if (T == bool && value is int) {
      return (value != 0) as T;
    }
    if (T == bool && value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true as T;
      if (lower == 'false' || lower == '0') return false as T;
    }
    return null;
  }
}

/// عقد Mapper مرن — كل تحويل DTO→Domain يمر من هنا.
///
/// **القاعدة الذهبية:** لا يُنشأ Entity مباشرة من json بدون المرور عبر Mapper.
/// هذا يضمن أن تغيير الباك-إند لا يكسر إلا Mapper واحد فقط.
abstract class ResilientMapper<Dto, Domain> {
  const ResilientMapper();
  Domain fromDto(Dto dto);
  Dto toDto(Domain domain);

  /// تحويل آمن لقائمة — يتجاوز العناصر الفاسدة بدلاً من كسر القائمة كاملة.
  List<Domain> fromDtoList(List<dynamic> list) {
    final result = <Domain>[];
    for (final item in list) {
      try {
        if (item is Dto) result.add(fromDto(item));
      } catch (_) {
        // تجاهل عنصر فاسد واحد — لا تكسر كل البيانات
        continue;
      }
    }
    return result;
  }
}

/// DTO أساسي مرن — يتجاهل الحقول غير المعروفة تلقائياً.
///
/// **الاستخدام:** كل DTO يرث من هذا أو يستخدم ResilientField داخلياً.
abstract class ResilientDto {
  const ResilientDto();

  /// الحقول غير المعروفة — محفوظة للتدقيق دون كسر التحليل.
  Map<String, dynamic> get unknownFields => const {};

  /// تحقق لطيف — يعيد false بدلاً من رمي استثناء عند بيانات ناقصة.
  bool get isValid => true;
}

/// مساعد التوافق الإصداري — يسمح للـ API القديم والجديد بالعمل معاً.
class ApiVersionTolerance {
  const ApiVersionTolerance._();

  /// ادمج استجابتين مختلفتي البنية في بنية موحدة.
  ///
  /// مثال: الباك-إند القديم يعيد `totalHours` والجديد يعيد `totals.drive`
  static T pickFirst<T>(List<T?> candidates, T fallback) {
    for (final c in candidates) {
      if (c != null) return c;
    }
    return fallback;
  }

  /// طبّع قيمة حالة — يحوّل أي صيغة إلى صيغة موحدة.
  ///
  /// يقبل: "OFF", "off_duty", "Off Duty", 1, "1"
  static String normalizeStatus(dynamic raw, {String fallback = 'OFF'}) {
    if (raw == null) return fallback;
    final s = raw.toString().trim().toUpperCase();
    const mapping = {
      '1': 'OFF',
      '2': 'SB',
      '3': 'D',
      '4': 'ON',
      'OFF_DUTY': 'OFF',
      'OFF DUTY': 'OFF',
      'SLEEPER': 'SB',
      'SLEEPER_BERTH': 'SB',
      'DRIVING': 'D',
      'ON_DUTY': 'ON',
      'ON DUTY': 'ON',
    };
    return mapping[s] ?? s;
  }
}
