import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../providers/status_dashboard_providers.dart';

/// شاشة تظهر عندما تتغير حالة السائق إلى Driving
/// تمنع تشتت السائق وتخفي واجهة التحكم مع الحفاظ على عداد الوقت المتبقي التزاماً بقواعد FMCSA.
class DrivingLockScreen extends ConsumerWidget {
  const DrivingLockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    final dashboard = ref.watch(statusDashboardProvider).valueOrNull;
    final driveRemaining =
        dashboard?.hosIndicators.drive.value ??
        dashboard?.remainingCircle.remaining;

    return Container(
      color: context.colors.scrim.withValues(alpha: 0.92), // خلفية داكنة جداً
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onDoubleTap: () {
                  // UI Bypass: Just hide the screen locally so we can test other pages
                  if (kDebugMode) {
                    ref
                            .read(developerBypassDrivingScreenProvider.notifier)
                            .state =
                        true;
                  }
                },
                child: Icon(
                  Icons.directions_car,
                  color: context.gold,
                  size: AppSpacing.iconHeroLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                loc.vehicleInMotionTitle,
                style: context.styles.pageTitle.copyWith(color: context.onBand),
                textAlign: TextAlign.center,
              ),
              if (driveRemaining != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  loc.remainingLabel.toUpperCase(),
                  style: context.styles.caption.copyWith(
                    color: context.onDarkMuted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  DurationFormat.hhMm(driveRemaining),
                  style: context.styles.timer.copyWith(
                    color: driveRemaining <= const Duration(minutes: 15)
                        ? context.dangerOnDark
                        : context.gold,
                    fontSize: AppTypography.heroTimerSize,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Text(
                  loc.vehicleInMotionDesc,
                  style: context.styles.body.copyWith(
                    color: context.onDarkMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
