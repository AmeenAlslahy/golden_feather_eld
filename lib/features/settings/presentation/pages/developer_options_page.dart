import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';

class DeveloperOptionsPage extends StatelessWidget {
  const DeveloperOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.developerOptions),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(
                context.loc.trackingLogs),
            subtitle: Text(
                context.loc.viewRawGpsLogs),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/tracking-logs'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: Text(context.loc.mockErrors),
            subtitle: Text(
                context.loc.toolsToTestUi),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(context.loc.notAvailableInProductionBuild)),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: Text(
              context.loc.clearCache,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: Text(context.loc.clearLocalAppData),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(context.loc.cacheCleared)),
              );
            },
          ),
        ],
      ),
    );
  }
}
