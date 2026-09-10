import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../core/widgets/eld_info_row.dart';
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
        backgroundColor: AppColors.primaryBlue,
        centerTitle: true,
        title: Text(
          isArabic ? 'حول التطبيق' : 'About',
          style: const TextStyle(
            fontSize: AppTypography.bodySize,
            fontWeight: AppTypography.bold,
            color: AppColors.surface,
          ),
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
              ],
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label,
          style: const TextStyle(fontSize: AppTypography.bodySize)),
      trailing: Text(
        isOk ? okText : badText,
        style: TextStyle(
          fontSize: AppTypography.captionSize,
          fontWeight: AppTypography.bold,
          color: color,
        ),
      ),
    );
  }
}
