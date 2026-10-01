import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../home/presentation/pages/home_page.dart';

/// شاشة تظهر عندما تتغير حالة السائق إلى Driving
/// تمنع تشتت السائق وتخفي واجهة التطبيق التزاماً بقواعد FMCSA.
class DrivingLockScreen extends ConsumerWidget {
  const DrivingLockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;

    return Container(
      color: Colors.black.withValues(alpha: 0.9), // خلفية داكنة جداً
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onDoubleTap: () {
                // UI Bypass: Just hide the screen locally so we can test other pages
                if (kDebugMode) ref.read(developerBypassDrivingScreenProvider.notifier).state = true;
              },
              child: const Icon(
                Icons.directions_car,
                color: AppColors.primaryGold,
                size: 100,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              loc.vehicleInMotionTitle,
              style: context.styles.pageTitle.copyWith(color: AppColors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                loc.vehicleInMotionDesc,
                style: context.styles.body.copyWith(color: AppColors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
