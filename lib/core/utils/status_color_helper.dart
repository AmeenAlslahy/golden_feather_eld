import 'package:flutter/material.dart';

import '../../domain/duty_status/duty_status_code.dart';
import '../theme/app_colors.dart';

/// الخريطة اللونية الوحيدة لعرض حالات الواجب — رموز الهوية الرسمية
/// حصراً (`AppColors`).
///
/// كانت ثلاث خرائط متباعدة: نسخ hex في النطاق (وقيمها تخالف التعليقات
/// المرفقة بها)، وخريطة ثالثة خاصة في معاينة الفحص (SB أزرق!). الآن
/// مصدر واحد يستهلكه بلاط الأحداث ومعاينة الفحص معاً.
class StatusColorHelper {
  StatusColorHelper._();

  /// [status] يقبل الرموز الخام والقصيرة والقيم الفارغة/null
  /// (تُقرأ off-duty — انظر [DutyStatusCode.fromAny]).
  static Color getStatusColor(String? status) {
    return switch (DutyStatusCode.fromAny(status)) {
      DutyStatusCode.onDutyNotDriving ||
      DutyStatusCode.yardMove ||
      DutyStatusCode.personalConveyance => AppColors.primaryGold,
      DutyStatusCode.offDuty => AppColors.textSecondary,
      DutyStatusCode.driving => AppColors.successGreen,
      DutyStatusCode.sleeperBerth => AppColors.warningYellow,
    };
  }
}
