import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/theme/app_colors.dart';
import 'package:golden_feather_eld/core/utils/status_color_helper.dart';

/// P0 (تدقيق الهوية البصرية 2026-10-24): لون عرض حالات الواجب هو رموز
/// الهوية الرسمية حصراً — كان النطاق يحمل نسخ hex متباعدة عنها، ومعاينة
/// الفحص خريطة ثالثة مختلفة. هذا الاختبار يثبّت التوحيد.
void main() {
  test('كل حالة ترسم بلونها الرسمي من AppColors', () {
    expect(StatusColorHelper.getStatusColor('ON_DUTY'), AppColors.primaryGold);
    expect(
      StatusColorHelper.getStatusColor('YARD_MOVE'),
      AppColors.primaryGold,
    );
    expect(
      StatusColorHelper.getStatusColor('PERSONAL_CONVEYANCE'),
      AppColors.primaryGold,
    );
    expect(
      StatusColorHelper.getStatusColor('OFF_DUTY'),
      AppColors.textSecondary,
    );
    expect(StatusColorHelper.getStatusColor('DRIVING'), AppColors.successGreen);
    expect(
      StatusColorHelper.getStatusColor('SLEEPER'),
      AppColors.warningYellow,
    );
  });

  test('الرموز القصيرة والقيم الفارغة تُحلّ لنفس الخريطة', () {
    expect(StatusColorHelper.getStatusColor('ON'), AppColors.primaryGold);
    expect(StatusColorHelper.getStatusColor('D'), AppColors.successGreen);
    expect(StatusColorHelper.getStatusColor('SB'), AppColors.warningYellow);
    expect(StatusColorHelper.getStatusColor('OFF'), AppColors.textSecondary);
    expect(StatusColorHelper.getStatusColor('YM'), AppColors.primaryGold);
    expect(StatusColorHelper.getStatusColor('PC'), AppColors.primaryGold);
    // null/فارغ ⇒ off-duty (سلوك fromAny) — لا لون مخترع لحالة مجهولة.
    expect(StatusColorHelper.getStatusColor(null), AppColors.textSecondary);
    expect(StatusColorHelper.getStatusColor(''), AppColors.textSecondary);
  });
}
