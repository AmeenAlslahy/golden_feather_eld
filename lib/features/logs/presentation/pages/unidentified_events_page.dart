import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/contracts/contract_enums.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../hos/presentation/providers/recap_provider.dart';
import '../../../hos/presentation/providers/status_dashboard_providers.dart';
import '../providers/logs_provider.dart';
import '../providers/unidentified_events_provider.dart';

class UnidentifiedEventsPage extends ConsumerStatefulWidget {
  const UnidentifiedEventsPage({super.key});

  @override
  ConsumerState<UnidentifiedEventsPage> createState() =>
      _UnidentifiedEventsPageState();
}

class _UnidentifiedEventsPageState extends ConsumerState<UnidentifiedEventsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  // Owned by the page: disposing a controller right after `showDialog`
  // returns crashes the dialog's exit animation, which still reads it.
  final _annotation = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) _load();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    _annotation.dispose();
    super.dispose();
  }

  UnidentifiedTab get _tab =>
      _tabs.index == 0 ? UnidentifiedTab.unclaimed : UnidentifiedTab.rejected;

  void _load() {
    ref.read(unidentifiedEventsProvider.notifier).load(_tab);
  }

  Future<void> _annotate({
    required String title,
    required String hint,
    required Future<String?> Function(String text) action,
  }) async {
    final controller = _annotation..clear();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
    if (text == null || !mounted) return;
    if (text.isEmpty) {
      _snack(
        Localizations.localeOf(context).languageCode == 'ar'
            ? 'التعليق مطلوب.'
            : 'An annotation is required.',
      );
      return;
    }
    final error = await action(text);
    if (!mounted) return;
    if (error != null) {
      _snack(error);
      return;
    }
    _load();
    // SRS 11.4 / 11.7: an accepted (or rejected) event changes the driver's
    // daily record on the server — re-read logs, dashboard and recap so the
    // new driving time and any re-certification flag show without a restart.
    ref.read(logsProvider.notifier).loadLogs(refresh: true);
    ref.invalidate(statusDashboardProvider);
    ref.invalidate(recapProvider);
    _snack(
      Localizations.localeOf(context).languageCode == 'ar'
          ? 'تم تحديث سجلك. راجع السجل اليومي؛ قد يلزم إعادة التصديق.'
          : 'Your record was updated. Review the daily log; it may need re-certification.',
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(unidentifiedEventsProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.loc.unidentifiedEvents,
          style: context.styles.appBarTitle,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.surface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.surface),
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.surface,
          labelColor: AppColors.surface,
          unselectedLabelColor: AppColors.surface.withValues(alpha: 0.7),
          tabs: [
            Tab(text: context.loc.unclaimed.toUpperCase()),
            Tab(text: context.loc.rejected.toUpperCase()),
          ],
        ),
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (state.error != null)
                  MaterialBanner(
                    content: Text(state.error!),
                    actions: [
                      TextButton(
                        onPressed: _load,
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'إعادة المحاولة'
                              : 'Retry',
                        ),
                      ),
                    ],
                  ),
                _StatsRow(items: state.items, tab: _tab),
                Expanded(
                  child: _EventList(
              items: state.items,
              error: state.error,
              canAct: _tab == UnidentifiedTab.unclaimed,
              onClaim: (id) => _annotate(
                title: Localizations.localeOf(context).languageCode == 'ar'
                    ? 'افتراض'
                    : 'ASSUME',
                hint: Localizations.localeOf(context).languageCode == 'ar'
                    ? 'التعليق مطلوب. تُحتسب هذه المدة قيادة.'
                    : 'Required annotation. This time is assumed as driving.',
                action: (text) =>
                    ref.read(unidentifiedEventsProvider.notifier).claim(id, text),
              ),
              onReject: (id) => _annotate(
                title: Localizations.localeOf(context).languageCode == 'ar'
                    ? 'ليست لي'
                    : 'NOT MINE',
                hint: Localizations.localeOf(context).languageCode == 'ar'
                    ? 'سبب الرفض مطلوب'
                    : 'Required rejection reason',
                action: (text) => ref
                    .read(unidentifiedEventsProvider.notifier)
                    .reject(id, text),
              ),
            ),
                ),
              ],
            ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.items, required this.tab});

  final List<Map<String, dynamic>> items;
  final UnidentifiedTab tab;

  @override
  Widget build(BuildContext context) {
    // SRS 11.6 counts unidentified *driving* inside a rolling 24-hour window,
    // not every driving row the server ever returned. A row without a
    // parseable time is still counted rather than silently hidden.
    final since = DateTime.now().toUtc().subtract(const Duration(hours: 24));
    final driving = items.where((item) {
      final status = '${item['dutyStatus'] ?? ''}'.toUpperCase();
      if (!status.contains('DRIV')) return false;
      final raw = item['endTime'] ?? item['startTime'];
      final when = raw == null ? null : DateTime.tryParse('$raw');
      return when == null || !when.toUtc().isBefore(since);
    }).length;
    final count = '${items.length}';
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          _Stat('TOTAL', count),
          _Stat('UNCLAIMED', tab == UnidentifiedTab.unclaimed ? count : '—'),
          _Stat('REJECTED', tab == UnidentifiedTab.rejected ? count : '—'),
          _Stat('DRIVING 24H', '$driving'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({
    required this.items,
    required this.error,
    required this.canAct,
    required this.onClaim,
    required this.onReject,
  });

  final List<Map<String, dynamic>> items;
  final String? error;
  final bool canAct;
  final ValueChanged<int> onClaim;
  final ValueChanged<int> onReject;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            error ?? context.loc.noRecords,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = items[index];
        final id = item['statusId'] is int ? item['statusId'] as int : null;
        final when = '${item['startTime'] ?? ''}';
        final end = '${item['endTime'] ?? ''}';
        final where = '${item['location'] ?? ''}';
        final status = '${item['dutyStatus'] ?? 'DRIVING'}';
        final duration = '${item['formattedDuration'] ?? ''}';
        final vehicle = '${item['vehicleName'] ?? ''}';
        final reason = '${item['rejectionReason'] ?? ''}';
        final pending = item['daysPending'];
        final overdue = item['overdue'] == true;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(end.isEmpty ? when : '$when – $end'),
                if (duration.isNotEmpty) Text(duration),
                if (vehicle.isNotEmpty) Text(vehicle),
                if (where.isNotEmpty) Text(where),
                if (pending != null)
                  Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'معلّق $pending يوم'
                        : 'Pending $pending day(s)',
                  ),
                if (overdue)
                  Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'متأخر'
                        : 'Overdue',
                    style: const TextStyle(
                        color: AppColors.dangerRed, fontWeight: FontWeight.bold),
                  ),
                if (reason.isNotEmpty) Text(reason),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'النسخة الأصلية محفوظة'
                        : 'Original record preserved',
                  ),
                ),
                if (canAct && id != null)
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => onClaim(id),
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'افتراض'
                              : 'ASSUME',
                        ),
                      ),
                      TextButton(
                        onPressed: () => onReject(id),
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'ليست لي'
                              : 'NOT MINE',
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
