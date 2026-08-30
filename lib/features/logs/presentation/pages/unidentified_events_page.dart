import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class UnidentifiedEventsPage extends StatelessWidget {
  const UnidentifiedEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            context.loc.unidentifiedEvents,
            style: const TextStyle(
              fontSize: AppTypography.bodySize,
              fontWeight: AppTypography.bold,
              color: AppColors.surface,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.surface),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.surface,
            indicatorWeight: 3,
            labelColor: AppColors.surface,
            unselectedLabelColor: AppColors.surface.withValues(alpha: 0.7),
            labelStyle: const TextStyle(
              fontWeight: AppTypography.bold,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: context.loc.unclaimed.toUpperCase()),
              Tab(text: context.loc.rejected.toUpperCase()),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _UnclaimedTab(),
            _RejectedTab(),
          ],
        ),
      ),
    );
  }
}

class _UnclaimedTab extends StatelessWidget {
  const _UnclaimedTab();

  @override
  Widget build(BuildContext context) {
    // Dummy events based on the screenshot
    final events = [
      {
        'status': 'ON',
        'color': Colors.blue,
        'date': 'Aug 26, 2026 7:19 AM EDT'
      },
      {
        'status': 'D',
        'color': Colors.green,
        'date': 'Aug 26, 2026 7:15 AM EDT'
      },
      {
        'status': 'ON',
        'color': Colors.blue,
        'date': 'Aug 26, 2026 7:14 AM EDT'
      },
    ];

    return Column(
      children: [
        // Sticky Header for Vehicle ID
        Container(
          width: double.infinity,
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: const Text(
            '286 (1FUJA6CK06LV66287)',
            style: TextStyle(
              fontWeight: AppTypography.bold,
              fontSize: AppTypography.bodySize,
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: events.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, thickness: 1),
            itemBuilder: (context, index) {
              final event = events[index];
              return InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('ميزة تبني الأحداث المجهولة قيد التطوير')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.md),
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    children: [
                      // Colored Indicator Line
                      Container(
                        width: 4,
                        height: 20,
                        color: event['color'] as Color,
                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                      ),
                      // Status Code
                      SizedBox(
                        width: 40,
                        child: Text(
                          event['status'] as String,
                          style: const TextStyle(
                            fontWeight: AppTypography.bold,
                            fontSize: AppTypography.bodySize,
                          ),
                        ),
                      ),
                      // Date/Time
                      Expanded(
                        child: Text(
                          event['date'] as String,
                          style: const TextStyle(
                            fontSize: AppTypography.bodySize,
                          ),
                        ),
                      ),
                      // Trailing Arrow
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RejectedTab extends StatelessWidget {
  const _RejectedTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        context.loc.noRecords,
        style: TextStyle(
          fontSize: 18.0,
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant
              .withValues(alpha: 0.5),
          fontWeight: AppTypography.semiBold,
        ),
      ),
    );
  }
}
