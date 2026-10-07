import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../domain/entities/hardware_alert.dart';
import '../../presentation/providers/hardware_alerts_provider.dart';
import '../widgets/diagnostics/active_malfunction_actions.dart';
import '../widgets/diagnostics/event_card.dart';
import '../widgets/diagnostics/stat_row.dart';

/// SRS 7.14 — شاشة التشخيصات والأعطال (مستقلة عن شاشة الاتصال).
///
/// تفصل DATA_DIAGNOSTIC عن MALFUNCTION بصرياً وبمنطق التصنيف، ولا تُخفي
/// المؤشرات عن السائق المتأثر، ولا تعتبر كل diagnostic عطلاً.
class DiagnosticsPage extends ConsumerWidget {
  const DiagnosticsPage({super.key});

  bool _isMalfunction(HardwareAlert a) =>
      a.type.toUpperCase().contains('MALFUNCTION');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(hardwareAlertsProvider);
    final loc = context.loc;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.diagnosticsScreen, style: context.styles.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: AppColors.surface,
            onPressed: () => ref.invalidate(hardwareAlertsProvider),
          ),
        ],
      ),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            anyErrorUserMessage(e, loc: loc),
            style: context.styles.error,
          ),
        ),
        data: (alerts) {
          final malfunctions =
              alerts.where(_isMalfunction).toList(growable: false);
          final diagnostics =
              alerts.where((a) => !_isMalfunction(a)).toList(growable: false);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              StatRow(alerts: alerts, malfunctions: malfunctions),
              const SizedBox(height: AppSpacing.lg),
              Text(loc.diagnosticEvents, style: context.styles.sectionTitle),
              const SizedBox(height: AppSpacing.sm),
              if (diagnostics.isEmpty)
                Text(loc.dvirListNoRecords, style: context.styles.muted)
              else
                for (final a in diagnostics)
                  EventCard(alert: a, malfunction: false),
              const SizedBox(height: AppSpacing.lg),
              Text(loc.eldMalfunctionTitle,
                  style: context.styles.sectionTitle),
              const SizedBox(height: AppSpacing.sm),
              if (malfunctions.isEmpty)
                Text(loc.dvirListNoRecords, style: context.styles.muted)
              else ...[
                for (final a in malfunctions) EventCard(alert: a, malfunction: true),
                const SizedBox(height: AppSpacing.md),
                // SRS 3.7 / 7.14: إجراءات العطل النشط — إخطار الناقل +
                // التسجيل اليدوي + طلب التمديد. الأزرار إرشادية للسائق.
                const ActiveMalfunctionActions(),
              ],
              if (kDebugMode) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(loc.simulateMalfunctionDebug,
                    style: context.styles.caption),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => AppFeedback.info(
                      context, loc.simulatedMalfunctionRecorded),
                  child: Text(loc.simulateMalfunction),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}



