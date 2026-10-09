import 'package:flutter/material.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/time/time_authority_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/contracts/contract_enums.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/unidentified_events_provider.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/error/user_facing_message.dart';

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

  // SRS 11.2 — filters: status = tabs; vehicle = server `uniqueId` of the
  // vehicle in use; date = local match on the event's start day.
  bool _currentVehicleOnly = false;
  DateTime? _dateFilter;

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

  String? get _vehicleFilterUniqueId {
    if (!_currentVehicleOnly) return null;
    final v = ref.read(vehicleProvider).selectedVehicle;
    final uid = v?.uniqueId ?? v?.id;
    return (uid == null || uid.isEmpty) ? null : uid;
  }

  void _load() {
    ref
        .read(unidentifiedEventsProvider.notifier)
        .load(_tab, uniqueId: _vehicleFilterUniqueId);
  }

  bool get _hasFilters => _currentVehicleOnly || _dateFilter != null;

  List<Map<String, dynamic>> _applyDateFilter(List<Map<String, dynamic>> items) {
    final day = _dateFilter;
    if (day == null) return items;
    return items.where((item) {
      final raw = item['startTime'];
      final when = raw == null ? null : DateTime.tryParse('$raw')?.toLocal();
      return when != null &&
          when.year == day.year &&
          when.month == day.month &&
          when.day == day.day;
    }).toList();
  }

  Future<void> _pickDate() async {
    final now = ref.read(timeAuthorityProvider).nowUtc().toLocal();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFilter ?? now,
      firstDate: now.subtract(const Duration(days: 190)),
      lastDate: now,
    );
    if (!mounted || picked == null) return;
    setState(() => _dateFilter = picked);
  }

  Future<void> _toggleVehicleFilter() async {
    final turningOn = !_currentVehicleOnly;
    if (turningOn) {
      // The vehicle state loads lazily; wait for it once so the filter
      // carries the real uniqueId rather than silently matching nothing.
      var vehicle = ref.read(vehicleProvider);
      if (vehicle.selectedVehicle == null && !vehicle.isInitialized) {
        await ref.read(vehicleProvider.notifier).loadVehicles();
        if (!mounted) return;
        vehicle = ref.read(vehicleProvider);
      }
      if (vehicle.selectedVehicle == null) {
        _snack(context.loc.noVehicleIsSelected);
        return;
      }
    }
    setState(() => _currentVehicleOnly = turningOn);
    _load();
  }

  void _clearFilters() {
    setState(() {
      _currentVehicleOnly = false;
      _dateFilter = null;
    });
    _load();
  }

  Future<void> _annotate({
    required String title,
    required String hint,
    required Future<Failure?> Function(String text) action,
  }) async {
    final controller = _annotation..clear();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: AppTextField(
          controller: controller,
          maxLines: 3,
          hint: hint,
          keyboardType: TextInputType.text,
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
        context.loc.anAnnotationIsRequired,
      );
      return;
    }
    final error = await action(text);
    if (!mounted) return;
    if (error != null) {
      AppFeedback.error(context, anyErrorUserMessage(error, loc: context.loc));
      return;
    }
    _load();
    // Note: Dependencies (logs, dashboard, recap) are refreshed inside the notifier.
    AppFeedback.success(
      context,
      context.loc.yourRecordWasUpdatedReviewThe,
    );
  }

  void _snack(String message) => AppFeedback.error(context, message);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(unidentifiedEventsProvider);
    final items = _applyDateFilter(state.items);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.loc.unidentifiedEvents,
          style: context.styles.appBarTitle,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: context.loc.filter,
            icon: Icon(
              _hasFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: AppColors.surface,
            ),
            onSelected: (key) {
              switch (key) {
                case 'date':
                  _pickDate();
                case 'vehicle':
                  _toggleVehicleFilter();
                case 'clear':
                  _clearFilters();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'date',
                child: Text(context.loc.byDate),
              ),
              CheckedPopupMenuItem(
                value: 'vehicle',
                checked: _currentVehicleOnly,
                child: Text(
                    context.loc.currentVehicleOnly),
              ),
              if (_hasFilters)
                PopupMenuItem(
                  value: 'clear',
                  child: Text(context.loc.clearFilters),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: AppColors.surface,
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
                    content: Text(state.error!, style: context.styles.error),
                    actions: [
                      TextButton(
                        onPressed: _load,
                        child: Text(
                          context.loc.retryButton,
                        ),
                      ),
                    ],
                  ),
                if (_hasFilters)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm),
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        if (_dateFilter != null)
                          InputChip(
                            label: Text(MaterialLocalizations.of(context)
                                .formatMediumDate(_dateFilter!)),
                            onDeleted: () =>
                                setState(() => _dateFilter = null),
                          ),
                        if (_currentVehicleOnly)
                          InputChip(
                            label: Text(context.loc.currentVehicle),
                            onDeleted: _toggleVehicleFilter,
                          ),
                      ],
                    ),
                  ),
                _StatsRow(
                  now: ref.read(timeAuthorityProvider).nowUtc(),
                  items: items,
                  tab: _tab,
                  unclaimedCount: state.unclaimedCount,
                  rejectedCount: state.rejectedCount,
                ),
                Expanded(
                  child: _EventList(
              items: items,
              error: state.error,
              canAct: _tab == UnidentifiedTab.unclaimed,
              onClaim: (id) => _annotate(
                title: context.loc.assume,
                hint: context.loc.requiredAnnotationThisTimeIsAssumed,
                action: (text) =>
                    ref.read(unidentifiedEventsProvider.notifier).claim(id, text),
              ),
              onReject: (id) => _annotate(
                title: context.loc.notMine,
                hint: context.loc.requiredRejectionReason,
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
  const _StatsRow({
    required this.now,
    required this.items,
    required this.tab,
    this.unclaimedCount,
    this.rejectedCount,
  });

  final DateTime now;
  final List<Map<String, dynamic>> items;
  final UnidentifiedTab tab;
  final int? unclaimedCount;
  final int? rejectedCount;

  @override
  Widget build(BuildContext context) {
    // SRS 11.6 counts unidentified *driving* inside a rolling 24-hour window,
    // not every driving row the server ever returned. A row without a
    // parseable time is still counted rather than silently hidden.
    final since = now.subtract(const Duration(hours: 24));
    final driving = items.where((item) {
      final status = '${item['dutyStatus'] ?? ''}'.toUpperCase();
      if (!status.contains('DRIV')) return false;
      final raw = item['endTime'] ?? item['startTime'];
      final when = raw == null ? null : DateTime.tryParse('$raw');
      return when == null || !when.toUtc().isBefore(since);
    }).length;
    // SRS 11.2 — counters across both statuses; the current tab's count is
    // the (possibly date-filtered) visible list, the other tab's count comes
    // from the parallel fetch. '—' only when that fetch failed.
    final unclaimed =
        tab == UnidentifiedTab.unclaimed ? items.length : unclaimedCount;
    final rejected =
        tab == UnidentifiedTab.rejected ? items.length : rejectedCount;
    final total = (unclaimed == null || rejected == null)
        ? items.length
        : unclaimed + rejected;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          _Stat(context.loc.total, '$total'),
          _Stat(context.loc.unclaimed, '${unclaimed ?? '—'}'),
          _Stat(context.loc.rejected, '${rejected ?? '—'}'),
          _Stat(context.loc.driving24h, '$driving'),
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
              Text(value, style: context.styles.bodyBold),
              Text(label, style: context.styles.caption.copyWith(fontSize: 10)),
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
        final eldId = '${item['uniqueId'] ?? ''}';
        final allocation = '${item['allocationStatus'] ?? ''}';
        final reason = '${item['rejectionReason'] ?? ''}';
        final pending = item['daysPending'];
        final overdue = item['overdue'] == true;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(status,
                          style: context.styles.bodyBold),
                    ),
                    // SRS 11.2 — allocation state chip from the server.
                    if (allocation.isNotEmpty)
                      Chip(
                        label: Text(allocation.replaceAll('_', ' ')),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(end.isEmpty ? when : '$when – $end'),
                if (duration.isNotEmpty) Text(duration),
                if (vehicle.isNotEmpty) Text(vehicle),
                // SRS 11.2 — ELD / vehicle identifier of the record.
                if (eldId.isNotEmpty) Text('ELD: $eldId'),
                if (where.isNotEmpty) Text(where),
                if (pending != null)
                  Text(
                    context.loc.pendingDays(pending),
                  ),
                if (overdue)
                  Text(
                    context.loc.overdue,
                    style: context.styles.error
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                if (reason.isNotEmpty) Text(reason),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    context.loc.originalRecordPreserved,
                  ),
                ),
                if (canAct && id != null)
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => onClaim(id),
                        child: Text(
                          context.loc.assume,
                        ),
                      ),
                      TextButton(
                        onPressed: () => onReject(id),
                        child: Text(
                          context.loc.notMine,
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
