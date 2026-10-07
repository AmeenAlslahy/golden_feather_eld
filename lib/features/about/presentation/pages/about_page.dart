import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:geolocator/geolocator.dart';
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
import '../../../tracking/presentation/providers/tracking_providers.dart';
import '../../../connection/presentation/pages/diagnostics_page.dart';
import '../../../connection/presentation/providers/hardware_alerts_provider.dart';
import '../../../connection/presentation/providers/hardware_status_provider.dart';
import '../../../connection/presentation/widgets/eld_diagnostics_section.dart';
import '../../../../l10n/app_localizations.dart';

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

    final packageInfo = ref.watch(packageInfoProvider);
    final isConnected = ref.watch(isConnectedProvider);
    final gpsStatus = ref.watch(gpsStatusProvider);
    final storage = ref.watch(localStorageProvider);

    final loc = context.loc;
    final notAvailable = loc.notAvailable;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        centerTitle: true,
        title: Text(
          loc.aboutTitle,
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
                  loc.applicationInfo,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                EldInfoRow(
                  label: loc.appNameLabel,
                  value: AppConstants.appName,
                ),
                packageInfo.when(
                  data: (info) => Column(
                    children: [
                      EldInfoRow(
                        label: loc.appVersionLabel,
                        value: '${info.version} (${info.buildNumber})',
                      ),
                      EldInfoRow(
                        label: loc.appPackageLabel,
                        value: info.packageName,
                      ),
                    ],
                  ),
                  loading: () => EldInfoRow(
                    label: loc.appVersionLabel,
                    value: '...',
                  ),
                  error: (_, __) => EldInfoRow(
                    label: loc.appVersionLabel,
                    value: AppConstants.appVersion,
                  ),
                ),
                EldInfoRow(
                  label: loc.deviceIdLabel,
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
                  loc.diagnosticsAndConnection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                _StatusTile(
                  icon: Icons.cloud_outlined,
                  label: loc.centralServer,
                  isOk: isConnected.valueOrNull ?? false,
                  okText: loc.connected,
                  badText: loc.disconnected,
                ),
                const Divider(color: AppColors.border),
                _StatusTile(
                  icon: Icons.gps_fixed,
                  label: loc.locationService,
                  isOk: gpsStatus.valueOrNull == ServiceStatus.enabled,
                  okText: loc.enabled,
                  badText: loc.disabled,
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
                              label: loc.hardwareAlerts,
                              isOk: alerts.isEmpty,
                              okText: loc.noActiveAlerts,
                              badText: loc.activeAlerts,
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
                          anyErrorUserMessage(err, loc: AppLocalizations.of(context)!),
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
                final hwStatusAsync = ref.watch(hardwareStatusProvider);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.loc.technicalInfo,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    hwStatusAsync.when(
                      data: (data) => Column(
                        children: [
                          EldInfoRow(
                            label: context.loc.eldEngineVersion,
                            value: data.engineVersion ?? notAvailable,
                          ),
                          EldInfoRow(
                            label: context.loc.hardwareVersion,
                            value: data.deviceVersion ?? notAvailable,
                          ),
                          EldInfoRow(
                            label: context.loc.lastDataReceived,
                            value: data.lastHeartbeat ?? notAvailable,
                          ),
                        ],
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      // Never a raw exception string for the driver.
                      error: (err, _) => Text(
                        anyErrorUserMessage(err, loc: AppLocalizations.of(context)!),
                        style: context.styles.error,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ========== حالة اتصال ELD + التسجيل اليدوي (SRS 3.7 / 3.8) ==========
          EldCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        loc.eldConnectionStatus,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    // Retry for both server reads (data pages: retry + refresh).
                    IconButton(
                      tooltip: loc.refresh,
                      color: context.styles.body.color,
                      icon: Icon(
                        Icons.refresh,
                        color: context.styles.body.color,
                      ),
                      onPressed: () {
                        ref.invalidate(hardwareStatusProvider);
                        ref.invalidate(hardwareReadinessProvider);
                      },
                    ),
                  ],
                ),
                const EldConnectivityPanel(),
                const EldReadinessPanel(),
                const SizedBox(height: AppSpacing.sm),
                const ManualRecordingSection(),
                const SizedBox(height: AppSpacing.sm),
                // SRS 7.14: الشاشة المستقلة للتشخيصات والأعطال.
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    icon: const Icon(Icons.monitor_heart, size: 18),
                    label: Text(context.loc.diagnosticsScreen),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const DiagnosticsPage(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            loc.supportText,
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
