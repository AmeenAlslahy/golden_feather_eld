import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/hardware_status_provider.dart';

/// Server-side ELD connectivity status lines (SRS 3.8 diagnostics).
class EldConnectivityPanel extends ConsumerWidget {
  const EldConnectivityPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    final status = ref.watch(hardwareStatusProvider);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: status.when(
        loading: () => Text(
          loc.eldDiagnosticReading,
          style: context.styles.body,
        ),
        error: (error, _) => Text(
          anyErrorUserMessage(error, loc: AppLocalizations.of(context)!),
          style: context.styles.error,
        ),
        data: (data) => _statusBody(context, data),
      ),
    );
  }

  Widget _statusBody(BuildContext context, ConnectivityStatus data) {
    final loc = context.loc;
    final lines = <String>[
      _statusLine(data, loc),
      if (data.hasDiagnostic)
        loc.eldDiagnosticDiagnosticFormat(data.diagnostics.join(', ')),
      if (data.malfunctions.isNotEmpty)
        loc.eldDiagnosticMalfunctionFormat(data.malfunctions.join(', ')),
      if (data.lastHeartbeat != null && data.lastHeartbeat!.isNotEmpty)
        loc.eldDiagnosticLastValidDataFormat(data.lastHeartbeat!),
      if (data.dataAgeSeconds != null)
        loc.eldDiagnosticDataAgeFormat(data.dataAgeSeconds!.toString()),
      if (data.normalOperationAllowed == false)
        loc.eldDiagnosticNotReady,
      if (data.isReliable == false)
        loc.eldDiagnosticDataNotReliable,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(line, style: context.styles.body),
          ),
      ],
    );
  }

  String _statusLine(ConnectivityStatus data, AppLocalizations loc) {
    switch (data.connectionStatus?.toUpperCase()) {
      case 'CONNECTED':
        return loc.eldDiagnosticConnected;
      case 'DISCONNECTED':
        return loc.eldDiagnosticDisconnected;
      case 'UNAVAILABLE':
        return loc.eldDiagnosticUnavailable;
      case 'MALFUNCTION':
        return loc.eldDiagnosticMalfunction;
      case null:
        return loc.eldDiagnosticNoConnectionStatus;
      default:
        return data.connectionStatus!;
    }
  }
}
