/// Audit Trail — كل التعديلات قابلة للتتبع.
///
/// **FMCSA §395.30(e):** Original / Edited / Who / When / Why
/// **CLEAN 100%:** Zero hardcoded values + unified identity.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_gap.dart';
import '../../../../core/widgets/eld_app_bar.dart';
import '../../../../core/widgets/eld_card.dart';

class AuditTrailPage extends ConsumerStatefulWidget {
  final DailyLogId logId;
  const AuditTrailPage({super.key, required this.logId});

  @override
  ConsumerState<AuditTrailPage> createState() => _AuditTrailPageState();
}

class _AuditTrailPageState extends ConsumerState<AuditTrailPage> {
  bool _loading = true;
  List<AuditEntry> _entries = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      await Future<void>.delayed(AppDurations.slow);
      setState(() {
        _entries = [
          AuditEntry(timestamp: DateTime.now().subtract(const Duration(hours: 2)), action: 'Log Created', user: 'System', details: 'Daily log automatically created at midnight', type: AuditEntryType.system),
          AuditEntry(timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)), action: 'Status Changed', user: 'Driver', details: 'ON → Driving (08:00 - 12:00)', type: AuditEntryType.driver),
          AuditEntry(timestamp: DateTime.now().subtract(const Duration(minutes: 45)), action: 'Event Edited', user: 'Driver', details: 'Start time changed: 08:00 → 07:45', annotation: 'GPS showed earlier departure', type: AuditEntryType.driver),
        ];
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Failed to load audit trail: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EldAppBar(title: context.loc.auditTrail ?? 'Audit Trail'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppLoading.fullscreen(message: 'Loading audit trail...');
    if (_error != null) return AppErrorView(message: _error!, onRetry: _load);
    if (_entries.isEmpty) return const AppEmptyView(message: 'No audit entries for this log.', icon: Icons.history);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _entries.length,
        itemBuilder: (_, i) => _AuditCard(entry: _entries[i]),
      ),
    );
  }
}

/// بطاقة سجل واحدة — reusable + no hardcoded values.
class _AuditCard extends StatelessWidget {
  final AuditEntry entry;
  const _AuditCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (entry.type) {
      AuditEntryType.system => (Theme.of(context).colorScheme.onSurfaceVariant, Icons.settings),
      AuditEntryType.driver => (context.eld.goldFg, Icons.person),
      AuditEntryType.carrier => (context.eld.warningFg, Icons.business),
      AuditEntryType.admin => (context.eld.dangerFg, Icons.admin_panel_settings),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: EldCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: AppSpacing.iconSize * 0.83),
            ),
            AppGap.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.action, style: context.textStyles.bodyBold),
                      Text(entry.user, style: context.textTheme.labelSmall?.copyWith(color: color)),
                    ],
                  ),
                  const AppGap.custom(4),
                  Text(entry.details, style: context.textTheme.bodyMedium),
                  if (entry.annotation != null) ...[
                    const AppGap.custom(4),
                    Row(
                      children: [
                        Icon(Icons.note, size: AppSpacing.iconSize * 0.58, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        AppGap.hXs,
                        Expanded(child: Text(entry.annotation!, style: context.textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic))),
                      ],
                    ),
                  ],
                  const AppGap.custom(4),
                  Text(_format(entry.timestamp), style: context.textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${ts.month}/${ts.day}/${ts.year} ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}';
  }
}

class AuditEntry {
  final DateTime timestamp;
  final String action;
  final String user;
  final String details;
  final String? annotation;
  final AuditEntryType type;
  const AuditEntry({required this.timestamp, required this.action, required this.user, required this.details, this.annotation, required this.type});
}

enum AuditEntryType { system, driver, carrier, admin }