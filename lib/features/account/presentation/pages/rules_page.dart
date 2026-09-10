import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../core/widgets/eld_info_row.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../../hos/domain/engine/hos_state_machine.dart';

/// Rules screen (read-only).
///
/// SRS §6: all HOS rules and exceptions are managed centrally by the Fleet
/// Manager. The driver can only view the active configuration.
/// TODO(Phase 5): read values from GET /eld/config instead of the local
/// hosConfigurationProvider.
class RulesPage extends ConsumerWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(hosConfigurationProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final loc = context.loc;

    String hours(int minutes) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      if (m == 0) return isArabic ? '$h ساعة' : '$h h';
      return isArabic ? '$h س $m د' : '${h}h ${m}m';
    }

    final cycleLabel =
        '${config.cycleLimitHours}/${config.maxConsecutiveDays}';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          loc.rules,
          style: const TextStyle(
            fontSize: AppTypography.bodySize,
            fontWeight: AppTypography.bold,
            color: AppColors.surface,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.surface),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const EldDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ========== Mandatory notice (SRS §6) ==========
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warningYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warningYellow.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline, color: AppColors.textPrimary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      isArabic
                          ? 'تُدار قواعد ساعات الخدمة والاستثناءات مركزياً وفق لوائح FMCSA. '
                              'لأي تغيير يرجى التواصل مع مدير الأسطول (Fleet Manager).'
                          : 'HOS rules and exceptions are managed centrally per FMCSA '
                              'regulations. Contact your Fleet Manager for any change.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ========== Active cycle ==========
            EldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'الدورة المطبقة' : 'Active Cycle',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  EldInfoRow(
                    label: isArabic ? 'الدورة' : 'Cycle',
                    value: 'USA $cycleLabel',
                  ),
                  EldInfoRow(
                    label: isArabic ? 'إعادة التشغيل' : 'Restart',
                    value: hours(config.weeklyRestartHours * 60),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ========== Daily limits ==========
            EldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'الحدود اليومية' : 'Daily Limits',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  EldInfoRow(
                    label: isArabic ? 'القيادة' : 'Driving',
                    value: hours(config.drivingLimitMinutes),
                  ),
                  EldInfoRow(
                    label: isArabic ? 'نافذة العمل' : 'Shift window',
                    value: hours(config.shiftLimitMinutes),
                  ),
                  EldInfoRow(
                    label: isArabic ? 'استراحة إلزامية' : 'Required break',
                    value:
                        '${config.breakDurationMinutes} ${isArabic ? 'د' : 'min'}'
                        ' / ${hours(config.driveBeforeBreakMinutes)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ========== Regulatory references ==========
            EldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'المراجع التنظيمية' : 'Regulatory References',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const EldInfoRow(
                    label: '30-Minute Break',
                    value: 'FMCSA 49 CFR §395.3',
                  ),
                  const EldInfoRow(
                    label: 'Short Haul 16-Hour',
                    value: 'FMCSA 49 CFR §395.1(o)',
                  ),
                  const EldInfoRow(
                    label: 'Personal Conveyance',
                    value: 'FMCSA 49 CFR §395.8',
                  ),
                  const EldInfoRow(
                    label: 'Yard Moves',
                    value: 'FMCSA 49 CFR §395.28',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
