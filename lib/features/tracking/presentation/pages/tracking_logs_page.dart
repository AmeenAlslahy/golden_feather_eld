import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../providers/tracking_provider.dart';

/// صفحة سجلات التتبع - من status_screen.dart الأصلي
class TrackingLogsPage extends ConsumerStatefulWidget {
  const TrackingLogsPage({super.key});

  @override
  ConsumerState<TrackingLogsPage> createState() => _TrackingLogsPageState();
}

class _TrackingLogsPageState extends ConsumerState<TrackingLogsPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshLogs();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _refreshLogs();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshLogs() async {
    await ref.read(trackingStateProvider.notifier).loadLogs();
  }

  Future<void> _shareLogs() async {
    final logs = ref.read(trackingStateProvider).logs;
    if (logs.isEmpty) return;

    final text = logs.map((log) {
      final t = log.dateTime;
      return '${t.hour}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')} - ${log.message}';
    }).join('\n');

    await Share.share(text);
  }

  Future<void> _clearLogs(AppLocalizations loc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.confirmTitle),
        content: Text(loc.confirmClearLogs),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.okButton),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(trackingStateProvider.notifier).clearLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final trackingState = ref.watch(trackingStateProvider);
    final logs = trackingState.logs;

    Widget buildEmptyState() {
      if (trackingState.status == TrackingStatus.loading) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(
                loc.loadingRecords,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      }

      IconData icon;
      String message;

      switch (trackingState.status) {
        case TrackingStatus.initial:
        case TrackingStatus.stopped:
          icon = Icons.play_circle_outline;
          message = loc.trackingNotStarted;
          break;
        case TrackingStatus.error:
          final errorMsg = trackingState.errorMessage?.toLowerCase() ?? '';
          if (trackingState.errorType == TrackingErrorType.permission ||
              errorMsg.contains('gps')) {
            icon = Icons.location_off;
            message = loc.gpsDisabled;
          } else if (errorMsg.contains('network') ||
              errorMsg.contains('server') ||
              errorMsg.contains('connection')) {
            icon = Icons.wifi_off;
            message = loc.notConnectedToServer;
          } else {
            icon = Icons.error_outline;
            message = loc.unexpectedError;
          }
          break;
        case TrackingStatus.active:
        default:
          icon = Icons.history;
          message = loc.noRecordsToday;
          break;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const EldDrawer(),
      appBar: AppBar(
        title: Text(loc.statusTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLogs,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _clearLogs(loc),
          ),
        ],
      ),
      body: logs.isEmpty
          ? buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: logs.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        // الوقت
                        SizedBox(
                          width: 60,
                          child: Text(
                            '${log.dateTime.hour}:${log.dateTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // الرسالة
                        Expanded(
                          child: Text(
                            log.message,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
