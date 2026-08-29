import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/eld_card.dart';
import '../providers/inspection_provider.dart';

/// شاشة سجلات التفتيش المفصلة
class InspectionLogsPage extends ConsumerWidget {
  const InspectionLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspectionState = ref.watch(inspectionProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.surface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isArabic ? 'سجلات التفتيش' : 'Inspection Logs',
          style: const TextStyle(
            fontSize: AppTypography.bodySize,
            fontWeight: AppTypography.bold,
            color: AppColors.surface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== معلومات السائق ==========
            EldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, isArabic ? 'معلومات السائق' : 'Driver Information'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoRow(context, isArabic ? 'الاسم' : 'Name', 'Amin Alsalhi'),
                  _buildInfoRow(context, isArabic ? 'الرخصة' : 'License', 'CDL-582491'),
                  _buildInfoRow(context, isArabic ? 'الناقل' : 'Carrier', 'Golden Feather Transport'),
                  _buildInfoRow(context, isArabic ? 'رقم USDOT' : 'USDOT', '1234567'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ========== معلومات المركبة ==========
            EldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, isArabic ? 'معلومات المركبة' : 'Vehicle Information'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoRow(context, isArabic ? 'رقم المركبة' : 'Vehicle', '646'),
                  _buildInfoRow(context, isArabic ? 'النوع' : 'Type', '2015 VOLVO TT'),
                  _buildInfoRow(context, isArabic ? 'رقم الهيكل' : 'VIN', '1FUJGLDR5CSBJ0527'),
                  _buildInfoRow(context, isArabic ? 'المقطورة' : 'Trailer', '1402'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ========== معلومات جهاز ELD ==========
            EldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, isArabic ? 'معلومات جهاز ELD' : 'ELD Information'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoRow(context, isArabic ? 'الشركة المصنعة' : 'Manufacturer', 'Golden Feather'),
                  _buildInfoRow(context, isArabic ? 'الطراز' : 'Model', 'GF-ELD-001'),
                  _buildInfoRow(context, isArabic ? 'معرف الجهاز' : 'Device ID', 'GF-10000001'),
                  _buildInfoRow(context, isArabic ? 'إصدار البرنامج' : 'Software Version', '1.0.0'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ========== سجلات آخر 8 أيام ==========
            EldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, isArabic ? 'ملخص السجلات' : 'Log Summary'),
                  const SizedBox(height: AppSpacing.sm),
                  ...inspectionState.days.map((day) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(day.formattedDate, style: const TextStyle(fontSize: AppTypography.captionSize)),
                        Text('${day.drivingHours.toStringAsFixed(1)}h',
                            style: const TextStyle(fontSize: AppTypography.captionSize, fontWeight: AppTypography.bold)),
                      ],
                    ),
                  )),
                  const Divider(color: AppColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isArabic ? 'إجمالي المسافة' : 'Total Distance',
                          style: const TextStyle(fontSize: AppTypography.bodySize, fontWeight: AppTypography.bold)),
                      Text('${(inspectionState.days.fold(0.0, (sum, day) => sum + day.drivingHours) * 60).toStringAsFixed(0)} mi',
                          style: const TextStyle(fontSize: AppTypography.bodySize, fontWeight: AppTypography.bold)),
                    ],
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.primaryBlue,
            fontWeight: AppTypography.bold,
          ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: AppTypography.bodySize, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: AppTypography.bodySize, fontWeight: AppTypography.semiBold)),
        ],
      ),
    );
  }
}
