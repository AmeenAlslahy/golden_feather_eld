import 'eld_info_row.dart';

export 'eld_info_row.dart';

/// الاسم الدلالي الموحد لصف المفتاح والقيمة وفق Design System 2.0.
///
/// تم ربط `AppKeyValueRow` مباشرة بـ `EldInfoRow` للحفاظ على التوافق التام
/// مع الاستخدامات الحالية ومنع إنشاء أنظمة موازية أو مضاعفة الأكواد.
typedef AppKeyValueRow = EldInfoRow;
