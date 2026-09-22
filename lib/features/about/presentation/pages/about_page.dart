import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_gap.dart';
import '../../../../core/widgets/eld_app_bar.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../core/widgets/eld_info_row.dart';
import '../../../connection/presentation/providers/hardware_alerts_provider.dart';
import '../../../connection/presentation/providers/hardware_status_provider.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';

/// مزود معلومات حزمة التطبيق
final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

/// شاشة "حول التطبيق والتشخيص" (SRS §17) — 0% قيم يدوية، 100% loc
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);
    final isConnected = ref.watch(isConnectedProvider);
    final gpsStatus = ref.watch(gpsStatusProvider);
    final storage = ref.watch(localStorageProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: EldAppBar(title: context.loc.aboutTitle),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ========== معلومات التطبيق ==========
          EldCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.loc.applicationInfo, style: context.textTheme.titleMedium),
                AppGap.sm,
                EldInfoRow(label: context.loc.nameLabel, value: AppConstants.appName),
                packageInfo.when(
                  data: (info) => Column(
                    children: [
                      EldInfoRow(label: context.loc.versionLabel, value: '${info.version} (${info.buildNumber})'),
                      EldInfoRow(label: context.loc.packageLabel, value: info.packageName),
                    ],
                  ),
                  loading: () => EldInfoRow(label: context.loc.versionLabel, value: '...'),
                  error: (_, __) => EldInfoRow(label: context.loc.versionLabel, value: AppConstants.appVersion),
                ),
                EldInfoRow(
                  label: context.loc.deviceIdLabel,
                  value: storage.deviceId.isNotEmpty ? storage.deviceId : context.loc.notAvailable,
                ),
              ],
            ),
          ),
          AppGap.md,
          // ========== حالة الاتصال ==========
          EldCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.loc.diagnosticsTitle, style: context.textTheme.titleMedium),
                AppGap.sm,
                _StatusTile(
                  icon: Icons.cloud_outlined,
                  label: context.loc.centralServer,
                  isOk: isConnected.valueOrNull ?? false,
                  okText: context.loc.connected,
                  badText: context.loc.disconnected,
                ),
                const Divider(),
                _StatusTile(
                  icon: Icons.gps_fixed,
                  label: context.loc.locationService,
                  isOk: gpsStatus.valueOrNull == ServiceStatus.enabled,
                  okText: context.loc.enabledLabel,
                  badText: context.loc.disabledLabel,
                ),
                // حالة اتصال الـ ELD
                Consumer(
                  builder: (context, ref, _) {
                    final alertsState = ref.watch(hardwareAlertsProvider);
                    return alertsState.when(
                      data: (alerts) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          _StatusTile(
                            icon: Icons.developer_board,
                            label: context.loc.ecmSyncStatus,
                            isOk: alerts.isEmpty,
                            okText: context.loc.syncedLabel,
                            badText: context.loc.desyncedLabel,
                          ),
                          const Divider(),
                          _StatusTile(
                            icon: Icons.bluetooth_connected,
                            label: context.loc.hardwareConnection,
                            isOk: alerts.isEmpty,
                            okText: context.loc.healthyLabel,
                            badText: context.loc.faultyLabel,
                          ),
                          if (alerts.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: alerts
                                    .map((a) => Text('• ${a.message}', style: context.textTheme.bodySmall?.copyWith(color: context.eld.dangerFg)))
                                    .toList(),
                              ),
                            ),
                        ],
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: AppLoading(),
                      ),
                      error: (err, _) => Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text('Error loading hardware status: $err', style: TextStyle(color: context.eld.dangerFg)),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          AppGap.md,
          // ========== معلومات تقنية (SRS 3.8) ==========
          EldCard(
            child: Consumer(
              builder: (context, ref, _) {
                final hwStatusAsync = ref.watch(hardwareStatusProvider);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.loc.technicalInfo, style: context.textTheme.titleMedium),
                    AppGap.sm,
                    hwStatusAsync.when(
                      data: (data) => Column(
                        children: [
                          EldInfoRow(label: context.loc.eldEngineVersion, value: data.engineVersion),
                          EldInfoRow(label: context.loc.hardwareVersion, value: data.deviceVersion),
                          EldInfoRow(label: context.loc.lastDataReceived, value: data.lastDataTime),
                        ],
                      ),
                      loading: () => const AppLoading(),
                      error: (err, _) => Text('Error: $err', style: TextStyle(color: context.eld.dangerFg)),
                    ),
                  ],
                );
              },
            ),
          ),
          AppGap.md,
          Text(
            context.loc.supportMessage,
            style: context.textTheme.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
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
    final color = isOk ? context.eld.successFg : context.eld.dangerFg;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label, style: context.textTheme.bodyMedium),
      trailing: Text(
        isOk ? okText : badText,
        style: context.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
