import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/battery_optimization_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../providers/tracking_provider.dart';
import '../widgets/quick_actions.dart';
import '../widgets/tracking_status_card.dart';
import '../../../../core/widgets/connection_status_indicator.dart';
import 'tracking_logs_page.dart';

/// صفحة التتبع الرئيسية - من main_screen.dart الأصلي
class TrackingPage extends ConsumerStatefulWidget {
  const TrackingPage({super.key});

  @override
  ConsumerState<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends ConsumerState<TrackingPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(trackingStateProvider.notifier).loadLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final trackingState = ref.watch(trackingStateProvider);

    // ✅ أضف هذا: إظهار حوار البطارية إذا لزم
    if (trackingState.showBatteryDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // إزالة الإشارة فوراً لتجنب التكرار المتعدد
        ref.read(trackingStateProvider.notifier).clearBatteryDialog();
        _showBatteryDialog(context, ref);
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const EldDrawer(),
      appBar: AppBar(
        title: Text(loc.trackingTitle),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Center(child: ConnectionStatusIndicator()),
          ),
          // زر السجلات
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TrackingLogsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // بطاقة حالة التتبع
            const TrackingStatusCard(),
            const SizedBox(height: AppSpacing.md),

            // إجراءات سريعة
            const QuickActions(),
            const SizedBox(height: AppSpacing.md),

            // رسالة خطأ
            if (trackingState.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Text(
                  trackingState.arabicErrorMessage ??
                      trackingState.errorMessage ??
                      '',
                  style: AppTextStyles(context).body.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer),
                ),
              ),

            // معلومات إضافية
            EldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.deviceInformation,
                    style: AppTextStyles(context).sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoItem(context, loc.idLabel, 'DEV-001'),
                  _buildInfoItem(context, loc.urlLabel, 'demo.traccar.org'),
                  _buildInfoItem(
                      context, loc.accuracyLabel, loc.mediumAccuracyLabel),
                  _buildInfoItem(context, loc.intervalLabel, '300'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles(context).caption),
          Text(value, style: AppTextStyles(context).body),
        ],
      ),
    );
  }

  // ✅ أضف هذه الدالة في نفس الملف
  Future<void> _showBatteryDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const BatteryOptimizationDialog(),
    );

    if (mounted) {
      // إذا وافق المستخدم، نطلب تعطيل التحسين
      if (result == true) {
        await ref
            .read(batteryOptimizationServiceProvider)
            .requestDisableBatteryOptimization();
      }
      // نبدأ التتبع في كل الأحوال، ونتخطى الفحص لمنع التكرار
      ref
          .read(trackingStateProvider.notifier)
          .startTracking(skipBatteryCheck: true);
    }
  }
}
