import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_gap.dart';

/// شاشة تظهر عندما تتغير حالة السائق إلى Driving
/// تمنع تشتت السائق وتخفي واجهة التطبيق التزاماً بقواعد FMCSA.
class DrivingLockScreen extends StatelessWidget {
  const DrivingLockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Container(
      color: AppColors.black.withValues(alpha: 0.9), // خلفية داكنة جداً
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
            AppGap.xl,
            Text(
              context.loc.vehicleInMotion,
              style: const TextStyle(
                color: AppColors.surface,
                fontSize: AppTypography.titleSize,
                fontWeight: AppTypography.bold,
              ),
              textAlign: TextAlign.center,
            ),
            AppGap.md,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                context.loc.toComplyWithFmcsaRegulations,
                style: const TextStyle(
                  color: AppColors.surface70,
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
