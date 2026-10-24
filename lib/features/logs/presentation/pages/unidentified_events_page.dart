import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/contracts/contract_enums.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/time_authority_provider.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../providers/unidentified_events_provider.dart';
import '../widgets/annotation_dialog.dart';
import '../widgets/unidentified_events_list.dart';
import '../widgets/unidentified_stats_row.dart';

class UnidentifiedEventsPage extends ConsumerStatefulWidget {
  const UnidentifiedEventsPage({super.key});

  @override
  ConsumerState<UnidentifiedEventsPage> createState() =>
      _UnidentifiedEventsPageState();
}

class _UnidentifiedEventsPageState extends ConsumerState<UnidentifiedEventsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_onTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(unidentifiedEventsProvider.notifier).load();
    });
  }

  void _onTabChange() {
    if (!_tabs.indexIsChanging) {
      final tab = _tabs.index == 0
          ? UnidentifiedTab.unclaimed
          : UnidentifiedTab.rejected;
      ref.read(unidentifiedEventsProvider.notifier).setTab(tab);
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChange);
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = ref.read(timeAuthorityProvider).nowUtc().toLocal();
    final currentDate = ref.read(unidentifiedEventsProvider).dateFilter;
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? now,
      firstDate: now.subtract(const Duration(days: 190)),
      lastDate: now,
    );
    if (!mounted || picked == null) return;
    ref.read(unidentifiedEventsProvider.notifier).setDateFilter(picked);
  }

  Future<void> _toggleVehicleFilter() async {
    final success = await ref
        .read(unidentifiedEventsProvider.notifier)
        .toggleVehicleFilter();
    if (!mounted) return;
    if (!success) {
      AppFeedback.error(context, context.loc.noVehicleIsSelected);
    }
  }

  Future<void> _annotate({
    required String title,
    required String hint,
    required Future<Failure?> Function(String text) action,
  }) async {
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AnnotationDialog(title: title, hint: hint),
    );
    if (text == null || !mounted) return;
    if (text.isEmpty) {
      AppFeedback.error(context, context.loc.anAnnotationIsRequired);
      return;
    }
    final error = await action(text);
    if (!mounted) return;
    if (error != null) {
      AppFeedback.error(context, anyErrorUserMessage(error, loc: context.loc));
      return;
    }
    AppFeedback.success(context, context.loc.yourRecordWasUpdatedReviewThe);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(unidentifiedEventsProvider);
    final notifier = ref.read(unidentifiedEventsProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.loc.unidentifiedEvents,
          style: context.styles.appBarTitle,
        ),
        leading: const BackButton(),
        actions: [
          PopupMenuButton<String>(
            tooltip: context.loc.filter,
            icon: Icon(
              state.hasFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: context.onGold,
            ),
            onSelected: (key) {
              switch (key) {
                case 'date':
                  _pickDate();
                case 'vehicle':
                  _toggleVehicleFilter();
                case 'clear':
                  notifier.clearFilters();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'date', child: Text(context.loc.byDate)),
              CheckedPopupMenuItem(
                value: 'vehicle',
                checked: state.currentVehicleOnly,
                child: Text(context.loc.currentVehicleOnly),
              ),
              if (state.hasFilters)
                PopupMenuItem(
                  value: 'clear',
                  child: Text(context.loc.clearFilters),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: context.onGold,
            onPressed: notifier.refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
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
                        onPressed: notifier.refresh,
                        child: Text(context.loc.retryButton),
                      ),
                    ],
                  ),
                if (state.hasFilters)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        if (state.dateFilter != null)
                          InputChip(
                            label: Text(
                              MaterialLocalizations.of(
                                context,
                              ).formatMediumDate(state.dateFilter!),
                            ),
                            onDeleted: () => notifier.setDateFilter(null),
                          ),
                        if (state.currentVehicleOnly)
                          InputChip(
                            label: Text(context.loc.currentVehicle),
                            onDeleted: _toggleVehicleFilter,
                          ),
                      ],
                    ),
                  ),
                UnidentifiedStatsRow(stats: state.stats),
                Expanded(
                  child: UnidentifiedEventsList(
                    items: state.items,
                    error: state.error,
                    canAct: state.tab == UnidentifiedTab.unclaimed,
                    onClaim: (id) => _annotate(
                      title: context.loc.assume,
                      hint: context.loc.requiredAnnotationThisTimeIsAssumed,
                      action: (text) => notifier.claim(id, text),
                    ),
                    onReject: (id) => _annotate(
                      title: context.loc.notMine,
                      hint: context.loc.requiredRejectionReason,
                      action: (text) => notifier.reject(id, text),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
