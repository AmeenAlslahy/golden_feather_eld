import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/tracking/domain/entities/connection_status.dart';
import '../../routes.dart';
import '../extensions/context_extensions.dart';
import '../services/live_tracking_data_source.dart';
import '../theme/app_colors.dart';

final connectionStatusStreamProvider =
    StreamProvider.autoDispose<ConnectionStatus>((ref) async* {
  final liveTracking = ref.watch(liveTrackingDataSourceProvider);
  // إرسال حالة ابتدائية "غير متصل" لضمان عدم تعليق الواجهة في حالة التحميل (Loading)
  // لأن الـ Stream قد يكون Broadcast Event انطلق قبل الاستماع
  yield ConnectionStatus.disconnected;
  yield* liveTracking.connectionStatus;
});

class ConnectionStatusIndicator extends ConsumerWidget {
  const ConnectionStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsyncValue = ref.watch(connectionStatusStreamProvider);

    // لا تسجيل داخل build: المعرّف يظهر في AppBar ويُعاد بناؤه كثيراً.
    final status = statusAsyncValue.value ?? ConnectionStatus.disconnected;

    return _buildIndicator(context, status);
  }

  Widget _buildIndicator(BuildContext context, ConnectionStatus status) {
    if (status == ConnectionStatus.disconnected ||
        status == ConnectionStatus.error ||
        status == ConnectionStatus.unconfigured) {
      return IconButton(
        icon: const Icon(Icons.warning_amber,
            color: AppColors.warningYellow, size: 28),
        onPressed: () {
          context.push(AppRoutes.connection);
        },
      );
    }

    Color color;
    String text;
    IconData icon;
    bool isSyncingOrConnecting = false;

    if (status == ConnectionStatus.connected) {
      color = AppColors.successGreen;
      text = context.loc.connected;
      icon = Icons.wifi;
    } else {
      color = AppColors.warningYellow;
      text = context.loc.connecting;
      icon = Icons.wifi_protected_setup;
      isSyncingOrConnecting = true;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSyncingOrConnecting)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style:
                    (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
                        .copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
