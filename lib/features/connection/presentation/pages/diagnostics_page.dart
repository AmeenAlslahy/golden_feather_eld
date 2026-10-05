import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/hardware_alert.dart';
import '../../presentation/providers/hardware_alerts_provider.dart';

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
              _StatRow(alerts: alerts, malfunctions: malfunctions),
              const SizedBox(height: AppSpacing.lg),
              Text(loc.diagnosticEvents, style: context.styles.sectionTitle),
              const SizedBox(height: AppSpacing.sm),
              if (diagnostics.isEmpty)
                Text(loc.dvirListNoRecords, style: context.styles.muted)
              else
                for (final a in diagnostics)
                  _EventCard(alert: a, malfunction: false),
              const SizedBox(height: AppSpacing.lg),
              Text(loc.eldMalfunctionTitle,
                  style: context.styles.sectionTitle),
              const SizedBox(height: AppSpacing.sm),
              if (malfunctions.isEmpty)
                Text(loc.dvirListNoRecords, style: context.styles.muted)
              else ...[
                for (final a in malfunctions) _EventCard(alert: a, malfunction: true),
                const SizedBox(height: AppSpacing.md),
                // SRS 3.7 / 7.14: إجراءات العطل النشط — إخطار الناقل +
                // التسجيل اليدوي + طلب التمديد. الأزرار إرشادية للسائق.
                _ActiveMalfunctionActions(),
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

class _StatRow extends StatelessWidget {
  final List<HardwareAlert> alerts;
  final List<HardwareAlert> malfunctions;

  const _StatRow({required this.alerts, required this.malfunctions});

  @override
  Widget build(BuildContext context) {
    final diagnostics = alerts.length - malfunctions.length;
    String two(int v) => v.toString().padLeft(2, '0');
    return Row(
      children: [
        _StatCard(context.loc.active, two(alerts.length)),
        _StatCard('ACTIVE DIAG', two(diagnostics)),
        _StatCard('ACTIVE MALF', two(malfunctions.length)),
        _StatCard('TOTAL DIAG', two(diagnostics)),
        _StatCard('TOTAL MALF', two(malfunctions.length)),
      ].map((w) => Expanded(child: w)).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: 4),
        child: Column(
          children: [
            Text(value, style: context.styles.number),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: context.styles.caption.copyWith(fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final HardwareAlert alert;
  final bool malfunction;

  const _EventCard({required this.alert, required this.malfunction});

  @override
  Widget build(BuildContext context) {
    final kind =
        malfunction ? 'MALFUNCTION' : 'DATA_DIAGNOSTIC';
    final detectedAt = alert.timestamp;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: malfunction
            ? AppColors.dangerBg.withValues(alpha: 0.35)
            : AppColors.warningBg.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
          color: malfunction ? AppColors.dangerRed : AppColors.warningYellow,
          width: malfunction ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // تمييز بصري صريح: MALFUNCTION ≠ DATA_DIAGNOSTIC
              Text(kind,
                  style: context.styles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: malfunction
                        ? AppColors.dangerText
                        : AppColors.warningText,
                  )),
              const Spacer(),
              Text('DETECTED',
                  style: context.styles.caption
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(alert.message, style: context.styles.body),
          if (detectedAt != null)
            Text(
              AppLocalizations.of(context)!.startedOnDate(
                  '${detectedAt.month}/${detectedAt.day}/${detectedAt.year}'),
              style: context.styles.caption,
            ),
        ],
      ),
    );
  }
}

/// إجراءات العطل النشط وفق SRS 3.7: تدوين العطل وإخطار الناقل خلال 24 ساعة،
/// إعادة بناء السجل (24 ساعة + 7 أيام نماذج ورقية)، والاستمرار اليدوي حتى
/// إصلاح ELD.
class _ActiveMalfunctionActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.notifications_active, size: 18),
          label: Text(context.loc.notifyCarrier),
          onPressed: () => AppFeedback.info(
              context, context.loc.eldMalfunctionStep1),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_note, size: 18),
          label: Text(context.loc.eldMalfunctionManualActive),
          onPressed: () => AppFeedback.info(
              context, context.loc.eldMalfunctionStep2),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          icon: const Icon(Icons.schedule, size: 18),
          label: Text(context.loc.requestExtension),
          onPressed: () => AppFeedback.info(
              context, context.loc.eldMalfunctionStep3),
        ),
      ],
    );
  }
}
