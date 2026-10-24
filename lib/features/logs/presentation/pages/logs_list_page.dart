import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/eld_retry_view.dart';
import '../../../../routes.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/logs_provider.dart';
import '../widgets/log_list_item.dart';

/// شاشة قائمة السجلات
class LogsListPage extends ConsumerWidget {
  const LogsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsState = ref.watch(logsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const EldDrawer(),
      appBar: AppBar(
        title: Text(context.loc.logsTitle, style: context.styles.appBarTitle),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.file_copy,
              color: context.onGold,
            ), // أيقونة القائمة العلوية اليمنى كما في التصميم
            onSelected: (value) {
              if (value == 'suggested') {
                context.push(AppRoutes.suggestedEvents);
              } else if (value == 'unidentified') {
                context.push(AppRoutes.unidentifiedEvents);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'suggested',
                child: Text(context.loc.suggestedEvents),
              ),
              PopupMenuItem<String>(
                value: 'unidentified',
                child: Text(context.loc.unidentifiedEvents),
              ),
            ],
          ),
        ],
      ),
      body: (logsState.isLoading && logsState.logs.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : (logsState.error != null && logsState.logs.isEmpty)
          ? EldRetryView(
              message: anyErrorUserMessage(
                logsState.error!,
                loc: AppLocalizations.of(context)!,
              ),
              onRetry: () =>
                  ref.read(logsProvider.notifier).loadLogs(refresh: true),
            )
          : logsState.logs.isEmpty
          ? EldRetryView(
              message: context.loc.noRecords,
              isError: false,
              onRetry: () =>
                  ref.read(logsProvider.notifier).loadLogs(refresh: true),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(logsProvider.notifier).loadLogs(refresh: true),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.axis == Axis.vertical &&
                      notification.metrics.extentAfter < 240 &&
                      !logsState.isLoading &&
                      logsState.error == null &&
                      logsState.loadMoreError == null &&
                      !logsState.hasReachedMax) {
                    ref.read(logsProvider.notifier).loadLogs();
                  }
                  return false;
                },
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount:
                      logsState.logs.length +
                      (logsState.loadMoreError != null ||
                              (logsState.isLoading && logsState.logs.isNotEmpty)
                          ? 1
                          : 0),
                  separatorBuilder: (_, __) =>
                      Divider(color: Theme.of(context).dividerColor, height: 1),
                  itemBuilder: (context, index) {
                    if (index == logsState.logs.length) {
                      if (logsState.loadMoreError != null) {
                        return EldRetryView(
                          message: anyErrorUserMessage(
                            logsState.loadMoreError!,
                            loc: AppLocalizations.of(context)!,
                          ),
                          onRetry: () =>
                              ref.read(logsProvider.notifier).loadLogs(),
                        );
                      }
                      return const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }

                    final log = logsState.logs[index];
                    return LogListItem(
                      log: log,
                      onTap: () {
                        ref.read(logsProvider.notifier).selectLog(log);
                        context.push(
                          AppRoutes.logDetail.replaceAll(
                            ':id',
                            log.id.value.toString(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
    );
  }
}
