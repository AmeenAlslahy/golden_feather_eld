import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../core/widgets/eld_info_row.dart';
import '../../../connection/presentation/providers/hardware_alerts_provider.dart';
import '../../../connection/presentation/providers/hardware_status_provider.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';

/// مزود معلومات حزمة التطبيق
final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

/// شاشة "حول التطبيق والتشخيص" (SRS §17)
///
/// - متاحة بدون تسجيل دخول
/// - تعرض إصدار التطبيق ومعرّف الجهاز الفريد
/// - تعرض حالة الاتصال بالخادم المركزي وخدمة الموقع
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final packageInfo = ref.watch(packageInfoProvider);
    final isConnected = ref.watch(isConnectedProvider);
    final gpsStatus = ref.watch(gpsStatusProvider);
    final storage = ref.watch(localStorageProvider);

    final notAvailable = isArabic ? 'غير متوفر' : 'N/A';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        centerTitle: true,
        title: Text(
          isArabic ? 'حول التطبيق' : 'About',
          style: context.styles.appBarTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ========== معلومات التطبيق ==========
          EldCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'معلومات التطبيق' : 'Application',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                EldInfoRow(
                  label: isArabic ? 'الاسم' : 'Name',
                  value: AppConstants.appName,
                ),
                packageInfo.when(
                  data: (info) => Column(
                    children: [
                      EldInfoRow(
                        label: isArabic ? 'الإصدار' : 'Version',
                        value: '${info.version} (${info.buildNumber})',
                      ),
                      EldInfoRow(
                        label: isArabic ? 'معرّف الحزمة' : 'Package',
                        value: info.packageName,
                      ),
                    ],
                  ),
                  loading: () => EldInfoRow(
                    label: isArabic ? 'الإصدار' : 'Version',
                    value: '...',
                  ),
                  error: (_, __) => EldInfoRow(
                    label: isArabic ? 'الإصدار' : 'Version',
                    value: AppConstants.appVersion,
                  ),
                ),
                EldInfoRow(
                  label: isArabic ? 'معرّف الجهاز' : 'Device ID',
                  value: storage.deviceId.isNotEmpty
                      ? storage.deviceId
                      : notAvailable,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ========== حالة الاتصال ==========
          EldCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'التشخيص والاتصال' : 'Diagnostics',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                _StatusTile(
                  icon: Icons.cloud_outlined,
                  label: isArabic ? 'الخادم المركزي' : 'Central server',
                  isOk: isConnected.valueOrNull ?? false,
                  okText: isArabic ? 'متصل' : 'Connected',
                  badText: isArabic ? 'غير متصل' : 'Disconnected',
                ),
                const Divider(color: AppColors.border),
                _StatusTile(
                  icon: Icons.gps_fixed,
                  label: isArabic ? 'خدمة الموقع (GPS)' : 'Location service (GPS)',
                  isOk: gpsStatus.valueOrNull == ServiceStatus.enabled,
                  okText: isArabic ? 'مفعّل' : 'Enabled',
                  badText: isArabic ? 'معطّل' : 'Disabled',
                ),
                
                // إضافة حالة اتصال الـ ELD 
                Consumer(
                  builder: (context, ref, _) {
                    final alertsState = ref.watch(hardwareAlertsProvider);
                    
                    return alertsState.when(
                      data: (alerts) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(color: AppColors.border),
                            _StatusTile(
                              icon: Icons.developer_board,
                              label: isArabic ? 'تنبيهات الجهاز' : 'Hardware alerts',
                              isOk: alerts.isEmpty,
                              okText: isArabic ? 'لا توجد تنبيهات' : 'No active alerts',
                              badText: isArabic ? 'يوجد تنبيهات' : 'Active alerts',
                            ),
                            if (alerts.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: alerts.map((a) => Text(
                                    '• ${a.message}',
                                    style: context.styles.error,
                                  )).toList(),
                                ),
                              ),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, _) => Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          anyErrorUserMessage(err, isArabic: isArabic),
                          style: context.styles.error,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ========== معلومات تقنية (SRS 3.8) ==========
          EldCard(
            child: Consumer(
              builder: (context, ref, _) {
                final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                final hwStatusAsync = ref.watch(hardwareStatusProvider);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'المعلومات التقنية' : 'Technical Info',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    hwStatusAsync.when(
                      data: (data) => Column(
                        children: [
                          EldInfoRow(
                            label: isArabic ? 'إصدار محرك ELD' : 'ELD Engine Version',
                            value: data.engineVersion ?? notAvailable,
                          ),
                          EldInfoRow(
                            label: isArabic ? 'إصدار الجهاز (Hardware)' : 'Hardware Version',
                            value: data.deviceVersion ?? notAvailable,
                          ),
                          EldInfoRow(
                            label: isArabic ? 'توقيت آخر بيانات' : 'Last Data Received',
                            value: data.lastHeartbeat ?? notAvailable,
                          ),
                        ],
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      // Never a raw exception string for the driver.
                      error: (err, _) => Text(
                        anyErrorUserMessage(err, isArabic: isArabic),
                        style: context.styles.error,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            isArabic
                ? 'للدعم الفني يرجى تزويد فريق الدعم بمعرّف الجهاز ورقم الإصدار أعلاه.'
                : 'For technical support, provide the device ID and version shown above.',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isOk;
  final String okText;
  final String badText;

  const _StatusTile({
    required this.icon,
    required this.label,
    required this.isOk,
    required this.okText,
    required this.badText,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOk ? AppColors.successGreen : AppColors.dangerRed;
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: color),
        title: Text(label,
            style: context.styles.body),
        trailing: Text(
          isOk ? okText : badText,
          style: TextStyle(
            fontSize: AppTypography.captionSize,
            fontWeight: AppTypography.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
