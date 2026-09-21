import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// شاشة تظهر عندما تتغير حالة السائق إلى Driving
/// تمنع تشتت السائق وتخفي واجهة التطبيق التزاماً بقواعد FMCSA.
class DrivingLockScreen extends StatelessWidget {
  const DrivingLockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Container(
      color: Colors.black.withValues(alpha: 0.9), // خلفية داكنة جداً
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_car,
              color: AppColors.primaryBlue,
              size: 100,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              isArabic ? 'المركبة في حالة حركة' : 'Vehicle in Motion',
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppTypography.titleSize,
                fontWeight: AppTypography.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                isArabic 
                    ? 'التزاماً بقواعد السلامة المرورية ولوائح FMCSA، يتم حظر استخدام التطبيق أثناء القيادة. ستتم استعادة الواجهة فور توقف المركبة.'
                    : 'To comply with FMCSA regulations and safety rules, the application is locked while driving. It will unlock when the vehicle stops.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: AppTypography.bodySize,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
